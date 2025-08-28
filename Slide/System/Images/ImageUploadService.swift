//
//  ImageUploadService.swift
//  Slide
//
//  Created by Nick Rogers on 7/29/25.
//



import Combine
import FirebaseStorage
import Foundation
import PhotosUI
import SwiftUI
import UIKit

// MARK: - Image Upload Service
class ImageUploadService: ObservableObject {
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0.0
    @Published var uploadError: String?

    private let storage = Storage.storage()

    func uploadImages(
        images: [UIImage],
        venueUUID: String,
        completion: @escaping (Result<[ImageUploadResult], Error>) -> Void
    ) {
        isUploading = true
        uploadProgress = 0.0
        uploadError = nil

        Task {
            do {
                var results: [ImageUploadResult] = []
                let totalImages = images.count
                
                for (index, image) in images.enumerated() {
                    // Compress and resize image
                    let processedImage = try await processImage(image)
                    
                    // Upload to Firebase
                    let result = try await uploadToFirebase(
                        image: processedImage,
                        venueUUID: venueUUID
                    )
                    
                    results.append(result)
                    
                    // Update progress
                    DispatchQueue.main.async {
                        self.uploadProgress = Double(index + 1) / Double(totalImages)
                    }
                }

                DispatchQueue.main.async {
                    self.isUploading = false
                    completion(.success(results))
                }

            } catch {
                DispatchQueue.main.async {
                    self.isUploading = false
                    self.uploadError = error.localizedDescription
                    completion(.failure(error))
                }
            }
        }
    }
    
    func uploadSingleImage(
        image: UIImage,
        venueUUID: String,
        completion: @escaping (Result<ImageUploadResult, Error>) -> Void
    ) {
        uploadImages(images: [image], venueUUID: venueUUID) { result in
            switch result {
            case .success(let results):
                if let firstResult = results.first {
                    completion(.success(firstResult))
                } else {
                    completion(.failure(ImageUploadError.uploadFailed))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func processImage(_ image: UIImage) async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                // Resize image to max 1920x1920 while maintaining aspect ratio
                let maxSize: CGFloat = 1920
                let size = image.size
                
                var newSize = size
                if size.width > maxSize || size.height > maxSize {
                    let aspectRatio = size.width / size.height
                    if size.width > size.height {
                        newSize = CGSize(width: maxSize, height: maxSize / aspectRatio)
                    } else {
                        newSize = CGSize(width: maxSize * aspectRatio, height: maxSize)
                    }
                }
                
                UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
                image.draw(in: CGRect(origin: .zero, size: newSize))
                
                guard let resizedImage = UIGraphicsGetImageFromCurrentImageContext() else {
                    UIGraphicsEndImageContext()
                    continuation.resume(throwing: ImageUploadError.processingFailed)
                    return
                }
                
                UIGraphicsEndImageContext()
                continuation.resume(returning: resizedImage)
            }
        }
    }

    private func uploadToFirebase(
        image: UIImage,
        venueUUID: String
    ) async throws -> ImageUploadResult {
        
        let imageID = UUID().uuidString
        let imagePath = "venues/\(venueUUID)/images/\(imageID).jpg"
        
        // Convert image to JPEG data with compression
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw ImageUploadError.processingFailed
        }
        
        // Upload image
        let imageRef = storage.reference().child(imagePath)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        let _ = try await imageRef.putDataAsync(imageData, metadata: metadata)
        let downloadURL = try await imageRef.downloadURL()
        
        return ImageUploadResult(
            imageID: imageID,
            imageURL: downloadURL.absoluteString
        )
    }
}

// MARK: - Data Models
struct ImageUploadResult {
    let imageID: String
    let imageURL: String
}

enum ImageUploadError: LocalizedError {
    case processingFailed
    case uploadFailed
    case invalidImage
    
    var errorDescription: String? {
        switch self {
        case .processingFailed:
            return "Failed to process image"
        case .uploadFailed:
            return "Failed to upload to Firebase"
        case .invalidImage:
            return "Invalid image format"
        }
    }
}

// MARK: - Photo Picker
struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    @Environment(\.presentationMode) var presentationMode
    let maxSelectionCount: Int

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = maxSelectionCount
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(
        _ uiViewController: PHPickerViewController,
        context: Context
    ) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker

        init(_ parent: PhotoPicker) {
            self.parent = parent
        }

        func picker(
            _ picker: PHPickerViewController,
            didFinishPicking results: [PHPickerResult]
        ) {
            parent.presentationMode.wrappedValue.dismiss()

            guard !results.isEmpty else { return }
            
            var images: [UIImage] = []
            let group = DispatchGroup()
            
            for result in results {
                group.enter()
                
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    result.itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                        defer { group.leave() }
                        
                        if let uiImage = image as? UIImage {
                            DispatchQueue.main.async {
                                images.append(uiImage)
                            }
                        }
                    }
                } else {
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                self.parent.selectedImages = images
            }
        }
    }
}

// MARK: - Example Usage View
struct ImageUploadExampleView: View {
    @StateObject private var uploadService = ImageUploadService()
    @State private var selectedImages: [UIImage] = []
    @State private var showingPhotoPicker = false
    @State private var uploadResults: [ImageUploadResult] = []

    let venueUUID = "example-venue-uuid"  // Replace with actual venue UUID

    var body: some View {
        VStack(spacing: 20) {
            Button("Select Photos") {
                showingPhotoPicker = true
            }
            .buttonStyle(.borderedProminent)

            if !selectedImages.isEmpty {
                Text("\(selectedImages.count) photos selected")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 80)
                                .clipped()
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                }

                Button("Upload Photos") {
                    uploadService.uploadImages(
                        images: selectedImages,
                        venueUUID: venueUUID
                    ) { result in
                        switch result {
                        case .success(let results):
                            self.uploadResults = results
                        case .failure(let error):
                            print("Upload failed: \(error)")
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(uploadService.isUploading)
            }

            if uploadService.isUploading {
                ProgressView("Uploading photos...")
                    .progressViewStyle(CircularProgressViewStyle())

                ProgressView(value: uploadService.uploadProgress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(maxWidth: 200)
            }

            if let error = uploadService.uploadError {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .font(.caption)
            }

            if !uploadResults.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Upload Successful!")
                        .font(.headline)
                        .foregroundColor(.green)

                    Text("\(uploadResults.count) photos uploaded")
                        .font(.caption)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding()
        .sheet(isPresented: $showingPhotoPicker) {
            PhotoPicker(
                selectedImages: $selectedImages,
                maxSelectionCount: 10
            )
        }
    }
}
