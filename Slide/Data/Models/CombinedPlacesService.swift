//
//  CombinedPlacesService.swift
//  Slide
//
//  Created by Nick Rogers on 8/28/25.
//

import Foundation
import SwiftUI
import Foundation

public struct LatLngBounds: Codable, Equatable {
    public let low: LatLng
    public let high: LatLng
    public init(low: LatLng, high: LatLng) {
        self.low = low
        self.high = high
    }
}

public enum RankPreference: String, Codable {
    case popularity = "POPULARITY"
    case distance = "DISTANCE"
}


public struct LocationBias: Codable, Equatable {
    public let rectangle: LatLngBounds?
    public let circle: GeoCircle?
    public init(rectangle: LatLngBounds? = nil, circle: GeoCircle? = nil) {
        self.rectangle = rectangle
        self.circle = circle
    }
    
    
}

public struct GeoCircle: Codable, Equatable {
    public let center: LatLng
    public let radius: Double // Note: changed to Double as API might expect decimal
    
    public init(center: LatLng, radius: Int) {
        self.center = center
        self.radius = Double(radius)
    }
    
    private enum CodingKeys: String, CodingKey {
        case center = "center"
        case radius = "radius"
    }
}

public struct LocationRestriction: Codable, Equatable {
    public let rectangle: LatLngBounds?
    public let circle: GeoCircle?
    
    public init(rectangle: LatLngBounds? = nil, circle: GeoCircle? = nil) {
        self.rectangle = rectangle
        self.circle = circle
    }
    
    private enum CodingKeys: String, CodingKey {
        case rectangle = "rectangle"
        case circle = "circle" // This might need to be different for Text Search
    }
}

public struct AutocompleteRequest: Codable, Equatable {
    public let input: String
    public let locationBias: LocationBias?
    public let includedPrimaryTypes: [String]?
}

public struct AutocompleteResponse: Codable, Equatable {
    public let suggestions: [AutocompleteSuggestion]?

    public static let defaultFieldMask = "suggestions.placePrediction.placeId,suggestions.placePrediction.text,suggestions.placePrediction.types"
}

public struct AutocompleteSuggestion: Codable, Equatable {
    public let placePrediction: PlacePrediction?
    public let queryPrediction: QueryPrediction?
}

public struct PlacePrediction: Codable, Equatable {
    public let placeId: String?
    public let text: PredictionText?
    public let types: [String]?
}

public struct PredictionText: Codable, Equatable {
    public let text: String?
    public let matches: [TextMatch]?
}

public struct TextMatch: Codable, Equatable {
    public let endOffset: Int?
    public let startOffset: Int?
}

public struct QueryPrediction: Codable, Equatable {
    public let text: PredictionText?
}

public struct TextSearchRequest: Codable, Equatable {
    public let textQuery: String
    public let locationBias: LocationBias?
    public let locationRestriction: LocationRestriction?
    public let openNow: Bool?
    public let maxResultCount: Int?
    public let pageToken: String?
}

public struct TextSearchResponse: Codable, Equatable {
    public let places: [Place]?
    public let nextPageToken: String?
}

public struct NearbySearchRequest: Codable, Equatable {
    public let includedTypes: [String]?
    public let excludedTypes: [String]?
    public let maxResultCount: Int?
    public let locationRestriction: LocationRestriction
    public let rankPreference: RankPreference?
    public let openNow: Bool?
    public let pageToken: String?
}

public struct NearbySearchResponse: Codable, Equatable {
    public let places: [Place]?
    public let nextPageToken: String?
}

public final class CombinedPlacesService {
    public enum ServiceError: Error, LocalizedError {
        case invalidURL
        case http(Int, String)
        case decoding(Error)
        case encoding(Error)
        case emptyResponse
        case imageDownloadFailed
        case unknown(Error)

        public var errorDescription: String? {
            switch self {
            case .invalidURL: return "Invalid URL"
            case .http(let code, let body): return "HTTP error: \(code) — \(body)"
            case .decoding(let err): return "Decoding error: \(err.localizedDescription)"
            case .encoding(let err): return "Encoding error: \(err.localizedDescription)"
            case .emptyResponse: return "Empty response"
            case .imageDownloadFailed: return "Failed to download image"
            case .unknown(let err): return err.localizedDescription
            }
        }
    }

    private let apiKey: String
    private let session: URLSession

    // Base per Places API v1
    private let baseURL = URL(string: "https://places.googleapis.com/v1")!

    public init(session: URLSession = .shared) {
        self.apiKey = APIServiceKeys.googleMapsAPI
        self.session = session
    }

    // MARK: - Nearby Search

    public func searchNearby(
        location: LatLng,
        radiusMeters: Int,
        includedTypes: [String]? = nil,
        excludedTypes: [String]? = nil,
        maxResultCount: Int? = nil,
        rankPreference: RankPreference? = nil,
        openNow: Bool? = nil,
        pageToken: String? = nil,
        fieldMask: String = Place.defaultFieldMask
    ) async throws -> NearbySearchResponse {
        let url = baseURL.appendingPathComponent("places:searchNearby")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        addCommonHeaders(&request, fieldMask: fieldMask)

        let body = NearbySearchRequest(
            includedTypes: includedTypes,
            excludedTypes: excludedTypes,
            maxResultCount: maxResultCount,
            locationRestriction: .init(circle: .init(center: location, radius: radiusMeters)),
            rankPreference: rankPreference,
            openNow: openNow,
            pageToken: pageToken
        )

        request.httpBody = try encodeJSON(body)

        let data = try await data(for: request)
        let response = try decodeJSON(NearbySearchResponse.self, from: data)
        return response
    }

    // MARK: - Text Search

    public func searchText(
        query: String,
        locationBias: LocationBias? = nil,
        locationRestriction: LocationRestriction? = nil,
        includedTypes: [String]? = nil,
        openNow: Bool? = nil,
        maxResultCount: Int? = nil,
        pageToken: String? = nil,
        fieldMask: String = Place.defaultFieldMask
    ) async throws -> TextSearchResponse {
        let url = baseURL.appendingPathComponent("places:searchText")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        addCommonHeaders(&request, fieldMask: fieldMask)

        let body = TextSearchRequest(
            textQuery: query,
            locationBias: locationBias,
            locationRestriction: locationRestriction,
            openNow: openNow,
            maxResultCount: maxResultCount,
            pageToken: pageToken
        )
        
        let json = try encodeJSON(body)
        request.httpBody = json

        let data = try await data(for: request)
     
        let response = try decodeJSON(TextSearchResponse.self, from: data)
        print("ℹ️ Places Service Manager Result: \(response.places?.count)")
        return response
    }

    // MARK: - Place Details

    public func fetchPlaceDetails(
        placeId: String,
        fieldMask: String = Place.detailsFieldMask
    ) async throws -> Place {
        let url = baseURL.appendingPathComponent("places/\(placeId)")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        addCommonHeaders(&request, fieldMask: fieldMask)

        let data = try await data(for: request)
        let place = try decodeJSON(Place.self, from: data)
        return place
    }

    // MARK: - Place Photos (Media)

    // name: "places/{placeId}/photos/{photoResourceName}"
    // Provide either maxWidthPx or maxHeightPx
    public func fetchPhoto(
        name: String,
        maxWidthPx: Int? = nil,
        maxHeightPx: Int? = nil
    ) async throws -> Data {
        var components = URLComponents(url: baseURL.appendingPathComponent("\(name)/media"), resolvingAgainstBaseURL: false)
        var queryItems: [URLQueryItem] = []
        if let w = maxWidthPx { queryItems.append(.init(name: "maxWidthPx", value: String(w))) }
        if let h = maxHeightPx { queryItems.append(.init(name: "maxHeightPx", value: String(h))) }
        components?.queryItems = queryItems.isEmpty ? nil : queryItems
        guard let url = components?.url else { throw ServiceError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ServiceError.emptyResponse }
        guard 200..<300 ~= http.statusCode else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw ServiceError.http(http.statusCode, body)
        }
        return data
    }

    // MARK: - Autocomplete

    public func autocomplete(
        input: String,
        locationBias: LocationBias? = nil,
        includedPrimaryTypes: [String]? = nil,
        sessionToken: String? = nil,
        fieldMask: String = AutocompleteResponse.defaultFieldMask
    ) async throws -> AutocompleteResponse {
        let url = baseURL.appendingPathComponent("places:autocomplete")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        addCommonHeaders(&request, fieldMask: fieldMask)
        if let sessionToken { request.setValue(sessionToken, forHTTPHeaderField: "X-Goog-Maps-Platform-Request-Session-Token") }

        let body = AutocompleteRequest(
            input: input,
            locationBias: locationBias,
            includedPrimaryTypes: includedPrimaryTypes
        )
        request.httpBody = try encodeJSON(body)

        let data = try await data(for: request)
        return try decodeJSON(AutocompleteResponse.self, from: data)
    }

    // MARK: - Helpers

    private func addCommonHeaders(_ request: inout URLRequest, fieldMask: String) {
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        request.setValue(fieldMask, forHTTPHeaderField: "X-Goog-FieldMask")
    }

    private func data(for request: URLRequest) async throws -> Data {
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw ServiceError.emptyResponse }
            guard 200..<300 ~= http.statusCode else {
                let body = String(data: data, encoding: .utf8) ?? ""
                throw ServiceError.http(http.statusCode, body)
            }
            return data
        } catch let err as ServiceError {
            throw err
        } catch {
            throw ServiceError.unknown(error)
        }
    }

    private func encodeJSON<T: Encodable>(_ value: T) throws -> Data {
        do {
            let encoder = JSONEncoder()
            
            // Google Places v1 expects camelCase keys; use defaults
            return try encoder.encode(value)
        } catch {
            throw ServiceError.encoding(error)
        }
    }

    private func decodeJSON<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            let decoder = JSONDecoder()
            // Responses use camelCase; use defaults
            return try decoder.decode(T.self, from: data)
        } catch {
            throw ServiceError.decoding(error)
        }
    }
}

