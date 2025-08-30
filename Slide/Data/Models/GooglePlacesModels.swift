//
//  GooglePlacesModels.swift
//  Slide
//
//  Created by Nick Rogers on 8/28/25.
//

import Foundation
import FoundationModels

@Generable
public struct Place: Identifiable, Codable, Equatable, Hashable {
    public let name: String?
    public let id: String?
    public let displayName: LocalizedText?
    @Guide(description: "A list of categories representative of this place")
    public let types: [String]?
    @Guide(description: "The place's primary category type")
    public let primaryType: String?
    @Guide(description: "The properly formatted display name for the primary category")
    public let primaryTypeDisplayName: LocalizedText?
    public let nationalPhoneNumber: String?
    public let internationalPhoneNumber: String?
    public let formattedAddress: String?
    public let shortFormattedAddress: String?
    public let postalAddress: PostalAddress?
    public let addressComponents: [AddressComponent]?
    public let plusCode: PlusCode?
    @Guide(description: "The latitude and longitude coordinates of the place")
    public let location: LatLng?
    public let viewport: Viewport?
    public let rating: Double?
    public let googleMapsUri: String?
    public let websiteUri: String?
    @Guide(description: "A short list of most relavent reviews for this place")
    public let reviews: [Review]?
    public let regularOpeningHours: OpeningHours?
    public let timeZone: GmsTimeZone?
    public let photos: [Photo]?
    public let adrFormatAddress: String?
    public let businessStatus: BusinessStatus?
    public let priceLevel: PriceLevel?
    public let attributions: [Attribution]?
    public let iconMaskBaseUri: String?
    public let iconBackgroundColor: String?
    public let currentOpeningHours: OpeningHours?
    public let currentSecondaryOpeningHours: [OpeningHours]?
    public let regularSecondaryOpeningHours: [OpeningHours]?
    public let editorialSummary: LocalizedText?
    public let paymentOptions: PaymentOptions?
    public let parkingOptions: ParkingOptions?
    public let subDestinations: [SubDestination]?
    public let fuelOptions: FuelOptions?
    public let evChargeOptions: EVChargeOptions?
    @Guide(description: "A short summary about the place using Google's generative model")
    public let generativeSummary: GenerativeSummary?
    @Guide(description: "A list of places this place may coontain")
    public let containingPlaces: [ContainingPlace]?
    public let addressDescriptor: AddressDescriptor?
    public let googleMapsLinks: GoogleMapsLinks?
    public let priceRange: PriceRange?
    @Guide(description: "A brief summary of the most relavent reviews")
    public let reviewSummary: ReviewSummary?
    public let evChargeAmenitySummary: EvChargeAmenitySummary?
    public let neighborhoodSummary: NeighborhoodSummary?

    public let utcOffsetMinutes: Int?
    public let userRatingCount: Int?

    // Restaurant/amenity booleans
    public let takeout: Bool?
    public let delivery: Bool?
    public let dineIn: Bool?
    public let curbsidePickup: Bool?
    public let reservable: Bool?
    public let servesBreakfast: Bool?
    public let servesLunch: Bool?
    public let servesDinner: Bool?
    public let servesBeer: Bool?
    public let servesWine: Bool?
    public let servesBrunch: Bool?
    public let servesVegetarianFood: Bool?
    public let outdoorSeating: Bool?
    public let liveMusic: Bool?
    public let menuForChildren: Bool?
    public let servesCocktails: Bool?
    public let servesDessert: Bool?
    public let servesCoffee: Bool?
    public let goodForChildren: Bool?
    public let allowsDogs: Bool?
    public let restroom: Bool?
    public let goodForGroups: Bool?
    public let goodForWatchingSports: Bool?

    public let accessibilityOptions: AccessibilityOptions?
    public let pureServiceAreaBusiness: Bool?
    
    // Default field mask for list/search endpoints
       public static let defaultFieldMask = "places.id,places.name,places.displayName,places.formattedAddress,places.location,places.types,places.rating,places.userRatingCount,places.photos"

       // Default field mask for GET details endpoint (no places.* prefix)
       public static let detailsFieldMask = "id,name,displayName,formattedAddress,location,types,rating,userRatingCount,photos"
    
    var displayNameText: String {
        return displayName?.text ?? name ?? "Unknown Place"
    }
    
    var primaryTypeDisplayText: String {
        return primaryTypeDisplayName?.text ?? primaryType?.replacingOccurrences(of: "_", with: " ").capitalized ?? "Place"
    }
    
    var isOpen: Bool? {
        return currentOpeningHours?.openNow
    }
    
    var ratingText: String? {
        guard let rating = rating else { return nil }
        return String(format: "%.1f", rating)
    }
    
    var ratingCountText: String? {
        guard let count = userRatingCount else { return nil }
        if count >= 1000 {
            return String(format: "%.1fk", Double(count) / 1000.0)
        }
        return "\(count)"
    }
    
    var servingOptions: [String] {
        var options: [String] = []
        if takeout == true { options.append("Takeout") }
        if delivery == true { options.append("Delivery") }
        if dineIn == true { options.append("Dine-in") }
        if curbsidePickup == true { options.append("Curbside") }
        return options
    }
    
    var mealOptions: [String] {
        var options: [String] = []
        if servesBreakfast == true { options.append("Breakfast") }
        if servesLunch == true { options.append("Lunch") }
        if servesDinner == true { options.append("Dinner") }
        if servesBrunch == true { options.append("Brunch") }
        return options
    }
    
    var amenities: [String] {
        var amenities: [String] = []
        if outdoorSeating == true { amenities.append("Outdoor Seating") }
        if liveMusic == true { amenities.append("Live Music") }
        if goodForChildren == true { amenities.append("Kid Friendly") }
        if allowsDogs == true { amenities.append("Dog Friendly") }
        if restroom == true { amenities.append("Restroom") }
        if goodForGroups == true { amenities.append("Good for Groups") }
        if reservable == true { amenities.append("Reservations") }
        return amenities
    }
}

// MARK: - Simple shared types
@Generable
public struct LocalizedText: Codable, Equatable, Hashable {
    public let text: String?
    public let languageCode: String?
}

@Generable
public struct PostalAddress: Codable, Equatable, Hashable {
    public let revision: Int?
    public let regionCode: String?
    public let languageCode: String?
    public let postalCode: String?
    public let sortingCode: String?
    public let administrativeArea: String?
    public let locality: String?
    public let sublocality: String?
    public let addressLines: [String]?
    public let recipients: [String]?
    public let organization: String?
}

@Generable
public struct AddressComponent: Codable, Equatable, Hashable {
    public let longText: String?
    public let shortText: String?
    public let types: [String]?
    public let languageCode: String?
}

@Generable
public struct PlusCode: Codable, Equatable, Hashable {
    public let globalCode: String?
    public let compoundCode: String?
}

@Generable
public struct LatLng: Codable, Equatable, Hashable {
    public let latitude: Double?
    public let longitude: Double?
    public let cityName: String?
}

@Generable
public struct Viewport: Codable, Equatable, Hashable {
    public let low: LatLng?
    public let high: LatLng?
}

// MARK: - Reviews
@Generable
public struct Review: Codable, Equatable, Hashable {
    public let name: String?
    public let relativePublishTimeDescription: String?
    public let text: LocalizedText?
    public let originalText: LocalizedText?
    public let rating: Double?
    public let authorAttribution: AuthorAttribution?
    public let publishTime: String? // RFC3339
    public let flagContentUri: String?
    public let googleMapsUri: String?
}

@Generable
public struct AuthorAttribution: Codable, Equatable, Hashable {
    public let displayName: String?
    public let uri: String?
    public let photoUri: String?
}

// MARK: - Opening Hours
@Generable
public struct OpeningHours: Codable, Equatable, Hashable {
    public let periods: [Period]?
    public let weekdayDescriptions: [String]?
    public let secondaryHoursType: SecondaryHoursType?
    public let specialDays: [SpecialDay]?
    public let nextOpenTime: String? // RFC3339
    public let nextCloseTime: String? // RFC3339
    public let openNow: Bool?
}

@Generable
public struct Period: Codable, Equatable, Hashable {
    public let open: Point?
    public let close: Point?
}

@Generable
public struct Point: Codable, Equatable, Hashable {
    public let date: GmsDate?
    public let truncated: Bool?
    public let day: Int? // 0=Sun
    public let hour: Int? // 0-23
    public let minute: Int? // 0-59
}

@Generable
public struct GmsDate: Codable, Equatable, Hashable { // Avoid Foundation.Date name
    public let year: Int?
    public let month: Int?
    public let day: Int?
}

@Generable
public enum SecondaryHoursType: String, Codable, Equatable, Hashable {
    case SECONDARY_HOURS_TYPE_UNSPECIFIED
    case DRIVE_THROUGH
    case HAPPY_HOUR
    case DELIVERY
    case TAKEOUT
    case KITCHEN
    case BREAKFAST
    case LUNCH
    case DINNER
    case BRUNCH
    case PICKUP
    case ACCESS
    case SENIOR_HOURS
    case ONLINE_SERVICE_HOURS
}

@Generable
public struct SpecialDay: Codable, Equatable, Hashable {
    public let date: GmsDate?
}

@Generable
public struct GmsTimeZone: Codable, Equatable, Hashable { // Avoid Foundation.TimeZone name
    public let id: String?
    public let version: String?
}

// MARK: - Photos
@Generable
public struct Photo: Codable, Equatable, Hashable {
    public let name: String?
    public let widthPx: Int?
    public let heightPx: Int?
    public let authorAttributions: [AuthorAttribution]?
    public let flagContentUri: String?
    public let googleMapsUri: String?
}

@Generable
public enum BusinessStatus: String, Codable, Equatable, Hashable {
    case BUSINESS_STATUS_UNSPECIFIED
    case OPERATIONAL
    case CLOSED_TEMPORARILY
    case CLOSED_PERMANENTLY
}

@Generable
public enum PriceLevel: String, Codable, Equatable, Hashable {
    case PRICE_LEVEL_UNSPECIFIED
    case PRICE_LEVEL_FREE
    case PRICE_LEVEL_INEXPENSIVE
    case PRICE_LEVEL_MODERATE
    case PRICE_LEVEL_EXPENSIVE
    case PRICE_LEVEL_VERY_EXPENSIVE
}

@Generable
public struct Attribution: Codable, Equatable, Hashable {
    public let provider: String?
    public let providerUri: String?
}

@Generable
public struct PaymentOptions: Codable, Equatable, Hashable {
    public let acceptsCreditCards: Bool?
    public let acceptsDebitCards: Bool?
    public let acceptsCashOnly: Bool?
    public let acceptsNfc: Bool?
}

@Generable
public struct ParkingOptions: Codable, Equatable, Hashable {
    public let freeParkingLot: Bool?
    public let paidParkingLot: Bool?
    public let freeStreetParking: Bool?
    public let paidStreetParking: Bool?
    public let valetParking: Bool?
    public let freeGarageParking: Bool?
    public let paidGarageParking: Bool?
}

@Generable
public struct SubDestination: Codable, Equatable, Hashable {
    public let name: String?
    public let id: String?
}

@Generable
public struct AccessibilityOptions: Codable, Equatable, Hashable {
    public let wheelchairAccessibleParking: Bool?
    public let wheelchairAccessibleEntrance: Bool?
    public let wheelchairAccessibleRestroom: Bool?
    public let wheelchairAccessibleSeating: Bool?
}

// MARK: - Fuel

@Generable
public struct FuelOptions: Codable, Equatable, Hashable {
    public let fuelPrices: [FuelPrice]?
}

@Generable
public struct FuelPrice: Codable, Equatable, Hashable {
    public let type: FuelType?
    public let price: Money?
    public let updateTime: String? // RFC3339
}

@Generable
public enum FuelType: String, Codable, Equatable, Hashable {
    case FUEL_TYPE_UNSPECIFIED
    case DIESEL
    case DIESEL_PLUS
    case REGULAR_UNLEADED
    case MIDGRADE
    case PREMIUM
    case SP91
    case SP91_E10
    case SP92
    case SP95
    case SP95_E10
    case SP98
    case SP99
    case SP100
    case LPG
    case E80
    case E85
    case E100
    case METHANE
    case BIO_DIESEL
    case TRUCK_DIESEL
}

@Generable
public struct Money: Codable, Equatable, Hashable {
    public let currencyCode: String?
    public let units: String? // int64 as string in JSON
    public let nanos: Int?
}

// MARK: - EV Charging
@Generable
public struct EVChargeOptions: Codable, Equatable, Hashable {
    public let connectorCount: Int?
    public let connectorAggregation: [ConnectorAggregation]?
}

@Generable
public struct ConnectorAggregation: Codable, Equatable, Hashable {
    public let type: EVConnectorType?
    public let maxChargeRateKw: Double?
    public let count: Int?
    public let availabilityLastUpdateTime: String? // RFC3339
    public let availableCount: Int?
    public let outOfServiceCount: Int?
}

@Generable
public enum EVConnectorType: String, Codable, Equatable, Hashable {
    case EV_CONNECTOR_TYPE_UNSPECIFIED
    case EV_CONNECTOR_TYPE_OTHER
    case EV_CONNECTOR_TYPE_J1772
    case EV_CONNECTOR_TYPE_TYPE_2
    case EV_CONNECTOR_TYPE_CHADEMO
    case EV_CONNECTOR_TYPE_CCS_COMBO_1
    case EV_CONNECTOR_TYPE_CCS_COMBO_2
    case EV_CONNECTOR_TYPE_TESLA
    case EV_CONNECTOR_TYPE_UNSPECIFIED_GB_T
    case EV_CONNECTOR_TYPE_UNSPECIFIED_WALL_OUTLET
    case EV_CONNECTOR_TYPE_NACS
}

@Generable
public struct GenerativeSummary: Codable, Equatable, Hashable {
    public let overview: LocalizedText?
    public let overviewFlagContentUri: String?
    public let disclosureText: LocalizedText?
}

@Generable
public struct ContainingPlace: Codable, Equatable, Hashable {
    public let name: String?
    public let id: String?
}

// MARK: - Address Descriptor
@Generable
public struct AddressDescriptor: Codable, Equatable, Hashable {
    public let landmarks: [Landmark]?
    public let areas: [Area]?
}
@Generable
public struct Landmark: Codable, Equatable, Hashable {
    public let name: String?
    public let placeId: String?
    public let displayName: LocalizedText?
    public let types: [String]?
    public let spatialRelationship: SpatialRelationship?
    public let straightLineDistanceMeters: Double?
    public let travelDistanceMeters: Double?
}

@Generable
public enum SpatialRelationship: String, Codable, Equatable, Hashable {
    case NEAR
    case WITHIN
    case BESIDE
    case ACROSS_THE_ROAD
    case DOWN_THE_ROAD
    case AROUND_THE_CORNER
    case BEHIND
}

@Generable
public struct Area: Codable, Equatable, Hashable {
    public let name: String?
    public let placeId: String?
    public let displayName: LocalizedText?
    public let containment: Containment?
}

@Generable
public enum Containment: String, Codable, Equatable, Hashable {
    case CONTAINMENT_UNSPECIFIED
    case WITHIN
    case OUTSKIRTS
    case NEAR
}

@Generable
public struct GoogleMapsLinks: Codable, Equatable, Hashable {
    public let directionsUri: String?
    public let placeUri: String?
    public let writeAReviewUri: String?
    public let reviewsUri: String?
    public let photosUri: String?
}

@Generable
public struct PriceRange: Codable, Equatable, Hashable {
    public let startPrice: Money?
    public let endPrice: Money?
}

// MARK: - AI Summaries
@Generable
public struct ReviewSummary: Codable, Equatable, Hashable {
    public let text: LocalizedText?
    public let flagContentUri: String?
    public let disclosureText: LocalizedText?
    public let reviewsUri: String?
}

@Generable
public struct EvChargeAmenitySummary: Codable, Equatable, Hashable {
    public let overview: ContentBlock?
    public let coffee: ContentBlock?
    public let restaurant: ContentBlock?
    public let store: ContentBlock?
    public let flagContentUri: String?
    public let disclosureText: LocalizedText?
}

@Generable
public struct ContentBlock: Codable, Equatable, Hashable {
    public let content: LocalizedText?
    public let referencedPlaces: [String]?
}

@Generable
public struct NeighborhoodSummary: Codable, Equatable, Hashable {
    public let overview: ContentBlock?
    public let description: ContentBlock?
    public let flagContentUri: String?
    public let disclosureText: LocalizedText?
}


/**
 * Google Maps Places API Place Types Enum
 * Updated with types from November 7, 2024 release
 * Types marked with * were added in the November 7, 2024 release
 */
@Generable
public enum GoogleMapsPlaceType: String, CaseIterable, Equatable, Codable {
    // Automotive
    case carDealer = "car_dealer"
    case carRental = "car_rental"
    case carRepair = "car_repair"
    case carWash = "car_wash"
    case electricVehicleChargingStation = "electric_vehicle_charging_station"
    case gasStation = "gas_station"
    case parking = "parking"
    case restStop = "rest_stop"
    
    // Business
    case corporateOffice = "corporate_office" // *
    case farm = "farm"
    case ranch = "ranch" // *
    
    // Culture
    case artGallery = "art_gallery"
    case artStudio = "art_studio" // *
    case auditorium = "auditorium" // *
    case culturalLandmark = "cultural_landmark" // *
    case historicalPlace = "historical_place" // *
    case monument = "monument" // *
    case museum = "museum"
    case performingArtsTheater = "performing_arts_theater"
    case sculpture = "sculpture" // *
    
    // Education
    case library = "library"
    case preschool = "preschool"
    case primarySchool = "primary_school"
    case school = "school"
    case secondarySchool = "secondary_school"
    case university = "university"
    
    // Entertainment and Recreation
    case adventureSportsCenter = "adventure_sports_center" // *
    case amphitheatre = "amphitheatre" // *
    case amusementCenter = "amusement_center"
    case amusementPark = "amusement_park"
    case aquarium = "aquarium"
    case banquetHall = "banquet_hall"
    case barbecueArea = "barbecue_area" // *
    case botanicalGarden = "botanical_garden" // *
    case bowlingAlley = "bowling_alley"
    case casino = "casino"
    case childrensCamp = "childrens_camp" // *
    case comedyClub = "comedy_club" // *
    case communityCenter = "community_center"
    case concertHall = "concert_hall" // *
    case conventionCenter = "convention_center"
    case culturalCenter = "cultural_center"
    case cyclingPark = "cycling_park" // *
    case danceHall = "dance_hall" // *
    case dogPark = "dog_park"
    case eventVenue = "event_venue"
    case ferrisWheel = "ferris_wheel" // *
    case garden = "garden" // *
    case hikingArea = "hiking_area" // *
    case historicalLandmark = "historical_landmark"
    case internetCafe = "internet_cafe" // *
    case karaoke = "karaoke" // *
    case marina = "marina"
    case movieRental = "movie_rental"
    case movieTheater = "movie_theater"
    case nationalPark = "national_park"
    case nightClub = "night_club"
    case observationDeck = "observation_deck" // *
    case offRoadingArea = "off_roading_area" // *
    case operaHouse = "opera_house" // *
    case park = "park"
    case philharmonicHall = "philharmonic_hall" // *
    case picnicGround = "picnic_ground" // *
    case planetarium = "planetarium" // *
    case plaza = "plaza" // *
    case rollerCoaster = "roller_coaster" // *
    case skateboardPark = "skateboard_park" // *
    case statePark = "state_park" // *
    case touristAttraction = "tourist_attraction"
    case videoArcade = "video_arcade" // *
    case visitorCenter = "visitor_center"
    case waterPark = "water_park" // *
    case weddingVenue = "wedding_venue"
    case wildlifePark = "wildlife_park" // *
    case wildlifeRefuge = "wildlife_refuge" // *
    case zoo = "zoo"
    
    // Facilities
    case publicBath = "public_bath" // *
    case publicBathroom = "public_bathroom" // *
    case stable = "stable" // *
    
    // Finance
    case accounting = "accounting"
    case atm = "atm"
    case bank = "bank"
    
    // Food and Drink
    case acaiShop = "acai_shop" // *
    case afghaniRestaurant = "afghani_restaurant" // *
    case africanRestaurant = "african_restaurant" // *
    case americanRestaurant = "american_restaurant"
    case asianRestaurant = "asian_restaurant" // *
    case bagelShop = "bagel_shop" // *
    case bakery = "bakery"
    case bar = "bar"
    case barAndGrill = "bar_and_grill" // *
    case barbecueRestaurant = "barbecue_restaurant"
    case brazilianRestaurant = "brazilian_restaurant"
    case breakfastRestaurant = "breakfast_restaurant"
    case brunchRestaurant = "brunch_restaurant"
    case buffetRestaurant = "buffet_restaurant" // *
    case cafe = "cafe"
    case cafeteria = "cafeteria" // *
    case candyStore = "candy_store" // *
    case catCafe = "cat_cafe" // *
    case chineseRestaurant = "chinese_restaurant"
    case chocolateFactory = "chocolate_factory" // *
    case chocolateShop = "chocolate_shop" // *
    case coffeeShop = "coffee_shop"
    case confectionery = "confectionery" // *
    case deli = "deli" // *
    case dessertRestaurant = "dessert_restaurant" // *
    case dessertShop = "dessert_shop" // *
    case diner = "diner" // *
    case dogCafe = "dog_cafe" // *
    case donutShop = "donut_shop" // *
    case fastFoodRestaurant = "fast_food_restaurant"
    case fineDiningRestaurant = "fine_dining_restaurant" // *
    case foodCourt = "food_court" // *
    case frenchRestaurant = "french_restaurant"
    case greekRestaurant = "greek_restaurant"
    case hamburgerRestaurant = "hamburger_restaurant"
    case iceCreamShop = "ice_cream_shop"
    case indianRestaurant = "indian_restaurant"
    case indonesianRestaurant = "indonesian_restaurant"
    case italianRestaurant = "italian_restaurant"
    case japaneseRestaurant = "japanese_restaurant"
    case juiceShop = "juice_shop" // *
    case koreanRestaurant = "korean_restaurant" // *
    case lebaneseRestaurant = "lebanese_restaurant"
    case mealDelivery = "meal_delivery"
    case mealTakeaway = "meal_takeaway"
    case mediterraneanRestaurant = "mediterranean_restaurant"
    case mexicanRestaurant = "mexican_restaurant"
    case middleEasternRestaurant = "middle_eastern_restaurant"
    case pizzaRestaurant = "pizza_restaurant"
    case pub = "pub" // *
    case ramenRestaurant = "ramen_restaurant"
    case restaurant = "restaurant"
    case sandwichShop = "sandwich_shop"
    case seafoodRestaurant = "seafood_restaurant"
    case spanishRestaurant = "spanish_restaurant"
    case steakHouse = "steak_house"
    case sushiRestaurant = "sushi_restaurant"
    case teaHouse = "tea_house" // *
    case thaiRestaurant = "thai_restaurant"
    case turkishRestaurant = "turkish_restaurant"
    case veganRestaurant = "vegan_restaurant"
    case vegetarianRestaurant = "vegetarian_restaurant"
    case vietnameseRestaurant = "vietnamese_restaurant"
    case wineBar = "wine_bar" // *
    
    // Geographical Areas
    case administrativeAreaLevel1 = "administrative_area_level_1"
    case administrativeAreaLevel2 = "administrative_area_level_2"
    case country = "country"
    case locality = "locality"
    case postalCode = "postal_code"
    case schoolDistrict = "school_district"
    
    // Government
    case cityHall = "city_hall"
    case courthouse = "courthouse"
    case embassy = "embassy"
    case fireStation = "fire_station"
    case governmentOffice = "government_office" // *
    case localGovernmentOffice = "local_government_office"
    case neighborhoodPoliceStation = "neighborhood_police_station" // Japan only
    case police = "police"
    case postOffice = "post_office"
    
    // Health and Wellness
    case chiropractor = "chiropractor" // *
    case dentalClinic = "dental_clinic"
    case dentist = "dentist"
    case doctor = "doctor"
    case drugstore = "drugstore"
    case hospital = "hospital"
    case massage = "massage" // *
    case medicalLab = "medical_lab" // *
    case pharmacy = "pharmacy"
    case physiotherapist = "physiotherapist"
    case sauna = "sauna" // *
    case skinCareClinic = "skin_care_clinic" // *
    case spa = "spa"
    case tanningStudio = "tanning_studio" // *
    case wellnessCenter = "wellness_center" // *
    case yogaStudio = "yoga_studio" // *
    
    // Housing
    case apartmentBuilding = "apartment_building" // *
    case apartmentComplex = "apartment_complex" // *
    case condominiumComplex = "condominium_complex" // *
    case housingComplex = "housing_complex" // *
    
    // Lodging
    case bedAndBreakfast = "bed_and_breakfast"
    case budgetJapaneseInn = "budget_japanese_inn" // *
    case campground = "campground"
    case campingCabin = "camping_cabin"
    case cottage = "cottage"
    case extendedStayHotel = "extended_stay_hotel"
    case farmstay = "farmstay"
    case guestHouse = "guest_house"
    case hostel = "hostel" // *
    case hotel = "hotel" // *
    case inn = "inn" // *
    case japaneseInn = "japanese_inn" // *
    case lodging = "lodging"
    case mobileHomePark = "mobile_home_park" // *
    case motel = "motel"
    case privateGuestRoom = "private_guest_room"
    case resortHotel = "resort_hotel"
    case rvPark = "rv_park"
    
    // Natural Features
    case beach = "beach" // *
    
    // Places of Worship
    case church = "church"
    case hinduTemple = "hindu_temple"
    case mosque = "mosque"
    case synagogue = "synagogue"
    
    // Services
    case astrologer = "astrologer" // *
    case barberShop = "barber_shop"
    case beautician = "beautician" // *
    case beautySalon = "beauty_salon"
    case bodyArtService = "body_art_service" // *
    case cateringService = "catering_service" // *
    case cemetery = "cemetery"
    case childCareAgency = "child_care_agency"
    case consultant = "consultant"
    case courierService = "courier_service"
    case electrician = "electrician"
    case florist = "florist"
    case foodDelivery = "food_delivery" // *
    case footCare = "foot_care" // *
    case funeralHome = "funeral_home"
    case hairCare = "hair_care"
    case hairSalon = "hair_salon"
    case insuranceAgency = "insurance_agency"
    case laundry = "laundry" // *
    case lawyer = "lawyer"
    case locksmith = "locksmith"
    case makeupArtist = "makeup_artist" // *
    case movingCompany = "moving_company"
    case nailSalon = "nail_salon" // *
    case painter = "painter"
    case plumber = "plumber"
    case psychic = "psychic" // *
    case realEstateAgency = "real_estate_agency"
    case roofingContractor = "roofing_contractor"
    case storage = "storage"
    case summerCampOrganizer = "summer_camp_organizer" // *
    case tailor = "tailor"
    case telecommunicationsServiceProvider = "telecommunications_service_provider"
    case tourAgency = "tour_agency" // *
    case touristInformationCenter = "tourist_information_center" // *
    case travelAgency = "travel_agency"
    case veterinaryCare = "veterinary_care"
    
    // Shopping
    case asianGroceryStore = "asian_grocery_store" // *
    case autoPartsStore = "auto_parts_store"
    case bicycleStore = "bicycle_store"
    case bookStore = "book_store"
    case butcherShop = "butcher_shop" // *
    case cellPhoneStore = "cell_phone_store"
    case clothingStore = "clothing_store"
    case convenienceStore = "convenience_store"
    case departmentStore = "department_store"
    case discountStore = "discount_store"
    case electronicsStore = "electronics_store"
    case foodStore = "food_store" // *
    case furnitureStore = "furniture_store"
    case giftShop = "gift_shop"
    case groceryStore = "grocery_store"
    case hardwareStore = "hardware_store"
    case homeGoodsStore = "home_goods_store"
    case homeImprovementStore = "home_improvement_store"
    case jewelryStore = "jewelry_store"
    case liquorStore = "liquor_store"
    case market = "market"
    case petStore = "pet_store"
    case shoeStore = "shoe_store"
    case shoppingMall = "shopping_mall"
    case sportingGoodsStore = "sporting_goods_store"
    case store = "store"
    case supermarket = "supermarket"
    case warehouseStore = "warehouse_store" // *
    case wholesaler = "wholesaler"
    
    // Sports
    case arena = "arena" // *
    case athleticField = "athletic_field"
    case fishingCharter = "fishing_charter" // *
    case fishingPond = "fishing_pond" // *
    case fitnessCenter = "fitness_center"
    case golfCourse = "golf_course"
    case gym = "gym"
    case iceSkatingRink = "ice_skating_rink" // *
    case playground = "playground" // *
    case skiResort = "ski_resort"
    case sportsActivityLocation = "sports_activity_location" // *
    case sportsClub = "sports_club"
    case sportsCoaching = "sports_coaching" // *
    case sportsComplex = "sports_complex"
    case stadium = "stadium"
    case swimmingPool = "swimming_pool"
    
    // Transportation
    case airport = "airport"
    case airstrip = "airstrip" // *
    case busStation = "bus_station"
    case busStop = "bus_stop"
    case ferryTerminal = "ferry_terminal"
    case heliport = "heliport"
    case internationalAirport = "international_airport" // *
    case lightRailStation = "light_rail_station"
    case parkAndRide = "park_and_ride" // *
    case subwayStation = "subway_station"
    case taxiStand = "taxi_stand"
    case trainStation = "train_station"
    case transitDepot = "transit_depot"
    case transitStation = "transit_station"
    case truckStop = "truck_stop"
}

// MARK: - Convenience Extensions
extension GoogleMapsPlaceType {
    /// Human-readable display name for the place type
    var displayName: String {
        return rawValue.replacingOccurrences(of: "_", with: " ").capitalized
    }
    
    /// Categories for grouping place types
    var category: PlaceTypeCategory {
        switch self {
        case .carDealer, .carRental, .carRepair, .carWash, .electricVehicleChargingStation, .gasStation, .parking, .restStop:
            return .automotive
        case .corporateOffice, .farm, .ranch:
            return .business
        case .artGallery, .artStudio, .auditorium, .culturalLandmark, .historicalPlace, .monument, .museum, .performingArtsTheater, .sculpture:
            return .culture
        case .library, .preschool, .primarySchool, .school, .secondarySchool, .university:
            return .education
        case .adventureSportsCenter, .amphitheatre, .amusementCenter, .amusementPark, .aquarium, .banquetHall, .barbecueArea, .botanicalGarden, .bowlingAlley, .casino, .childrensCamp, .comedyClub, .communityCenter, .concertHall, .conventionCenter, .culturalCenter, .cyclingPark, .danceHall, .dogPark, .eventVenue, .ferrisWheel, .garden, .hikingArea, .historicalLandmark, .internetCafe, .karaoke, .marina, .movieRental, .movieTheater, .nationalPark, .nightClub, .observationDeck, .offRoadingArea, .operaHouse, .park, .philharmonicHall, .picnicGround, .planetarium, .plaza, .rollerCoaster, .skateboardPark, .statePark, .touristAttraction, .videoArcade, .visitorCenter, .waterPark, .weddingVenue, .wildlifePark, .wildlifeRefuge, .zoo:
            return .entertainmentAndRecreation
        case .publicBath, .publicBathroom, .stable:
            return .facilities
        case .accounting, .atm, .bank:
            return .finance
        case .acaiShop, .afghaniRestaurant, .africanRestaurant, .americanRestaurant, .asianRestaurant, .bagelShop, .bakery, .bar, .barAndGrill, .barbecueRestaurant, .brazilianRestaurant, .breakfastRestaurant, .brunchRestaurant, .buffetRestaurant, .cafe, .cafeteria, .candyStore, .catCafe, .chineseRestaurant, .chocolateFactory, .chocolateShop, .coffeeShop, .confectionery, .deli, .dessertRestaurant, .dessertShop, .diner, .dogCafe, .donutShop, .fastFoodRestaurant, .fineDiningRestaurant, .foodCourt, .frenchRestaurant, .greekRestaurant, .hamburgerRestaurant, .iceCreamShop, .indianRestaurant, .indonesianRestaurant, .italianRestaurant, .japaneseRestaurant, .juiceShop, .koreanRestaurant, .lebaneseRestaurant, .mealDelivery, .mealTakeaway, .mediterraneanRestaurant, .mexicanRestaurant, .middleEasternRestaurant, .pizzaRestaurant, .pub, .ramenRestaurant, .restaurant, .sandwichShop, .seafoodRestaurant, .spanishRestaurant, .steakHouse, .sushiRestaurant, .teaHouse, .thaiRestaurant, .turkishRestaurant, .veganRestaurant, .vegetarianRestaurant, .vietnameseRestaurant, .wineBar:
            return .foodAndDrink
        case .administrativeAreaLevel1, .administrativeAreaLevel2, .country, .locality, .postalCode, .schoolDistrict:
            return .geographicalAreas
        case .cityHall, .courthouse, .embassy, .fireStation, .governmentOffice, .localGovernmentOffice, .neighborhoodPoliceStation, .police, .postOffice:
            return .government
        case .chiropractor, .dentalClinic, .dentist, .doctor, .drugstore, .hospital, .massage, .medicalLab, .pharmacy, .physiotherapist, .sauna, .skinCareClinic, .spa, .tanningStudio, .wellnessCenter, .yogaStudio:
            return .healthAndWellness
        case .apartmentBuilding, .apartmentComplex, .condominiumComplex, .housingComplex:
            return .housing
        case .bedAndBreakfast, .budgetJapaneseInn, .campground, .campingCabin, .cottage, .extendedStayHotel, .farmstay, .guestHouse, .hostel, .hotel, .inn, .japaneseInn, .lodging, .mobileHomePark, .motel, .privateGuestRoom, .resortHotel, .rvPark:
            return .lodging
        case .beach:
            return .naturalFeatures
        case .church, .hinduTemple, .mosque, .synagogue:
            return .placesOfWorship
        case .astrologer, .barberShop, .beautician, .beautySalon, .bodyArtService, .cateringService, .cemetery, .childCareAgency, .consultant, .courierService, .electrician, .florist, .foodDelivery, .footCare, .funeralHome, .hairCare, .hairSalon, .insuranceAgency, .laundry, .lawyer, .locksmith, .makeupArtist, .movingCompany, .nailSalon, .painter, .plumber, .psychic, .realEstateAgency, .roofingContractor, .storage, .summerCampOrganizer, .tailor, .telecommunicationsServiceProvider, .tourAgency, .touristInformationCenter, .travelAgency, .veterinaryCare:
            return .services
        case .asianGroceryStore, .autoPartsStore, .bicycleStore, .bookStore, .butcherShop, .cellPhoneStore, .clothingStore, .convenienceStore, .departmentStore, .discountStore, .electronicsStore, .foodStore, .furnitureStore, .giftShop, .groceryStore, .hardwareStore, .homeGoodsStore, .homeImprovementStore, .jewelryStore, .liquorStore, .market, .petStore, .shoeStore, .shoppingMall, .sportingGoodsStore, .store, .supermarket, .warehouseStore, .wholesaler:
            return .shopping
        case .arena, .athleticField, .fishingCharter, .fishingPond, .fitnessCenter, .golfCourse, .gym, .iceSkatingRink, .playground, .skiResort, .sportsActivityLocation, .sportsClub, .sportsCoaching, .sportsComplex, .stadium, .swimmingPool:
            return .sports
        case .airport, .airstrip, .busStation, .busStop, .ferryTerminal, .heliport, .internationalAirport, .lightRailStation, .parkAndRide, .subwayStation, .taxiStand, .trainStation, .transitDepot, .transitStation, .truckStop:
            return .transportation
        }
    }
}

@Generable
enum PlaceTypeCategory: String, CaseIterable {
    case automotive = "Automotive"
    case business = "Business"
    case culture = "Culture"
    case education = "Education"
    case entertainmentAndRecreation = "Entertainment and Recreation"
    case facilities = "Facilities"
    case finance = "Finance"
    case foodAndDrink = "Food and Drink"
    case geographicalAreas = "Geographical Areas"
    case government = "Government"
    case healthAndWellness = "Health and Wellness"
    case housing = "Housing"
    case lodging = "Lodging"
    case naturalFeatures = "Natural Features"
    case placesOfWorship = "Places of Worship"
    case services = "Services"
    case shopping = "Shopping"
    case sports = "Sports"
    case transportation = "Transportation"
}

