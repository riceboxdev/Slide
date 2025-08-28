//
//  SlideBusinessManager.swift
//  Slide
//
//  Created by Nick Rogers on 8/25/25.
//


import SwiftUI
import Foundation
import FirebaseFirestore
import FirebaseFirestore
import Combine

@MainActor
class SlideBusinessManager: ObservableObject {
    @Published var businesses: [SlideBusiness] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private let collection = "businesses"
    private var listener: ListenerRegistration?
    
    // MARK: - Collection Reference
    private var businessesCollection: CollectionReference {
        db.collection(collection)
    }
    
    // MARK: - CRUD Operations
    
    /// Add a new business to Firestore
    func addBusiness(_ business: SlideBusiness) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            let docRef = businessesCollection.document()
            var businessToAdd = business
            
            // Create a new business with the document ID if it doesn't have one
            if business.id == nil {
                businessToAdd = SlideBusiness(
                    id: docRef.documentID,
                    displayName: business.displayName,
                    formattedAddress: business.formattedAddress,
                    location: business.location,
                    plusCode: business.plusCode,
                    types: business.types,
                    businessStatus: business.businessStatus,
                    rating: business.rating,
                    userRatingCount: business.userRatingCount,
                    websiteUri: business.websiteUri,
                    nationalPhoneNumber: business.nationalPhoneNumber,
                    internationalPhoneNumber: business.internationalPhoneNumber,
                    addressComponents: business.addressComponents,
                    addressDescriptor: business.addressDescriptor,
                    photos: business.photos,
                    viewport: business.viewport,
                    googleMapsUri: business.googleMapsUri,
                    regularOpeningHours: business.regularOpeningHours,
                    currentOpeningHours: business.currentOpeningHours,
                    primaryType: business.primaryType,
                    primaryTypeDisplayName: business.primaryTypeDisplayName,
                    shortFormattedAddress: business.shortFormattedAddress,
                    editorialSummary: business.editorialSummary,
                    reviews: business.reviews,
                    paymentOptions: business.paymentOptions,
                    parkingOptions: business.parkingOptions,
                    accessibilityOptions: business.accessibilityOptions,
                    fuelOptions: business.fuelOptions,
                    evChargeOptions: business.evChargeOptions,
                    generativeSummary: business.generativeSummary,
                    priceLevel: business.priceLevel,
                    userRatingsTotal: business.userRatingsTotal,
                    utcOffset: business.utcOffset,
                    adrFormatAddress: business.adrFormatAddress,
                    businessStatus_: business.businessStatus_,
                    iconMaskBaseUri: business.iconMaskBaseUri,
                    iconBackgroundColor: business.iconBackgroundColor,
                    takeout: business.takeout,
                    delivery: business.delivery,
                    dineIn: business.dineIn,
                    curbsidePickup: business.curbsidePickup,
                    reservable: business.reservable,
                    servesBreakfast: business.servesBreakfast,
                    servesLunch: business.servesLunch,
                    servesDinner: business.servesDinner,
                    servesBeer: business.servesBeer,
                    servesWine: business.servesWine,
                    servesBrunch: business.servesBrunch,
                    servesVegetarianFood: business.servesVegetarianFood,
                    outdoorSeating: business.outdoorSeating,
                    liveMusic: business.liveMusic,
                    restroom: business.restroom,
                    goodForChildren: business.goodForChildren,
                    goodForGroups: business.goodForGroups,
                    allowsDogs: business.allowsDogs,
                    googleMapsLinks: business.googleMapsLinks,
                    reviewSummary: business.reviewSummary,
                    postalAddress: business.postalAddress,
                    createdAt: Timestamp(date: Date.now),
                    updatedAt: Timestamp(date: Date.now)
                )
            }
            
            try docRef.setData(from: businessToAdd)
            print("Business added with ID: \(docRef.documentID)")
        } catch {
            errorMessage = "Failed to add business: \(error.localizedDescription)"
            throw error
        }
        
        isLoading = false
    }
    
    /// Update an existing business
    func updateBusiness(_ business: SlideBusiness) async throws {
        guard let businessId = business.id else {
            throw SlideBusinessError.missingID
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try businessesCollection.document(businessId).setData(from: business)
            print("Business updated with ID: \(businessId)")
        } catch {
            errorMessage = "Failed to update business: \(error.localizedDescription)"
            throw error
        }
        
        isLoading = false
    }
    
    /// Delete a business by ID
    func deleteBusiness(withId id: String) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            try await businessesCollection.document(id).delete()
            print("Business deleted with ID: \(id)")
        } catch {
            errorMessage = "Failed to delete business: \(error.localizedDescription)"
            throw error
        }
        
        isLoading = false
    }
    
    /// Fetch a single business by ID
    func fetchBusiness(withId id: String) async throws -> SlideBusiness? {
        do {
            let document = try await businessesCollection.document(id).getDocument()
            return try document.data(as: SlideBusiness.self)
        } catch {
            errorMessage = "Failed to fetch business: \(error.localizedDescription)"
            throw error
        }
    }
    
    /// Fetch all businesses
    func fetchAllBusinesses() async throws -> [SlideBusiness] {
        isLoading = true
        errorMessage = nil
        
        do {
            let snapshot = try await businessesCollection.getDocuments()
            let fetchedBusinesses = try snapshot.documents.compactMap { document in
                try document.data(as: SlideBusiness.self)
            }
            
            businesses = fetchedBusinesses
            print("Fetched \(businesses.count) businesses")
            isLoading = false
            return fetchedBusinesses
        } catch {
            errorMessage = "Failed to fetch businesses: \(error.localizedDescription)"
            isLoading = false
            throw error
        }
    }
    
    // MARK: - Real-time Listeners
    
    /// Start listening for real-time updates to all businesses
    func startListening() {
        listener = businessesCollection.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                Task { @MainActor in
                    self.errorMessage = "Failed to listen for updates: \(error.localizedDescription)"
                }
                return
            }
            
            guard let snapshot = snapshot else { return }
            
            Task { @MainActor in
                do {
                    self.businesses = try snapshot.documents.compactMap { document in
                        try document.data(as: SlideBusiness.self)
                    }
                } catch {
                    self.errorMessage = "Failed to decode businesses: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Query Operations
    
    /// Fetch businesses by type
    func fetchBusinesses(ofType type: String) async throws -> [SlideBusiness] {
        do {
            let snapshot = try await businessesCollection
                .whereField("primaryType", isEqualTo: type)
                .getDocuments()
            
            return try snapshot.documents.compactMap { document in
                try document.data(as: SlideBusiness.self)
            }
        } catch {
            errorMessage = "Failed to fetch businesses by type: \(error.localizedDescription)"
            throw error
        }
    }
    
    /// Fetch businesses within a radius of a location
    func fetchBusinesses(near location: GeoLocation, radiusInKm: Double = 10.0) async throws -> [SlideBusiness] {
        // Note: Firestore doesn't have built-in geoqueries, so this is a simplified approach
        // For production, consider using GeoFirestore or implement proper geohashing
        
        do {
            let snapshot = try await businessesCollection.getDocuments()
            let allBusinesses = try snapshot.documents.compactMap { document in
                try document.data(as: SlideBusiness.self)
            }
            
            return allBusinesses.filter { business in
                guard let businessLocation = business.location else { return false }
                let distance = calculateDistance(
                    from: location,
                    to: businessLocation
                )
                return distance <= radiusInKm
            }
        } catch {
            errorMessage = "Failed to fetch nearby businesses: \(error.localizedDescription)"
            throw error
        }
    }
    
    /// Search businesses by name
    func searchBusinesses(byName name: String) async throws -> [SlideBusiness] {
        do {
            let snapshot = try await businessesCollection
                .whereField("displayName.text", isGreaterThanOrEqualTo: name)
                .whereField("displayName.text", isLessThan: name + "\u{f8ff}")
                .getDocuments()
            
            return try snapshot.documents.compactMap { document in
                try document.data(as: SlideBusiness.self)
            }
        } catch {
            errorMessage = "Failed to search businesses: \(error.localizedDescription)"
            throw error
        }
    }
    
    /// Fetch businesses with rating above threshold
    func fetchBusinesses(withRatingAbove rating: Double) async throws -> [SlideBusiness] {
        do {
            let snapshot = try await businessesCollection
                .whereField("rating", isGreaterThanOrEqualTo: rating)
                .getDocuments()
            
            return try snapshot.documents.compactMap { document in
                try document.data(as: SlideBusiness.self)
            }
        } catch {
            errorMessage = "Failed to fetch highly rated businesses: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Batch Operations
    
    /// Add multiple businesses in a batch
    func addBusinesses(_ businesses: [SlideBusiness]) async throws {
        let batch = db.batch()
        
        for business in businesses {
            let docRef = businessesCollection.document()
            var businessToAdd = business
            
            if business.id == nil {
                // Update with document ID - simplified for brevity
                businessToAdd = SlideBusiness(
                    id: docRef.documentID,
                    displayName: business.displayName,
                    formattedAddress: business.formattedAddress,
                    location: business.location,
                    plusCode: business.plusCode,
                    types: business.types,
                    businessStatus: business.businessStatus,
                    rating: business.rating,
                    userRatingCount: business.userRatingCount,
                    websiteUri: business.websiteUri,
                    nationalPhoneNumber: business.nationalPhoneNumber,
                    internationalPhoneNumber: business.internationalPhoneNumber,
                    addressComponents: business.addressComponents,
                    addressDescriptor: business.addressDescriptor,
                    photos: business.photos,
                    viewport: business.viewport,
                    googleMapsUri: business.googleMapsUri,
                    regularOpeningHours: business.regularOpeningHours,
                    currentOpeningHours: business.currentOpeningHours,
                    primaryType: business.primaryType,
                    primaryTypeDisplayName: business.primaryTypeDisplayName,
                    shortFormattedAddress: business.shortFormattedAddress,
                    editorialSummary: business.editorialSummary,
                    reviews: business.reviews,
                    paymentOptions: business.paymentOptions,
                    parkingOptions: business.parkingOptions,
                    accessibilityOptions: business.accessibilityOptions,
                    fuelOptions: business.fuelOptions,
                    evChargeOptions: business.evChargeOptions,
                    generativeSummary: business.generativeSummary,
                    priceLevel: business.priceLevel,
                    userRatingsTotal: business.userRatingsTotal,
                    utcOffset: business.utcOffset,
                    adrFormatAddress: business.adrFormatAddress,
                    businessStatus_: business.businessStatus_,
                    iconMaskBaseUri: business.iconMaskBaseUri,
                    iconBackgroundColor: business.iconBackgroundColor,
                    takeout: business.takeout,
                    delivery: business.delivery,
                    dineIn: business.dineIn,
                    curbsidePickup: business.curbsidePickup,
                    reservable: business.reservable,
                    servesBreakfast: business.servesBreakfast,
                    servesLunch: business.servesLunch,
                    servesDinner: business.servesDinner,
                    servesBeer: business.servesBeer,
                    servesWine: business.servesWine,
                    servesBrunch: business.servesBrunch,
                    servesVegetarianFood: business.servesVegetarianFood,
                    outdoorSeating: business.outdoorSeating,
                    liveMusic: business.liveMusic,
                    restroom: business.restroom,
                    goodForChildren: business.goodForChildren,
                    goodForGroups: business.goodForGroups,
                    allowsDogs: business.allowsDogs,
                    googleMapsLinks: business.googleMapsLinks,
                    reviewSummary: business.reviewSummary,
                    postalAddress: business.postalAddress,
                    createdAt: Timestamp(date: Date.now),
                    updatedAt: Timestamp(date: Date.now)
                )
            }
            
            do {
                try batch.setData(from: businessToAdd, forDocument: docRef)
            } catch {
                throw SlideBusinessError.batchOperationFailed(error.localizedDescription)
            }
        }
        
        try await batch.commit()
        print("Added \(businesses.count) businesses in batch")
    }
    
    // MARK: - Helper Methods
    
    private func calculateDistance(from: GeoLocation, to: GeoLocation) -> Double {
        let earthRadius = 6371.0 // Earth's radius in kilometers
        
        let lat1Rad = from.latitude * .pi / 180
        let lat2Rad = to.latitude * .pi / 180
        let deltaLatRad = (to.latitude - from.latitude) * .pi / 180
        let deltaLonRad = (to.longitude - from.longitude) * .pi / 180
        
        let a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
                cos(lat1Rad) * cos(lat2Rad) *
                sin(deltaLonRad / 2) * sin(deltaLonRad / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        
        return earthRadius * c
    }
    
    deinit {
        listener?.remove()
        listener = nil
    }
}

// MARK: - Custom Errors

enum SlideBusinessError: LocalizedError {
    case missingID
    case batchOperationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .missingID:
            return "Business ID is required for this operation"
        case .batchOperationFailed(let message):
            return "Batch operation failed: \(message)"
        }
    }
}

// MARK: - Convenience Extensions

extension SlideBusinessManager {
    /// Get businesses grouped by type
    var businessesByType: [String: [SlideBusiness]] {
        Dictionary(grouping: businesses) { business in
            business.primaryType ?? "Unknown"
        }
    }
    
    /// Get average rating of all businesses
    var averageRating: Double {
        let ratingsSum = businesses.compactMap { $0.rating }.reduce(0, +)
        let ratingsCount = businesses.compactMap { $0.rating }.count
        return ratingsCount > 0 ? ratingsSum / Double(ratingsCount) : 0.0
    }
    
    /// Get businesses count by status
    var businessStatusCounts: [String: Int] {
        Dictionary(grouping: businesses) { business in
            business.businessStatus ?? "Unknown"
        }.mapValues { $0.count }
    }
}
