//
//  SlideBusiness.swift
//  Slide
//
//  Created by Nick Rogers on 8/25/25.
//

import SwiftUI
import Foundation
import FirebaseFirestore

struct SlideBusiness: Identifiable, Codable {
    var id: String?
    var displayName: DisplayName?
    var username: String?
    var formattedAddress: String?
    var location: GeoLocation?
    var plusCode: PlusCode?
    var types: [String]?
    var businessStatus: String?
    var rating: Double?
    var userRatingCount: Int?
    var websiteUri: String?
    var nationalPhoneNumber: String?
    var internationalPhoneNumber: String?
    var addressComponents: [AddressComponent]?
    var addressDescriptor: AddressDescriptor?
    var photos: [Photo]?
    var viewport: Viewport?
    var googleMapsUri: String?
    var regularOpeningHours: OpeningHours?
    var currentOpeningHours: OpeningHours?
    var primaryType: String?
    var primaryTypeDisplayName: DisplayName?
    var shortFormattedAddress: String?
    var editorialSummary: DisplayName?
    var reviews: [Review]?
    var paymentOptions: PaymentOptions?
    var parkingOptions: ParkingOptions?
    var accessibilityOptions: AccessibilityOptions?
    var fuelOptions: FuelOptions?
    var evChargeOptions: EVChargeOptions?
    var generativeSummary: GenerativeSummary?
    var priceLevel: String?
    var userRatingsTotal: Int?
    var utcOffset: String?
    var adrFormatAddress: String?
    var businessStatus_: String?
    var iconMaskBaseUri: String?
    var iconBackgroundColor: String?
    var takeout: Bool?
    var delivery: Bool?
    var dineIn: Bool?
    var isBlackOwned: Bool?
    var curbsidePickup: Bool?
    var reservable: Bool?
    var servesBreakfast: Bool?
    var servesLunch: Bool?
    var servesDinner: Bool?
    var servesBeer: Bool?
    var servesWine: Bool?
    var servesBrunch: Bool?
    var servesVegetarianFood: Bool?
    var outdoorSeating: Bool?
    var liveMusic: Bool?
    var restroom: Bool?
    var goodForChildren: Bool?
    var goodForGroups: Bool?
    var allowsDogs: Bool?
    var googleMapsLinks: GoogleMapsLinks?
    var reviewSummary: ReviewSummary?
    var postalAddress: PostalAddress?
    
    var profilePhoto: String?
    var bannerPhoto: String?
    var videoReference: String?
    
    var createdAt: Timestamp
    var updatedAt: Timestamp
}

struct DisplayName: Codable {
    var text: String
    var languageCode: String?
}

struct GeoLocation: Codable, Identifiable {
    var id: String { "\(latitude),\(longitude)" }
    
    let latitude: Double
    let longitude: Double
    
    // Using custom init to handle any additional fields that might be present
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        // Ignore any other fields that might be present
    }
    
    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
    
    private enum CodingKeys: String, CodingKey {
        case latitude, longitude
    }
}
