//
//  AddBusiness.swift
//  Slide
//
//  Created by Nick Rogers on 8/22/25.
//

import SwiftUI
import Combine
import CoreLocation


// MARK: - Main Autocomplete View
struct AddressAutocompleteView: View {
    @StateObject private var locationManager: LocationManager
    @ObservedObject var placesService: GooglePlacesService
    @State private var searchTask: Task<Void, Never>?
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var selectedType: GooglePlaceType = .all
    @State private var includeQueries = true
    @State private var selectedPlace: AutocompleteSuggestion?
    @State private var placeDetails: PlaceSearchDetailsResponse?
  
    
    // Replace with your actual Google Places API key
    private let apiKey = "AIzaSyARxu6sVxRQ1JV097gqRhN7ierVoODA-4A"
    
    let onPlaceSelected: (AutocompleteSuggestion) -> Void
    
    init(placesService: GooglePlacesService, onPlaceSelected: @escaping (AutocompleteSuggestion) -> Void) {
        let locationManager = LocationManager.shared
        self._locationManager = StateObject(wrappedValue: locationManager)
        self._placesService = ObservedObject(wrappedValue: placesService)
        self.onPlaceSelected = onPlaceSelected
    }
    
    var body: some View {
      
            VStack(spacing: 0) {
                // Location status indicator
//                LocationStatusView(locationManager: locationManager)
                
                Text("Start typing your business name or address and we'll get your information.")
                    .padding()
                
                // Search bar with filters
                AddressSearchBar(
                    searchText: $searchText,
                    isSearching: $isSearching,
                    selectedType: $selectedType,
                    includeQueries: $includeQueries
                )
                .padding(.top)
                
                // Search results
                Group {
                    if !placesService.suggestions.isEmpty {
                        SearchResultsView(
                            placesService: placesService,
                            searchText: $searchText,
                            selectedType: selectedType,
                            includeQueries: includeQueries,
                            onPlaceSelected: { suggestion in
                                onPlaceSelected(suggestion)
                            }
                        )
                    } else {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "magnifyingglass.circle")
                                .font(.system(size: 60))
                                .foregroundColor(.secondary)
                            
                            Text("Search for places worldwide")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("Powered by Google Places API")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        Spacer()
                    }
                }
                .transition(.opacity)
                .animation(.smooth, value: placesService.suggestions)
            }
            .navigationTitle("Search Places")
            .onChange(of: searchText) { newValue in
                performSearch()
            }
            .onChange(of: selectedType) { _ in
                performSearch()
            }
            .onChange(of: includeQueries) { _ in
                performSearch()
            }
            .onAppear {
                locationManager.requestLocationPermission()
            }
//            .sheet(isPresented: $showingPlaceDetails) {
//                if let place = selectedPlace?.placeId {
//                    PlaceDetailsView(placeId: place)
//                }
//            }
        
    }
    
    private func performSearch() {
        // Cancel previous search
        searchTask?.cancel()
        
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            placesService.suggestions = []
            return
        }
        
        searchTask = Task {
            // Debounce - wait 300ms
            try? await Task.sleep(nanoseconds: 300_000_000)
            
            // Check if task was cancelled during sleep
            guard !Task.isCancelled else { return }
            
            // Perform search
            await placesService.searchPlaces(
                query: searchText.trimmingCharacters(in: .whitespacesAndNewlines),
                placeType: selectedType,
                includeQueryPredictions: includeQueries
            )
        }
    }
}


// MARK: - Search Bar Component
struct AddressSearchBar: View {
    @Binding var searchText: String
    @Binding var isSearching: Bool
    @Binding var selectedType: GooglePlaceType
    @Binding var includeQueries: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search for places...", text: $searchText)
//                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onTapGesture {
                        isSearching = true
                    }
                
                if isSearching {
                    Button("Cancel") {
                        searchText = ""
                        isSearching = false
                        hideKeyboard()
                    }
                    .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .glassEffect(.regular.interactive())
            
            // Filters
            if isSearching {
                VStack(spacing: 8) {
                    // Type filter picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(GooglePlaceType.allCases, id: \.self) { type in
                                Button(action: {
                                    selectedType = type
                                }) {
                                    Text(type.displayName)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(selectedType == type ? Color.blue : Color.gray.opacity(0.2))
                                        .foregroundColor(selectedType == type ? .white : .primary)
                                        .cornerRadius(16)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Query predictions toggle
                    HStack {
                        Toggle("Include search suggestions", isOn: $includeQueries)
                            .font(.caption)
                        Spacer()
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Suggestion Row Component
struct SuggestionRow: View {
    let suggestion: AutocompleteSuggestion
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
//                Image(systemName: suggestion.isPlace ? "location.fill" : "magnifyingglass")
//                    .foregroundColor(suggestion.isPlace ? .blue : .orange)
//                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(suggestion.primaryText)
                        .font(.body)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    if !suggestion.secondaryText.isEmpty {
                        Text(suggestion.secondaryText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    
                    // Show distance if available
                    if let distance = suggestion.distanceMeters {
                        Text("\(Int(distance))m away")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    // Place type badge
                    Text(suggestion.primaryType)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(suggestion.isPlace ? Color.accent.opacity(0.2) : Color.orange.opacity(0.2))
                        .cornerRadius(4)
                        .foregroundColor(suggestion.isPlace ? Color.accent : .orange)
                    
                    // Place vs Query indicator
                    Text(suggestion.isPlace ? "Place" : "Query")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Location Status View
struct LocationStatusView: View {
    @ObservedObject var locationManager: LocationManager
    
    var body: some View {
        HStack {
            Image(systemName: locationStatusIcon)
                .foregroundColor(locationStatusColor)
            
            Text(locationStatusText)
                .font(.caption)
                .foregroundColor(locationStatusColor)
            
            Spacer()
            
            Image("google_logo")
                .resizable()
                .frame(width: 40, height: 13)
                .opacity(0.7)
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
        .background(Color(.systemGray6))
    }
    
    private var locationStatusIcon: String {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return locationManager.location != nil ? "location.fill" : "location"
        case .denied, .restricted:
            return "location.slash"
        default:
            return "location"
        }
    }
    
    private var locationStatusColor: Color {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return locationManager.location != nil ? .green : .orange
        case .denied, .restricted:
            return .red
        default:
            return .secondary
        }
    }
    
    private var locationStatusText: String {
        if let error = locationManager.locationError {
            return error
        }
        
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            if locationManager.location != nil {
                return "Location found - results biased nearby"
            } else {
                return "Finding location..."
            }
        case .denied, .restricted:
            return "Location access denied - showing global results"
        case .notDetermined:
            return "Requesting location permission..."
        @unknown default:
            return "Location status unknown"
        }
    }
}

// MARK: - Search Results View
struct SearchResultsView: View {
    @ObservedObject var placesService: GooglePlacesService
    @State private var searchTask: Task<Void, Never>?
    @Binding var searchText: String
    let selectedType: GooglePlaceType
    let includeQueries: Bool
    let onPlaceSelected: (AutocompleteSuggestion) -> Void
    
    var body: some View {
        VStack {
            Group {
                if let error = placesService.searchError {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                        
                        Text("Search Error")
                            .font(.headline)
                        
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Retry") {
                            performSearch()
                        }
                        .foregroundColor(.blue)
                    }
                    .padding()
                    Spacer()
                } else if placesService.suggestions.isEmpty && !searchText.isEmpty && !placesService.isSearching {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        
                        Text("No results found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Try adjusting your search or changing filters")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    Spacer()
                } else {
                    VStack {
                        Group {
                            if placesService.isSearching {
                                IndeterminateProgressBar(color: .accent)
                                    .frame(height: 6)
                            } else {
                                Rectangle().fill(.clear).frame(height: 6)
                            }
                        }
                        .padding(.top)
                        .transition(.opacity)
                        .animation(.smooth, value: placesService.isSearching)
                        VStack {
                            ForEach(placesService.suggestions) { suggestion in
                                SuggestionRow(suggestion: suggestion) {
                                    onPlaceSelected(suggestion)
                                }
                            }
                            .transition(.identity)
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .transition(.opacity)
            .animation(.smooth, value: placesService.suggestions)
        }
        .onAppear {
            if !searchText.isEmpty {
                performSearch()
            }
        }
    }
    
    private func performSearch() {
        // Cancel previous search
        searchTask?.cancel()
        
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            placesService.suggestions = []
            return
        }
        
        searchTask = Task {
            // Debounce - wait 300ms
            try? await Task.sleep(nanoseconds: 300_000_000)
            
            // Check if task was cancelled during sleep
            guard !Task.isCancelled else { return }
            
            // Perform search
            await placesService.searchPlaces(
                query: searchText.trimmingCharacters(in: .whitespacesAndNewlines),
                placeType: selectedType,
                includeQueryPredictions: includeQueries
            )
        }
    }
}

// MARK: - Place Detail View
struct PlaceDetailView: View {
    let place: AutocompleteSuggestion
    let details: PlaceSearchDetailsResponse?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(details?.name ?? place.primaryText)
                            .font(.title)
                            .bold()
                        
                        if !place.secondaryText.isEmpty {
                            Text(place.secondaryText)
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text(place.isPlace ? "Place" : "Search Query")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(place.isPlace ? Color.blue.opacity(0.2) : Color.orange.opacity(0.2))
                                .cornerRadius(8)
                                .foregroundColor(place.isPlace ? .blue : .orange)
                            
                            if let distance = place.distanceMeters {
                                Text("\(distance)m away")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    if place.isPlace {
                        Divider()
                        
                        // Place Details (if available)
                        if let details = details {
                            VStack(alignment: .leading, spacing: 12) {
                                DetailRow(title: "Address", value: details.formattedAddress)
                                
                                if let phone = details.phoneNumber {
                                    HStack {
                                        Text("Phone:")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        Button(phone) {
                                            if let url = URL(string: "tel:\(phone)") {
                                                UIApplication.shared.open(url)
                                            }
                                        }
                                        .foregroundColor(.blue)
                                        
                                        Spacer()
                                    }
                                }
                                
                                if let website = details.website {
                                    HStack {
                                        Text("Website:")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        Link("Visit Website", destination: URL(string: website)!)
                                            .foregroundColor(.blue)
                                        
                                        Spacer()
                                    }
                                }
                                
                                if let rating = details.rating {
                                    HStack {
                                        Text("Rating:")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        HStack(spacing: 2) {
                                            ForEach(0..<5) { star in
                                                Image(systemName: star < Int(rating) ? "star.fill" : "star")
                                                    .foregroundColor(.yellow)
                                                    .font(.caption)
                                            }
                                            
                                            Text("\(rating, specifier: "%.1f")")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            
                                            if let count = details.userRatingCount {
                                                Text("(\(count))")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        
                                        Spacer()
                                    }
                                }
                            }
                            
                            Divider()
                            
                            // Coordinates
                            if let location = details.location {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Location")
                                        .font(.headline)
                                    
                                    Text("Latitude: \(location.latitude, specifier: "%.6f")")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text("Longitude: \(location.longitude, specifier: "%.6f")")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        } else if let placeId = place.placeId {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Place Information")
                                    .font(.headline)
                                
                                Text("Place ID: \(placeId)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                if !place.types.isEmpty {
                                    Text("Types: \(place.types.joined(separator: ", "))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    } else {
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Search Query")
                                .font(.headline)
                            
                            Text("Use this text to perform a more detailed search:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(place.fullText)
                                .font(.body)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                            
                            Button("Search for '\(place.primaryText)'") {
                                // You could implement a text search here
                                dismiss()
                            }
                            .foregroundColor(.blue)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Detail Row Component
struct DetailRow: View {
    let title: String
    let value: String?
    
    var body: some View {
        if let value = value, !value.isEmpty {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.body)
            }
        }
    }
}

// MARK: - Helper Extension
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    AddressAutocompleteView(placesService: GooglePlacesService(apiKey: "AIzaSyARxu6sVxRQ1JV097gqRhN7ierVoODA-4A", locationManager: LocationManager.shared)) { suggestion in
        
    }
}
