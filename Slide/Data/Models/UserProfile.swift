//
//  UserProfile.swift
//  Slide
//
//  Created by Nick Rogers on 7/29/25.
//


import CoreLocation
import FirebaseCore
import Foundation
import SwiftUI

// MARK: - User Profile Model
struct UserProfile: Codable, Identifiable, Equatable {
    var id: String
    var username: String
    var personalInfo: PersonalInfo
    var locationSettings: LocationSettings
    var socialInfo: SocialInfo
    var type: UserType?

    // Computed properties
    var displayName: String {
        return personalInfo.displayName ?? personalInfo.firstName
    }

    var isLocationEnabled: Bool {
        return locationSettings.isLocationTrackingEnabled
    }
}

enum UserType: Codable, CaseIterable, Equatable {
    case defaultUser
    case businessOwner
    case businessStaff
    case admin
}

struct PersonalInfo: Codable, Equatable {
    var firstName: String
    var lastName: String?
    var displayName: String?
    
    var email: String
    var phoneNumber: String?
    var dateOfBirth: Date?
    
    var countryOfResidence: String?
    
    var profileImageURL: String?

    var bio: String?

    // Account info
    var accountCreated: Date
    var lastLogin: Date?
    var isEmailVerified: Bool
    var isPhoneVerified: Bool
    var isOnboardingComplete: Bool
    var enableNotifications: Bool

    // Standard initializer
    init(
        firstName: String,
        lastName: String? = nil,
        displayName: String? = nil,
        email: String,
        phoneNumber: String? = nil,
        profileImageURL: String? = nil,
        dateOfBirth: Date? = nil,
        bio: String? = nil,
    
        accountCreated: Date = Date(),
        lastLogin: Date? = nil,
        isEmailVerified: Bool = false,
        isPhoneVerified: Bool = false,
        isOnboardingComplete: Bool = false,
        enableNotifications: Bool
    ) {
        self.firstName = firstName
        self.lastName = lastName
        self.displayName = displayName
        self.email = email
        self.phoneNumber = phoneNumber
        self.profileImageURL = profileImageURL
        self.dateOfBirth = dateOfBirth
        self.bio = bio
      
        self.accountCreated = accountCreated
        self.lastLogin = lastLogin
        self.isEmailVerified = isEmailVerified
        self.isPhoneVerified = isPhoneVerified
        self.isOnboardingComplete = isOnboardingComplete
        self.enableNotifications = enableNotifications
    }

    enum CodingKeys: String, CodingKey {
        case firstName
        case lastName
        case displayName
        case email
        case phoneNumber
        case profileImageURL
        case dateOfBirth
        case bio
        case interests
        case accountCreated
        case lastLogin
        case isEmailVerified
        case isPhoneVerified
        case isOnboardingComplete
        case enableNotifications
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Decode standard fields
        firstName = try container.decode(String.self, forKey: .firstName)
        lastName = try container.decodeIfPresent(String.self, forKey: .lastName)
        displayName = try container.decodeIfPresent(
            String.self,
            forKey: .displayName
        )
        email = try container.decode(String.self, forKey: .email)
        phoneNumber = try container.decodeIfPresent(
            String.self,
            forKey: .phoneNumber
        )
        profileImageURL = try container.decodeIfPresent(
            String.self,
            forKey: .profileImageURL
        )
        isEmailVerified = try container.decode(
            Bool.self,
            forKey: .isEmailVerified
        )
        isPhoneVerified = try container.decode(
            Bool.self,
            forKey: .isPhoneVerified
        )
        isOnboardingComplete = try container.decode(
            Bool.self,
            forKey: .isOnboardingComplete
        )
        
        enableNotifications = try container.decodeIfPresent(
            Bool.self,
            forKey: .enableNotifications
        ) ?? false
        
        bio = try container.decodeIfPresent(String.self, forKey: .bio)
      

        // Custom decoding for dates
        // Handle dateOfBirth
        if let dateOfBirthTimestamp = try? container.decodeIfPresent(
            Timestamp.self,
            forKey: .dateOfBirth
        ) {
            dateOfBirth = dateOfBirthTimestamp.dateValue()
        } else if let dateOfBirthString = try? container.decodeIfPresent(
            String.self,
            forKey: .dateOfBirth
        ) {
            dateOfBirth = ISO8601DateFormatter().date(from: dateOfBirthString)
        } else {
            dateOfBirth = nil
        }

        // Handle accountCreated
        if let accountCreatedTimestamp = try? container.decode(
            Timestamp.self,
            forKey: .accountCreated
        ) {
            accountCreated = accountCreatedTimestamp.dateValue()
        } else if let accountCreatedString = try? container.decode(
            String.self,
            forKey: .accountCreated
        ) {
            accountCreated =
                ISO8601DateFormatter().date(from: accountCreatedString)
                ?? Date()
        } else {
            throw DecodingError.dataCorruptedError(
                forKey: .accountCreated,
                in: container,
                debugDescription:
                    "accountCreated must be a Firestore Timestamp or ISO 8601 string"
            )
        }

        // Handle lastLogin
        if let lastLoginTimestamp = try? container.decodeIfPresent(
            Timestamp.self,
            forKey: .lastLogin
        ) {
            lastLogin = lastLoginTimestamp.dateValue()
        } else if let lastLoginString = try? container.decodeIfPresent(
            String.self,
            forKey: .lastLogin
        ) {
            lastLogin = ISO8601DateFormatter().date(from: lastLoginString)
        } else {
            lastLogin = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(firstName, forKey: .firstName)
        try container.encodeIfPresent(lastName, forKey: .lastName)
        try container.encodeIfPresent(displayName, forKey: .displayName)
        try container.encode(email, forKey: .email)
        try container.encodeIfPresent(phoneNumber, forKey: .phoneNumber)
        try container.encodeIfPresent(profileImageURL, forKey: .profileImageURL)
        try container.encode(isEmailVerified, forKey: .isEmailVerified)
        try container.encode(isPhoneVerified, forKey: .isPhoneVerified)
        try container.encode(isOnboardingComplete, forKey: .isOnboardingComplete)
        try container.encodeIfPresent(bio, forKey: .bio)
   
        try container.encode(enableNotifications, forKey: .enableNotifications)

        // Encode dates as Firestore Timestamps
        try container.encodeIfPresent(
            dateOfBirth.map { Timestamp(date: $0) },
            forKey: .dateOfBirth
        )
        try container.encode(
            Timestamp(date: accountCreated),
            forKey: .accountCreated
        )
        try container.encodeIfPresent(
            lastLogin.map { Timestamp(date: $0) },
            forKey: .lastLogin
        )
    }
}


// MARK: - LocationSettings (modified to handle string-based coordinates)
struct LocationSettings: Codable, Equatable {
    var isLocationTrackingEnabled: Bool
    var allowBackgroundLocationUpdates: Bool
    var proximityRadius: Double
    var currentLocation: LocationCoordinate?
    var homeLocation: LocationCoordinate?
    var workLocation: LocationCoordinate?
    var frequentLocations: [LocationCoordinate]
    var locationHistory: [LocationHistoryEntry]
    var lastLocationUpdate: Date?

    enum CodingKeys: String, CodingKey {
        case isLocationTrackingEnabled
        case allowBackgroundLocationUpdates
        case proximityRadius
        case currentLocation
        case homeLocation
        case workLocation
        case frequentLocations
        case locationHistory
        case lastLocationUpdate
    }

    init(
        isLocationTrackingEnabled: Bool = false,
        allowBackgroundLocationUpdates: Bool = false,
        proximityRadius: Double = 500.0,
        currentLocation: LocationCoordinate? = nil,
        homeLocation: LocationCoordinate? = nil,
        workLocation: LocationCoordinate? = nil,
        frequentLocations: [LocationCoordinate] = [],
        locationHistory: [LocationHistoryEntry] = [],
        lastLocationUpdate: Date? = nil
    ) {
        self.isLocationTrackingEnabled = isLocationTrackingEnabled
        self.allowBackgroundLocationUpdates = allowBackgroundLocationUpdates
        self.proximityRadius = proximityRadius
        self.currentLocation = currentLocation
        self.homeLocation = homeLocation
        self.workLocation = workLocation
        self.frequentLocations = frequentLocations
        self.locationHistory = locationHistory
        self.lastLocationUpdate = lastLocationUpdate
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        isLocationTrackingEnabled = try container.decode(
            Bool.self,
            forKey: .isLocationTrackingEnabled
        )
        allowBackgroundLocationUpdates = try container.decode(
            Bool.self,
            forKey: .allowBackgroundLocationUpdates
        )
        proximityRadius = try container.decode(
            Double.self,
            forKey: .proximityRadius
        )
        currentLocation = try container.decodeIfPresent(
            LocationCoordinate.self,
            forKey: .currentLocation
        )
        homeLocation = try container.decodeIfPresent(
            LocationCoordinate.self,
            forKey: .homeLocation
        )
        workLocation = try container.decodeIfPresent(
            LocationCoordinate.self,
            forKey: .workLocation
        )
        frequentLocations =
            try container.decodeIfPresent(
                [LocationCoordinate].self,
                forKey: .frequentLocations
            ) ?? []
        locationHistory =
            try container.decodeIfPresent(
                [LocationHistoryEntry].self,
                forKey: .locationHistory
            ) ?? []

        if let lastLocationUpdateTimestamp = try? container.decodeIfPresent(
            Timestamp.self,
            forKey: .lastLocationUpdate
        ) {
            lastLocationUpdate = lastLocationUpdateTimestamp.dateValue()
        } else if let lastLocationUpdateString = try? container.decodeIfPresent(
            String.self,
            forKey: .lastLocationUpdate
        ) {
            lastLocationUpdate = ISO8601DateFormatter().date(
                from: lastLocationUpdateString
            )
        } else {
            lastLocationUpdate = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(
            isLocationTrackingEnabled,
            forKey: .isLocationTrackingEnabled
        )
        try container.encode(
            allowBackgroundLocationUpdates,
            forKey: .allowBackgroundLocationUpdates
        )
        try container.encode(proximityRadius, forKey: .proximityRadius)
        try container.encodeIfPresent(currentLocation, forKey: .currentLocation)
        try container.encodeIfPresent(homeLocation, forKey: .homeLocation)
        try container.encodeIfPresent(workLocation, forKey: .workLocation)
        try container.encode(frequentLocations, forKey: .frequentLocations)
        try container.encode(locationHistory, forKey: .locationHistory)
        try container.encodeIfPresent(
            lastLocationUpdate.map { Timestamp(date: $0) },
            forKey: .lastLocationUpdate
        )
    }

    static func == (lhs: LocationSettings, rhs: LocationSettings) -> Bool {
        return lhs.isLocationTrackingEnabled == rhs.isLocationTrackingEnabled
            && lhs.allowBackgroundLocationUpdates
                == rhs.allowBackgroundLocationUpdates
            && lhs.proximityRadius == rhs.proximityRadius
            && lhs.currentLocation == rhs.currentLocation
            && lhs.homeLocation == rhs.homeLocation
            && lhs.workLocation == rhs.workLocation
            && lhs.frequentLocations == rhs.frequentLocations
            && lhs.locationHistory == rhs.locationHistory
            && lhs.lastLocationUpdate == rhs.lastLocationUpdate
    }
}

enum AccessibilityFeature: String, Codable, CaseIterable {
    case wheelchairAccessible = "wheelchair_accessible"
    case hearingLoop = "hearing_loop"
    case brailleMenu = "braille_menu"
    case serviceAnimalsWelcome = "service_animals_welcome"
    case lowSensoryEnvironment = "low_sensory"
    
    var displayName: String {
        return self.rawValue.capitalized.replacingOccurrences(of: "_", with: " ")
    }
}

enum DietaryRestriction: String, Codable, CaseIterable {
    case vegetarian, vegan, glutenFree, dairyFree, nutFree, halal, kosher, keto, paleo
    
    var displayName: String {
        switch self {
        case .glutenFree: return "Gluten-Free"
        case .dairyFree: return "Dairy-Free"
        case .nutFree: return "Nut-Free"
        default: return self.rawValue.capitalized
        }
    }
}


// MARK: - Alternative: Generic Array Decoder Helper
extension KeyedDecodingContainer {
    func decodeStringArray(forKey key: Key) throws -> [String] {
        // Try to decode as array first
        if let array = try? decode([String].self, forKey: key) {
            return array
        }
        // If that fails, try to decode as single string
        if let string = try? decode(String.self, forKey: key) {
            return [string]
        }
        // If both fail, return empty array
        return []
    }

    func decodeStringArrayIfPresent(forKey key: Key) -> [String] {
        // Try to decode as array first
        if let array = try? decodeIfPresent([String].self, forKey: key) {
            return array
        }
        // If that fails, try to decode as single string
        if let string = try? decodeIfPresent(String.self, forKey: key) {
            return [string]
        }
        // If both fail, return empty array
        return []
    }
}



// MARK: - Social Information
struct SocialInfo: Codable, Equatable {
    var friends: [String]  // User IDs
    var followers: [String]  // User IDs
    var following: [String]  // User IDs
    var blockedUsers: [String]  // User IDs
    var socialMediaLinks: [SocialMediaLink]
    var privacySettings: PrivacySettings
    var shareLocation: Bool
    var shareActivity: Bool
}

struct SocialMediaLink: Codable, Equatable {
    var platform: String
    var username: String
    var url: String
}

struct PrivacySettings: Codable, Equatable {
    var profileVisibility: ProfileVisibility
    var showRealName: Bool
    var showLocation: Bool
    var showActivity: Bool
    var allowFriendRequests: Bool
    var allowMessages: Bool
}

enum ProfileVisibility: String, CaseIterable, Codable, Equatable {
    case isPublic = "public"
    case friendsOnly = "friends_only"
    case isPrivate = "private"
}

// MARK: - User Profile Extensions
extension UserProfile {
    // Create a new user profile with default values
    static func createDefault(firstName: String, email: String, id: String, username:String?, avatar: String)
        -> UserProfile
    {
        return UserProfile(
            id: id,
            username: username ?? "",
            personalInfo: PersonalInfo(
                firstName: firstName,
                lastName: nil,
                displayName: nil,
                email: email,
                phoneNumber: nil,
                profileImageURL: avatar,
                dateOfBirth: nil,
                bio: nil,
        
                accountCreated: Date(),
                lastLogin: nil,
                isEmailVerified: false,
                isPhoneVerified: false,
                isOnboardingComplete: false,
                enableNotifications: false
            ),
            locationSettings: LocationSettings(
                isLocationTrackingEnabled: false,
                allowBackgroundLocationUpdates: false,
                proximityRadius: 500.0,
                currentLocation: nil,
                homeLocation: nil,
                workLocation: nil,
                frequentLocations: [],
                locationHistory: [],
                lastLocationUpdate: nil
            ),
            socialInfo: SocialInfo(
                friends: [],
                followers: [],
                following: [],
                blockedUsers: [],
                socialMediaLinks: [],
                privacySettings: PrivacySettings(
                    profileVisibility: .isPublic,
                    showRealName: true,
                    showLocation: false,
                    showActivity: true,
                    allowFriendRequests: true,
                    allowMessages: true
                ),
                shareLocation: false,
                shareActivity: true
            ),
            type: .defaultUser
        )
    }

    // Update user's current location
    mutating func updateLocation(_ location: CLLocation) {
        let coordinate = LocationCoordinate(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            address: nil,
            name: nil,
            timestamp: Date()
        )

        locationSettings.currentLocation = coordinate
        locationSettings.lastLocationUpdate = Date()

        // Add to location history
        let historyEntry = LocationHistoryEntry(
            location: coordinate,
            timestamp: Date(),
            duration: 0,
            venueId: nil
        )
        locationSettings.locationHistory.append(historyEntry)

        // Keep only last 100 location entries
        if locationSettings.locationHistory.count > 100 {
            locationSettings.locationHistory.removeFirst()
        }
    }

    // Check if user should receive proximity notifications
    func shouldReceiveProximityNotifications() -> Bool {
        return locationSettings.isLocationTrackingEnabled
//        notificationSettings.isNotificationsEnabled
//            && notificationSettings.proximityNotifications
//            &&
    }
}



struct LocationCoordinate: Codable, Equatable, Hashable {
    var latitude: Double
    var longitude: Double
    var address: String?
    var name: String?
    var timestamp: Date
}

struct LocationHistoryEntry: Codable, Equatable, Hashable {
    var location: LocationCoordinate
    var timestamp: Date
    var duration: Double
    var venueId: String?
}
