//
//  MapsCategories.swift
//  BOOKD
//
//  Created by Nick Rogers on 7/21/25.
//

import Foundation
import MapKit
import Foundation

extension MKPointOfInterestCategory {
    
    /// Returns a user-friendly display name for the point of interest category
    var displayName: String {
        switch self {
        // Arts and culture
        case .museum: return "Museum"
        case .musicVenue: return "Music Venue"
        case .theater: return "Theater"
            
        // Education
        case .library: return "Library"
        case .planetarium: return "Planetarium"
        case .school: return "School"
        case .university: return "University"
            
        // Entertainment
        case .movieTheater: return "Movie Theater"
        case .nightlife: return "Nightlife"
            
        // Health and safety
        case .fireStation: return "Fire Station"
        case .hospital: return "Hospital"
        case .pharmacy: return "Pharmacy"
        case .police: return "Police"
            
        // Historical and cultural landmarks
        case .castle: return "Castle"
        case .fortress: return "Fortress"
        case .landmark: return "Landmark"
        case .nationalMonument: return "National Monument"
            
        // Food and drink
        case .bakery: return "Bakery"
        case .brewery: return "Brewery"
        case .cafe: return "Cafe"
        case .distillery: return "Distillery"
        case .foodMarket: return "Food Market"
        case .restaurant: return "Restaurant"
        case .winery: return "Winery"
            
        // Personal services
        case .animalService: return "Animal Service"
        case .atm: return "ATM"
        case .automotiveRepair: return "Automotive Repair"
        case .bank: return "Bank"
        case .beauty: return "Beauty Service"
        case .evCharger: return "EV Charger"
        case .fitnessCenter: return "Fitness Center"
        case .laundry: return "Laundry"
        case .mailbox: return "Mailbox"
        case .postOffice: return "Post Office"
        case .restroom: return "Restroom"
        case .spa: return "Spa"
        case .store: return "Store"
            
        // Parks and recreation
        case .amusementPark: return "Amusement Park"
        case .aquarium: return "Aquarium"
        case .beach: return "Beach"
        case .campground: return "Campground"
        case .fairground: return "Fairground"
        case .marina: return "Marina"
        case .nationalPark: return "National Park"
        case .park: return "Park"
        case .rvPark: return "RV Park"
        case .zoo: return "Zoo"
            
        // Sports
        case .baseball: return "Baseball"
        case .basketball: return "Basketball"
        case .bowling: return "Bowling"
        case .goKart: return "Go-Kart"
        case .golf: return "Golf"
        case .hiking: return "Hiking"
        case .miniGolf: return "Mini Golf"
        case .rockClimbing: return "Rock Climbing"
        case .skatePark: return "Skate Park"
        case .skating: return "Skating"
        case .skiing: return "Skiing"
        case .soccer: return "Soccer"
        case .stadium: return "Stadium"
        case .tennis: return "Tennis"
        case .volleyball: return "Volleyball"
            
        // Travel
        case .airport: return "Airport"
        case .carRental: return "Car Rental"
        case .conventionCenter: return "Convention Center"
        case .gasStation: return "Gas Station"
        case .hotel: return "Hotel"
        case .parking: return "Parking"
        case .publicTransport: return "Public Transport"
            
        // Water sports
        case .fishing: return "Fishing"
        case .kayaking: return "Kayaking"
        case .surfing: return "Surfing"
        case .swimming: return "Swimming"
            
        // Fallback for unknown categories
        default:
            // Convert raw value to a more readable format
            let rawString = self.rawValue
            
            // Remove common prefixes if they exist
            let cleanedString = rawString.replacingOccurrences(of: "MKPOICategory", with: "")
                .replacingOccurrences(of: "MKPointOfInterestCategory", with: "")
            
            // Convert camelCase to Title Case with spaces
            let result = cleanedString.replacingOccurrences(of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression)
            
            // Capitalize first letter and return
            return result.prefix(1).uppercased() + result.dropFirst().lowercased()
        }
    }
    
    /// Returns the category group name for organizing categories
    var categoryGroup: String {
        switch self {
        case .museum, .musicVenue, .theater:
            return "Arts & Culture"
        case .library, .planetarium, .school, .university:
            return "Education"
        case .movieTheater, .nightlife:
            return "Entertainment"
        case .fireStation, .hospital, .pharmacy, .police:
            return "Health & Safety"
        case .castle, .fortress, .landmark, .nationalMonument:
            return "Historical & Cultural Landmarks"
        case .bakery, .brewery, .cafe, .distillery, .foodMarket, .restaurant, .winery:
            return "Food & Drink"
        case .animalService, .atm, .automotiveRepair, .bank, .beauty, .evCharger, .fitnessCenter, .laundry, .mailbox, .postOffice, .restroom, .spa, .store:
            return "Personal Services"
        case .amusementPark, .aquarium, .beach, .campground, .fairground, .marina, .nationalPark, .park, .rvPark, .zoo:
            return "Parks & Recreation"
        case .baseball, .basketball, .bowling, .goKart, .golf, .hiking, .miniGolf, .rockClimbing, .skatePark, .skating, .skiing, .soccer, .stadium, .tennis, .volleyball:
            return "Sports"
        case .airport, .carRental, .conventionCenter, .gasStation, .hotel, .parking, .publicTransport:
            return "Travel"
        case .fishing, .kayaking, .surfing, .swimming:
            return "Water Sports"
        default:
            return "Other"
        }
    }
}

// MARK: - Usage Examples

/*
// Usage in SwiftUI
Text(pointOfInterestCategory.displayName)

// Usage in a list or picker
ForEach(categories, id: \.self) { category in
    Text(category.displayName)
}

// Usage with grouping
let groupedCategories = Dictionary(grouping: allCategories) { $0.categoryGroup }
*/
