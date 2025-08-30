//
//  VideoItem.swift
//  Slide
//
//  Created by Nick Rogers on 8/25/25.
//

import SwiftUI
import AVFoundation
import Combine
import UIKit
import AVKit
import swiftui_loop_videoplayer

// MARK: - Video Item Model
struct VideoItem: Identifiable, Hashable {
    let id: String // Changed from UUID() to String for Firestore compatibility
    let url: URL
    let thumbnailURL: URL?
    let title: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Player Pool Manager
class VideoPlayerPool: ObservableObject {
    private var availablePlayers: [AVPlayer] = []
    private var activePlayers: [String: AVPlayer] = [:]
    private let maxPoolSize = 5
    
    init() {
        for _ in 0..<maxPoolSize {
            let player = AVPlayer()
            player.actionAtItemEnd = .none
            availablePlayers.append(player)
        }
    }
    
    func getPlayer(for videoId: String, url: URL) -> AVPlayer {
        if let existingPlayer = activePlayers[videoId] {
            return existingPlayer
        }
        
        let player = availablePlayers.popLast() ?? {
            let newPlayer = AVPlayer()
            newPlayer.actionAtItemEnd = .none
            return newPlayer
        }()
        
        let playerItem = AVPlayerItem(url: url)
        playerItem.preferredForwardBufferDuration = 2.0
        player.replaceCurrentItem(with: playerItem)
        
        activePlayers[videoId] = player
        
        return player
    }
    
    func releasePlayer(for videoId: String) {
        guard let player = activePlayers.removeValue(forKey: videoId) else { return }
        
        player.pause()
        player.replaceCurrentItem(with: nil)
        
        if availablePlayers.count < maxPoolSize {
            availablePlayers.append(player)
        }
    }
    
    func pauseAll() {
        activePlayers.values.forEach { $0.pause() }
    }
}

// MARK: - PlayerView class for optimized player display
class PlayerView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    var player: AVPlayer? {
        get { playerLayer.player }
        set { playerLayer.player = newValue }
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}

struct OptimizedVideoPlayer: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        view.player = player
        view.playerLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PlayerView, context: Context) {
        uiView.player = player
        uiView.playerLayer.videoGravity = .resizeAspectFill
    }
}


// MARK: - Video Preloader
class VideoPreloader: ObservableObject {
    private var preloadTasks: [String: URLSessionDataTask] = [:]
    private var cache = NSCache<NSString, NSData>()
    
    init() {
        cache.countLimit = 50 // Keep 50 videos cached
        cache.totalCostLimit = 100 * 1024 * 1024 // 100MB cache
    }
    
    func preloadVideo(for item: VideoItem) {
        let key = item.url.absoluteString
        
        // Skip if already cached or being loaded
        if cache.object(forKey: key as NSString) != nil || preloadTasks[key] != nil {
            return
        }
        
        let task = URLSession.shared.dataTask(with: item.url) { [weak self] data, response, error in
            guard let data = data, error == nil else { return }
            
            DispatchQueue.main.async {
                self?.cache.setObject(data as NSData, forKey: key as NSString)
                self?.preloadTasks.removeValue(forKey: key)
            }
        }
        
        preloadTasks[key] = task
        task.resume()
    }
    
    func cancelPreload(for item: VideoItem) {
        let key = item.url.absoluteString
        preloadTasks[key]?.cancel()
        preloadTasks.removeValue(forKey: key)
    }
}



// MARK: - Video Cell with Smart Loading
struct VideoCell: View {
    let item: VideoItem
    let isVisible: Bool
    let showControls: Bool
    /// If true, video will loop automatically when finished playing.
    let isLooping: Bool
    
    let onVisibilityChange: (Bool) -> Void
    @Binding var isMuted: Bool
    
    @EnvironmentObject private var playerPool: VideoPlayerPool
    @State private var thumbnailImage: UIImage?
    @State private var isPlayerReady = false
    @State private var showControlsOverlay: Bool = false
    @State private var player: AVPlayer?
    @State private var cancellables = Set<AnyCancellable>()
    @State private var endObserver: Any? = nil
    
    init(item: VideoItem, isVisible: Bool, showControls: Bool = false, isMuted: Binding<Bool>, isLooping: Bool = true, onVisibilityChange: @escaping (Bool) -> Void) {
        self.item = item
        self.isVisible = isVisible
        self.showControls = showControls
        self._isMuted = isMuted
        self.isLooping = isLooping
        self.onVisibilityChange = onVisibilityChange
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background color for loading state
                Color.black
                
                // Thumbnail layer (shows immediately)
                if let thumbnail = thumbnailImage {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .opacity(isPlayerReady && isVisible ? 0 : 1)
                        .animation(.easeInOut(duration: 0.3), value: isPlayerReady && isVisible)
                }
                
                // Video player layer
                if let player = player, isVisible {
                    OptimizedVideoPlayer(player: player)
                        .opacity(isPlayerReady ? 1 : 0)
                        .animation(.easeInOut(duration: 0.3), value: isPlayerReady)
                        .onTapGesture {
                            flashControls()
                        }
                }
                
                // Loading indicator
                if !isPlayerReady && thumbnailImage == nil {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                }
                
               
            }
        }
        .clipped()
        .overlay(alignment: .bottomTrailing) {
            if showControlsOverlay {
                mediaControls()
                    .transition(.blurReplace)
                    .animation(.smooth, value: showControlsOverlay)
            }
        }
        .onAppear {
            print("VideoCell appeared for: \(item.title)")
            loadThumbnail()
            if isVisible {
                setupPlayer()
                flashControls()
            }
        }
        .onDisappear {
            print("VideoCell disappeared for: \(item.title)")
            cleanupPlayer()
        }
        .onChange(of: isVisible) { oldValue, newValue in
            print("Visibility changed for \(item.title): \(newValue)")
            handleVisibilityChange(newValue)
        }
        .onChange(of: isMuted) { newMuted in
            print("Muted state changed for \(item.title): \(newMuted)")
            player?.isMuted = newMuted
        }
    }
    
    private func flashControls() {
        Task {
            withAnimation(.smooth) {
                self.showControlsOverlay = true
            }
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            withAnimation(.smooth) {
                self.showControlsOverlay = false
            }
        }
    }
    
    @ViewBuilder
    func mediaControls() -> some View {
        let buttonSize: CGFloat = 30
        Circle()
            .fill(.clear)
            .frame(width: buttonSize, height: buttonSize)
            .overlay {
                Image(systemName: isMuted ? "speaker.slash" : "speaker")
                    .padding(6)
            }
            .glassEffect(.regular)
            .padding()
    }
    
    private func setupPlayer() {
        print("Setting up player for: \(item.title)")
        let newPlayer = playerPool.getPlayer(for: item.id, url: item.url)
        newPlayer.isMuted = isMuted
        self.player = newPlayer
        
        if isLooping, let playerItem = newPlayer.currentItem {
            endObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: playerItem, queue: .main) { _ in
                newPlayer.seek(to: .zero)
                newPlayer.play()
            }
        }
        
        // Monitor player status
        newPlayer.publisher(for: \.currentItem?.status)
            .receive(on: DispatchQueue.main)
            .sink { status in
                print("Player status for \(item.title): \(status?.rawValue ?? -1)")
                if status == .readyToPlay {
                    self.isPlayerReady = true
                    if isVisible {
                        newPlayer.play()
                    }
                } else if status == .failed {
                    print("Player failed for \(item.title): \(newPlayer.currentItem?.error?.localizedDescription ?? "Unknown error")")
                }
            }
            .store(in: &cancellables)
    }
    
    private func loadThumbnail() {
        guard let thumbnailURL = item.thumbnailURL else {
            print("No thumbnail URL for: \(item.title)")
            return
        }
        
        print("Loading thumbnail for: \(item.title) from: \(thumbnailURL)")
        
        URLSession.shared.dataTask(with: thumbnailURL) { data, response, error in
            if let error = error {
                print("Thumbnail load error for \(item.title): \(error.localizedDescription)")
                return
            }
            
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    print("Thumbnail loaded successfully for: \(item.title)")
                    self.thumbnailImage = image
                }
            } else {
                print("Failed to create image from data for: \(item.title)")
            }
        }.resume()
    }
    
    private func handleVisibilityChange(_ visible: Bool) {
        onVisibilityChange(visible)
        
        if visible {
            if player == nil {
                setupPlayer()
            } else if isPlayerReady {
                player?.play()
            }
        } else {
            player?.pause()
        }
    }
    
    private func cleanupPlayer() {
        cancellables.removeAll()
        if let player = player {
            player.pause()
            playerPool.releasePlayer(for: item.id)
            self.player = nil
            self.isPlayerReady = false
        }
        if let observer = endObserver {
            NotificationCenter.default.removeObserver(observer)
            endObserver = nil
        }
    }
}

// MARK: - Standalone Single Video Player
struct SingleVideoPlayer: View {
    let videoItem: VideoItem
    let showControls: Bool
    @Binding var isMuted: Bool
    /// If true, video will loop automatically when finished playing.
    let isLooping: Bool
    
    @StateObject private var playerPool = VideoPlayerPool()
    @State private var isVideoVisible = true
    
    init(videoItem: VideoItem, showControls: Bool = true, isMuted: Binding<Bool>, isLooping: Bool = true) {
        self.videoItem = videoItem
        self.showControls = showControls
        self._isMuted = isMuted
        self.isLooping = isLooping
    }
    
    var body: some View {
        VideoCell(
            item: videoItem,
            isVisible: isVideoVisible,
            showControls: showControls,
            isMuted: $isMuted,
            isLooping: isLooping
        ) { isVisible in
            // Handle visibility changes if needed
            print("Video visibility: \(isVisible)")
        }
        .environmentObject(playerPool)
        .onAppear {
            isVideoVisible = true
        }
        .onDisappear {
            isVideoVisible = false
        }
    }
}

struct SingleVideoDetailView: View {
    let video: VideoItem
    @State private var isMuted: Bool = false
    
    var body: some View {
        VStack {
            // Full-screen video player with controls
            SingleVideoPlayer(videoItem: video, showControls: true, isMuted: $isMuted)
                .aspectRatio(16/9, contentMode: .fit)
            
            // Video details below
            VStack(alignment: .leading, spacing: 16) {
                Text(video.title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Video URL: \(video.url.absoluteString)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct EmbeddedVideoView: View {
    let video: VideoItem
    var height: CGFloat = 200
    @Binding var isMuted: Bool
    /// If true, video will loop automatically when finished playing.
    let isLooping: Bool
    
    init(video: VideoItem, height: CGFloat = 200, isMuted: Binding<Bool>, isLooping: Bool = true) {
        self.video = video
        self.height = height
        self._isMuted = isMuted
        self.isLooping = isLooping
    }
    
    var body: some View {
        VStack {
           
            
            // Embedded video without controls
            SingleVideoPlayer(videoItem: video, showControls: false, isMuted: $isMuted, isLooping: isLooping)
                .frame(height: height)
           
        }
    }
}

struct CompactVideoPlayer: View {
    let video: VideoItem
    @State private var isPlaying = false
    @State private var isMuted: Bool = false
    
    var body: some View {
        VStack {
            // Compact video player
            SingleVideoPlayer(videoItem: video, showControls: true, isMuted: $isMuted)
                .frame(height: 250)
                .cornerRadius(8)
            
            HStack {
                VStack(alignment: .leading) {
                    Text(video.title)
                        .font(.headline)
                    Text("Tap to play")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 4)
    }
}


// MARK: - Visibility Tracking View Modifier
struct VisibilityTracker: UIViewRepresentable {
    let onVisibilityChanged: (Bool) -> Void
    
    func makeUIView(context: Context) -> UIView {
        let view = VisibilityTrackingView()
        view.onVisibilityChanged = onVisibilityChanged
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

class VisibilityTrackingView: UIView {
    var onVisibilityChanged: ((Bool) -> Void)?
    private var isVisible = false
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        checkVisibility()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        checkVisibility()
    }
    
    private func checkVisibility() {
        guard let window = window else { return }
        
        let viewFrame = convert(bounds, to: window)
        let windowBounds = window.bounds
        
        let visibleRect = viewFrame.intersection(windowBounds)
        let visibilityThreshold: CGFloat = 0.5
        
        let newIsVisible = visibleRect.height >= bounds.height * visibilityThreshold
        
        if newIsVisible != isVisible {
            isVisible = newIsVisible
            onVisibilityChanged?(isVisible)
        }
    }
}

// MARK: - Main Feed View
struct FastVideoFeed: View {
    @State private var videos: [VideoItem] = []
    @State private var visibleVideos: Set<String> = []
    @StateObject private var preloader = VideoPreloader()
    @StateObject private var playerPool = VideoPlayerPool()
    @State private var isMuted: Bool = false
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(videos.enumerated(), id: \.element.id) { index, video in
                        VideoCell(
                            item: video,
                            isVisible: visibleVideos.contains(video.id),
                            showControls: false,
                            isMuted: $isMuted
                        ) { isVisible in
                            handleVideoVisibility(video.id, isVisible: isVisible)
                        }
                        .frame(height: UIScreen.main.bounds.height * 0.7)
                        .background(
                            VisibilityTracker { isVisible in
                                handleVideoVisibility(video.id, isVisible: isVisible)
                            }
                        )
                        .onAppear {
                            // Preload next few videos
                            preloadUpcomingVideos(from: index)
                        }
                        .id(video.id)
                    }
                }
            }
            .environmentObject(playerPool)
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                playerPool.pauseAll()
            }
        }
        .onAppear {
            loadSampleVideos()
        }
    }
    
    private func handleVideoVisibility(_ videoId: String, isVisible: Bool) {
        print("Video visibility changed: \(videoId) - \(isVisible)")
        
        if isVisible {
            visibleVideos.insert(videoId)
            // Pause other videos when a new one becomes visible
            let othersToRemove = visibleVideos.filter { $0 != videoId }
            for otherId in othersToRemove {
                visibleVideos.remove(otherId)
            }
        } else {
            visibleVideos.remove(videoId)
        }
    }
    
    private func preloadUpcomingVideos(from currentIndex: Int) {
        guard !videos.isEmpty, videos.indices.contains(currentIndex) else { return }
        let preloadStart = currentIndex + 1
        let preloadEnd = min(currentIndex + 3, videos.count - 1)
        guard preloadStart <= preloadEnd else { return }
        for index in preloadStart...preloadEnd {
            guard videos.indices.contains(index) else { continue }
            preloader.preloadVideo(for: videos[index])
        }
        // Cancel preloading for videos that are too far away
        if currentIndex > 3 {
            let cancelStart = 0
            let cancelEnd = currentIndex - 4
            guard cancelStart <= cancelEnd, cancelEnd < videos.count else { return }
            for index in cancelStart...cancelEnd {
                guard videos.indices.contains(index) else { continue }
                preloader.cancelPreload(for: videos[index])
            }
        }
    }
    
    private func loadSampleVideos() {
        print("Loading sample videos...")
        // Sample video data with working URLs
        videos = [
            VideoItem(
                id: UUID().uuidString,
                url: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")!,
                thumbnailURL: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/BigBuckBunny.jpg"),
                title: "Big Buck Bunny"
            ),
            VideoItem(
                id: UUID().uuidString,
                url: URL(string: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4")!,
                thumbnailURL: URL(string: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/ElephantsDream.jpg"),
                title: "Elephant's Dream"
            ),
            VideoItem(
                id: UUID().uuidString,
                url: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4")!,
                thumbnailURL: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/ForBiggerBlazes.jpg"),
                title: "For Bigger Blazes"
            ),
            VideoItem(
                id: UUID().uuidString,
                url: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4")!,
                thumbnailURL: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/ForBiggerEscapes.jpg"),
                title: "For Bigger Escapes"
            ),
            VideoItem(
                id: UUID().uuidString,
                url: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4")!,
                thumbnailURL: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/ForBiggerFun.jpg"),
                title: "For Bigger Fun"
            ),
            VideoItem(
                id: UUID().uuidString,
                url: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4")!,
                thumbnailURL: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/ForBiggerJoyrides.jpg"),
                title: "For Bigger Joyrides"
            )
        ]
        print("Loaded \(videos.count) videos")
    }
}

struct UIVideoPlayerView: View {
    // MARK: - Properties
    let videoItem: VideoItem
    var height: CGFloat = 200
    @Binding var isMuted: Bool
    
    // MARK: - State
    @State private var isReadyToPlay: Bool = false
    @State private var showError: Bool = false
    @State private var playbackCommand: PlaybackCommand = .idle
    @State private var currentTime: Double = 0
    @State private var playerEvents: [PlayerEvent] = []
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Main Video Player using VideoItem
            ExtVideoPlayer(settings: .constant(videoSettings),
                          command: $playbackCommand)
                .onPlayerTimeChange { newTime in
                    currentTime = newTime
                }
                .onPlayerEventChange { events in
                    playerEvents = events
                    handlePlayerEvents(events)
                }
                .onAppear {
                    // Start playback when view appears
                    playbackCommand = .play
                }
                .onTapGesture {
                    isMuted.toggle()
                }
              
                
            
            // Optional overlay for video title
            overlayView
        }
//        .frame(height: height)
        .onChange(of: isMuted) { wasMuted, isMuted in
            if isMuted == true {
                playbackCommand = .mute
            } else {
                playbackCommand = .unmute
            }
        }
    }
}



// MARK: - Private Helpers
private extension UIVideoPlayerView {
    /// Video player settings using VideoItem's URL
    var videoSettings: VideoSettings {
        .init {
            // Use the URL from VideoItem directly
            SourceName(videoItem.url.absoluteString)
            Ext("mp4")
            Gravity(.resizeAspectFill)
            Loop() // Enable looping
            TimePublishing() // Enable time updates
            Events([.itemStatusChangedAny,.playing, .paused, .durationAny, .errorAny])
        }
    }
    
    /// Handle player events
    func handlePlayerEvents(_ events: [PlayerEvent]) {
        for event in events {
            switch event {
            case .itemStatusChanged(let status):
                switch status {
                case .unknown:
                    break
                case .readyToPlay:
                    if isMuted {
                        playbackCommand = .mute
                    }
                    self.isReadyToPlay = true
                case .failed:
                    self.showError = true
                @unknown default:
                    break
                }
            case .playing:
                print("Video \(videoItem.title) started playing")
            case .paused:
                print("Video \(videoItem.title) paused")
            case .duration(let duration):
                print("Video duration: \(CMTimeGetSeconds(duration)) seconds")
            case .error(let error):
                print("Playback error for \(videoItem.title): \(error)")
            default:
                break
            }
        }
    }
    
    /// Overlay view with video title
    @ViewBuilder
    var overlayView: some View {
        if !isReadyToPlay {
            Color.gray.opacity(0.2)
        } else if isReadyToPlay {
            
        } else if showError {
            VStack {
                Image(systemName: "arrow.trianglehead.clockwise")
                    .imageScale(.large)
                Text("Try Again")
            }
        }
    }
}

#Preview {
    NavigationView {
        UIVideoPlayerView(videoItem: sampleVideo, isMuted: .constant(true))
    }
}


let sampleSocialVideo = VideoItem(
    id: UUID().uuidString,
    url: Bundle.main.url(forResource: "socialvideo", withExtension: ".mp4")!,
    thumbnailURL: URL(
        string:
            "https://firebasestorage.googleapis.com/v0/b/bookd-16634.firebasestorage.app/o/dev%2Fframe-1%20(1).png?alt=media&token=fd6cbe0b-2316-4139-8083-a56db3bb1e1d"
    ),
    title: "SoFi Stadium"
)

