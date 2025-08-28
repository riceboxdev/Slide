//
//  UserService.swift
//  Slide
//
//  Created by Nick Rogers on 7/29/25.
//


import Combine
import Contacts
import CoreLocation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import Foundation
import MapKit
import SwiftUI
import UserNotifications

// MARK: - User Service
@MainActor
class UserService: ObservableObject {
    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    // MARK: - Real-time User Profile Listener
    private var userProfileListener: ListenerRegistration?

    /// Start listening in real-time to user profile changes.
    /// - Parameters:
    ///   - userId: User ID to listen for
    ///   - onUpdate: Closure to be called with updated UserProfile, or nil if not found
    func startUserProfileListener(
        userId: String,
        onUpdate: @escaping (UserProfile?) -> Void
    ) {
        userProfileListener?.remove()
        userProfileListener = db.collection("users").document(userId)
            .addSnapshotListener { documentSnapshot, error in
                Task { @MainActor in
                    guard let document = documentSnapshot, document.exists
                    else {
                        onUpdate(nil)
                        return
                    }
                    let data = document.data()
                    do {
                        let profile = try document.data(as: UserProfile.self)
                        onUpdate(profile)
                    } catch {
                        print(
                            "Error decoding user profile in listener: \(error)"
                        )
                        onUpdate(nil)
                    }
                }
            }
    }

    func stopUserProfileListener() {
        userProfileListener?.remove()
        userProfileListener = nil
    }

    func createUserProfile(userId: String, profile: UserProfile) async throws {
        do {
            try db.collection("users").document(userId).setData(from: profile)
        } catch {
            throw UserServiceError.createProfileError(error.localizedDescription)
        }
    }

    func getUserProfile(userId: String) async throws -> UserProfile {
        print("🔵 [UserService] Getting user profile for userId: \(userId)")

        do {
            let document = try await db.collection("users").document(userId)
                .getDocument()

            if !document.exists {
                print(
                    "❌ [UserService] Document does not exist for userId: \(userId)"
                )
                throw UserServiceError.userNotFound
            }

            print("✅ [UserService] Document retrieved successfully")

            if let data = document.data() {
                print(
                    "🔍 [UserService] Document data keys: \(data.keys.joined(separator: ", "))"
                )
                print("🔍 [UserService] Document data: \(data)")

                // Log specific problematic fields
                if let activityHistory = data["activityHistory"]
                    as? [String: Any]
                {
                    print(
                        "🔍 [UserService] ActivityHistory keys: \(activityHistory.keys.joined(separator: ", "))"
                    )

                    if let favoriteVenues = activityHistory["favoriteVenues"] {
                        print(
                            "🔍 [UserService] favoriteVenues type: \(type(of: favoriteVenues)), value: \(favoriteVenues)"
                        )
                    }

                    if let savedVenues = activityHistory["savedVenues"] {
                        print(
                            "🔍 [UserService] savedVenues type: \(type(of: savedVenues)), value: \(savedVenues)"
                        )
                    }

                    if let recentSearches = activityHistory["recentSearches"] {
                        print(
                            "🔍 [UserService] recentSearches type: \(type(of: recentSearches)), value: \(recentSearches)"
                        )
                    }
                }

                if let socialInfo = data["socialInfo"] as? [String: Any] {
                    print(
                        "🔍 [UserService] SocialInfo keys: \(socialInfo.keys.joined(separator: ", "))"
                    )

                    if let friends = socialInfo["friends"] {
                        print(
                            "🔍 [UserService] friends type: \(type(of: friends)), value: \(friends)"
                        )
                    }

                    if let followers = socialInfo["followers"] {
                        print(
                            "🔍 [UserService] followers type: \(type(of: followers)), value: \(followers)"
                        )
                    }

                    if let following = socialInfo["following"] {
                        print(
                            "🔍 [UserService] following type: \(type(of: following)), value: \(following)"
                        )
                    }
                }

                if let locationSettings = data["locationSettings"]
                    as? [String: Any]
                {
                    print(
                        "🔍 [UserService] LocationSettings keys: \(locationSettings.keys.joined(separator: ", "))"
                    )

                    if let lastLocationUpdate = locationSettings[
                        "lastLocationUpdate"
                    ] {
                        print(
                            "🔍 [UserService] lastLocationUpdate type: \(type(of: lastLocationUpdate)), value: \(lastLocationUpdate)"
                        )
                    }
                }

                if let personalInfo = data["personalInfo"] as? [String: Any] {
                    print(
                        "🔍 [UserService] PersonalInfo keys: \(personalInfo.keys.joined(separator: ", "))"
                    )

                    if let accountCreated = personalInfo["accountCreated"] {
                        print(
                            "🔍 [UserService] accountCreated type: \(type(of: accountCreated)), value: \(accountCreated)"
                        )
                    }

                    if let lastLogin = personalInfo["lastLogin"] {
                        print(
                            "🔍 [UserService] lastLogin type: \(type(of: lastLogin)), value: \(lastLogin)"
                        )
                    }
                }
            }

            // Try Firestore's built-in Codable support first
            print("🔄 [UserService] Attempting Firestore built-in decoding...")

            do {
                let profile = try document.data(as: UserProfile.self)
                print("✅ [UserService] Firestore built-in decoding successful")
                return profile
            } catch {
                print(
                    "⚠️ [UserService] Firestore built-in decoding failed: \(error)"
                )
                print("⚠️ [UserService] Error type: \(type(of: error))")

                if let decodingError = error as? DecodingError {
                    print("⚠️ [UserService] Decoding error details:")
                    switch decodingError {
                    case .dataCorrupted(let context):
                        print("   - Data corrupted at: \(context.codingPath)")
                        print("   - Description: \(context.debugDescription)")
                    case .keyNotFound(let key, let context):
                        print("   - Key not found: \(key)")
                        print("   - Context: \(context.debugDescription)")
                        print("   - Coding path: \(context.codingPath)")
                    case .typeMismatch(let type, let context):
                        print("   - Type mismatch for: \(type)")
                        print("   - Context: \(context.debugDescription)")
                        print("   - Coding path: \(context.codingPath)")
                    case .valueNotFound(let type, let context):
                        print("   - Value not found for: \(type)")
                        print("   - Context: \(context.debugDescription)")
                        print("   - Coding path: \(context.codingPath)")
                    @unknown default:
                        print("   - Unknown decoding error")
                    }
                }

                // Fallback to manual decoding with error handling
                print("🔄 [UserService] Attempting manual decoding...")

                guard let data = document.data() else {
                    print("❌ [UserService] No document data available")
                    throw UserServiceError.userNotFound
                }

                return try decodeUserProfileManually(from: data)
            }

        } catch {
            print("❌ [UserService] Error getting user profile: \(error)")
            print("❌ [UserService] Error type: \(type(of: error))")
            throw error
        }
    }

    private func decodeUserProfileManually(from data: [String: Any]) throws -> UserProfile {
        print("🔄 [UserService] Starting manual decoding...")

        // Clean up the data before decoding
        var cleanedData = data

        print("🔍 [UserService] Original data keys: \(data.keys.joined(separator: ", "))")

        // Fix socialInfo array fields that might be single strings
        if let socialInfo = cleanedData["socialInfo"] as? [String: Any] {
            print("🔄 [UserService] Processing socialInfo...")
            var cleanedSocialInfo = socialInfo

            // Fix friends array
            if let friends = socialInfo["friends"] as? String {
                print("🔧 [UserService] Converting friends from String to Array: \(friends)")
                cleanedSocialInfo["friends"] = [friends]
            } else if let friends = socialInfo["friends"] as? [String] {
                print("✅ [UserService] friends is already an array with \(friends.count) items")
            } else {
                print("🔧 [UserService] friends is missing or nil, setting to empty array")
                cleanedSocialInfo["friends"] = [String]()
            }

            // Fix followers array
            if let followers = socialInfo["followers"] as? String {
                print("🔧 [UserService] Converting followers from String to Array: \(followers)")
                cleanedSocialInfo["followers"] = [followers]
            } else if let followers = socialInfo["followers"] as? [String] {
                print("✅ [UserService] followers is already an array with \(followers.count) items")
            } else {
                print("🔧 [UserService] followers is missing or nil, setting to empty array")
                cleanedSocialInfo["followers"] = [String]()
            }

            // Fix following array
            if let following = socialInfo["following"] as? String {
                print("🔧 [UserService] Converting following from String to Array: \(following)")
                cleanedSocialInfo["following"] = [following]
            } else if let following = socialInfo["following"] as? [String] {
                print("✅ [UserService] following is already an array with \(following.count) items")
            } else {
                print("🔧 [UserService] following is missing or nil, setting to empty array")
                cleanedSocialInfo["following"] = [String]()
            }

            // Fix blockedUsers array
            if let blockedUsers = socialInfo["blockedUsers"] as? String {
                print("🔧 [UserService] Converting blockedUsers from String to Array: \(blockedUsers)")
                cleanedSocialInfo["blockedUsers"] = [blockedUsers]
            } else if let blockedUsers = socialInfo["blockedUsers"] as? [String] {
                print("✅ [UserService] blockedUsers is already an array with \(blockedUsers.count) items")
            } else {
                print("🔧 [UserService] blockedUsers is missing or nil, setting to empty array")
                cleanedSocialInfo["blockedUsers"] = [String]()
            }

            // Fix socialMediaLinks array
            if let socialMediaLinks = socialInfo["socialMediaLinks"] as? [String: Any] {
                print("🔧 [UserService] Converting socialMediaLinks from Dictionary to Array")
                cleanedSocialInfo["socialMediaLinks"] = [socialMediaLinks]
            } else if let socialMediaLinks = socialInfo["socialMediaLinks"] as? [[String: Any]] {
                print("✅ [UserService] socialMediaLinks is already an array with \(socialMediaLinks.count) items")
            } else {
                print("🔧 [UserService] socialMediaLinks is missing or nil, setting to empty array")
                cleanedSocialInfo["socialMediaLinks"] = [[String: Any]]()
            }

            cleanedData["socialInfo"] = cleanedSocialInfo
            print("✅ [UserService] SocialInfo processing complete")
        } else {
            print("⚠️ [UserService] No socialInfo found in document")
        }

        // Fix locationSettings array fields that might be single objects or strings
        if let locationSettings = cleanedData["locationSettings"] as? [String: Any] {
            print("🔄 [UserService] Processing locationSettings...")
            var cleanedLocationSettings = locationSettings

            // Fix frequentLocations array
            if let frequentLocations = locationSettings["frequentLocations"] as? [String: Any] {
                print("🔧 [UserService] Converting frequentLocations from Dictionary to Array")
                cleanedLocationSettings["frequentLocations"] = [frequentLocations]
            } else if let frequentLocations = locationSettings["frequentLocations"] as? [[String: Any]] {
                print("✅ [UserService] frequentLocations is already an array with \(frequentLocations.count) items")
            } else {
                print("🔧 [UserService] frequentLocations is missing or nil, setting to empty array")
                cleanedLocationSettings["frequentLocations"] = [[String: Any]]()
            }

            // Fix locationHistory array
            if let locationHistory = locationSettings["locationHistory"] as? [String: Any] {
                print("🔧 [UserService] Converting locationHistory from Dictionary to Array")
                cleanedLocationSettings["locationHistory"] = [locationHistory]
            } else if let locationHistory = locationSettings["locationHistory"] as? [[String: Any]] {
                print("✅ [UserService] locationHistory is already an array with \(locationHistory.count) items")
            } else {
                print("🔧 [UserService] locationHistory is missing or nil, setting to empty array")
                cleanedLocationSettings["locationHistory"] = [[String: Any]]()
            }

            cleanedData["locationSettings"] = cleanedLocationSettings
            print("✅ [UserService] LocationSettings processing complete")
        } else {
            print("⚠️ [UserService] No locationSettings found in document")
        }

        // Convert FIRTimestamp objects to ISO8601 strings before JSON serialization
        print("🔄 [UserService] Converting FIRTimestamp objects to strings...")
        if let converted = convertFirestoreTimestamps(cleanedData) as? [String: Any] {
            cleanedData = converted
        } else {
            print("❌ [UserService] Failed to convert Firestore Timestamps")
        }
        
        // Fix coordinate string/double conversion
        print("🔄 [UserService] Converting coordinate strings to doubles...")
        cleanedData = convertCoordinateStringsToDoubles(cleanedData)

        print("🔄 [UserService] Converting cleaned data to JSON...")

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: cleanedData)
            print("✅ [UserService] JSON serialization successful, data size: \(jsonData.count) bytes")

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            print("🔄 [UserService] Attempting to decode UserProfile...")

            let profile = try decoder.decode(UserProfile.self, from: jsonData)
            print("✅ [UserService] Manual decoding successful!")

            return profile

        } catch {
            print("❌ [UserService] Manual decoding failed: \(error)")
            print("❌ [UserService] Error type: \(type(of: error))")

            if let decodingError = error as? DecodingError {
                print("❌ [UserService] Manual decoding error details:")
                switch decodingError {
                case .dataCorrupted(let context):
                    print("   - Data corrupted at: \(context.codingPath)")
                    print("   - Description: \(context.debugDescription)")
                case .keyNotFound(let key, let context):
                    print("   - Key not found: \(key)")
                    print("   - Context: \(context.debugDescription)")
                    print("   - Coding path: \(context.codingPath)")
                case .typeMismatch(let type, let context):
                    print("   - Type mismatch for: \(type)")
                    print("   - Context: \(context.debugDescription)")
                    print("   - Coding path: \(context.codingPath)")
                case .valueNotFound(let type, let context):
                    print("   - Value not found for: \(type)")
                    print("   - Context: \(context.debugDescription)")
                    print("   - Coding path: \(context.codingPath)")
                @unknown default:
                    print("   - Unknown decoding error")
                }
            }

            // If we still can't decode, let's try to identify the specific problematic field
            print("🔍 [UserService] Attempting to identify problematic field...")

            // Try to decode each major section individually
            if let personalInfo = cleanedData["personalInfo"] as? [String: Any] {
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let personalInfoData = try JSONSerialization.data(withJSONObject: personalInfo)
                    let _ = try decoder.decode(PersonalInfo.self, from: personalInfoData)
                    print("✅ [UserService] PersonalInfo decodes successfully")
                } catch {
                    print("❌ [UserService] PersonalInfo decoding failed: \(error)")
                }
            }

            if let locationSettings = cleanedData["locationSettings"] as? [String: Any] {
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let locationData = try JSONSerialization.data(withJSONObject: locationSettings)
                    let _ = try decoder.decode(LocationSettings.self, from: locationData)
                    print("✅ [UserService] LocationSettings decodes successfully")
                } catch {
                    print("❌ [UserService] LocationSettings decoding failed: \(error)")
                }
            }

            if let socialInfo = cleanedData["socialInfo"] as? [String: Any] {
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let socialData = try JSONSerialization.data(withJSONObject: socialInfo)
                    let _ = try decoder.decode(SocialInfo.self, from: socialData)
                    print("✅ [UserService] SocialInfo decodes successfully")
                } catch {
                    print("❌ [UserService] SocialInfo decoding failed: \(error)")
                }
            }

            throw error
        }
    }

    // MARK: - Helper Functions for Manual Decoding

    /// Recursively converts Firestore Timestamp objects to ISO8601 strings
    private func convertFirestoreTimestamps(_ data: Any) -> Any {
        if let timestamp = data as? Timestamp {
            // Convert FIRTimestamp to ISO8601 string
            return ISO8601DateFormatter().string(from: timestamp.dateValue())
        } else if let dictionary = data as? [String: Any] {
            // Recursively process dictionary values
            var converted = [String: Any]()
            for (key, value) in dictionary {
                converted[key] = convertFirestoreTimestamps(value)
            }
            return converted
        } else if let array = data as? [Any] {
            // Recursively process array elements
            return array.map { convertFirestoreTimestamps($0) }
        } else {
            // Return unchanged for all other types
            return data
        }
    }

    /// Converts string coordinates to doubles in location data
    private func convertCoordinateStringsToDoubles(_ data: [String: Any]) -> [String: Any] {
        var cleanedData = data
        
        // Handle locationSettings coordinates
        if var locationSettings = cleanedData["locationSettings"] as? [String: Any] {
            
            // Convert currentLocation coordinates
            if var currentLocation = locationSettings["currentLocation"] as? [String: Any] {
                if let latitudeString = currentLocation["latitude"] as? String,
                   let latitude = Double(latitudeString) {
                    currentLocation["latitude"] = latitude
                    print("🔧 [UserService] Converted currentLocation latitude from String to Double: \(latitude)")
                }
                if let longitudeString = currentLocation["longitude"] as? String,
                   let longitude = Double(longitudeString) {
                    currentLocation["longitude"] = longitude
                    print("🔧 [UserService] Converted currentLocation longitude from String to Double: \(longitude)")
                }
                locationSettings["currentLocation"] = currentLocation
            }
            
            // Convert homeLocation coordinates if present
            if var homeLocation = locationSettings["homeLocation"] as? [String: Any] {
                if let latitudeString = homeLocation["latitude"] as? String,
                   let latitude = Double(latitudeString) {
                    homeLocation["latitude"] = latitude
                }
                if let longitudeString = homeLocation["longitude"] as? String,
                   let longitude = Double(longitudeString) {
                    homeLocation["longitude"] = longitude
                }
                locationSettings["homeLocation"] = homeLocation
            }
            
            // Convert workLocation coordinates if present
            if var workLocation = locationSettings["workLocation"] as? [String: Any] {
                if let latitudeString = workLocation["latitude"] as? String,
                   let latitude = Double(latitudeString) {
                    workLocation["latitude"] = latitude
                }
                if let longitudeString = workLocation["longitude"] as? String,
                   let longitude = Double(longitudeString) {
                    workLocation["longitude"] = longitude
                }
                locationSettings["workLocation"] = workLocation
            }
            
            // Convert frequentLocations coordinates
            if let frequentLocations = locationSettings["frequentLocations"] as? [[String: Any]] {
                let convertedFrequentLocations = frequentLocations.map { location -> [String: Any] in
                    var convertedLocation = location
                    if let latitudeString = location["latitude"] as? String,
                       let latitude = Double(latitudeString) {
                        convertedLocation["latitude"] = latitude
                    }
                    if let longitudeString = location["longitude"] as? String,
                       let longitude = Double(longitudeString) {
                        convertedLocation["longitude"] = longitude
                    }
                    return convertedLocation
                }
                locationSettings["frequentLocations"] = convertedFrequentLocations
            }
            
            // Convert locationHistory coordinates
            if let locationHistory = locationSettings["locationHistory"] as? [[String: Any]] {
                let convertedLocationHistory = locationHistory.map { entry -> [String: Any] in
                    var convertedEntry = entry
                    if var location = entry["location"] as? [String: Any] {
                        if let latitudeString = location["latitude"] as? String,
                           let latitude = Double(latitudeString) {
                            location["latitude"] = latitude
                        }
                        if let longitudeString = location["longitude"] as? String,
                           let longitude = Double(longitudeString) {
                            location["longitude"] = longitude
                        }
                        convertedEntry["location"] = location
                    }
                    return convertedEntry
                }
                locationSettings["locationHistory"] = convertedLocationHistory
            }
            
            cleanedData["locationSettings"] = locationSettings
            print("✅ [UserService] Coordinate conversion complete")
        }
        
        return cleanedData
    }

    func updateUserProfile(_ profile: UserProfile) async throws {
        print("🔵 [UserService] Updating user profile...")

        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ [UserService] User not authenticated")
            throw UserServiceError.notAuthenticated
        }

        print("🔍 [UserService] Updating profile for userId: \(userId)")

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(profile)

            print(
                "✅ [UserService] Profile encoded successfully for update, data size: \(data.count) bytes"
            )

            let dictionary =
                try JSONSerialization.jsonObject(with: data) as? [String: Any]
                ?? [:]

            print(
                "✅ [UserService] Dictionary created with \(dictionary.keys.count) keys for update"
            )

            try await db.collection("users").document(userId).updateData(
                dictionary
            )

            print(
                "✅ [UserService] User profile updated successfully in Firestore"
            )

        } catch {
            print("❌ [UserService] Error updating user profile: \(error)")
            print("❌ [UserService] Error type: \(type(of: error))")
            throw error
        }
    }

    func updateUserLocation(_ location: CLLocation) async {
        print("🔵 [UserService] Updating user location...")

        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ [UserService] User not authenticated for location update")
            return
        }

        print("🔍 [UserService] Updating location for userId: \(userId)")
        print(
            "🔍 [UserService] Location: lat=\(location.coordinate.latitude), lng=\(location.coordinate.longitude)"
        )

        let locationData: [String: Any] = [
            "locationSettings.currentLocation": [
                "latitude": location.coordinate.latitude,
                "longitude": location.coordinate.longitude,
                "timestamp": ISO8601DateFormatter().string(from: Date()),
            ],
            "locationSettings.lastLocationUpdate": ISO8601DateFormatter()
                .string(from: Date()),
        ]

        print("🔍 [UserService] Location data prepared: \(locationData)")

        do {
            try await db.collection("users").document(userId).updateData(
                locationData
            )
            print("✅ [UserService] User location updated successfully")
        } catch {
            print("❌ [UserService] Error updating user location: \(error)")
            print("❌ [UserService] Error type: \(type(of: error))")
        }
    }
}

// MARK: - User Service Error Types
enum UserServiceError: Error, LocalizedError {
    case userNotFound
    case notAuthenticated
    case decodingError(String)
    case encodingError(String)
    case networkError(String)
    case createProfileError(String)
    

    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User profile not found"
        case .notAuthenticated:
            return "User not authenticated"
        case .decodingError(let message):
            return "Failed to decode user data: \(message)"
        case .encodingError(let message):
            return "Failed to encode user data: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .createProfileError(_):
            return "Failed to create user profile"
        }
    }
}

