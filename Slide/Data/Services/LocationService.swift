//
//  LocationService.swift
//  Slide
//
//  Created by Nick Rogers on 7/29/25.
//


import Combine
import Contacts
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import Foundation
import MapKit
import SwiftUI
import UserNotifications

// MARK: - Location Service
@MainActor
class LocationService: NSObject, ObservableObject {
    @Published var isLocationEnabled = false
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var error: LocationError?

    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var cancellables = Set<AnyCancellable>()

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 50  // Update every 50 meters
    }

    func initialize() async {
        authorizationStatus = locationManager.authorizationStatus
        updateLocationEnabled()
    }

    func requestLocationPermission() {
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            error = LocationError.permissionDenied
        case .authorizedWhenInUse:
            locationManager.requestAlwaysAuthorization()
        case .authorizedAlways:
            startLocationUpdates()
        @unknown default:
            break
        }
    }

    private func startLocationUpdates() {
        guard isLocationEnabled else { return }
        locationManager.startUpdatingLocation()
        locationManager.startMonitoringSignificantLocationChanges()
    }

    private func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        locationManager.stopMonitoringSignificantLocationChanges()
    }

    private func updateLocationEnabled() {
        let newStatus =
            authorizationStatus == .authorizedWhenInUse
            || authorizationStatus == .authorizedAlways

        if newStatus != isLocationEnabled {
            isLocationEnabled = newStatus

            if isLocationEnabled {
                startLocationUpdates()
            } else {
                stopLocationUpdates()
            }
        }
    }

    func getCurrentLocation() async throws -> CLLocation {
        return try await withCheckedThrowingContinuation { continuation in
            locationManager.requestLocation()

            // Store continuation for completion
            // This is a simplified version - in production, you'd want better error handling
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                if let location = self.currentLocation {
                    continuation.resume(returning: location)
                } else {
                    continuation.resume(
                        throwing: LocationError.locationNotAvailable
                    )
                }
            }
        }
    }

    // **MARK: - Distance Calculation**

    /// Calculate distance between user's current location and a target coordinate
    /// - Parameters:
    ///   - coordinate: Target coordinate to measure distance to
    ///   - useCurrentLocation: If true, uses current location; if false, requests fresh location
    /// - Returns: Distance in meters
    func distanceToCoordinate(
        _ coordinate: CLLocationCoordinate2D,
        useCurrentLocation: Bool = true
    ) async throws -> CLLocationDistance {
        let userLocation: CLLocation

        if useCurrentLocation, let current = currentLocation {
            userLocation = current
        } else {
            userLocation = try await getCurrentLocation()
        }

        let targetLocation = CLLocation(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        return userLocation.distance(from: targetLocation)
    }

    /// Calculate distance between user's current location and a target location
    /// - Parameters:
    ///   - location: Target location to measure distance to
    ///   - useCurrentLocation: If true, uses current location; if false, requests fresh location
    /// - Returns: Distance in meters
    func distanceToLocation(
        _ location: CLLocation,
        useCurrentLocation: Bool = true
    ) async throws -> CLLocationDistance {
        let userLocation: CLLocation

        if useCurrentLocation, let current = currentLocation {
            userLocation = current
        } else {
            userLocation = try await getCurrentLocation()
        }

        return userLocation.distance(from: location)
    }

    /// Get formatted distance string with appropriate units
    /// - Parameter distance: Distance in meters
    /// - Returns: Formatted string (e.g., "1.2 km", "350 m")
    func formatDistance(_ distance: CLLocationDistance) -> String {
        let formatter = MKDistanceFormatter()
        formatter.unitStyle = .abbreviated
        return formatter.string(fromDistance: distance)
    }

    // **MARK: - Reverse Geocoding**

    /// Convert coordinates to address
    /// - Parameter coordinate: Coordinate to reverse geocode
    /// - Returns: Array of placemarks containing address information
    func reverseGeocodeCoordinate(_ coordinate: CLLocationCoordinate2D)
        async throws -> [CLPlacemark]
    {
        let location = CLLocation(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        return try await reverseGeocodeLocation(location)
    }

    /// Convert location to address
    /// - Parameter location: Location to reverse geocode
    /// - Returns: Array of placemarks containing address information
    func reverseGeocodeLocation(_ location: CLLocation) async throws
        -> [CLPlacemark]
    {
        return try await withCheckedThrowingContinuation { continuation in
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                if let error = error {
                    continuation.resume(
                        throwing: LocationError.geocodingFailed(
                            error.localizedDescription
                        )
                    )
                } else if let placemarks = placemarks {
                    continuation.resume(returning: placemarks)
                } else {
                    continuation.resume(
                        throwing: LocationError.geocodingFailed(
                            "No results found"
                        )
                    )
                }
            }
        }
    }

    /// Get formatted address string from placemark
    /// - Parameter placemark: Placemark to format
    /// - Returns: Formatted address string
    func formatAddress(from placemark: CLPlacemark) -> String {
        let formatter = CNPostalAddressFormatter()
        if let postalAddress = placemark.postalAddress {
            return formatter.string(from: postalAddress)
        } else {
            // Fallback formatting
            var components: [String] = []

            if let name = placemark.name {
                components.append(name)
            }
            if let thoroughfare = placemark.thoroughfare {
                components.append(thoroughfare)
            }
            if let locality = placemark.locality {
                components.append(locality)
            }
            if let administrativeArea = placemark.administrativeArea {
                components.append(administrativeArea)
            }
            if let postalCode = placemark.postalCode {
                components.append(postalCode)
            }
            if let country = placemark.country {
                components.append(country)
            }

            return components.joined(separator: ", ")
        }
    }

    // **MARK: - Address Autocompletion**

    /// Search for address completions based on partial input
    /// - Parameters:
    ///   - query: Partial address or location name
    ///   - region: Optional region to bias results (uses current location if available)
    ///   - resultTypes: Types of results to return (default: address)
    /// - Returns: Array of completion results
    func searchAddressCompletions(
        for query: String,
        in region: CLCircularRegion? = nil,
        resultTypes: MKLocalSearchCompleter.ResultType = [.address]
    ) async throws -> [MKLocalSearchCompletion] {
        let completer = MKLocalSearchCompleter()
        completer.resultTypes = resultTypes

        // Set region bias
        if let region = region {
            completer.region = MKCoordinateRegion(
                center: region.center,
                latitudinalMeters: region.radius * 2,
                longitudinalMeters: region.radius * 2
            )
        } else if let currentLocation = currentLocation {
            completer.region = MKCoordinateRegion(
                center: currentLocation.coordinate,
                latitudinalMeters: 10000,
                longitudinalMeters: 10000
            )
        }

        return try await withCheckedThrowingContinuation { continuation in
            class ContinuationBox {
                var resumed = false
                let continuation:
                    CheckedContinuation<[MKLocalSearchCompletion], Error>
                init(
                    _ continuation: CheckedContinuation<
                        [MKLocalSearchCompletion], Error
                    >
                ) { self.continuation = continuation }
                func resume(with value: [MKLocalSearchCompletion]) {
                    guard !resumed else { return }
                    resumed = true
                    continuation.resume(returning: value)
                }
                func resume(throwing error: Error) {
                    guard !resumed else { return }
                    resumed = true
                    continuation.resume(throwing: error)
                }
            }
            let box = ContinuationBox(continuation)
            let delegate = SearchCompleterDelegate { results, error in
                if let error = error {
                    box.resume(
                        throwing: LocationError.searchFailed(
                            error.localizedDescription
                        )
                    )
                } else {
                    box.resume(with: results)
                }
            }
            completer.delegate = delegate
            completer.queryFragment = query
            // Timeout after 5 seconds if nothing returned
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                box.resume(with: [])
            }
        }
    }

    /// Get detailed location information from a search completion
    /// - Parameter completion: Search completion to get details for
    /// - Returns: Array of map items with detailed location information
    func getLocationDetails(for completion: MKLocalSearchCompletion)
        async throws -> [MKMapItem]
    {
        let searchRequest = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: searchRequest)

        return try await withCheckedThrowingContinuation { continuation in
            search.start { response, error in
                if let error = error {
                    continuation.resume(
                        throwing: LocationError.searchFailed(
                            error.localizedDescription
                        )
                    )
                } else if let response = response {
                    continuation.resume(returning: response.mapItems)
                } else {
                    continuation.resume(returning: [])
                }
            }
        }
    }

    /// Simple text-based location search
    /// - Parameters:
    ///   - query: Search query
    ///   - region: Optional region to bias results
    /// - Returns: Array of map items matching the query
    func searchLocations(
        for query: String,
        in region: MKCoordinateRegion? = nil
    ) async throws -> [MKMapItem] {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = query

        if let region = region {
            searchRequest.region = region
        } else if let currentLocation = currentLocation {
            searchRequest.region = MKCoordinateRegion(
                center: currentLocation.coordinate,
                latitudinalMeters: 10000,
                longitudinalMeters: 10000
            )
        }

        let search = MKLocalSearch(request: searchRequest)

        return try await withCheckedThrowingContinuation { continuation in
            search.start { response, error in
                if let error = error {
                    continuation.resume(
                        throwing: LocationError.searchFailed(
                            error.localizedDescription
                        )
                    )
                } else if let response = response {
                    continuation.resume(returning: response.mapItems)
                } else {
                    continuation.resume(returning: [])
                }
            }
        }
    }
}

// **MARK: - Location Manager Delegate**
extension LocationService: CLLocationManagerDelegate {
    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let location = locations.last else { return }
        currentLocation = location
    }

    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        self.error = LocationError.locationUpdateFailed(
            error.localizedDescription
        )
    }

    func locationManager(
        _ manager: CLLocationManager,
        didChangeAuthorization status: CLAuthorizationStatus
    ) {
        authorizationStatus = status
        updateLocationEnabled()
    }
}

// **MARK: - Search Completer Delegate**
private class SearchCompleterDelegate: NSObject, MKLocalSearchCompleterDelegate
{
    private let completion: ([MKLocalSearchCompletion], Error?) -> Void

    init(completion: @escaping ([MKLocalSearchCompletion], Error?) -> Void) {
        self.completion = completion
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        completion(completer.results, nil)
    }

    func completer(
        _ completer: MKLocalSearchCompleter,
        didFailWithError error: Error
    ) {
        completion([], error)
    }
}

// MARK: - LocationError
enum LocationError: LocalizedError {
    case permissionDenied
    case locationNotAvailable
    case locationUpdateFailed(String)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Location permission denied"
        case .locationNotAvailable:
            return "Location not available"
        case .locationUpdateFailed(let message):
            return "Location update failed: \(message)"
        }
    }
}

extension LocationError {
    static func geocodingFailed(_ message: String) -> LocationError {
        // Add to your existing LocationError enum
        return .locationUpdateFailed("Geocoding failed: \(message)")
    }

    static func searchFailed(_ message: String) -> LocationError {
        // Add to your existing LocationError enum
        return .locationUpdateFailed("Search failed: \(message)")
    }
}
