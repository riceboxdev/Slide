//
//  PlaceDetailsResponse.swift
//  Slide
//
//  Created by Nick Rogers on 8/23/25.
//


import Foundation
import Combine
import SwiftUI
import _MapKit_SwiftUI


// MARK: - Models
struct PlaceDetailsResponse: Codable {
    let id: String?
    let name: String?
    let displayName: DisplayName?
    let formattedAddress: String?
    let location: GeoLocation?
    let plusCode: PlusCode?
    let types: [String]?
    let businessStatus: String?
    let rating: Double?
    let userRatingCount: Int?
    let websiteUri: String?
    let nationalPhoneNumber: String?
    let internationalPhoneNumber: String?
    let addressComponents: [AddressComponent]?
    let addressDescriptor: AddressDescriptor?
    let photos: [Photo]?
    let viewport: Viewport?
    let googleMapsUri: String?
    let regularOpeningHours: OpeningHours?
    let currentOpeningHours: OpeningHours?
    let primaryType: String?
    let primaryTypeDisplayName: DisplayName?
    let shortFormattedAddress: String?
    let editorialSummary: DisplayName?
    let reviews: [Review]?
    let paymentOptions: PaymentOptions?
    let parkingOptions: ParkingOptions?
    let accessibilityOptions: AccessibilityOptions?
    let fuelOptions: FuelOptions?
    let evChargeOptions: EVChargeOptions?
    let generativeSummary: GenerativeSummary?
    let priceLevel: String?
    let userRatingsTotal: Int?
    let utcOffset: String?
    let adrFormatAddress: String?
    let businessStatus_: String?
    let iconMaskBaseUri: String?
    let iconBackgroundColor: String?
    let takeout: Bool?
    let delivery: Bool?
    let dineIn: Bool?
    let curbsidePickup: Bool?
    let reservable: Bool?
    let servesBreakfast: Bool?
    let servesLunch: Bool?
    let servesDinner: Bool?
    let servesBeer: Bool?
    let servesWine: Bool?
    let servesBrunch: Bool?
    let servesVegetarianFood: Bool?
    let outdoorSeating: Bool?
    let liveMusic: Bool?
    let restroom: Bool?
    let goodForChildren: Bool?
    let goodForGroups: Bool?
    let allowsDogs: Bool?
    let googleMapsLinks: GoogleMapsLinks?
    let reviewSummary: ReviewSummary?
    let postalAddress: PostalAddress?
}

// MARK: - Models
struct SlideBuisiness: Codable {
    let id: String?
    let name: String?
    let displayName: DisplayName?
    let formattedAddress: String?
    let location: GeoLocation?
    let plusCode: PlusCode?
    let types: [String]?
    let businessStatus: String?
    let rating: Double?
    let userRatingCount: Int?
    let websiteUri: String?
    let nationalPhoneNumber: String?
    let internationalPhoneNumber: String?
    let addressComponents: [AddressComponent]?
    let addressDescriptor: AddressDescriptor?
    let photos: [Photo]?
    let viewport: Viewport?
    let googleMapsUri: String?
    let regularOpeningHours: OpeningHours?
    let currentOpeningHours: OpeningHours?
    let primaryType: String?
    let primaryTypeDisplayName: DisplayName?
    let shortFormattedAddress: String?
    let editorialSummary: DisplayName?
    let reviews: [Review]?
    let paymentOptions: PaymentOptions?
    let parkingOptions: ParkingOptions?
    let accessibilityOptions: AccessibilityOptions?
    let fuelOptions: FuelOptions?
    let evChargeOptions: EVChargeOptions?
    let generativeSummary: GenerativeSummary?
    let priceLevel: String?
    let userRatingsTotal: Int?
    let utcOffset: String?
    let adrFormatAddress: String?
    let businessStatus_: String?
    let iconMaskBaseUri: String?
    let iconBackgroundColor: String?
    let takeout: Bool?
    let delivery: Bool?
    let dineIn: Bool?
    let curbsidePickup: Bool?
    let reservable: Bool?
    let servesBreakfast: Bool?
    let servesLunch: Bool?
    let servesDinner: Bool?
    let servesBeer: Bool?
    let servesWine: Bool?
    let servesBrunch: Bool?
    let servesVegetarianFood: Bool?
    let outdoorSeating: Bool?
    let liveMusic: Bool?
    let restroom: Bool?
    let goodForChildren: Bool?
    let goodForGroups: Bool?
    let allowsDogs: Bool?
    let googleMapsLinks: GoogleMapsLinks?
    let reviewSummary: ReviewSummary?
    let postalAddress: PostalAddress?
}

// MARK: - New Models for missing fields

struct GenerativeSummary: Codable {
    let overview: DisplayName?
    let overviewFlagContentUri: String?
    let disclosureText: DisplayName?
}

struct GoogleMapsLinks: Codable {
    let directionsUri: String?
    let placeUri: String?
    let writeAReviewUri: String?
    let reviewsUri: String?
    let photosUri: String?
}

struct ReviewSummary: Codable {
    let text: DisplayName?
    let flagContentUri: String?
    let disclosureText: DisplayName?
    let reviewsUri: String?
}

struct PostalAddress: Codable {
    let regionCode: String?
    let languageCode: String?
    let postalCode: String?
    let administrativeArea: String?
    let locality: String?
    let addressLines: [String]?
}

// MARK: - Existing Models (keeping them the same)

struct DisplayName: Codable {
    let text: String
    let languageCode: String?
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

struct PlusCode: Codable {
    let globalCode: String?
    let compoundCode: String?
}

struct AddressComponent: Codable {
    let longText: String
    let shortText: String
    let types: [String]
    let languageCode: String?
}

struct AddressDescriptor: Codable {
    let landmarks: [Landmark]?
    let areas: [Area]?
}

struct Landmark: Codable {
    let name: String
    let placeId: String
    let displayName: DisplayName
    let types: [String]
    let spatialRelationship: String?
    let straightLineDistanceMeters: Double?
}

struct Area: Codable {
    let name: String
    let placeId: String
    let displayName: DisplayName
    let containment: String
}

struct Photo: Codable {
    let name: String
    let widthPx: Int
    let heightPx: Int
    let authorAttributions: [AuthorAttribution]?
    let flagContentUri: String?
    let googleMapsUri: String?
}

struct AuthorAttribution: Codable {
    let displayName: String?
    let uri: String?
    let photoUri: String?
}

struct Viewport: Codable {
    let low: GeoLocation
    let high: GeoLocation
}

struct OpeningHours: Codable {
    let openNow: Bool?
    let periods: [Period]?
    let weekdayDescriptions: [String]?
}

struct Period: Codable {
    let open: TimeOfDay?
    let close: TimeOfDay?
}

struct TimeOfDay: Codable {
    let day: Int?
    let hour: Int?
    let minute: Int?
}

struct Review: Codable {
    let name: String?
    let relativePublishTimeDescription: String?
    let rating: Int?
    let text: DisplayName?
    let originalText: DisplayName?
    let authorAttribution: AuthorAttribution?
    let publishTime: String?
    let flagContentUri: String?
    let googleMapsUri: String?
}

struct PaymentOptions: Codable {
    let acceptsCreditCards: Bool?
    let acceptsDebitCards: Bool?
    let acceptsCashOnly: Bool?
    let acceptsNfc: Bool?
}

struct ParkingOptions: Codable {
    let paidGarageParking: Bool?
    let paidLotParking: Bool?
    let paidStreetParking: Bool?
    let valetParking: Bool?
    let freeGarageParking: Bool?
    let freeLotParking: Bool?
    let freeStreetParking: Bool?
}

struct AccessibilityOptions: Codable {
    let wheelchairAccessibleParking: Bool?
    let wheelchairAccessibleEntrance: Bool?
    let wheelchairAccessibleRestroom: Bool?
    let wheelchairAccessibleSeating: Bool?
}

struct FuelOptions: Codable {
    let fuelTypes: [String]?
}

struct EVChargeOptions: Codable {
    let connectorCount: Int?
    let connectorAggregation: [ConnectorAggregation]?
}

struct ConnectorAggregation: Codable {
    let type: String?
    let maxChargeRateKw: Double?
    let count: Int?
}

// MARK: - Field Enums (keeping the same)
enum PlaceDetailsField: String, CaseIterable {
    // ID Only SKU
    case id = "id"
    case name = "name"
    case photos = "photos"
    case attributions = "attributions"
    
    // Essentials SKU
    case addressComponents = "addressComponents"
    case addressDescriptor = "addressDescriptor"
    case adrFormatAddress = "adrFormatAddress"
    case formattedAddress = "formattedAddress"
    case location = "location"
    case plusCode = "plusCode"
    case postalAddress = "postalAddress"
    case shortFormattedAddress = "shortFormattedAddress"
    case types = "types"
    case viewport = "viewport"
    
    // Pro SKU
    case accessibilityOptions = "accessibilityOptions"
    case businessStatus = "businessStatus"
    case containingPlaces = "containingPlaces"
    case displayName = "displayName"
    case googleMapsLinks = "googleMapsLinks"
    case googleMapsUri = "googleMapsUri"
    case iconBackgroundColor = "iconBackgroundColor"
    case iconMaskBaseUri = "iconMaskBaseUri"
    case primaryType = "primaryType"
    case primaryTypeDisplayName = "primaryTypeDisplayName"
    case pureServiceAreaBusiness = "pureServiceAreaBusiness"
    case subDestinations = "subDestinations"
    case utcOffsetMinutes = "utcOffsetMinutes"
    
    // Enterprise SKU
    case currentOpeningHours = "currentOpeningHours"
    case currentSecondaryOpeningHours = "currentSecondaryOpeningHours"
    case internationalPhoneNumber = "internationalPhoneNumber"
    case nationalPhoneNumber = "nationalPhoneNumber"
    case priceLevel = "priceLevel"
    case priceRange = "priceRange"
    case rating = "rating"
    case regularOpeningHours = "regularOpeningHours"
    case regularSecondaryOpeningHours = "regularSecondaryOpeningHours"
    case userRatingCount = "userRatingCount"
    case websiteUri = "websiteUri"
    
    // Enterprise + Atmosphere SKU
    case allowsDogs = "allowsDogs"
    case curbsidePickup = "curbsidePickup"
    case delivery = "delivery"
    case dineIn = "dineIn"
    case editorialSummary = "editorialSummary"
    case evChargeOptions = "evChargeOptions"
    case fuelOptions = "fuelOptions"
    case generativeSummary = "generativeSummary"
    case goodForChildren = "goodForChildren"
    case goodForGroups = "goodForGroups"
    case liveMusic = "liveMusic"
    case outdoorSeating = "outdoorSeating"
    case paymentOptions = "paymentOptions"
    case reservable = "reservable"
    case restroom = "restroom"
    case reviews = "reviews"
    case reviewSummary = "reviewSummary"
    case servesBeer = "servesBeer"
    case servesBreakfast = "servesBreakfast"
    case servesBrunch = "servesBrunch"
    case servesCocktails = "servesCocktails"
    case servesCoffee = "servesCoffee"
    case servesDessert = "servesDessert"
    case servesDinner = "servesDinner"
    case servesLunch = "servesLunch"
    case servesVegetarianFood = "servesVegetarianFood"
    case servesWine = "servesWine"
    case takeout = "takeout"
}

// MARK: - Google Places API Models
struct GooglePlacesResponse: Codable {
    let suggestions: [Suggestion]
}

struct Suggestion: Codable, Identifiable {
    let id = UUID()
    let placePrediction: PlacePrediction?
    let queryPrediction: QueryPrediction?
    
    private enum CodingKeys: String, CodingKey {
        case placePrediction, queryPrediction
    }
}

struct PlacePrediction: Codable {
    let place: String
    let placeId: String
    let text: PredictionText
    let structuredFormat: StructuredFormat?
    let types: [String]?
    let distanceMeters: Int?
    
    private enum CodingKeys: String, CodingKey {
        case place, placeId, text, structuredFormat, types, distanceMeters
    }
}

struct QueryPrediction: Codable {
    let text: PredictionText
    let structuredFormat: StructuredFormat?
    
    private enum CodingKeys: String, CodingKey {
        case text, structuredFormat
    }
}

struct PredictionText: Codable {
    let text: String
    let matches: [TextMatch]?
}

struct TextMatch: Codable {
    let endOffset: Int?
}

struct StructuredFormat: Codable {
    let mainText: PredictionText
    let secondaryText: PredictionText?
}

// MARK: - Place Details Models
struct PlaceSearchDetailsResponse: Codable {
    let name: String?
    let formattedAddress: String?
    let location: LocationCoordinate?
    let types: [String]?
    let phoneNumber: String?
    let website: String?
    let rating: Double?
    let userRatingCount: Int?
    
    private enum CodingKeys: String, CodingKey {
        case name, formattedAddress = "formattedAddress", location, types
        case phoneNumber = "nationalPhoneNumber", website = "websiteUri"
        case rating, userRatingCount = "userRatingCount"
    }
}



// MARK: - Primary Types Enum
enum GooglePlaceType: String, CaseIterable {
    case restaurant = "restaurant"
    case lodging = "lodging"
    case tourist_attraction = "tourist_attraction"
    case shopping_mall = "shopping_mall"
    case gas_station = "gas_station"
    case hospital = "hospital"
    case pharmacy = "pharmacy"
    case bank = "bank"
    case school = "school"
    case gym = "gym"
    case all = ""
    
    var displayName: String {
        switch self {
        case .all: return "All Places"
        case .restaurant: return "Restaurants"
        case .lodging: return "Hotels"
        case .tourist_attraction: return "Attractions"
        case .shopping_mall: return "Shopping"
        case .gas_station: return "Gas Stations"
        case .hospital: return "Hospitals"
        case .pharmacy: return "Pharmacies"
        case .bank: return "Banks"
        case .school: return "Schools"
        case .gym: return "Gyms"
        }
    }
}

// MARK: - Autocomplete Suggestion Model
struct AutocompleteSuggestion: Identifiable, Hashable {
    let id = UUID()
    let placeId: String?
    let primaryText: String
    let secondaryText: String
    let fullText: String
    let types: [String]
    let distanceMeters: Int?
    let isPlace: Bool
    
    init(from suggestion: Suggestion) {
        if let placePrediction = suggestion.placePrediction {
            self.placeId = placePrediction.placeId
            self.fullText = placePrediction.text.text
            self.types = placePrediction.types ?? []
            self.distanceMeters = placePrediction.distanceMeters
            self.isPlace = true
            
            if let structured = placePrediction.structuredFormat {
                self.primaryText = structured.mainText.text
                self.secondaryText = structured.secondaryText?.text ?? ""
            } else {
                self.primaryText = placePrediction.text.text
                self.secondaryText = ""
            }
        } else if let queryPrediction = suggestion.queryPrediction {
            self.placeId = nil
            self.fullText = queryPrediction.text.text
            self.types = []
            self.distanceMeters = nil
            self.isPlace = false
            
            if let structured = queryPrediction.structuredFormat {
                self.primaryText = structured.mainText.text
                self.secondaryText = structured.secondaryText?.text ?? ""
            } else {
                self.primaryText = queryPrediction.text.text
                self.secondaryText = ""
            }
        } else {
            self.placeId = nil
            self.primaryText = "Unknown"
            self.secondaryText = ""
            self.fullText = "Unknown"
            self.types = []
            self.distanceMeters = nil
            self.isPlace = false
        }
    }
    
    var primaryType: String {
        return types.first?.replacingOccurrences(of: "_", with: " ").capitalized ?? "Place"
    }
}



// MARK: - API Error
enum APIError: Error, LocalizedError {
    case httpError(Int)
    
    var errorDescription: String? {
        switch self {
        case .httpError(let code):
            return "HTTP Error: \(code)"
        }
    }
}

// Method 1: Direct JSON String Parsing
func createPlaceDetailsFromJSON() -> PlaceDetailsResponse? {
    let jsonString = """
    {
      "name": "places/ChIJT4_7y4a3woARcEGeJLecuV8",
      "id": "ChIJT4_7y4a3woARcEGeJLecuV8",
      "types": [
        "stadium",
        "event_venue",
        "sports_complex",
        "sports_activity_location",
        "point_of_interest",
        "establishment"
      ],
      "nationalPhoneNumber": "(424) 541-9100",
      "internationalPhoneNumber": "+1 424-541-9100",
      "formattedAddress": "1001 Stadium Dr, Inglewood, CA 90301, USA",
      "addressComponents": [
        {
          "longText": "1001",
          "shortText": "1001",
          "types": ["street_number"],
          "languageCode": "en-US"
        },
        {
          "longText": "Stadium Drive",
          "shortText": "Stadium Dr",
          "types": ["route"],
          "languageCode": "en"
        },
        {
          "longText": "Inglewood",
          "shortText": "Inglewood",
          "types": ["locality", "political"],
          "languageCode": "en"
        },
        {
          "longText": "California",
          "shortText": "CA",
          "types": ["administrative_area_level_1", "political"],
          "languageCode": "en"
        },
        {
          "longText": "90301",
          "shortText": "90301",
          "types": ["postal_code"],
          "languageCode": "en-US"
        }
      ],
      "plusCode": {
        "globalCode": "8553XM36+99",
        "compoundCode": "XM36+99 Inglewood, CA, USA"
      },
      "location": {
        "latitude": 33.9534765,
        "longitude": -118.33902349999998
      },
      "viewport": {
        "low": {
          "latitude": 33.9521593197085,
          "longitude": -118.33950743029149
        },
        "high": {
          "latitude": 33.9548572802915,
          "longitude": -118.33680946970851
        }
      },
      "rating": 4.5,
      "googleMapsUri": "https://maps.google.com/?cid=6897716614701924720",
      "websiteUri": "https://www.sofistadium.com/",
      "utcOffsetMinutes": -420,
      "adrFormatAddress": "<span class=\\"street-address\\">1001 Stadium Dr</span>, <span class=\\"locality\\">Inglewood</span>, <span class=\\"region\\">CA</span> <span class=\\"postal-code\\">90301</span>, <span class=\\"country-name\\">USA</span>",
      "businessStatus": "OPERATIONAL",
      "userRatingCount": 20008,
      "iconMaskBaseUri": "https://maps.gstatic.com/mapfiles/place_api/icons/v2/stadium_pinlet",
      "iconBackgroundColor": "#4DB546",
      "displayName": {
        "text": "SoFi Stadium",
        "languageCode": "en"
      },
      "primaryTypeDisplayName": {
        "text": "Stadium",
        "languageCode": "en-US"
      },
      "primaryType": "stadium",
      "shortFormattedAddress": "1001 Stadium Dr, Inglewood",
      "restroom": true,
      "paymentOptions": {
        "acceptsCreditCards": true,
        "acceptsDebitCards": true,
        "acceptsCashOnly": false,
        "acceptsNfc": true
      },
      "accessibilityOptions": {
        "wheelchairAccessibleParking": true,
        "wheelchairAccessibleEntrance": true,
        "wheelchairAccessibleRestroom": true
      },
      "generativeSummary": {
        "overview": {
          "text": "State-of-the-art sports venue featuring clean lines, a gigantic video screen and a seating capacity for up to 100,000 people.",
          "languageCode": "en-US"
        },
        "overviewFlagContentUri": "https://www.google.com/local/review/rap/report?postId=example",
        "disclosureText": {
          "text": "Summarized with Gemini",
          "languageCode": "en-US"
        }
      },
      "pureServiceAreaBusiness": false,
      "googleMapsLinks": {
        "directionsUri": "https://www.google.com/maps/dir//",
        "placeUri": "https://maps.google.com/?cid=6897716614701924720",
        "writeAReviewUri": "https://www.google.com/maps/place/review",
        "reviewsUri": "https://www.google.com/maps/place/reviews",
        "photosUri": "https://www.google.com/maps/place/photos"
      },
      "reviewSummary": {
        "text": {
          "text": "People say this stadium offers a modern and impressive architectural design, and a state-of-the-art sound system with a giant jumbotron.",
          "languageCode": "en-US"
        },
        "flagContentUri": "https://www.google.com/local/review/rap/report",
        "disclosureText": {
          "text": "Summarized with Gemini",
          "languageCode": "en-US"
        }
      },
      "postalAddress": {
        "regionCode": "US",
        "languageCode": "en-US",
        "postalCode": "90301",
        "administrativeArea": "California",
        "locality": "Inglewood",
        "addressLines": ["1001 Stadium Dr"]
      }
    }
    """
    
    guard let jsonData = jsonString.data(using: .utf8) else {
        print("Failed to convert JSON string to Data")
        return nil
    }
    
    do {
        let decoder = JSONDecoder()
        let placeDetails = try decoder.decode(PlaceDetailsResponse.self, from: jsonData)
        return placeDetails
    } catch {
        print("Failed to decode JSON: \(error)")
        return nil
    }
}

// Method 2: If you have the JSON as Data already
func createPlaceDetailsFromData(_ jsonData: Data) -> PlaceDetailsResponse? {
    do {
        let decoder = JSONDecoder()
        let placeDetails = try decoder.decode(PlaceDetailsResponse.self, from: jsonData)
        return placeDetails
    } catch {
        print("Failed to decode JSON: \(error)")
        return nil
    }
}
