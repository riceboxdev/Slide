//
//  ImageMetadata.swift
//  Slide
//
//  Created by Nick Rogers on 8/25/25.
//

import UIKit
import Firebase
import FirebaseStorage
import FirebaseFirestore
import ColorKit

// MARK: - Data Models

struct ImageMetadata: Codable {
    let id: String
    let fileName: String
    let fileSize: Int64
    let imageSize: ImageSize
    let colorAnalysis: ColorAnalysis
    let uploadDate: Date
    let downloadURL: String
    let contentType: String
    let tags: [String]?
    
    struct ImageSize: Codable {
        let width: Double
        let height: Double
    }
    
    struct ColorAnalysis: Codable {
        let dominantColors: [String] // Hex values of dominant colors
        let averageColor: String // Hex value of average color
        let palette: ColorPaletteData? // Generated palette
        
        struct ColorPaletteData: Codable {
            let background: String // Hex value
            let primary: String // Hex value
            let secondary: String? // Hex value (optional)
            let backgroundContrastWithWhite: CGFloat // Contrast ratio with white
            let contrastLevel: String // "acceptable", "acceptableForLargeText", or "low"
        }
    }
}

// MARK: - Firebase Image Manager

class FirebaseImageManager {
    private let storage = Storage.storage()
    private let firestore = Firestore.firestore()
    private let imagesCollection = "images"
    
    // MARK: - Upload Methods
    
    func uploadImage(_ image: UIImage,
                    fileName: String? = nil,
                    tags: [String]? = nil,
                    completion: @escaping (Result<ImageMetadata, Error>) -> Void) {
        
        Task {
            do {
                let metadata = try await uploadImageAsync(image, fileName: fileName, tags: tags)
                completion(.success(metadata))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func uploadImageAsync(_ image: UIImage,
                         fileName: String? = nil,
                         tags: [String]? = nil) async throws -> ImageMetadata {
        
        // Generate unique filename if not provided
        let finalFileName = fileName ?? "image_\(UUID().uuidString).jpg"
        let imageId = UUID().uuidString
        
        // Compress image
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NewImageUploadError.imageCompressionFailed
        }
        
        // Extract color analysis using ColorKit
        let colorAnalysis = try await extractColorAnalysis(from: image)
        
        // Upload to Firebase Storage
        let storageRef = storage.reference().child("images/\(imageId)/\(finalFileName)")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        // Upload image data
        let _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        
        // Get download URL
        let downloadURL = try await storageRef.downloadURL()
        
        // Create metadata object
        let imageMetadata = ImageMetadata(
            id: imageId,
            fileName: finalFileName,
            fileSize: Int64(imageData.count),
            imageSize: ImageMetadata.ImageSize(
                width: Double(image.size.width),
                height: Double(image.size.height)
            ),
            colorAnalysis: colorAnalysis,
            uploadDate: Date(),
            downloadURL: downloadURL.absoluteString,
            contentType: "image/jpeg",
            tags: tags
        )
        
        // Save metadata to Firestore
        try await saveMetadataToFirestore(imageMetadata)
        
        return imageMetadata
    }
    
    // MARK: - Color Analysis
    
    private func extractColorAnalysis(from image: UIImage) async throws -> ImageMetadata.ColorAnalysis {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    // Extract dominant colors using ColorKit
                    let dominantColors = try image.dominantColors()
                    let dominantHexColors = dominantColors.map { $0.hex }
                    
                    // Extract average color
                    let averageColor = try image.averageColor()
                    let averageHex = averageColor.hex
                    
                    // Generate color palette using ColorKit's ColorPalette
                    var colorPaletteData: ImageMetadata.ColorAnalysis.ColorPaletteData?
                    
                    if let palette = ColorPalette(orderedColors: dominantColors, ignoreContrastRatio: false) {
                        let backgroundContrastWithWhite = palette.background.contrastRatio(with: .white)
                        
                        // Convert ContrastRatioResult to string and double
                        let contrastValue = backgroundContrastWithWhite
                        let contrastLevel: String
                        switch backgroundContrastWithWhite {
                        case .acceptable:
                            contrastLevel = "acceptable"
                        case .acceptableForLargeText:
                            contrastLevel = "acceptableForLargeText"
                        case .low:
                            contrastLevel = "low"
                        }
                        
                        colorPaletteData = ImageMetadata.ColorAnalysis.ColorPaletteData(
                            background: palette.background.hex,
                            primary: palette.primary.hex,
                            secondary: palette.secondary?.hex,
                            backgroundContrastWithWhite: contrastValue,
                            contrastLevel: contrastLevel
                        )
                    }
                    
                    let colorAnalysis = ImageMetadata.ColorAnalysis(
                        dominantColors: dominantHexColors,
                        averageColor: averageHex,
                        palette: colorPaletteData
                    )
                    
                    continuation.resume(returning: colorAnalysis)
                    
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Firestore Operations
    
    private func saveMetadataToFirestore(_ metadata: ImageMetadata) async throws {
        let document = firestore.collection(imagesCollection).document(metadata.id)
        try await document.setData(from: metadata)
    }
    
    // MARK: - Retrieval Methods
    
    func getAllImages() async throws -> [ImageMetadata] {
        let snapshot = try await firestore.collection(imagesCollection)
            .order(by: "uploadDate", descending: true)
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            try document.data(as: ImageMetadata.self)
        }
    }
    
    func getImagesByColor(similarTo hexColor: String, threshold: Double = 30.0) async throws -> [ImageMetadata] {
        let allImages = try await getAllImages()
        let targetColor = UIColor(hex: hexColor)
        
        return allImages.filter { metadata in
            // Check if any dominant color is similar to target color
            return metadata.colorAnalysis.dominantColors.contains { dominantHex in
                let dominantColor = UIColor(hex: dominantHex)
                let difference = targetColor.difference(from: dominantColor, using: .CIE94)
                return difference.associatedValue < threshold
            }
        }
    }
    
    func getImagesByAverageColor(similarTo hexColor: String, threshold: Double = 20.0) async throws -> [ImageMetadata] {
        let allImages = try await getAllImages()
        let targetColor = UIColor(hex: hexColor)
        
        return allImages.filter { metadata in
            let averageColor = UIColor(hex: metadata.colorAnalysis.averageColor)
            let difference = targetColor.difference(from: averageColor, using: .CIE94)
            return difference.associatedValue < threshold
        }
    }
    
    func getImagesByTags(_ tags: [String]) async throws -> [ImageMetadata] {
        // Firestore array-contains-any query for tags
        let snapshot = try await firestore.collection(imagesCollection)
            .whereField("tags", arrayContainsAny: tags)
            .order(by: "uploadDate", descending: true)
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            try document.data(as: ImageMetadata.self)
        }
    }
    
    func getImageById(_ id: String) async throws -> ImageMetadata? {
        let document = try await firestore.collection(imagesCollection).document(id).getDocument()
        return try document.data(as: ImageMetadata.self)
    }
    
    func getImagesWithHighContrast(minimumRatio: Double = 4.5) async throws -> [ImageMetadata] {
        let allImages = try await getAllImages()
        
        return allImages.filter { metadata in
            guard let contrastRatio = metadata.colorAnalysis.palette?.backgroundContrastWithWhite else { return false }
            return contrastRatio >= minimumRatio
        }
    }
    
    func getAccessibleImages() async throws -> [ImageMetadata] {
        let allImages = try await getAllImages()
        
        return allImages.filter { metadata in
            guard let contrastLevel = metadata.colorAnalysis.palette?.contrastLevel else { return false }
            return contrastLevel == "acceptable"
        }
    }
    
    func getImagesForLargeText() async throws -> [ImageMetadata] {
        let allImages = try await getAllImages()
        
        return allImages.filter { metadata in
            guard let contrastLevel = metadata.colorAnalysis.palette?.contrastLevel else { return false }
            return contrastLevel == "acceptable" || contrastLevel == "acceptableForLargeText"
        }
    }
    
    func getImagesByPaletteColor(backgroundSimilarTo hexColor: String, threshold: Double = 20.0) async throws -> [ImageMetadata] {
        let allImages = try await getAllImages()
        let targetColor = UIColor(hex: hexColor)
        
        return allImages.filter { metadata in
            guard let backgroundHex = metadata.colorAnalysis.palette?.background else { return false }
            let backgroundColor = UIColor(hex: backgroundHex)
            let difference = targetColor.difference(from: backgroundColor, using: .CIE94)
            return difference.associatedValue < threshold
        }
    }
    
    func getImagesByPrimaryColor(similarTo hexColor: String, threshold: Double = 20.0) async throws -> [ImageMetadata] {
        let allImages = try await getAllImages()
        let targetColor = UIColor(hex: hexColor)
        
        return allImages.filter { metadata in
            guard let primaryHex = metadata.colorAnalysis.palette?.primary else { return false }
            let primaryColor = UIColor(hex: primaryHex)
            let difference = targetColor.difference(from: primaryColor, using: .CIE94)
            return difference.associatedValue < threshold
        }
    }
    
    // MARK: - Advanced Color Search Methods
    
    func getImagesByColorSimilarity(to hexColor: String, similarityLevel: UIColor.ColorDifferenceResult) async throws -> [ImageMetadata] {
        let allImages = try await getAllImages()
        let targetColor = UIColor(hex: hexColor)
        
        return allImages.filter { metadata in
            return metadata.colorAnalysis.dominantColors.contains { dominantHex in
                let dominantColor = UIColor(hex: dominantHex)
                let difference = targetColor.difference(from: dominantColor, using: .CIE94)
                
                switch similarityLevel {
                case .indentical, .similar:
                    return difference <= .similar(1.0)
                case .close:
                    return difference <= .close(2.0)
                case .near:
                    return difference <= .near(10.0)
                case .different:
                    return difference <= .different(50.0)
                case .far:
                    return true // Include all differences
                }
            }
        }
    }
    
    func getVerySpecificColorMatches(to hexColor: String) async throws -> [ImageMetadata] {
        return try await getImagesByColorSimilarity(to: hexColor, similarityLevel: .similar(1.0))
    }
    
    func getCloseColorMatches(to hexColor: String) async throws -> [ImageMetadata] {
        return try await getImagesByColorSimilarity(to: hexColor, similarityLevel: .close(2.0))
    }
    
    // MARK: - Update Methods
    
    func updateImageTags(_ imageId: String, tags: [String]) async throws {
        let document = firestore.collection(imagesCollection).document(imageId)
        try await document.updateData(["tags": tags])
    }
    
    func deleteImage(_ imageId: String) async throws {
        // Delete from Storage
        let storageRef = storage.reference().child("images/\(imageId)")
        try await storageRef.delete()
        
        // Delete metadata from Firestore
        try await firestore.collection(imagesCollection).document(imageId).delete()
    }
}

// MARK: - Error Types

enum NewImageUploadError: Error, LocalizedError {
    case imageCompressionFailed
    case colorExtractionFailed
    case uploadFailed(String)
    case metadataSaveFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .imageCompressionFailed:
            return "Failed to compress image"
        case .colorExtractionFailed:
            return "Failed to extract color information from image"
        case .uploadFailed(let message):
            return "Upload failed: \(message)"
        case .metadataSaveFailed(let message):
            return "Failed to save metadata: \(message)"
        }
    }
}

// MARK: - Usage Example

class ViewController: UIViewController {
    private let imageManager = FirebaseImageManager()
    
    private func uploadSelectedImage(_ image: UIImage) {
        // Show loading indicator
        showLoadingIndicator()
        
        imageManager.uploadImage(
            image,
            fileName: "user_photo.jpg",
            tags: ["portrait", "user_generated"]
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.hideLoadingIndicator()
                
                switch result {
                case .success(let metadata):
                    print("Upload successful!")
                    print("Image ID: \(metadata.id)")
                    print("Dominant colors: \(metadata.colorAnalysis.dominantColors)")
                    print("Average color: \(metadata.colorAnalysis.averageColor)")
                    self?.handleUploadSuccess(metadata)
                    
                case .failure(let error):
                    print("Upload failed: \(error.localizedDescription)")
                    self?.handleUploadError(error)
                }
            }
        }
    }
    
    private func searchImagesByColor(_ hexColor: String) {
        Task {
            do {
                let similarImages = try await imageManager.getImagesByColor(similarTo: hexColor)
                await MainActor.run {
                    // Update UI with similar images
                    displayImages(similarImages)
                }
            } catch {
                print("Search failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func searchImagesByPaletteBackground(_ hexColor: String) {
        Task {
            do {
                let similarImages = try await imageManager.getImagesByPaletteColor(backgroundSimilarTo: hexColor)
                await MainActor.run {
                    displayImages(similarImages)
                }
            } catch {
                print("Search failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func getHighContrastImages() {
        Task {
            do {
                let accessibleImages = try await imageManager.getImagesWithHighContrast()
                await MainActor.run {
                    displayImages(accessibleImages)
                }
            } catch {
                print("Search failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func getAccessibleImages() {
        Task {
            do {
                let accessibleImages = try await imageManager.getAccessibleImages()
                await MainActor.run {
                    displayImages(accessibleImages)
                }
            } catch {
                print("Search failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func displayImageColorInfo(_ metadata: ImageMetadata) {
        print("Image: \(metadata.fileName)")
        print("Dominant colors: \(metadata.colorAnalysis.dominantColors)")
        print("Average color: \(metadata.colorAnalysis.averageColor)")
        
        if let palette = metadata.colorAnalysis.palette {
            print("Palette:")
            print("  Background: \(palette.background)")
            print("  Primary: \(palette.primary)")
            if let secondary = palette.secondary {
                print("  Secondary: \(secondary)")
            }
            print("  Contrast with white: \(palette.backgroundContrastWithWhite)")
            print("  Accessibility level: \(palette.contrastLevel)")
        }
    }
    
    private func loadAllImages() {
        Task {
            do {
                let images = try await imageManager.getAllImages()
                await MainActor.run {
                    displayImages(images)
                }
            } catch {
                print("Failed to load images: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func showLoadingIndicator() {
        // Implement your loading UI
    }
    
    private func hideLoadingIndicator() {
        // Hide loading UI
    }
    
    private func handleUploadSuccess(_ metadata: ImageMetadata) {
        // Handle successful upload
    }
    
    private func handleUploadError(_ error: Error) {
        // Handle upload error
    }
    
    private func displayImages(_ images: [ImageMetadata]) {
        // Update your collection view or table view
    }
}

