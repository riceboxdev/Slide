//
//  BusinessServiceError.swift
//  Slide
//
//  Created by Nick Rogers on 7/29/25.
//


import Foundation
import FirebaseFirestore
import FirebaseFirestore
import CoreLocation
import Combine

// MARK: - Business Service Errors
enum BusinessServiceError: LocalizedError {
    case businessNotFound
    case invalidBusinessData
    case networkError(Error)
    case encodingError(Error)
    case decodingError(Error)
    case permissionDenied
    case quotaExceeded
    
    var errorDescription: String? {
        switch self {
        case .businessNotFound:
            return "Business not found"
        case .invalidBusinessData:
            return "Invalid business data provided"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Data encoding error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Data decoding error: \(error.localizedDescription)"
        case .permissionDenied:
            return "Permission denied"
        case .quotaExceeded:
            return "Quota exceeded"
        }
    }
}

// MARK: - Business Query Parameters
struct BusinessQueryParameters {
    let category: BusinessCategory?
    let subCategory: BusinessSubCategory?
    let priceRange: PriceRange?
    let tags: Set<BusinessTag>
    let isVerified: Bool?
    let radius: Double? // in kilometers
    let center: CLLocationCoordinate2D?
    let limit: Int
    let sortBy: BusinessSortOption
    
    init(category: BusinessCategory? = nil,
         subCategory: BusinessSubCategory? = nil,
         priceRange: PriceRange? = nil,
         tags: Set<BusinessTag> = [],
         isVerified: Bool? = nil,
         radius: Double? = nil,
         center: CLLocationCoordinate2D? = nil,
         limit: Int = 20,
         sortBy: BusinessSortOption = .rating) {
        self.category = category
        self.subCategory = subCategory
        self.priceRange = priceRange
        self.tags = tags
        self.isVerified = isVerified
        self.radius = radius
        self.center = center
        self.limit = limit
        self.sortBy = sortBy
    }
}

enum BusinessSortOption {
    case name
    case rating
    case reviewCount
    case createdAt
    case distance // requires center coordinate
}

// MARK: - Business Service Protocol
protocol BusinessServiceProtocol {
    func createBusiness(_ business: Business) async throws -> Business
    func updateBusiness(_ business: Business) async throws -> Business
    func deleteBusiness(id: String) async throws
    func updateBusinessRating(id: String, newRating: Double, newReviewCount: Int) async throws
    func batchUpdateBusinesses(_ businesses: [Business]) async throws
    
    // Real-time listeners
    func listenToBusiness(id: String) -> AnyPublisher<Business?, BusinessServiceError>
    func listenToBusinesses(with parameters: BusinessQueryParameters) -> AnyPublisher<[Business], BusinessServiceError>
    func listenToBusinessesByCategory(_ category: BusinessCategory, limit: Int) -> AnyPublisher<[Business], BusinessServiceError>
    func listenToBusinessesBySubCategory(_ subCategory: BusinessSubCategory, limit: Int) -> AnyPublisher<[Business], BusinessServiceError>
    func listenToBusinessesNearLocation(_ location: CLLocationCoordinate2D, radius: Double, limit: Int) -> AnyPublisher<[Business], BusinessServiceError>
    func listenToFeaturedBusinesses(limit: Int) -> AnyPublisher<[Business], BusinessServiceError>
    func listenToVerifiedBusinesses(limit: Int) -> AnyPublisher<[Business], BusinessServiceError>
    func searchBusinesses(query: String, limit: Int) -> AnyPublisher<[Business], BusinessServiceError>
}

// MARK: - Business Service Implementation
@MainActor
class BusinessService: ObservableObject, BusinessServiceProtocol {
    private let db = Firestore.firestore()
    private let collectionName = "businesses"
    private var activeListeners: [String: ListenerRegistration] = [:]
    
    deinit {
        // Clean up all listeners when service is deallocated
        Task {
            await removeAllListeners()
        }
    }
    
    // MARK: - Write Operations
    func createBusiness(_ business: Business) async throws -> Business {
        do {
            var businessToCreate = business
            businessToCreate = Business(
                id: business.id,
                name: business.name,
                description: business.description,
                address: business.address,
                location: business.location,
                phone: business.phone,
                website: business.website,
                email: business.email,
                primaryCategory: business.primaryCategory,
                subCategory: business.subCategory,
                ethnicCuisineType: business.ethnicCuisineType,
                priceRange: business.priceRange,
                rating: business.rating,
                reviewCount: business.reviewCount,
                images: business.images,
                hours: business.hours,
                tags: business.tags,
                instagramHandle: business.instagramHandle,
                isVerified: business.isVerified,
                featuredUntil: business.featuredUntil
            )
            
            try await db.collection(collectionName)
                .document(businessToCreate.id.uuidString)
                .setData(from: businessToCreate)
            
            return businessToCreate
        } catch let error as NSError {
            throw mapFirestoreError(error)
        }
    }
    
    func updateBusiness(_ business: Business) async throws -> Business {
        do {
            let businessData = try Firestore.Encoder().encode(business)
            var mutableData = businessData
            mutableData["updatedAt"] = FieldValue.serverTimestamp()
            
            try await db.collection(collectionName)
                .document(business.id.uuidString)
                .setData(mutableData, merge: false)
            
            return business
        } catch let error as NSError {
            throw mapFirestoreError(error)
        }
    }
    
    func deleteBusiness(id: String) async throws {
        do {
            try await db.collection(collectionName).document(id).delete()
        } catch let error as NSError {
            throw mapFirestoreError(error)
        }
    }
    
    func updateBusinessRating(id: String, newRating: Double, newReviewCount: Int) async throws {
        do {
            try await db.collection(collectionName).document(id).updateData([
                "rating": newRating,
                "reviewCount": newReviewCount,
                "updatedAt": FieldValue.serverTimestamp()
            ])
        } catch let error as NSError {
            throw mapFirestoreError(error)
        }
    }
    
    func batchUpdateBusinesses(_ businesses: [Business]) async throws {
        let batch = db.batch()
        
        for business in businesses {
            let docRef = db.collection(collectionName).document(business.id.uuidString)
            do {
                let businessData = try Firestore.Encoder().encode(business)
                var mutableData = businessData
                mutableData["updatedAt"] = FieldValue.serverTimestamp()
                batch.setData(mutableData, forDocument: docRef)
            } catch {
                throw BusinessServiceError.encodingError(error)
            }
        }
        
        do {
            try await batch.commit()
        } catch let error as NSError {
            throw mapFirestoreError(error)
        }
    }
    
    // MARK: - Real-time Listeners
    func listenToBusiness(id: String) -> AnyPublisher<Business?, BusinessServiceError> {
        let subject = PassthroughSubject<Business?, BusinessServiceError>()
        let listenerId = "business_\(id)"
        
        // Remove existing listener if any
        activeListeners[listenerId]?.remove()
        
        let listener = db.collection(collectionName).document(id)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    subject.send(completion: .failure(self?.mapFirestoreError(error as NSError) ?? BusinessServiceError.networkError(error)))
                    return
                }
                
                guard let document = snapshot else {
                    subject.send(nil)
                    return
                }
                
                if !document.exists {
                    subject.send(nil)
                    return
                }
                
                do {
                    let business = try document.data(as: Business.self)
                    subject.send(business)
                } catch {
                    subject.send(completion: .failure(BusinessServiceError.decodingError(error)))
                }
            }
        
        activeListeners[listenerId] = listener
        
        return subject
            .handleEvents(receiveCancel: { [weak self] in
                self?.activeListeners[listenerId]?.remove()
                self?.activeListeners.removeValue(forKey: listenerId)
            })
            .eraseToAnyPublisher()
    }
    
    func listenToBusinesses(with parameters: BusinessQueryParameters) -> AnyPublisher<[Business], BusinessServiceError> {
        let subject = PassthroughSubject<[Business], BusinessServiceError>()
        let listenerId = "businesses_\(UUID().uuidString)"
        
        var query: Query = db.collection(collectionName)
        
        // Apply filters
        if let category = parameters.category {
            query = query.whereField("primaryCategory", isEqualTo: category.rawValue)
        }
        
        if let subCategory = parameters.subCategory {
            query = query.whereField("subCategory", isEqualTo: subCategory.rawValue)
        }
        
        if let priceRange = parameters.priceRange {
            query = query.whereField("priceRange", isEqualTo: priceRange.rawValue)
        }
        
        if let isVerified = parameters.isVerified {
            query = query.whereField("isVerified", isEqualTo: isVerified)
        }
        
        // Apply sorting
        switch parameters.sortBy {
        case .name:
            query = query.order(by: "name")
        case .rating:
            query = query.order(by: "rating", descending: true)
        case .reviewCount:
            query = query.order(by: "reviewCount", descending: true)
        case .createdAt:
            query = query.order(by: "createdAt", descending: true)
        case .distance:
            query = query.order(by: "createdAt", descending: true)
        }
        
        query = query.limit(to: parameters.limit)
        
        let listener = query.addSnapshotListener { [weak self] snapshot, error in
            if let error = error {
                subject.send(completion: .failure(self?.mapFirestoreError(error as NSError) ?? BusinessServiceError.networkError(error)))
                return
            }
            
            guard let documents = snapshot?.documents else {
                subject.send([])
                return
            }
            
            do {
                var businesses = try documents.compactMap { document -> Business? in
                    try document.data(as: Business.self)
                }
                
                // Apply client-side filtering
                if !parameters.tags.isEmpty {
                    businesses = businesses.filter { business in
                        !parameters.tags.isDisjoint(with: business.tags)
                    }
                }
                
                if let center = parameters.center, let radius = parameters.radius {
                    businesses = businesses.filter { business in
                        let distance = self?.distanceBetween(center, business.location) ?? Double.greatestFiniteMagnitude
                        return distance <= radius
                    }
                    
                    if case .distance = parameters.sortBy {
                        businesses.sort { business1, business2 in
                            let distance1 = self?.distanceBetween(center, business1.location) ?? Double.greatestFiniteMagnitude
                            let distance2 = self?.distanceBetween(center, business2.location) ?? Double.greatestFiniteMagnitude
                            return distance1 < distance2
                        }
                    }
                }
                
                subject.send(businesses)
            } catch {
                subject.send(completion: .failure(BusinessServiceError.decodingError(error)))
            }
        }
        
        activeListeners[listenerId] = listener
        
        return subject
            .handleEvents(receiveCancel: { [weak self] in
                self?.activeListeners[listenerId]?.remove()
                self?.activeListeners.removeValue(forKey: listenerId)
            })
            .eraseToAnyPublisher()
    }
    
    func listenToBusinessesByCategory(_ category: BusinessCategory, limit: Int = 20) -> AnyPublisher<[Business], BusinessServiceError> {
        let parameters = BusinessQueryParameters(category: category, limit: limit, sortBy: .rating)
        return listenToBusinesses(with: parameters)
    }
    
    func listenToBusinessesBySubCategory(_ subCategory: BusinessSubCategory, limit: Int = 20) -> AnyPublisher<[Business], BusinessServiceError> {
        let parameters = BusinessQueryParameters(subCategory: subCategory, limit: limit, sortBy: .rating)
        return listenToBusinesses(with: parameters)
    }
    
    func listenToBusinessesNearLocation(_ location: CLLocationCoordinate2D, radius: Double, limit: Int = 20) -> AnyPublisher<[Business], BusinessServiceError> {
        let parameters = BusinessQueryParameters(
            radius: radius,
            center: location,
            limit: limit,
            sortBy: .distance
        )
        return listenToBusinesses(with: parameters)
    }
    
    func listenToFeaturedBusinesses(limit: Int = 20) -> AnyPublisher<[Business], BusinessServiceError> {
        let subject = PassthroughSubject<[Business], BusinessServiceError>()
        let listenerId = "featured_businesses"
        
        // Remove existing listener if any
        activeListeners[listenerId]?.remove()
        
        let query = db.collection(collectionName)
            .whereField("featuredUntil", isGreaterThan: Date())
            .order(by: "featuredUntil", descending: true)
            .limit(to: limit)
        
        let listener = query.addSnapshotListener { [weak self] snapshot, error in
            if let error = error {
                subject.send(completion: .failure(self?.mapFirestoreError(error as NSError) ?? BusinessServiceError.networkError(error)))
                return
            }
            
            guard let documents = snapshot?.documents else {
                subject.send([])
                return
            }
            
            do {
                let businesses = try documents.compactMap { document -> Business? in
                    try document.data(as: Business.self)
                }
                subject.send(businesses)
            } catch {
                subject.send(completion: .failure(BusinessServiceError.decodingError(error)))
            }
        }
        
        activeListeners[listenerId] = listener
        
        return subject
            .handleEvents(receiveCancel: { [weak self] in
                self?.activeListeners[listenerId]?.remove()
                self?.activeListeners.removeValue(forKey: listenerId)
            })
            .eraseToAnyPublisher()
    }
    
    func listenToVerifiedBusinesses(limit: Int = 20) -> AnyPublisher<[Business], BusinessServiceError> {
        let parameters = BusinessQueryParameters(isVerified: true, limit: limit, sortBy: .rating)
        return listenToBusinesses(with: parameters)
    }
    
    func searchBusinesses(query: String, limit: Int = 20) -> AnyPublisher<[Business], BusinessServiceError> {
        let subject = PassthroughSubject<[Business], BusinessServiceError>()
        let listenerId = "search_\(query.hashValue)"
        
        // Remove existing listener if any
        activeListeners[listenerId]?.remove()
        
        let searchQuery = query.lowercased()
        let firestoreQuery = db.collection(collectionName)
            .whereField("name", isGreaterThanOrEqualTo: searchQuery)
            .whereField("name", isLessThan: searchQuery + "\u{f8ff}")
            .limit(to: limit)
        
        let listener = firestoreQuery.addSnapshotListener { [weak self] snapshot, error in
            if let error = error {
                subject.send(completion: .failure(self?.mapFirestoreError(error as NSError) ?? BusinessServiceError.networkError(error)))
                return
            }
            
            guard let documents = snapshot?.documents else {
                subject.send([])
                return
            }
            
            do {
                let businesses = try documents.compactMap { document -> Business? in
                    try document.data(as: Business.self)
                }
                subject.send(businesses)
            } catch {
                subject.send(completion: .failure(BusinessServiceError.decodingError(error)))
            }
        }
        
        activeListeners[listenerId] = listener
        
        return subject
            .handleEvents(receiveCancel: { [weak self] in
                self?.activeListeners[listenerId]?.remove()
                self?.activeListeners.removeValue(forKey: listenerId)
            })
            .eraseToAnyPublisher()
    }
    
    // MARK: - Listener Management
    func removeListener(for id: String) {
        activeListeners[id]?.remove()
        activeListeners.removeValue(forKey: id)
    }
    
    func removeAllListeners() {
        activeListeners.values.forEach { $0.remove() }
        activeListeners.removeAll()
    }
    
    // MARK: - Helper Methods
    private func mapFirestoreError(_ error: NSError) -> BusinessServiceError {
        guard let firestoreError = FirestoreErrorCode(_bridgedNSError: error) else {
            return BusinessServiceError.networkError(error)
        }
        
        switch firestoreError.code {
        case .notFound:
            return BusinessServiceError.businessNotFound
        case .permissionDenied:
            return BusinessServiceError.permissionDenied
        case .resourceExhausted:
            return BusinessServiceError.quotaExceeded
        case .invalidArgument:
            return BusinessServiceError.invalidBusinessData
        default:
            return BusinessServiceError.networkError(error)
        }
    }
    
    private func distanceBetween(_ coord1: CLLocationCoordinate2D, _ coord2: CLLocationCoordinate2D) -> Double {
        let location1 = CLLocation(latitude: coord1.latitude, longitude: coord1.longitude)
        let location2 = CLLocation(latitude: coord2.latitude, longitude: coord2.longitude)
        return location1.distance(from: location2) / 1000.0 // Convert to kilometers
    }
}

// MARK: - Convenience Extensions for Tags
extension BusinessService {
    func listenToBusinesses(withTags tags: Set<BusinessTag>, limit: Int = 20) -> AnyPublisher<[Business], BusinessServiceError> {
        let parameters = BusinessQueryParameters(tags: tags, limit: limit, sortBy: .rating)
        return listenToBusinesses(with: parameters)
    }
    
    func listenToBusinesses(withTag tag: BusinessTag, limit: Int = 20) -> AnyPublisher<[Business], BusinessServiceError> {
        return listenToBusinesses(withTags: [tag], limit: limit)
    }
    
    func listenToOpenLateBusinesses(limit: Int = 20) -> AnyPublisher<[Business], BusinessServiceError> {
        return listenToBusinesses(withTag: .openLate, limit: limit)
    }
    
    func listenToTwentyFourSevenBusinesses(limit: Int = 20) -> AnyPublisher<[Business], BusinessServiceError> {
        return listenToBusinesses(withTag: .twentyFourSeven, limit: limit)
    }
    
    func listenToRooftopBusinesses(limit: Int = 20) -> AnyPublisher<[Business], BusinessServiceError> {
        return listenToBusinesses(withTag: .rooftop, limit: limit)
    }
    
    func listenToPetFriendlyBusinesses(limit: Int = 20) -> AnyPublisher<[Business], BusinessServiceError> {
        return listenToBusinesses(withTag: .petFriendly, limit: limit)
    }
}

