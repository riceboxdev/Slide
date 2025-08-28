//
//  Business.swift
//  Slide
//
//  Created by Nick Rogers on 7/29/25.
//


import Foundation
import CoreLocation

// MARK: - Business Model
struct Business: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String?
    let address: BusinessAddress
    let location: CLLocationCoordinate2D
    let phone: String?
    let website: String?
    let email: String?
    let avatar: String?
    
    // Category Information
    let primaryCategory: BusinessCategory
    let subCategory: BusinessSubCategory
    let ethnicCuisineType: EthnicCuisineType?
    
    // Business Details
    let priceRange: PriceRange
    let rating: Double
    let reviewCount: Int
    let images: [String] // URLs to images
    let hours: [DayOfWeek: BusinessHours]
    
    // Meta Tags
    let tags: Set<BusinessTag>
    
    // Social & Discovery
    let instagramHandle: String?
    let isVerified: Bool
    let featuredUntil: Date? // For promoted businesses
    
    // Timestamps
    let createdAt: Date
    let updatedAt: Date
    
    init(id: UUID = UUID(), name: String, description: String? = nil, address: BusinessAddress, location: CLLocationCoordinate2D, phone: String? = nil, website: String? = nil, email: String? = nil, avatar: String? = nil, primaryCategory: BusinessCategory, subCategory: BusinessSubCategory, ethnicCuisineType: EthnicCuisineType? = nil, priceRange: PriceRange, rating: Double = 0.0, reviewCount: Int = 0, images: [String] = [], hours: [DayOfWeek: BusinessHours] = [:], tags: Set<BusinessTag> = [], instagramHandle: String? = nil, isVerified: Bool = false, featuredUntil: Date? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.address = address
        self.location = location
        self.phone = phone
        self.website = website
        self.email = email
        self.avatar = avatar
        self.primaryCategory = primaryCategory
        self.subCategory = subCategory
        self.ethnicCuisineType = ethnicCuisineType
        self.priceRange = priceRange
        self.rating = rating
        self.reviewCount = reviewCount
        self.images = images
        self.hours = hours
        self.tags = tags
        self.instagramHandle = instagramHandle
        self.isVerified = isVerified
        self.featuredUntil = featuredUntil
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Address
struct BusinessAddress: Codable {
    let street: String
    let city: String
    let state: String
    let zipCode: String
    let country: String
    
    var formatted: String {
        "\(street), \(city), \(state) \(zipCode)"
    }
}

// MARK: - Business Hours
struct BusinessHours: Codable {
    let openTime: String // "HH:mm" format
    let closeTime: String // "HH:mm" format
    let isClosed: Bool
    
    init(openTime: String, closeTime: String) {
        self.openTime = openTime
        self.closeTime = closeTime
        self.isClosed = false
    }
    
    init(closed: Bool) {
        self.openTime = ""
        self.closeTime = ""
        self.isClosed = closed
    }
}

// MARK: - Enums
enum DayOfWeek: String, CaseIterable, Codable {
    case monday, tuesday, wednesday, thursday, friday, saturday, sunday
    
    var displayName: String {
        rawValue.capitalized
    }
}

enum PriceRange: String, CaseIterable, Codable {
    case budget = "$"
    case moderate = "$$"
    case expensive = "$$$"
    case luxury = "$$$$"
}

// MARK: - Primary Categories
enum BusinessCategory: String, CaseIterable, Codable {
    case foodAndDrink = "food_and_drink"
    case nightlifeAndEntertainment = "nightlife_and_entertainment"
    case lifestyleAndVices = "lifestyle_and_vices"
    case daytimeToNight = "daytime_to_night"
    
    var displayName: String {
        switch self {
        case .foodAndDrink:
            return "Food & Drink"
        case .nightlifeAndEntertainment:
            return "Nightlife & Entertainment"
        case .lifestyleAndVices:
            return "Lifestyle & Vices"
        case .daytimeToNight:
            return "Daytime-to-Night Spots"
        }
    }
    
    var displayNameWithBreaks: String {
        switch self {
        case .foodAndDrink:
            return "Food \n& Drink"
        case .nightlifeAndEntertainment:
            return "Nightlife \n& Entertainment"
        case .lifestyleAndVices:
            return "Lifestyle \n& Vices"
        case .daytimeToNight:
            return "Daytime-to-Night \nSpots"
        }
    }
    
    var emoji: String {
        switch self {
        case .foodAndDrink:
            return "🍽️"
        case .nightlifeAndEntertainment:
            return "🎉"
        case .lifestyleAndVices:
            return "🌿"
        case .daytimeToNight:
            return "☀️"
        }
    }
}

// MARK: - Sub Categories
enum BusinessSubCategory: String, CaseIterable, Codable {
    // Food & Drink - Restaurants
    case cafe, fineDining, casualDining, fastFood, foodTruck, foodTruckPark, diner, buffet, ethnicCuisine
    
    // Food & Drink - Bars & Alcohol
    case bar, sportsBar, diveBar, cocktailBar, wineBar, brewery, distillery, liquorStore
    
    // Food & Drink - Cafés & Desserts
    case coffeeShop, dessertSpot
    
    // Food & Drink - Late Night Eats
    case twentyFourHourSpots, afterHoursFood
    
    // Nightlife & Entertainment - Clubs & Lounges
    case nightclub, lounge, hookahLounge, rooftopBar
    
    // Nightlife & Entertainment - Live Entertainment
    case comedyClub, liveMusicVenue, karaokeBar, openMicSpot
    
    // Nightlife & Entertainment - Alternative Entertainment
    case arcadeBar, axeThrowing, escapeRoom, miniGolf
    
    // Lifestyle & Vices - Cannabis
    case dispensary, cbdStore
    
    // Lifestyle & Vices - Smoke/Vape
    case smokeShop, vapeShop
    
    // Lifestyle & Vices - Adult Stores
    case adultStore
    
    // Daytime-to-Night
    case rooftopSpot, breweryDayNight, beachBar, parkEvents
    
    var displayName: String {
        switch self {
        case .cafe: return "Cafe"
        case .fineDining: return "Fine Dining"
        case .casualDining: return "Casual Dining"
        case .fastFood: return "Fast Food"
        case .foodTruck: return "Food Truck"
        case .foodTruckPark: return "Food Truck Park"
        case .diner: return "Diner"
        case .buffet: return "Buffet"
        case .ethnicCuisine: return "Ethnic Cuisine"
        case .bar: return "Bar"
        case .sportsBar: return "Sports Bar"
        case .diveBar: return "Dive Bar"
        case .cocktailBar: return "Cocktail Bar"
        case .wineBar: return "Wine Bar"
        case .brewery: return "Brewery"
        case .distillery: return "Distillery"
        case .liquorStore: return "Liquor Store"
        case .coffeeShop: return "Coffee Shop"
        case .dessertSpot: return "Dessert Spot"
        case .twentyFourHourSpots: return "24-Hour Spots"
        case .afterHoursFood: return "After-Hours Food"
        case .nightclub: return "Nightclub"
        case .lounge: return "Lounge"
        case .hookahLounge: return "Hookah Lounge"
        case .rooftopBar: return "Rooftop Bar"
        case .comedyClub: return "Comedy Club"
        case .liveMusicVenue: return "Live Music Venue"
        case .karaokeBar: return "Karaoke Bar"
        case .openMicSpot: return "Open Mic Spot"
        case .arcadeBar: return "Arcade Bar"
        case .axeThrowing: return "Axe Throwing"
        case .escapeRoom: return "Escape Room"
        case .miniGolf: return "Mini Golf"
        case .dispensary: return "Dispensary"
        case .cbdStore: return "CBD Store"
        case .smokeShop: return "Smoke Shop"
        case .vapeShop: return "Vape Shop"
        case .adultStore: return "Adult Store"
        case .rooftopSpot: return "Rooftop Spot"
        case .breweryDayNight: return "Brewery"
        case .beachBar: return "Beach Bar"
        case .parkEvents: return "Park Events"
        }
    }
    
    var parentCategory: BusinessCategory {
        switch self {
        case .cafe, .fineDining, .casualDining, .fastFood, .foodTruck, .foodTruckPark, .diner, .buffet, .ethnicCuisine,
             .bar, .sportsBar, .diveBar, .cocktailBar, .wineBar, .brewery, .distillery, .liquorStore,
             .coffeeShop, .dessertSpot, .twentyFourHourSpots, .afterHoursFood:
            return .foodAndDrink
        case .nightclub, .lounge, .hookahLounge, .rooftopBar, .comedyClub, .liveMusicVenue, .karaokeBar, .openMicSpot,
             .arcadeBar, .axeThrowing, .escapeRoom, .miniGolf:
            return .nightlifeAndEntertainment
        case .dispensary, .cbdStore, .smokeShop, .vapeShop, .adultStore:
            return .lifestyleAndVices
        case .rooftopSpot, .breweryDayNight, .beachBar, .parkEvents:
            return .daytimeToNight
        }
    }
}

// MARK: - Ethnic Cuisine Types
enum EthnicCuisineType: String, CaseIterable, Codable {
    case mexican, italian, chinese, japanese, korean, thai, vietnamese, indian, mediterranean, greek, turkish, moroccan, french, spanish, german, brazilian, peruvian, ethiopian, lebanese, american, southern, cajun, caribbean, other
    
    var displayName: String {
        switch self {
        case .korean: return "Korean BBQ"
        case .other: return "Other"
        default: return rawValue.capitalized
        }
    }
}

// MARK: - Business Tags
enum BusinessTag: String, CaseIterable, Codable {
    // Hours & Availability
    case openLate, twentyFourSeven, happyHour
    
    // Atmosphere & Vibe
    case lgbtqFriendly, dressCodeRequired, casualAttire, outdoorSeating, petFriendly
    
    // Entertainment
    case liveDJ, liveMusic, danceFloor, poolTable, games, karaoke
    
    // Service & Pricing
    case freeEntry, coverCharge, bottleService, byob, valet, freeParking
    
    // Food & Drink
    case craftCocktails, localBeer, wineSelection, lateNightMenu, brunch, delivery, takeout
    
    // Special Features
    case rooftop, waterfront, historic, newlyOpened, localFavorite
    
    var displayName: String {
        switch self {
        case .openLate: return "Open Late"
        case .twentyFourSeven: return "24/7"
        case .happyHour: return "Happy Hour"
        case .lgbtqFriendly: return "LGBTQ+ Friendly"
        case .dressCodeRequired: return "Dress Code Required"
        case .casualAttire: return "Casual Attire"
        case .outdoorSeating: return "Outdoor Seating"
        case .petFriendly: return "Pet Friendly"
        case .liveDJ: return "Live DJ"
        case .liveMusic: return "Live Music"
        case .danceFloor: return "Dance Floor"
        case .poolTable: return "Pool Table"
        case .games: return "Games"
        case .karaoke: return "Karaoke"
        case .freeEntry: return "Free Entry"
        case .coverCharge: return "Cover Charge"
        case .bottleService: return "Bottle Service"
        case .byob: return "BYOB"
        case .valet: return "Valet"
        case .freeParking: return "Free Parking"
        case .craftCocktails: return "Craft Cocktails"
        case .localBeer: return "Local Beer"
        case .wineSelection: return "Wine Selection"
        case .lateNightMenu: return "Late Night Menu"
        case .brunch: return "Brunch"
        case .delivery: return "Delivery"
        case .takeout: return "Takeout"
        case .rooftop: return "Rooftop"
        case .waterfront: return "Waterfront"
        case .historic: return "Historic"
        case .newlyOpened: return "Newly Opened"
        case .localFavorite: return "Local Favorite"
        }
    }
}

// MARK: - Extensions for CLLocationCoordinate2D Codable Support
extension CLLocationCoordinate2D: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        self.init(latitude: latitude, longitude: longitude)
    }
    
    private enum CodingKeys: String, CodingKey {
        case latitude, longitude
    }
}

// MARK: - Helper Extensions
extension Business {
    var isOpenNow: Bool {
        let now = Date()
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: now)
        let dayOfWeek = DayOfWeek.allCases[weekday - 2 < 0 ? 6 : weekday - 2] // Adjust for Sunday = 1
        
        guard let todayHours = hours[dayOfWeek], !todayHours.isClosed else {
            return false
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        guard let openTime = formatter.date(from: todayHours.openTime),
              let closeTime = formatter.date(from: todayHours.closeTime) else {
            return false
        }
        
        let currentTime = formatter.date(from: formatter.string(from: now))!
        
        // Handle cases where close time is after midnight
        if closeTime < openTime {
            return currentTime >= openTime || currentTime <= closeTime
        } else {
            return currentTime >= openTime && currentTime <= closeTime
        }
    }
    
    var formattedPriceRange: String {
        priceRange.rawValue
    }
    
    func hasTag(_ tag: BusinessTag) -> Bool {
        tags.contains(tag)
    }
}

// MARK: - Sample Data
extension Business {
    static let sampleData: [Business] = [
        Business(
            name: "The Rooftop Lounge",
            description: "Upscale rooftop bar with city views and craft cocktails",
            address: BusinessAddress(street: "123 Main St", city: "Austin", state: "TX", zipCode: "78701", country: "USA"),
            location: CLLocationCoordinate2D(latitude: 30.2672, longitude: -97.7431),
            phone: "(512) 555-0123",
            website: "https://rooftopLounge.com",
            avatar: "https://firebasestorage.googleapis.com/v0/b/bookd-16634.firebasestorage.app/o/472191091_609161451487468_6275483151083901705_n.jpg?alt=media&token=7f616cf0-6c3a-4f1e-9b48-28c5130f4787",
            primaryCategory: .nightlifeAndEntertainment,
            subCategory: .rooftopBar,
            priceRange: .expensive,
            rating: 4.5,
            reviewCount: 234,
            images: ["https://example.com/image1.jpg"],
            hours: [
                .monday: BusinessHours(closed: true),
                .tuesday: BusinessHours(closed: true),
                .wednesday: BusinessHours(openTime: "17:00", closeTime: "02:00"),
                .thursday: BusinessHours(openTime: "17:00", closeTime: "02:00"),
                .friday: BusinessHours(openTime: "17:00", closeTime: "03:00"),
                .saturday: BusinessHours(openTime: "17:00", closeTime: "03:00"),
                .sunday: BusinessHours(openTime: "17:00", closeTime: "01:00")
            ],
            tags: [.rooftop, .craftCocktails, .dressCodeRequired, .openLate],
            instagramHandle: "@rooftoplougeATX"
        ),
        Business(
            name: "Green Planet Dispensary",
            description: "Premium cannabis products with a sleek and modern shopping experience",
            address: BusinessAddress(street: "420 Hemp Way", city: "Denver", state: "CO", zipCode: "80202", country: "USA"),
            location: CLLocationCoordinate2D(latitude: 39.7392, longitude: -104.9903),
            phone: "(303) 420-0001",
            website: "https://greenplanetdenver.com",
            avatar: "https://images.unsplash.com/photo-1617238070957-35215b8d0e63?auto=format&fit=crop&w=800&q=80",
            primaryCategory: .nightlifeAndEntertainment,
            subCategory: .rooftopBar,
            priceRange: .moderate,
            rating: 4.8,
            reviewCount: 512,
            images: ["https://images.unsplash.com/photo-1606925797301-f8678a118b29"],
            hours: [
                .monday: BusinessHours(openTime: "10:00", closeTime: "22:00"),
                .tuesday: BusinessHours(openTime: "10:00", closeTime: "22:00"),
                .wednesday: BusinessHours(openTime: "10:00", closeTime: "22:00"),
                .thursday: BusinessHours(openTime: "10:00", closeTime: "22:00"),
                .friday: BusinessHours(openTime: "10:00", closeTime: "23:00"),
                .saturday: BusinessHours(openTime: "10:00", closeTime: "23:00"),
                .sunday: BusinessHours(openTime: "10:00", closeTime: "20:00")
            ],
            tags: [],
            instagramHandle: "@greenplanetdenver"
        ),
        Business(
            name: "Sing It! Karaoke Bar",
            description: "Late-night karaoke lounge with private rooms and signature drinks",
            address: BusinessAddress(street: "88 Harmony Ln", city: "Los Angeles", state: "CA", zipCode: "90012", country: "USA"),
            location: CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437),
            phone: "(213) 555-8899",
            website: "https://singitkaraoke.com",
            avatar: "https://images.unsplash.com/photo-1581386322338-3faff89e5da0?auto=format&fit=crop&w=800&q=80",
            primaryCategory: .nightlifeAndEntertainment,
            subCategory: .rooftopBar,
            priceRange: .moderate,
            rating: 4.3,
            reviewCount: 189,
            images: ["https://images.unsplash.com/photo-1551754654-711f3f3c5cbb"],
            hours: [
                .monday: BusinessHours(openTime: "18:00", closeTime: "02:00"),
                .tuesday: BusinessHours(openTime: "18:00", closeTime: "02:00"),
                .wednesday: BusinessHours(openTime: "18:00", closeTime: "02:00"),
                .thursday: BusinessHours(openTime: "18:00", closeTime: "02:00"),
                .friday: BusinessHours(openTime: "18:00", closeTime: "03:00"),
                .saturday: BusinessHours(openTime: "18:00", closeTime: "03:00"),
                .sunday: BusinessHours(openTime: "18:00", closeTime: "01:00")
            ],
            tags: [.byob, .bottleService],
            instagramHandle: "@singitLA"
        )
    ]
}


