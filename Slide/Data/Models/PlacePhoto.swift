//
//  PlacePhoto.swift
//  Slide
//
//  Created by Nick Rogers on 8/28/25.
//


import Foundation
import SwiftUI
import Combine

// MARK: - Models
struct PlacePhoto: Codable, Identifiable {
    let id = UUID()
    let name: String
    let widthPx: Int
    let heightPx: Int
    let authorAttributions: [AuthorAttribution]?
    
    private enum CodingKeys: String, CodingKey {
        case name, widthPx, heightPx, authorAttributions
    }
}



struct PlaceDetailsResponse: Codable {
    let id: String
    let displayName: DisplayName?
    let photos: [PlacePhoto]?
}

struct PhotoResponse: Codable {
    let name: String
    let photoUri: String
}

// MARK: - Service
class PlacePhotoService: ObservableObject {
    static let shared = PlacePhotoService()
    
    private let apiKey: String
    private let baseURL = "https://places.googleapis.com/v1"
    private let session = URLSession.shared
    
    // Cache for downloaded images
    private var imageCache: [String: UIImage] = [:]
    
    init(apiKey: String = "") {
        self.apiKey = apiKey
    }
    
    // MARK: - Public Methods
    
    /// Fetch place details including photos
    func fetchPlaceDetails(placeId: String) async throws -> PlaceDetailsResponse {
        guard !apiKey.isEmpty else {
            throw PlacePhotoError.missingAPIKey
        }
        
        let url = URL(string: "\(baseURL)/places/\(placeId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        request.setValue("id,displayName,photos", forHTTPHeaderField: "X-Goog-FieldMask")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw PlacePhotoError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                throw PlacePhotoError.httpError(httpResponse.statusCode)
            }
            
            let placeDetails = try JSONDecoder().decode(PlaceDetailsResponse.self, from: data)
            return placeDetails
            
        } catch let error as DecodingError {
            throw PlacePhotoError.decodingError(error)
        } catch {
            throw PlacePhotoError.networkError(error)
        }
    }
    
    /// Fetch a photo using its resource name
    func fetchPhoto(photoName: String, maxWidth: Int = 400, maxHeight: Int = 400, skipRedirect: Bool = false) async throws -> UIImage {
        guard !apiKey.isEmpty else {
            throw PlacePhotoError.missingAPIKey
        }
        
        // Check cache first
        let cacheKey = "\(photoName)_\(maxWidth)x\(maxHeight)"
        if let cachedImage = imageCache[cacheKey] {
            return cachedImage
        }
        
        let encodedPhotoName = photoName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? photoName
        var urlComponents = URLComponents(string: "\(baseURL)/\(encodedPhotoName)/media")!
        
        urlComponents.queryItems = [
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "maxWidthPx", value: String(maxWidth)),
            URLQueryItem(name: "maxHeightPx", value: String(maxHeight))
        ]
        
        if skipRedirect {
            urlComponents.queryItems?.append(URLQueryItem(name: "skipHttpRedirect", value: "true"))
        }
        
        guard let url = urlComponents.url else {
            throw PlacePhotoError.invalidURL
        }
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw PlacePhotoError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                throw PlacePhotoError.httpError(httpResponse.statusCode)
            }
            
            // If skipRedirect is true, we get JSON with photoUri
            if skipRedirect {
                let photoResponse = try JSONDecoder().decode(PhotoResponse.self, from: data)
                guard let photoURL = URL(string: photoResponse.photoUri) else {
                    throw PlacePhotoError.invalidURL
                }
                let (imageData, _) = try await session.data(from: photoURL)
                guard let image = UIImage(data: imageData) else {
                    throw PlacePhotoError.invalidImageData
                }
                imageCache[cacheKey] = image
                return image
            } else {
                // Direct image data
                guard let image = UIImage(data: data) else {
                    throw PlacePhotoError.invalidImageData
                }
                imageCache[cacheKey] = image
                return image
            }
            
        } catch let error as DecodingError {
            throw PlacePhotoError.decodingError(error)
        } catch {
            throw PlacePhotoError.networkError(error)
        }
    }
    
    /// Clear image cache
    func clearCache() {
        imageCache.removeAll()
    }
    
    /// Get cache size in MB
    func getCacheSize() -> Double {
        let totalBytes = imageCache.values.reduce(0) { total, image in
            guard let data = image.pngData() else { return total }
            return total + data.count
        }
        return Double(totalBytes) / (1024 * 1024) // Convert to MB
    }
}

// MARK: - Errors
enum PlacePhotoError: LocalizedError {
    case missingAPIKey
    case invalidURL
    case invalidResponse
    case invalidImageData
    case httpError(Int)
    case networkError(Error)
    case decodingError(DecodingError)
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "API key is missing. Please set your Google Places API key."
        case .invalidURL:
            return "Invalid URL format."
        case .invalidResponse:
            return "Invalid response from server."
        case .invalidImageData:
            return "Unable to create image from response data."
        case .httpError(let code):
            return "HTTP error with status code: \(code)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        }
    }
}

// MARK: - SwiftUI Views

/// A view that displays a place photo with loading and error states
struct PlacePhotoView: View {
    let photoName: String
    let maxWidth: Int
    let maxHeight: Int
    let cornerRadius: CGFloat
    
    @StateObject private var photoService = PlacePhotoService.shared
    @State private var image: UIImage?
    @State private var isLoading = false
    @State private var error: PlacePhotoError?
    
    init(photoName: String, maxWidth: Int = 400, maxHeight: Int = 400, cornerRadius: CGFloat = 8) {
        self.photoName = photoName
        self.maxWidth = maxWidth
        self.maxHeight = maxHeight
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .cornerRadius(cornerRadius)
            } else if isLoading {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    )
            } else if error != nil {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        VStack {
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                            Text("Failed to load")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    )
            }
        }
        .task {
            await loadPhoto()
        }
    }
    
    private func loadPhoto() async {
        guard image == nil && !isLoading else { return }
        
        isLoading = true
        error = nil
        
        do {
            let loadedImage = try await photoService.fetchPhoto(
                photoName: photoName,
                maxWidth: maxWidth,
                maxHeight: maxHeight
            )
            await MainActor.run {
                self.image = loadedImage
                self.isLoading = false
            }
        } catch let placePhotoError as PlacePhotoError {
            await MainActor.run {
                self.error = placePhotoError
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = .networkError(error)
                self.isLoading = false
            }
        }
    }
}

/// A grid view for displaying multiple place photos
struct PlacePhotosGrid: View {
    let photos: [PlacePhoto]
    let columns: Int
    let spacing: CGFloat
    let photoSize: CGFloat
    
    init(photos: [PlacePhoto], columns: Int = 2, spacing: CGFloat = 8, photoSize: CGFloat = 150) {
        self.photos = photos
        self.columns = columns
        self.spacing = spacing
        self.photoSize = photoSize
    }
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns), spacing: spacing) {
            ForEach(photos) { photo in
                PlacePhotoView(
                    photoName: photo.name,
                    maxWidth: Int(photoSize * 2), // 2x for better quality
                    maxHeight: Int(photoSize * 2)
                )
                .frame(width: photoSize, height: photoSize)
                .clipped()
            }
        }
    }
}

// MARK: - Usage Example View
struct PlaceDetailsView: View {
    let placeId: String
    
    @StateObject private var photoService = PlacePhotoService.shared
    @State private var placeDetails: PlaceDetailsResponse?
    @State private var isLoading = false
    @State private var error: PlacePhotoError?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let placeDetails = placeDetails {
                    Text(placeDetails.displayName?.text ?? "Unknown Place")
                        .font(.title)
                        .bold()
                    
                    if let photos = placeDetails.photos, !photos.isEmpty {
                        Text("Photos")
                            .font(.headline)
                        
                        PlacePhotosGrid(photos: photos)
                    } else {
                        Text("No photos available")
                            .foregroundColor(.gray)
                    }
                } else if isLoading {
                    ProgressView("Loading place details...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = error {
                    Text("Error: \(error.localizedDescription)")
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
        }
        .task {
            await loadPlaceDetails()
        }
    }
    
    private func loadPlaceDetails() async {
        guard placeDetails == nil && !isLoading else { return }
        
        isLoading = true
        error = nil
        
        do {
            let details = try await photoService.fetchPlaceDetails(placeId: placeId)
            await MainActor.run {
                self.placeDetails = details
                self.isLoading = false
            }
        } catch let placePhotoError as PlacePhotoError {
            await MainActor.run {
                self.error = placePhotoError
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = .networkError(error)
                self.isLoading = false
            }
        }
    }
}


// MARK: - Errors



// MARK: - Combined Places Service

class NewPlacesAPIService: ObservableObject {
 
    
    private let apiKey: String
    private let baseURL = "https://places.googleapis.com/v1"
    private let searchURL = "https://places.googleapis.com/v1/places:searchNearby"
    private let session = URLSession.shared
    
    // Published properties for UI binding
    @Published var places: [Place] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Cache for downloaded images
    private var imageCache: [String: UIImage] = [:]
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    // MARK: - Place Search Methods
    
    /// Search for nearby places
    func searchNearbyPlaces(
        latitude: Double,
        longitude: Double,
        radius: Double = 1000.0,
        includedTypes: [String] = [],
        excludedTypes: [String] = [],
        maxResults: Int = 20,
        rankPreference: String = "POPULARITY",
        fieldMask: String = "*"
    ) async throws -> [Place] {
        guard !apiKey.isEmpty else {
            throw PlacePhotoError.missingAPIKey
        }
        
        let request = PlaceSearchRequest(
            includedTypes: includedTypes.isEmpty ? nil : includedTypes,
            excludedTypes: excludedTypes.isEmpty ? nil : excludedTypes,
            maxResultCount: maxResults,
            locationRestriction: PlaceSearchRequest.LocationRestriction(
                circle: PlaceSearchRequest.LocationRestriction.Circle(
                    center: PlaceSearchRequest.LocationRestriction.Circle.Center(
                        latitude: latitude,
                        longitude: longitude
                    ),
                    radius: radius
                )
            ),
            rankPreference: rankPreference,
            languageCode: "en"
        )
        
        guard let url = URL(string: searchURL) else {
            throw PlacePhotoError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        urlRequest.setValue(fieldMask, forHTTPHeaderField: "X-Goog-FieldMask")
        
        do {
            let jsonData = try JSONEncoder().encode(request)
            urlRequest.httpBody = jsonData
            
            let (data, response) = try await session.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw PlacePhotoError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                throw PlacePhotoError.httpError(httpResponse.statusCode)
            }
            
            let responseObj = try JSONDecoder().decode(PlaceSearchResponse.self, from: data)
            return responseObj.places
            
        } catch let error as DecodingError {
            throw PlacePhotoError.decodingError(error)
        } catch {
            throw PlacePhotoError.networkError(error)
        }
    }
    
    /// Search places with UI state updates
    @MainActor
    func searchPlacesAsync(
        latitude: Double,
        longitude: Double,
        radius: Double = 1000.0,
        includedTypes: [String] = [],
        excludedTypes: [String] = [],
        maxResults: Int = 20,
        rankPreference: String = "POPULARITY",
        fieldMask: String = "*"
    ) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let searchResults = try await searchNearbyPlaces(
                latitude: latitude,
                longitude: longitude,
                radius: radius,
                includedTypes: includedTypes,
                excludedTypes: excludedTypes,
                maxResults: maxResults,
                rankPreference: rankPreference,
                fieldMask: fieldMask
            )
            places = searchResults
        } catch {
            errorMessage = error.localizedDescription
            places = []
        }
        
        isLoading = false
    }
    
    // MARK: - Place Details Methods
    
    /// Fetch place details including photos
    func fetchPlaceDetails(placeId: String) async throws -> PlaceDetailsResponse {
        guard !apiKey.isEmpty else {
            throw PlacePhotoError.missingAPIKey
        }
        
        let url = URL(string: "\(baseURL)/places/\(placeId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        request.setValue("id,displayName,photos", forHTTPHeaderField: "X-Goog-FieldMask")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw PlacePhotoError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                throw PlacePhotoError.httpError(httpResponse.statusCode)
            }
            
            let placeDetails = try JSONDecoder().decode(PlaceDetailsResponse.self, from: data)
            return placeDetails
            
        } catch let error as DecodingError {
            throw PlacePhotoError.decodingError(error)
        } catch {
            throw PlacePhotoError.networkError(error)
        }
    }
    
    // MARK: - Photo Methods
    
    /// Fetch a photo using its resource name
    func fetchPhoto(photoName: String, maxWidth: Int = 400, maxHeight: Int = 400, skipRedirect: Bool = false) async throws -> UIImage {
        guard !apiKey.isEmpty else {
            throw PlacePhotoError.missingAPIKey
        }
        
        // Check cache first
        let cacheKey = "\(photoName)_\(maxWidth)x\(maxHeight)"
        if let cachedImage = imageCache[cacheKey] {
            return cachedImage
        }
        
        let encodedPhotoName = photoName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? photoName
        var urlComponents = URLComponents(string: "\(baseURL)/\(encodedPhotoName)/media")!
        
        urlComponents.queryItems = [
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "maxWidthPx", value: String(maxWidth)),
            URLQueryItem(name: "maxHeightPx", value: String(maxHeight))
        ]
        
        if skipRedirect {
            urlComponents.queryItems?.append(URLQueryItem(name: "skipHttpRedirect", value: "true"))
        }
        
        guard let url = urlComponents.url else {
            throw PlacePhotoError.invalidURL
        }
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw PlacePhotoError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                throw PlacePhotoError.httpError(httpResponse.statusCode)
            }
            
            // If skipRedirect is true, we get JSON with photoUri
            if skipRedirect {
                let photoResponse = try JSONDecoder().decode(PhotoResponse.self, from: data)
                guard let photoURL = URL(string: photoResponse.photoUri) else {
                    throw PlacePhotoError.invalidURL
                }
                let (imageData, _) = try await session.data(from: photoURL)
                guard let image = UIImage(data: imageData) else {
                    throw PlacePhotoError.invalidImageData
                }
                imageCache[cacheKey] = image
                return image
            } else {
                // Direct image data
                guard let image = UIImage(data: data) else {
                    throw PlacePhotoError.invalidImageData
                }
                imageCache[cacheKey] = image
                return image
            }
            
        } catch let error as DecodingError {
            throw PlacePhotoError.decodingError(error)
        } catch {
            throw PlacePhotoError.networkError(error)
        }
    }
    
    /// Fetch multiple photos for a place
    func fetchPlacePhotos(placeId: String, maxPhotos: Int = 5, maxWidth: Int = 400, maxHeight: Int = 400) async throws -> [UIImage] {
        let placeDetails = try await fetchPlaceDetails(placeId: placeId)
        
        guard let photos = placeDetails.photos else {
            return []
        }
        
        let photosToFetch = Array(photos.prefix(maxPhotos))
        var images: [UIImage] = []
        
        for photo in photosToFetch {
            do {
                let image = try await fetchPhoto(
                    photoName: photo.name,
                    maxWidth: maxWidth,
                    maxHeight: maxHeight
                )
                images.append(image)
            } catch {
                // Continue with other photos if one fails
                print("Failed to fetch photo \(photo.name): \(error)")
            }
        }
        
        return images
    }
    
    // MARK: - Cache Management
    
    /// Clear image cache
    func clearCache() {
        imageCache.removeAll()
    }
    
    /// Get cache size in MB
    func getCacheSize() -> Double {
        let totalBytes = imageCache.values.reduce(0) { total, image in
            guard let data = image.pngData() else { return total }
            return total + data.count
        }
        return Double(totalBytes) / (1024 * 1024) // Convert to MB
    }
    
    /// Get number of cached images
    func getCacheCount() -> Int {
        return imageCache.count
    }
    
    // MARK: - Convenience Methods
    
    /// Search for places and optionally fetch photos for each
    @MainActor
    func searchPlacesWithPhotos(
        latitude: Double,
        longitude: Double,
        radius: Double = 1000.0,
        includedTypes: [String] = [],
        maxResults: Int = 20,
        fetchPhotos: Bool = false,
        maxPhotosPerPlace: Int = 1
    ) async {
        isLoading = true
        errorMessage = nil
        
        do {
            var searchResults = try await searchNearbyPlaces(
                latitude: latitude,
                longitude: longitude,
                radius: radius,
                includedTypes: includedTypes,
                maxResults: maxResults
            )
            
            if fetchPhotos {
                // Fetch photos for each place (this might take a while)
                for i in 0..<searchResults.count {
                    if let placePhotos = searchResults[i].photos?.prefix(maxPhotosPerPlace) {
                        // Photos are already included in the search results
                        // You might want to preload the actual image data here
                    }
                }
            }
            
            places = searchResults
        } catch {
            errorMessage = error.localizedDescription
            places = []
        }
        
        isLoading = false
    }
}
