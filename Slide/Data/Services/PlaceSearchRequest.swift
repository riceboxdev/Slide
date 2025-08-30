//
//  PlaceSearchRequest.swift
//  Slide
//
//  Created by Nick Rogers on 8/28/25.
//



import SwiftUI
import CoreLocation
import Foundation
import Combine
import MapKit

// MARK: - Models
struct PlaceSearchRequest: Codable {
    let includedTypes: [String]?
    let excludedTypes: [String]?
    let maxResultCount: Int
    let locationRestriction: LocationRestriction
    let rankPreference: String?
    let languageCode: String?
    
    struct LocationRestriction: Codable {
        let circle: Circle
        
        struct Circle: Codable {
            let center: Center
            let radius: Double
            
            struct Center: Codable {
                let latitude: Double
                let longitude: Double
            }
        }
    }
}

struct PlaceSearchResponse: Codable {
    let places: [Place]
}

class PlacesAPIService: ObservableObject {
    private let apiKey: String
    private let baseURL = "https://places.googleapis.com/v1/places:searchNearby"
    
    @Published var places: [Place] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
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
        
        guard let url = URL(string: baseURL) else {
            throw URLError(.badURL)
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        urlRequest.setValue(fieldMask, forHTTPHeaderField: "X-Goog-FieldMask")
        
        let jsonData = try JSONEncoder().encode(request)
        urlRequest.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            let body = String(data: data, encoding: .utf8) ?? ""
            throw NSError(domain: "PlacesAPI", code: status, userInfo: [NSLocalizedDescriptionKey: "API error: Status code \(status) - \(body)"])
        }
        let responseObj = try JSONDecoder().decode(PlaceSearchResponse.self, from: data)
        return responseObj.places
    }
}

// MARK: - Location Manager
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    private let locationManager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocation() {
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.first
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.requestLocation()
        }
    }
    
    /// Returns the formatted distance from the user's location to the given LatLng, or nil if unavailable
    func formattedDistance(from latLng: LatLng) -> String? {
        guard let userLocation = location,
              let lat = latLng.latitude,
              let lng = latLng.longitude else { return nil }
        let targetLocation = CLLocation(latitude: lat, longitude: lng)
        let distance = userLocation.distance(from: targetLocation)
        let formatter = MKDistanceFormatter()
        formatter.unitStyle = .abbreviated
        return formatter.string(fromDistance: distance)
    }
}
