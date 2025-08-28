//
//  ImageManager.swift
//  Slide
//
//  Created by Nick Rogers on 7/29/25.
//


import Combine
import FirebaseStorage
import Foundation
import SwiftUI

// MARK: - Image Manager
class ImageManager: ObservableObject {
    static let shared = ImageManager()

    private let cache = NSCache<NSString, UIImage>()
    private let urlSession = URLSession.shared
    var cancellables = Set<AnyCancellable>()

    // In-flight requests to prevent duplicate downloads
    private var inflightRequests = [URL: AnyPublisher<UIImage, Error>]()

    private init() {
        setupCache()
    }

    private func setupCache() {
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024  // 50MB
    }

    // MARK: - Public Methods

    /// Fetches an image from URL with caching
    func fetchImage(from url: URL) -> AnyPublisher<UIImage, Error> {
        let cacheKey = NSString(string: url.absoluteString)

        // Check cache first
        if let cachedImage = cache.object(forKey: cacheKey) {
            return Just(cachedImage)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }

        // Check if request is already in flight
        if let existingRequest = inflightRequests[url] {
            return existingRequest
        }

        // Create new request
        let request = urlSession.dataTaskPublisher(for: url)
            .map(\.data)
            .tryMap { data in
                guard let image = UIImage(data: data) else {
                    throw ImageManagerError.invalidImageData
                }
                return image
            }
            .handleEvents(
                receiveOutput: { [weak self] image in
                    // Cache the image
                    self?.cache.setObject(image, forKey: cacheKey)
                },
                receiveCompletion: { [weak self] _ in
                    // Remove from inflight requests
                    self?.inflightRequests.removeValue(forKey: url)
                }
            )
            .receive(on: DispatchQueue.main)
            .share()
            .eraseToAnyPublisher()

        // Store the request to prevent duplicates
        inflightRequests[url] = request

        return request
    }

    /// Preload images for better performance
    func preloadImages(urls: [URL]) {
        urls.forEach { url in
            fetchImage(from: url)
                .sink(
                    receiveCompletion: { _ in },
                    receiveValue: { _ in }
                )
                .store(in: &cancellables)
        }
    }

    /// Clear all cached images
    func clearCache() {
        cache.removeAllObjects()
    }

    /// Remove specific image from cache
    func removeFromCache(url: URL) {
        let cacheKey = NSString(string: url.absoluteString)
        cache.removeObject(forKey: cacheKey)
    }

    /// Get cache statistics
    func getCacheInfo() -> (count: Int, totalCost: Int) {
        return (cache.countLimit, cache.totalCostLimit)
    }

    /// Upload a user profile image to Firebase Storage and get the download URL
    func uploadProfileImage(
        _ image: UIImage,
        userId: String,
        fileName: String = "profile.jpg"
    ) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw ImageManagerError.invalidImageData
        }

        let storageRef = Storage.storage().reference().child(
            "users/\(userId)/\(fileName)"
        )
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        let url = try await storageRef.downloadURL()
        return url.absoluteString
    }
}

// MARK: - ImageManager Extension for Async/Await
extension ImageManager {
    func fetchImage(from url: URL) -> AsyncThrowingStream<UIImage, Error> {
        AsyncThrowingStream { continuation in
            let cancellable = self.fetchImage(from: url)
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            continuation.finish()
                        case .failure(let error):
                            continuation.finish(throwing: error)
                        }
                    },
                    receiveValue: { image in
                        continuation.yield(image)
                    }
                )

            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }
}

// MARK: - Error Types
enum ImageManagerError: Error, LocalizedError {
    case invalidImageData
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidImageData:
            return "Invalid image data received"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - AsyncImage View with Caching
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    private let url: URL?
    private let content: (Image, UIImage) -> Content
    private let placeholder: () -> Placeholder

    @StateObject var imageManager = ImageManager.shared
    @State private var image: UIImage?
    @State private var isLoading = false
    @State private var error: Error?

    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image, UIImage) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let image = image {
                content(Image(uiImage: image), image)
            } else if isLoading {
                placeholder()
            } else if error != nil {
                placeholder()
            } else {
                placeholder()
            }
        }
        .onAppear {
            loadImage()
        }
        .onChange(of: url) { _, newURL in
            loadImage()
        }
    }

    private func loadImage() {
        guard let url = url else { return }

        isLoading = true
        error = nil

        imageManager.fetchImage(from: url)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case .failure(let error) = completion {
                        self.error = error
                    }
                },
                receiveValue: { uiImage in
                    self.image = uiImage
                }
            )
            .store(in: &imageManager.cancellables)
    }
}

// MARK: - Convenience Extensions
extension CachedAsyncImage where Content == Image, Placeholder == Color {
    init(url: URL?) {
        self.init(
            url: url,
            content: { image, _ in image },
            placeholder: { Color.gray.opacity(0.3) }
        )
    }
}

extension CachedAsyncImage
where Content == Image, Placeholder == ProgressView<EmptyView, EmptyView> {
    init(url: URL?, @ViewBuilder content: @escaping (Image, UIImage) -> Content)
    {
        self.init(
            url: url,
            content: content,
            placeholder: { ProgressView() }
        )
    }
}

// MARK: - Additional Convenience Extensions
extension CachedAsyncImage
where Placeholder == ProgressView<EmptyView, EmptyView> {
    init(url: URL?, @ViewBuilder content: @escaping (Image, UIImage) -> Content)
    {
        self.init(
            url: url,
            content: content,
            placeholder: { ProgressView() }
        )
    }
}

extension CachedAsyncImage where Placeholder == Color {
    init(url: URL?, @ViewBuilder content: @escaping (Image, UIImage) -> Content)
    {
        self.init(
            url: url,
            content: content,
            placeholder: { Color.gray.opacity(0.3) }
        )
    }
}
