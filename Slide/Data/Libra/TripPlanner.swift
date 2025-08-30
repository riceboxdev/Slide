//
//  TripPlanner.swift
//  Slide
//
//  Created by Cascade on 8/29/25.
//

import Foundation
import FoundationModels
import Observation
import CoreLocation
import SwiftUI

/// An agent that uses a LanguageModelSession with a custom tool to search for places
/// based on a user’s natural language query (e.g., "tacos and margaritas").





// MARK: - Helpers
 extension LatLng {
    var clLocation: CLLocation? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocation(latitude: lat, longitude: lon)
    }
}




struct APIServiceKeys {
    static let googleMapsAPI = "AIzaSyCVZ3-wgVaPNQV2V4tuBr7ctJC4IP2FOYk"
}
