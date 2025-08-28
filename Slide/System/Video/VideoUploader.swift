//
//  VideoUploader.swift
//  Slide
//
//  Created by Nick Rogers on 8/26/25.
//

import Foundation
import SwiftUI
import FirebaseStorage
import FirebaseFirestore
import AVFoundation
import AVKit
import PhotosUI
import Combine

struct VideoMetadata: Codable {
    let id: String
    let title: String
    let fileName: String
    let thumbnailFileName: String?
    let duration: TimeInterval?
    let fileSize: Int64?
    let uploadedAt: Date
    let storageURL: String
    let thumbnailStorageURL: String?
}

// MARK: - Video Upload Service
class VideoUploadService: ObservableObject {
    private let storage = Storage.storage()
    private let firestore = Firestore.firestore()
    
    @Published var uploadProgress: Double = 0.0
    @Published var isUploading = false
    @Published var uploadError: String?
    
    func uploadVideo(
        videoURL: URL,
        title: String,
        completion: @escaping (Result<VideoItem, Error>) -> Void
    ) {
        isUploading = true
        uploadError = nil
        uploadProgress = 0.0
        
        let videoId = UUID().uuidString
        let fileName = "\(videoId).mp4"
        let thumbnailFileName = "\(videoId)_thumbnail.jpg"
        
        // Get video metadata
        let asset = AVAsset(url: videoURL)
        let duration = asset.duration.seconds
        
        // Get file size
        let fileSize = getFileSize(url: videoURL)
        
        // Upload video file
        uploadVideoFile(videoURL: videoURL, fileName: fileName) { [weak self] result in
            switch result {
            case .success(let storageURL):
                // Generate and upload thumbnail
                self?.generateAndUploadThumbnail(
                    from: asset,
                    fileName: thumbnailFileName
                ) { thumbnailResult in
                    let thumbnailURL = try? thumbnailResult.get()
                    
                    // Save metadata to Firestore
                    let metadata = VideoMetadata(
                        id: videoId,
                        title: title,
                        fileName: fileName,
                        thumbnailFileName: thumbnailFileName,
                        duration: duration,
                        fileSize: fileSize,
                        uploadedAt: Date(),
                        storageURL: storageURL,
                        thumbnailStorageURL: thumbnailURL
                    )
                    
                    self?.saveMetadataToFirestore(metadata: metadata) { firestoreResult in
                        DispatchQueue.main.async {
                            self?.isUploading = false
                            
                            switch firestoreResult {
                            case .success:
                                let videoItem = VideoItem(
                                    id: videoId,
                                    url: URL(string: storageURL)!,
                                    thumbnailURL: thumbnailURL.flatMap { URL(string: $0) },
                                    title: title
                                )
                                completion(.success(videoItem))
                                
                            case .failure(let error):
                                self?.uploadError = error.localizedDescription
                                completion(.failure(error))
                            }
                        }
                    }
                }
                
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.isUploading = false
                    self?.uploadError = error.localizedDescription
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func uploadVideoFile(
        videoURL: URL,
        fileName: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let storageRef = storage.reference().child("videos/\(fileName)")
        
        let uploadTask = storageRef.putFile(from: videoURL, metadata: nil) { _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let downloadURL = url else {
                    completion(.failure(NSError(domain: "VideoUpload", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL"])))
                    return
                }
                
                completion(.success(downloadURL.absoluteString))
            }
        }
        
        uploadTask.observe(.progress) { [weak self] snapshot in
            guard let progress = snapshot.progress else { return }
            DispatchQueue.main.async {
                self?.uploadProgress = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
            }
        }
    }
    
    private func generateAndUploadThumbnail(
        from asset: AVAsset,
        fileName: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = CGSize(width: 300, height: 300)
        
        let time = CMTime(seconds: 1.0, preferredTimescale: 600)
        
        imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, cgImage, _, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let cgImage = cgImage else {
                completion(.failure(NSError(domain: "ThumbnailGeneration", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to generate thumbnail"])))
                return
            }
            
            let image = UIImage(cgImage: cgImage)
            guard let imageData = image.jpegData(compressionQuality: 0.7) else {
                completion(.failure(NSError(domain: "ThumbnailGeneration", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert thumbnail to data"])))
                return
            }
            
            let storageRef = self.storage.reference().child("thumbnails/\(fileName)")
            storageRef.putData(imageData, metadata: nil) { _, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                storageRef.downloadURL { url, error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    
                    guard let downloadURL = url else {
                        completion(.failure(NSError(domain: "ThumbnailUpload", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get thumbnail download URL"])))
                        return
                    }
                    
                    completion(.success(downloadURL.absoluteString))
                }
            }
        }
    }
    
    private func saveMetadataToFirestore(
        metadata: VideoMetadata,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        do {
            let data = try Firestore.Encoder().encode(metadata)
            firestore.collection("videos").document(metadata.id).setData(data) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    private func getFileSize(url: URL) -> Int64? {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return attributes[.size] as? Int64
        } catch {
            return nil
        }
    }
}

// MARK: - Video Retrieval Service
class VideoRetrievalService: ObservableObject {
    private let firestore = Firestore.firestore()
    
    @Published var videos: [VideoItem] = []
    @Published var isLoading = false
    @Published var error: String?
    
    func fetchVideos() {
        isLoading = true
        error = nil
        
        firestore.collection("videos")
            .order(by: "uploadedAt", descending: true)
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        self?.error = error.localizedDescription
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        self?.error = "No documents found"
                        return
                    }
                    
                    self?.videos = documents.compactMap { document in
                        do {
                            let metadata = try document.data(as: VideoMetadata.self)
                            return VideoItem(
                                id: metadata.id,
                                url: URL(string: metadata.storageURL)!,
                                thumbnailURL: metadata.thumbnailStorageURL.flatMap { URL(string: $0) },
                                title: metadata.title
                            )
                        } catch {
                            print("Error decoding video metadata: \(error)")
                            return nil
                        }
                    }
                }
            }
    }
    
    func fetchVideo(by id: String, completion: @escaping (VideoItem?) -> Void) {
        firestore.collection("videos").document(id).getDocument { snapshot, error in
            if let error = error {
                print("Error fetching video: \(error)")
                completion(nil)
                return
            }
            
            guard let document = snapshot, document.exists else {
                completion(nil)
                return
            }
            
            do {
                let metadata = try document.data(as: VideoMetadata.self)
                let videoItem = VideoItem(
                    id: document.documentID,
                    url: URL(string: metadata.storageURL)!,
                    thumbnailURL: metadata.thumbnailStorageURL.flatMap { URL(string: $0) },
                    title: metadata.title
                )
                completion(videoItem)
            } catch {
                print("Error decoding video metadata: \(error)")
                completion(nil)
            }
        }
    }
}

// MARK: - Video Upload View
struct VideoUploadView: View {
    @StateObject private var uploadService = VideoUploadService()
    @StateObject private var retrievalService = VideoRetrievalService()
    
    @State private var showingVideoPicker = false
    @State private var videoTitle = ""
    @State private var selectedVideoItem: PhotosPickerItem? = nil
    @State private var selectedVideoURL: URL? = nil
    @State private var showingTitleInput = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Upload Section
                VStack(spacing: 20) {
                    Button("Select Video") {
                        showingVideoPicker = true
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(uploadService.isUploading)
                    
                    if uploadService.isUploading {
                        VStack {
                            ProgressView(value: uploadService.uploadProgress)
                                .progressViewStyle(.linear)
                            Text("Uploading... \(Int(uploadService.uploadProgress * 100))%")
                                .font(.caption)
                        }
                    }
                    
                    if let error = uploadService.uploadError {
                        Text("Error: \(error)")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                .padding()
                
                Divider()
                
                // Videos List
                VStack {
                    HStack {
                        Text("Uploaded Videos")
                            .font(.headline)
                        Spacer()
                        Button("Refresh") {
                            retrievalService.fetchVideos()
                        }
                        .disabled(retrievalService.isLoading)
                    }
                    .padding(.horizontal)
                    
                    if retrievalService.isLoading {
                        ProgressView("Loading videos...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if retrievalService.videos.isEmpty {
                        Text("No videos uploaded yet")
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List(retrievalService.videos) { video in
                            VideoRowView(video: video)
                        }
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Video Uploader")
            .onAppear {
                retrievalService.fetchVideos()
            }
        }
        .photosPicker(
            isPresented: $showingVideoPicker,
            selection: $selectedVideoItem,
            matching: .videos,
            photoLibrary: .shared()
        )
        .onChange(of: selectedVideoItem) { newValue in
            guard let item = newValue else { return }
            item.loadTransferable(type: Data.self) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let data):
                        guard let data = data else { return }
                        // Save to a temp URL
                        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
                        do {
                            try data.write(to: tempURL)
                            selectedVideoURL = tempURL
                            showingTitleInput = true
                        } catch {
                            // Handle error (e.g., show an alert)
                        }
                    case .failure(let error):
                        // Handle error (e.g., show an alert)
                        print("Failed to load video: \(error)")
                    }
                }
            }
        }
        .sheet(isPresented: $showingTitleInput) {
            VideoTitleInputView(
                videoURL: selectedVideoURL,
                onUpload: { url, title in
                    uploadService.uploadVideo(videoURL: url, title: title) { result in
                        switch result {
                        case .success:
                            retrievalService.fetchVideos()
                        case .failure(let error):
                            print("Upload failed: \(error)")
                        }
                    }
                }
            )
        }
    }
}

// MARK: - Video Title Input View
struct VideoTitleInputView: View {
    let videoURL: URL?
    let onUpload: (URL, String) -> Void
    
    @State private var title = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Enter video title", text: $title)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                
                Button("Upload Video") {
                    guard let url = videoURL, !title.isEmpty else { return }
                    onUpload(url, title)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(title.isEmpty)
                
                Spacer()
            }
            .navigationTitle("Video Title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Video Row View
struct VideoRowView: View {
    let video: VideoItem
    
    var body: some View {
        HStack {
            // Thumbnail
            AsyncImage(url: video.thumbnailURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
            }
            .frame(width: 80, height: 60)
            .clipped()
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(video.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Text("Tap to play")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            NavigationLink(destination: VideoPlayerView(video: video)) {
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Video Player View
struct VideoPlayerView: View {
    let video: VideoItem
    
    var body: some View {
        VStack {
            VideoPlayer(player: AVPlayer(url: video.url))
                .aspectRatio(16/9, contentMode: .fit)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(video.title)
                    .font(.title2)
                    .bold()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            
            Spacer()
        }
        .navigationTitle("Video Player")
        .navigationBarTitleDisplayMode(.inline)
    }
}
