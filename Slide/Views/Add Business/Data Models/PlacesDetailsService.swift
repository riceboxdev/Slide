//
//  PlacesDetailsService.swift
//  Slide
//
//  Created by Nick Rogers on 8/23/25.
//


import Foundation
import Combine
import SwiftUI
import CoreLocation
import _MapKit_SwiftUI

// MARK: - Unified Google Places Service
@MainActor
class GooglePlacesService: ObservableObject {
    private let apiKey: String
    private let locationManager: LocationManager
    private let autocompleteURL = "https://places.googleapis.com/v1/places:autocomplete"
    private let placeDetailsURL = "https://places.googleapis.com/v1/places"
    
    // Autocomplete properties
    @Published var suggestions: [AutocompleteSuggestion] = []
    @Published var isSearching = false
    @Published var searchError: String?
    
    // Place details properties
    @Published var selectedPlace: AutocompleteSuggestion?
    @Published var placeDetails: PlaceDetailsResponse?
    @Published var isLoadingDetails = false
    @Published var detailsError: String?
    
    init(apiKey: String, locationManager: LocationManager) {
        self.apiKey = apiKey
        self.locationManager = locationManager
        print("GooglePlacesService initialized with API key: \(apiKey.prefix(8))...")
    }
    
    // MARK: - Autocomplete Search Methods
    func searchPlaces(
        query: String,
        placeType: GooglePlaceType = .all,
        includeQueryPredictions: Bool = true,
        language: String = "en"
    ) async {
        print("Starting search for: '\(query)' with type: \(placeType.rawValue)")
        
        guard !query.isEmpty else {
            suggestions = []
            return
        }
        
        isSearching = true
        searchError = nil
        
        defer {
            isSearching = false
        }
        
        do {
            let requestBody = buildAutocompleteRequestBody(
                query: query,
                placeType: placeType,
                includeQueryPredictions: includeQueryPredictions,
                language: language
            )
            
            var request = URLRequest(url: URL(string: autocompleteURL)!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
            request.setValue("*", forHTTPHeaderField: "X-Goog-FieldMask")
            request.httpBody = requestBody
            
            print("Request URL: \(autocompleteURL)")
            if let bodyString = String(data: requestBody, encoding: .utf8) {
                print("Request body: \(bodyString)")
            }
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw PlacesError.invalidResponse
            }
            
            print("HTTP Status Code: \(httpResponse.statusCode)")
            
            guard httpResponse.statusCode == 200 else {
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Error response: \(responseString)")
                    
                    // Try to parse API error
                    if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let error = errorData["error"] as? [String: Any],
                       let message = error["message"] as? String {
                        throw PlacesError.apiError(message)
                    }
                }
                throw PlacesError.httpError(httpResponse.statusCode)
            }
            
            // Debug: Print raw response
            if let responseString = String(data: data, encoding: .utf8) {
                print("Raw API response: \(responseString.prefix(1000))...")
            }
            
            let placesResponse = try JSONDecoder().decode(GooglePlacesResponse.self, from: data)
            let autocompleteSuggestions = placesResponse.suggestions.map { AutocompleteSuggestion(from: $0) }
            
            print("Found \(autocompleteSuggestions.count) suggestions")
            for suggestion in autocompleteSuggestions.prefix(3) {
                print("Suggestion: '\(suggestion.primaryText)' - \(suggestion.secondaryText)")
            }
            
            suggestions = autocompleteSuggestions
            
        } catch let error as DecodingError {
            let detailedError = formatDecodingError(error)
            searchError = "Decoding error: \(detailedError)"
            print("Detailed decoding error: \(error)")
            suggestions = []
        } catch let error as PlacesError {
            searchError = error.localizedDescription
            suggestions = []
        } catch {
            searchError = "Network error: \(error.localizedDescription)"
            suggestions = []
            print("Search error: \(error)")
        }
    }
    
    // MARK: - Place Details Methods
    func getPlaceDetails(
        placeId: String,
        fields: [PlaceDetailsField] = [.id, .displayName, .formattedAddress],
        languageCode: String? = nil,
        regionCode: String? = nil,
        sessionToken: String? = nil
    ) async throws -> PlaceDetailsResponse {
        
        guard !placeId.isEmpty else {
            throw PlacesError.invalidPlaceId
        }
        
        isLoadingDetails = true
        detailsError = nil
        
        defer {
            isLoadingDetails = false
        }
        
        var urlComponents = URLComponents(string: "\(placeDetailsURL)/\(placeId)")!
        
        var queryItems: [URLQueryItem] = []
        if let languageCode = languageCode {
            queryItems.append(URLQueryItem(name: "languageCode", value: languageCode))
        }
        if let regionCode = regionCode {
            queryItems.append(URLQueryItem(name: "regionCode", value: regionCode))
        }
        if let sessionToken = sessionToken {
            queryItems.append(URLQueryItem(name: "sessionToken", value: sessionToken))
        }
        
        if !queryItems.isEmpty {
            urlComponents.queryItems = queryItems
        }
        
        guard let url = urlComponents.url else {
            throw PlacesError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        request.setValue(fields.map(\.rawValue).joined(separator: ","), forHTTPHeaderField: "X-Goog-FieldMask")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw PlacesError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                // Try to decode error response for more details
                if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = errorData["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    throw PlacesError.apiError(message)
                }
                throw PlacesError.httpError(httpResponse.statusCode)
            }
            
            // Debug: Print raw JSON response to help with debugging
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Place Details API Response: \(jsonString)")
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let placeDetails = try decoder.decode(PlaceDetailsResponse.self, from: data)
            return placeDetails
            
        } catch let error as DecodingError {
            let detailedError = formatDecodingError(error)
            detailsError = "Decoding error: \(detailedError)"
            print("Detailed decoding error: \(error)")
            throw PlacesError.decodingError(error)
        } catch let error as PlacesError {
            detailsError = error.localizedDescription
            throw error
        } catch {
            detailsError = "Network error: \(error.localizedDescription)"
            throw PlacesError.networkError(error)
        }
    }
    
    // Legacy method for backwards compatibility
    func fetchPlaceDetails(placeId: String) async -> PlaceSearchDetailsResponse? {
        print("Fetching legacy place details for: \(placeId)")
        
        do {
            let fields: [PlaceDetailsField] = [
                .name, .formattedAddress, .location, .types,
                .nationalPhoneNumber, .websiteUri, .rating, .userRatingCount
            ]
            
            let fullDetails = try await getPlaceDetails(placeId: placeId, fields: fields)
            
            // Convert to legacy format
            return PlaceSearchDetailsResponse(
                name: fullDetails.name ?? fullDetails.displayName?.text,
                formattedAddress: fullDetails.formattedAddress,
                location: fullDetails.location != nil ?
                    LocationCoordinate(
                        latitude: fullDetails.location!.latitude,
                        longitude: fullDetails.location!.longitude,
                        timestamp: Date.now
                    ) : nil,
                types: fullDetails.types,
                phoneNumber: fullDetails.nationalPhoneNumber,
                website: fullDetails.websiteUri,
                rating: fullDetails.rating,
                userRatingCount: fullDetails.userRatingCount
            )
            
        } catch {
            print("Legacy place details error: \(error)")
            await MainActor.run {
                self.detailsError = "Failed to fetch place details: \(error.localizedDescription)"
            }
            return nil
        }
    }
    
    // MARK: - Convenience Methods for Place Details
    func getBasicDetails(placeId: String) async throws -> PlaceDetailsResponse {
        return try await getPlaceDetails(
            placeId: placeId,
            fields: [.id, .name, .photos, .attributions]
        )
    }
    
    func getEssentialDetails(placeId: String) async throws -> PlaceDetailsResponse {
        return try await getPlaceDetails(
            placeId: placeId,
            fields: [.id, .displayName, .formattedAddress, .location, .addressComponents, .plusCode, .types, .viewport]
        )
    }
    
    func getProDetails(placeId: String) async throws -> PlaceDetailsResponse {
        return try await getPlaceDetails(
            placeId: placeId,
            fields: [.id, .displayName, .formattedAddress, .location, .businessStatus, .googleMapsUri, .primaryType, .primaryTypeDisplayName]
        )
    }
    
    func getEnterpriseDetails(placeId: String) async throws -> PlaceDetailsResponse {
        return try await getPlaceDetails(
            placeId: placeId,
            fields: [.id, .displayName, .formattedAddress, .location, .rating, .userRatingCount, .websiteUri, .nationalPhoneNumber, .internationalPhoneNumber]
        )
    }
    
    func getAddressDescriptors(placeId: String) async throws -> PlaceDetailsResponse {
        return try await getPlaceDetails(
            placeId: placeId,
            fields: [.name, .displayName, .addressDescriptor]
        )
    }
    
    // MARK: - Private Helper Methods
    private func buildAutocompleteRequestBody(
        query: String,
        placeType: GooglePlaceType,
        includeQueryPredictions: Bool,
        language: String
    ) -> Data {
        var requestDict: [String: Any] = [
            "input": query,
            "languageCode": language,
            "includeQueryPredictions": includeQueryPredictions
        ]
        
        // Add location bias if available
        if let userLocation = locationManager.location {
            let coordinate = userLocation.coordinate
            requestDict["locationBias"] = [
                "circle": [
                    "center": [
                        "latitude": coordinate.latitude,
                        "longitude": coordinate.longitude
                    ],
                    "radius": 5000.0 // 5km radius
                ]
            ]
            
            // Add origin for distance calculation
            requestDict["origin"] = [
                "latitude": coordinate.latitude,
                "longitude": coordinate.longitude
            ]
            
            print("Using location bias: \(coordinate.latitude), \(coordinate.longitude)")
        }
        
        // Add place type filter if specified
        if placeType != .all {
            requestDict["includedPrimaryTypes"] = [placeType.rawValue]
        }
        
        return try! JSONSerialization.data(withJSONObject: requestDict)
    }
    
    private func formatDecodingError(_ error: DecodingError) -> String {
        switch error {
        case .typeMismatch(let type, let context):
            return "Type mismatch for \(type) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
        case .valueNotFound(let type, let context):
            return "Value not found for \(type) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
        case .keyNotFound(let key, let context):
            return "Key '\(key.stringValue)' not found at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
        case .dataCorrupted(let context):
            return "Data corrupted at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
        @unknown default:
            return "Unknown decoding error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Errors
enum PlacesError: LocalizedError {
    case invalidPlaceId
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case apiError(String)
    case decodingError(DecodingError)
    case networkError(Error)
    case missingAPIKey
    
    var errorDescription: String? {
        switch self {
        case .invalidPlaceId:
            return "Invalid place ID provided"
        case .invalidURL:
            return "Invalid URL constructed"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "HTTP error with status code: \(code)"
        case .apiError(let message):
            return "API error: \(message)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .missingAPIKey:
            return "Google Places API key is required"
        }
    }
}

