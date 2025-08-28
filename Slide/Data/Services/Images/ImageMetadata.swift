//
//  ImageMetadata.swift
//  Slide
//
//  Created by Nick Rogers on 8/25/25.
//

import UIKit
import SwiftUI
import Photos
import PhotosUI
import Firebase
import FirebaseStorage
import FirebaseFirestore
import ColorKit
import AVFoundation

// MARK: - Data Models

struct ImageMetadata: Codable {
    let id: String
    let fileName: String
    let fileSize: Int64
    let imageSize: ImageMetadata.ImageSize
    let colorAnalysis: ImageMetadata.ColorAnalysis
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
    
    // MARK: - HEIF Configuration
    
    private struct HEIFConfig {
        static let quality: CGFloat = 0.8
        static let contentType = "image/heif"
        static let fileExtension = "heic"
    }
    
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
        
        // Generate unique filename if not provided, ensuring .heic extension
        let baseFileName = fileName?.replacingOccurrences(of: ".jpg", with: "").replacingOccurrences(of: ".jpeg", with: "").replacingOccurrences(of: ".png", with: "") ?? "image_\(UUID().uuidString)"
        let finalFileName = "\(baseFileName).\(HEIFConfig.fileExtension)"
        let imageId = UUID().uuidString
        
        // Convert image to HEIF data
        let imageData = try convertImageToHEIF(image, quality: HEIFConfig.quality)
        
        // Extract color analysis using ColorKit
        let colorAnalysis = try await extractColorAnalysis(from: image)
        
        // Upload to Firebase Storage
        let storageRef = storage.reference().child("images/\(imageId)/\(finalFileName)")
        let metadata = StorageMetadata()
        metadata.contentType = HEIFConfig.contentType
        
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
            contentType: HEIFConfig.contentType,
            tags: tags
        )
        
        // Save metadata to Firestore
        try await saveMetadataToFirestore(imageMetadata)
        
        return imageMetadata
    }
    
    // MARK: - HEIF Conversion
    
    private func convertImageToHEIF(_ image: UIImage, quality: CGFloat) throws -> Data {
        guard #available(iOS 11.0, *) else {
            throw NewImageUploadError.heifNotSupported
        }
        
        // Check if HEIF encoding is available on this device
        guard AVAssetExportSession.allExportPresets().contains(AVAssetExportPresetHEVCHighestQuality) else {
            throw NewImageUploadError.heifNotSupported
        }
        
        let data = NSMutableData()
        
        guard let destination = CGImageDestinationCreateWithData(data, AVFileType.heic as CFString, 1, nil) else {
            throw NewImageUploadError.heifConversionFailed
        }
        
        guard let cgImage = image.cgImage else {
            throw NewImageUploadError.imageConversionFailed
        }
        
        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: quality
        ]
        
        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
        
        guard CGImageDestinationFinalize(destination) else {
            throw NewImageUploadError.heifConversionFailed
        }
        
        return data as Data
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
                            backgroundContrastWithWhite: contrastValue.associatedValue,
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
    
    // MARK: - HEIF Utility Methods
    
    func isHEIFSupported() -> Bool {
        if #available(iOS 11.0, *) {
            return AVAssetExportSession.allExportPresets().contains(AVAssetExportPresetHEVCHighestQuality)
        }
        return false
    }
    
    func getOptimalHEIFQuality(for imageSize: CGSize) -> CGFloat {
        let totalPixels = imageSize.width * imageSize.height
        
        // Adjust quality based on image size for optimal file size/quality balance
        switch totalPixels {
        case 0...1_000_000: // Up to 1MP
            return 0.9
        case 1_000_001...4_000_000: // 1-4MP
            return 0.85
        case 4_000_001...8_000_000: // 4-8MP
            return 0.8
        case 8_000_001...16_000_000: // 8-16MP
            return 0.75
        default: // Above 16MP
            return 0.7
        }
    }
    
    func uploadImageWithOptimalQuality(_ image: UIImage,
                                      fileName: String? = nil,
                                      tags: [String]? = nil) async throws -> ImageMetadata {
        
        let optimalQuality = getOptimalHEIFQuality(for: image.size)
        
        // Generate unique filename if not provided, ensuring .heic extension
        let baseFileName = fileName?.replacingOccurrences(of: ".jpg", with: "").replacingOccurrences(of: ".jpeg", with: "").replacingOccurrences(of: ".png", with: "") ?? "image_\(UUID().uuidString)"
        let finalFileName = "\(baseFileName).\(HEIFConfig.fileExtension)"
        let imageId = UUID().uuidString
        
        // Convert image to HEIF data with optimal quality
        let imageData = try convertImageToHEIF(image, quality: optimalQuality)
        
        // Extract color analysis using ColorKit
        let colorAnalysis = try await extractColorAnalysis(from: image)
        
        // Upload to Firebase Storage
        let storageRef = storage.reference().child("images/\(imageId)/\(finalFileName)")
        let metadata = StorageMetadata()
        metadata.contentType = HEIFConfig.contentType
        
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
            contentType: HEIFConfig.contentType,
            tags: tags
        )
        
        // Save metadata to Firestore
        try await saveMetadataToFirestore(imageMetadata)
        
        return imageMetadata
    }
    
    // MARK: - Firestore Operations
    
    private func saveMetadataToFirestore(_ metadata: ImageMetadata) async throws {
        let document = firestore.collection(imagesCollection).document(metadata.id)
        try document.setData(from: metadata)
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
            return metadata.colorAnalysis.dominantColors.contains { dominantHex in
                if let targetColor = targetColor, let dominantColor = UIColor(hex: dominantHex) {
                    let difference = targetColor.difference(from: dominantColor, using: .CIE94)
                    return difference.associatedValue < threshold
                } else {
                    return false
                }
            }
        }
    }
    
    func getImagesByAverageColor(similarTo hexColor: String, threshold: Double = 20.0) async throws -> [ImageMetadata] {
        let allImages = try await getAllImages()
        let targetColor = UIColor(hex: hexColor)
        
        return allImages.filter { metadata in
            if let targetColor = targetColor, let averageColor = UIColor(hex: metadata.colorAnalysis.averageColor) {
                let difference = targetColor.difference(from: averageColor, using: .CIE94)
                return difference.associatedValue < threshold
            } else {
                return false
            }
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
            guard let backgroundHex = metadata.colorAnalysis.palette?.background, let targetColor = targetColor, let backgroundColor = UIColor(hex: backgroundHex) else { return false }
            let difference = targetColor.difference(from: backgroundColor, using: .CIE94)
            return difference.associatedValue < threshold
        }
    }
    
    func getImagesByPrimaryColor(similarTo hexColor: String, threshold: Double = 20.0) async throws -> [ImageMetadata] {
        let allImages = try await getAllImages()
        let targetColor = UIColor(hex: hexColor)
        
        return allImages.filter { metadata in
            guard let primaryHex = metadata.colorAnalysis.palette?.primary, let targetColor = targetColor, let primaryColor = UIColor(hex: primaryHex) else { return false }
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
                if let targetColor = targetColor, let dominantColor = UIColor(hex: dominantHex) {
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
                } else {
                    return false
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
    
    // MARK: - Migration Methods for Existing Images
    
    func migrateImageToHEIF(_ imageId: String) async throws -> ImageMetadata {
        guard let existingMetadata = try await getImageById(imageId) else {
            throw NewImageUploadError.imageNotFound
        }
        
        // Download the existing image
        guard let url = URL(string: existingMetadata.downloadURL),
              let imageData = try? Data(contentsOf: url),
              let image = UIImage(data: imageData) else {
            throw NewImageUploadError.downloadFailed
        }
        
        // Delete the old image
        try await deleteImage(imageId)
        
        // Upload as HEIF with the same tags
        return try await uploadImageAsync(image, fileName: existingMetadata.fileName, tags: existingMetadata.tags)
    }
    
    func migrateAllImagesToHEIF() async throws -> [ImageMetadata] {
        let allImages = try await getAllImages()
        var migratedImages: [ImageMetadata] = []
        
        for image in allImages {
            if image.contentType != HEIFConfig.contentType {
                do {
                    let migratedImage = try await migrateImageToHEIF(image.id)
                    migratedImages.append(migratedImage)
                } catch {
                    print("Failed to migrate image \(image.id): \(error.localizedDescription)")
                }
            }
        }
        
        return migratedImages
    }
}

// MARK: - Error Types

enum NewImageUploadError: Error, LocalizedError {
    case imageCompressionFailed
    case heifConversionFailed
    case heifNotSupported
    case imageConversionFailed
    case colorExtractionFailed
    case uploadFailed(String)
    case metadataSaveFailed(String)
    case imageNotFound
    case downloadFailed
    
    var errorDescription: String? {
        switch self {
        case .imageCompressionFailed:
            return "Failed to compress image"
        case .heifConversionFailed:
            return "Failed to convert image to HEIF format"
        case .heifNotSupported:
            return "HEIF format is not supported on this device"
        case .imageConversionFailed:
            return "Failed to convert image to CGImage"
        case .colorExtractionFailed:
            return "Failed to extract color information from image"
        case .uploadFailed(let message):
            return "Upload failed: \(message)"
        case .metadataSaveFailed(let message):
            return "Failed to save metadata: \(message)"
        case .imageNotFound:
            return "Image not found"
        case .downloadFailed:
            return "Failed to download image for migration"
        }
    }
}

// MARK: - Usage Example

class ViewController: UIViewController {
    private let imageManager = FirebaseImageManager()
    
    private func uploadSelectedImage(_ image: UIImage) {
        // Check HEIF support first
        guard imageManager.isHEIFSupported() else {
            showError("HEIF format is not supported on this device")
            return
        }
        
        // Show loading indicator
        showLoadingIndicator()
        
        Task {
            do {
                // Upload with optimal quality
                let metadata = try await imageManager.uploadImageWithOptimalQuality(
                    image,
                    fileName: "user_photo",
                    tags: ["portrait", "user_generated"]
                )
                
                await MainActor.run {
                    self.hideLoadingIndicator()
                    print("Upload successful!")
                    print("Image ID: \(metadata.id)")
                    print("File size: \(metadata.fileSize) bytes")
                    print("Content type: \(metadata.contentType)")
                    print("Dominant colors: \(metadata.colorAnalysis.dominantColors)")
                    print("Average color: \(metadata.colorAnalysis.averageColor)")
                    self.handleUploadSuccess(metadata)
                }
                
            } catch {
                await MainActor.run {
                    self.hideLoadingIndicator()
                    print("Upload failed: \(error.localizedDescription)")
                    self.handleUploadError(error)
                }
            }
        }
    }
    
    private func migrateExistingImages() {
        Task {
            do {
                let migratedImages = try await imageManager.migrateAllImagesToHEIF()
                await MainActor.run {
                    print("Successfully migrated \(migratedImages.count) images to HEIF")
                }
            } catch {
                print("Migration failed: \(error.localizedDescription)")
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
    
    private func displayImageColorInfo(_ metadata: ImageMetadata) {
        print("Image: \(metadata.fileName)")
        print("Format: \(metadata.contentType)")
        print("File size: \(metadata.fileSize) bytes")
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
    
    // MARK: - Helper Methods
    
    private func showLoadingIndicator() {
        // Implement your loading UI
    }
    
    private func hideLoadingIndicator() {
        // Hide loading UI
    }
    
    private func showError(_ message: String) {
        // Show error message to user
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

struct PhotosPickerButton: View {
    let uploader = FirebaseImageManager()
    @State var pickedPhotos: [PhotosPickerItem] = []
    @State var processedItems: [UIImage] = []

    var style: PhotosPickerButtonStyle = .pill
    var onProcessedCompleted: ([UIImage]) -> Void
    
    public enum PhotosPickerButtonStyle {
        case pill
        case square
        case glassPill
    }
    
    var body: some View {
        Group {
            switch style {
            case .pill:
                PillButtonStyle()
            case .square:
                SquareButtonStyle()
            case .glassPill:
                glassPillButtonStyle()
            }
        }
    }
    
    fileprivate func SquareButtonStyle() -> some View {
        PhotosPicker(
            selection: $pickedPhotos,
            matching: .images
        ) {
            Image(systemName: "camera.fill")
                .frame(width: 45, height: 45)
                .background(.quaternary)
                .clipShape(.rect(cornerRadius: 14))
        }
        .onChange(of: pickedPhotos) { newItems in
            processedItems = []
            Task {
                for item in newItems {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run {
                            processedItems.append(image)
                        }
                    }
                }
            }
            onProcessedCompleted(self.processedItems)
        }
    }
    
    fileprivate func PillButtonStyle() -> some View {
        return Group {
            HStack {
                PhotosPicker(
                    selection: $pickedPhotos,
                    matching: .images
                ) {
                    Text(processedItems.isEmpty ? "Pick Photos" : "Upload Photos")
                        .font(.variableFont(14, axis: [FontVariations.weight.rawValue : 500]))
                        .frame(height: 45)
                        .padding(.horizontal)
                        .background(
                            .quaternary,
                            in: .capsule
                        )
                }
                if !processedItems.isEmpty {
                    Button {
                        pickedPhotos = []
                        processedItems = []
                    } label: {
                        Image(systemName: "trash")
                            .padding(8)
                            .frame(width: 45, height: 45)
                            .background(
                                .accent.opacity(0.3),
                                in: .circle
                            )
                            .foregroundStyle(.red)
                    }
                    .transition(.blurReplace)
                }
            }
        }
        .animation(.smooth, value: processedItems)
        .onChange(of: pickedPhotos) { newItems in
            processedItems = []
            Task {
                for item in newItems {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run {
                            processedItems.append(image)
                        }
                    }
                }
            }
            onProcessedCompleted(self.processedItems)
        }
    }
    
    fileprivate func glassPillButtonStyle() -> some View {
        return Group {
            HStack {
                PhotosPicker(
                    selection: $pickedPhotos,
                    matching: .images
                ) {
                    Text(processedItems.isEmpty ? "Pick Photos" : "Upload Photos")
                        .font(.variableFont(14, axis: [FontVariations.weight.rawValue : 500]))
                        .frame(height: 45)
                        .padding(.horizontal)
                        .glassEffect(.regular.tint(.accentColor.opacity(0.2)).interactive())
                }
                
                if !processedItems.isEmpty {
                    Button {
                        pickedPhotos = []
                        processedItems = []
                    } label: {
                        Image(systemName: "trash")
                            .padding(8)
                            .frame(width: 45, height: 45)
                            .background(
                                .accent.opacity(0.3),
                                in: .circle
                            )
                            .foregroundStyle(.red)
                    }
                    .transition(.blurReplace)
                }
            }
        }
        .animation(.smooth, value: processedItems)
        .onChange(of: pickedPhotos) { newItems in
            processedItems = []
            Task {
                for item in newItems {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run {
                            processedItems.append(image)
                        }
                    }
                }
            }
            onProcessedCompleted(self.processedItems)
        }
    }
}

#Preview {
    PhotosPickerButton(style: .glassPill) { images in
        
    }
}

