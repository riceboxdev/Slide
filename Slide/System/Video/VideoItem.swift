import SwiftUI
import AVFoundation
import AVKit
import Combine

// MARK: - Model

struct VideoItem: Identifiable, Hashable {
    let id: UUID = .init()
    let url: URL
    let posterURL: URL?
    let title: String
}

// MARK: - Player Pool

/// A small pool of reusable AVPlayer instances to avoid cold starts per cell.
final class PlayerPool {
    static let shared = PlayerPool()

    private let maxPlayers = 4 // tune for your feed style (1 playing, 1 prev, 1 next, + spare)
    private var players: [AVPlayer] = []
    private var playerInUse = Set<ObjectIdentifier>()

    private init() {
        players = (0..<maxPlayers).map { _ in
            let p = AVPlayer()
            p.automaticallyWaitsToMinimizeStalling = true
            return p
        }
    }

    /// Acquire a player (reuse if possible). You must call `release(_:)` when done.
    func acquire() -> AVPlayer {
        if let idx = players.firstIndex(where: { !playerInUse.contains(ObjectIdentifier($0)) }) {
            let p = players[idx]
            playerInUse.insert(ObjectIdentifier(p))
            return p
        } else {
            // Pool exhausted: create a temporary player (will not be pooled on release)
            let p = AVPlayer()
            p.automaticallyWaitsToMinimizeStalling = true
            playerInUse.insert(ObjectIdentifier(p))
            return p
        }
    }

    func release(_ player: AVPlayer) {
        player.pause()
        player.replaceCurrentItem(with: nil)
        player.seek(to: .zero)
        player.rate = 0
        player.actionAtItemEnd = .pause
        playerInUse.remove(ObjectIdentifier(player))
    }
}

// MARK: - Item Preheater

/// Prepares AVPlayerItems ahead of time so `play()` feels instant.
final class VideoPreheater {
    static let shared = VideoPreheater()

    private let cache = NSCache<NSURL, AVPlayerItem>()
    private var inFlight = [NSURL: Task<AVPlayerItem, Never>]()
    private let lock = NSLock()

    func preheat(url: URL) {
        let key = url as NSURL
        lock.lock(); defer { lock.unlock() }
        guard cache.object(forKey: key) == nil, inFlight[key] == nil else { return }
        inFlight[key] = Task.detached(priority: .utility) { [weak self] in
            let asset = AVURLAsset(url: url)
            // Ask for keys we need before playback
            let keys = ["playable", "hasProtectedContent", "duration"]
            do {
                try await asset.load(.isPlayable)
                _ = try? await asset.loadValues(forKeys: keys)
            } catch {
                // swallow; item may still become playable later
            }
            let item = AVPlayerItem(asset: asset)
            item.preferredForwardBufferDuration = 2 // seconds of buffer to aim for early
            self?.lock.lock()
            self?.cache.setObject(item, forKey: key)
            self?.inFlight[key] = nil
            self?.lock.unlock()
            return item
        }
    }

    func item(for url: URL) -> AVPlayerItem {
        let key = url as NSURL
        if let cached = cache.object(forKey: key) { return cached.copyIfNeeded() }
        // Not cached: create lightweight item synchronously
        let asset = AVURLAsset(url: url)
        let item = AVPlayerItem(asset: asset)
        item.preferredForwardBufferDuration = 2
        cache.setObject(item, forKey: key)
        return item
    }
}

private extension AVPlayerItem {
    /// AVPlayerItem is not strictly copyable; this returns the same instance for simplicity.
    /// If you need isolation per cell, construct a new item from the cached asset.
    func copyIfNeeded() -> AVPlayerItem { self }
}

// MARK: - Visibility Tracking

/// Reports how visible a view is within its scroll container (0...1).
struct VisibilityReporter: ViewModifier {
    let onChange: (CGFloat) -> Void

    func body(content: Content) -> some View {
        content
            .background(GeometryReader { geo in
                Color.clear.preference(key: VisibilityKey.self, value: geo)
            })
            .onPreferenceChange(VisibilityKey.self) { geo in
                guard let scroll = geo?.frame(in: .named("scroll")) else { return }
                guard let screen = geo?.frame(in: .global) else { return }
                // Use the container named "scroll" if provided; fall back to global heuristics
                let container = screen // fallback
                let viewport = UIScreen.main.bounds
                let intersection = scroll.intersection(viewport) ?? .null
                let visibleArea = max(0, intersection.width * intersection.height)
                let totalArea = max(1, scroll.width * scroll.height)
                let ratio = CGFloat(min(1, max(0, visibleArea / totalArea)))
                onChange(ratio)
            }
    }
}

private struct VisibilityKey: PreferenceKey {
    static var defaultValue: CGRect? = nil
    static func reduce(value: inout CGRect?, nextValue: () -> CGRect?) { value = nextValue() }
}

extension View {
    func reportVisibility(_ onChange: @escaping (CGFloat) -> Void) -> some View {
        modifier(VisibilityReporter(onChange: onChange))
    }
}

// MARK: - Player Layer Host (UIKit for speed)

struct PlayerLayerView: UIViewRepresentable {
    final class ContainerView: UIView {
        override static var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    }

    let player: AVPlayer
    var videoGravity: AVLayerVideoGravity = .resizeAspectFill

    func makeUIView(context: Context) -> ContainerView {
        let v = ContainerView()
        v.playerLayer.player = player
        v.playerLayer.videoGravity = videoGravity
        v.isUserInteractionEnabled = false
        return v
    }

    func updateUIView(_ uiView: ContainerView, context: Context) {
        if uiView.playerLayer.player !== player {
            uiView.playerLayer.player = player
        }
        uiView.playerLayer.videoGravity = videoGravity
    }
}

// MARK: - Video Cell

struct VideoCellView: View {
    let item: VideoItem
    @State private var player: AVPlayer? = nil
    @State private var isReady = false
    @State private var isActive = false // whether we want it playing
    @State private var cancellables = Set<AnyCancellable>()

    var body: some View {
        ZStack {
            if let player {
                PlayerLayerView(player: player)
                    .clipped()
                    .onReceive(player.publisher(for: \._status)) { _ in }
            } else {
                Color.black.opacity(0.1)
            }

            // Poster image overlay until ready to show moving pixels
            if !isReady, let poster = item.posterURL {
                AsyncImage(url: poster) { phase in
                    switch phase {
                    case .success(let image): image.resizable().scaledToFill()
                    default: Color.black.opacity(0.15)
                    }
                }
                .transition(.opacity)
            }

            // Simple title badge for demo
            VStack { Spacer() }
        }
        .frame(height: 420) // demo height; adapt to your layout
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(alignment: .bottomLeading) {
            Text(item.title)
                .font(.headline)
                .padding(12)
                .background(.ultraThinMaterial, in: Capsule())
                .padding()
        }
        .onAppear(perform: prepare)
        .onDisappear(perform: teardown)
        .reportVisibility { ratio in
            let shouldPlay = ratio > 0.6
            setActive(shouldPlay)
        }
    }

    private func prepare() {
        // Acquire from pool and attach a preheated item
        let p = PlayerPool.shared.acquire()
        let item = VideoPreheater.shared.item(for: item.url)

        // Observe ready-to-play
        NotificationCenter.default.publisher(for: .AVPlayerItemNewAccessLogEntry, object: item)
            .sink { _ in isReady = true }
            .store(in: &cancellables)
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: item)
            .sink { _ in
                // Loop
                p.seek(to: .zero)
                p.play()
            }
            .store(in: &cancellables)

        p.replaceCurrentItem(with: item)
        p.isMuted = true // unmute on tap if you want
        p.actionAtItemEnd = .pause
        player = p
    }

    private func teardown() {
        cancellables.removeAll()
        if let p = player { PlayerPool.shared.release(p) }
        player = nil
        isReady = false
    }

    private func setActive(_ play: Bool) {
        guard let p = player else { return }
        if play {
            p.play()
        } else {
            p.pause()
        }
    }
}

// MARK: - Feed ViewModel

final class FeedViewModel: ObservableObject {
    @Published var items: [VideoItem] = []

    func setItems(_ items: [VideoItem]) {
        self.items = items
    }

    /// Call when a given index becomes dominant in the viewport to preheat neighbors
    func preheatAround(index: Int, radius: Int = 2) {
        guard !items.isEmpty else { return }
        for offset in (-radius...radius) {
            let idx = index + offset
            guard idx >= 0 && idx < items.count else { continue }
            VideoPreheater.shared.preheat(url: items[idx].url)
        }
    }
}

// MARK: - Feed Demo

struct FeedDemoView: View {
    @StateObject private var vm = FeedViewModel()
    @State private var dominantIndex: Int = 0

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(Array(vm.items.enumerated()), id: \.[0]) { index, item in
                    VideoCellView(item: item)
                        .onAppear {
                            dominantIndex = index
                            vm.preheatAround(index: index)
                        }
                }
            }
            .padding(.vertical, 16)
        }
        .coordinateSpace(name: "scroll")
        .onAppear {
            vm.setItems(Self.sampleItems)
            // Kick off initial preheat
            vm.preheatAround(index: 0)
        }
    }
}

// MARK: - Sample Data

extension FeedDemoView {
    static let sampleItems: [VideoItem] = [
        VideoItem(url: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.m3u8")!,
                  posterURL: URL(string: "https://peach.blender.org/wp-content/uploads/bbb-splash.png")!,
                  title: "Bunny"),
        VideoItem(url: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.m3u8")!,
                  posterURL: URL(string: "https://orange.blender.org/wp-content/themes/orange/images/common/ed_head.jpg")!,
                  title: "Dream"),
        VideoItem(url: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.m3u8")!,
                  posterURL: URL(string: "https://durian.blender.org/wp-content/uploads/2010/05/sintel_poster.jpg")!,
                  title: "Sintel"),
        VideoItem(url: URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_ts/master.m3u8")!,
                  posterURL: nil,
                  title: "BipBop")
    ]
}

// MARK: - Notes
// 1) Use HLS (m3u8) with multiple bitrates. The preheater warms the asset & item so play() starts fast.
// 2) PlayerPool avoids spinning up decoders for each cell.
// 3) Visibility gating ensures only the mostly-visible cell plays to spare CPU/GPU.
// 4) For production: consider AVAssetDownloadURLSession to offline/cache HLS for frequently viewed items.
// 5) For sound-on: show a mute button and set requiresUserActionForAudio to true if you auto-play.
// 6) Tune preferredForwardBufferDuration & pool size based on device profiling.
