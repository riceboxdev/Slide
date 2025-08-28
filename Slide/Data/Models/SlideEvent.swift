//
//  SlideEvent.swift
//  Slide
//
//  Created by Nick Rogers on 8/26/25.
//


import Foundation
import FirebaseFirestore
import Combine

// MARK: - Event Models

struct SlideEvent: Identifiable, Codable {
    var id: String?
    var businessId: String // Reference to the business that created this event
    var title: String
    var description: String?
    var shortDescription: String? // For previews/cards
    
    // Event timing
    var startDate: Timestamp
    var endDate: Timestamp
    var timezone: String // e.g., "America/New_York"
    var isAllDay: Bool
    var isRecurring: Bool
    var recurrenceRule: RecurrenceRule?
    
    // Location (can be different from business location)
    var location: EventLocation?
    var isVirtual: Bool
    var virtualLink: String? // Zoom, Teams, etc.
    
    // Event details
    var category: EventCategory
    var tags: [String]? // e.g., ["music", "outdoor", "family-friendly"]
    var ageRestriction: AgeRestriction?
    var capacity: Int? // Max attendees
    var currentAttendees: Int // Current number of attendees
    var waitlistCount: Int // Number on waitlist
    
    // Pricing
    var ticketTypes: [TicketType]?
    var isFree: Bool
    var currency: String? // "USD", "EUR", etc.
    
    // Media
    var featuredImage: String? // Firebase Storage reference
    var images: [String]? // Additional images
    var videoReference: String? // Video preview/trailer
    
    // Status and visibility
    var status: EventStatus
    var visibility: EventVisibility
    var isPublished: Bool
    var isFeatured: Bool // For promoted events
    
    // Registration/RSVP
    var requiresRegistration: Bool
    var registrationDeadline: Timestamp?
    var allowWaitlist: Bool
    var autoApproveRegistration: Bool
    
    // Contact and additional info
    var contactEmail: String?
    var contactPhone: String?
    var websiteUrl: String?
    var specialInstructions: String? // What to bring, dress code, etc.
    var cancellationPolicy: String?
    
    // Metadata
    var createdAt: Timestamp
    var updatedAt: Timestamp
    var createdBy: String? // User ID who created the event
    
    // Analytics
    var viewCount: Int
    var shareCount: Int
    var favoriteCount: Int
}

enum EventCategory: String, CaseIterable, Codable {
    case music = "music"
    case food = "food"
    case sports = "sports"
    case arts = "arts"
    case business = "business"
    case education = "education"
    case technology = "technology"
    case health = "health"
    case community = "community"
    case entertainment = "entertainment"
    case shopping = "shopping"
    case family = "family"
    case nightlife = "nightlife"
    case outdoor = "outdoor"
    case spiritual = "spiritual"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .music: return "Music"
        case .food: return "Food & Drink"
        case .sports: return "Sports & Fitness"
        case .arts: return "Arts & Culture"
        case .business: return "Business & Networking"
        case .education: return "Education"
        case .technology: return "Technology"
        case .health: return "Health & Wellness"
        case .community: return "Community"
        case .entertainment: return "Entertainment"
        case .shopping: return "Shopping"
        case .family: return "Family"
        case .nightlife: return "Nightlife"
        case .outdoor: return "Outdoor Activities"
        case .spiritual: return "Spiritual"
        case .other: return "Other"
        }
    }
}

enum EventStatus: String, Codable {
    case draft = "draft"
    case published = "published"
    case cancelled = "cancelled"
    case postponed = "postponed"
    case completed = "completed"
    case soldOut = "sold_out"
}

enum EventVisibility: String, Codable {
    case public_ = "public" // Public to everyone
    case unlisted = "unlisted" // Only accessible via direct link
    case private_ = "private" // Invitation only
    case membersOnly = "members_only" // Only for business followers/members
}

struct EventLocation: Codable {
    var name: String? // Venue name
    var address: String
    var city: String?
    var state: String?
    var zipCode: String?
    var country: String?
    var coordinates: GeoPoint?
    var placeId: String? // Google Places ID
    var instructions: String? // Special location instructions
}

struct AgeRestriction: Codable {
    var minimumAge: Int?
    var maximumAge: Int?
    var requiresParent: Bool // For minors
    var description: String? // e.g., "21+ with valid ID"
}

struct TicketType: Identifiable, Codable {
    var id: String?
    var name: String // "General Admission", "VIP", "Early Bird"
    var description: String?
    var price: Double
    var currency: String
    var quantity: Int? // Total available
    var sold: Int // Number sold
    var saleStartDate: Timestamp?
    var saleEndDate: Timestamp?
    var isActive: Bool
    var perks: [String]? // What's included with this ticket
}

struct RecurrenceRule: Codable {
    var frequency: RecurrenceFrequency
    var interval: Int // Every X days/weeks/months
    var daysOfWeek: [Int]? // 1-7 (Sunday-Saturday)
    var dayOfMonth: Int? // For monthly events
    var endDate: Timestamp? // When recurrence stops
    var occurrenceCount: Int? // Number of occurrences
}

enum RecurrenceFrequency: String, Codable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case yearly = "yearly"
}

// MARK: - Event Registration/RSVP

struct EventRegistration: Identifiable, Codable {
    var id: String?
    var eventId: String
    var businessId: String
    var userId: String
    var userEmail: String
    var userName: String?
    var userPhone: String?
    
    var ticketTypeId: String?
    var quantity: Int
    var totalAmount: Double?
    var currency: String?
    
    var status: RegistrationStatus
    var registrationDate: Timestamp
    var checkedIn: Bool
    var checkInDate: Timestamp?
    
    var specialRequests: String? // Dietary restrictions, accessibility needs
    var additionalGuests: [EventGuest]?
    
    var paymentId: String? // Reference to payment/transaction
    var confirmationCode: String?
}

enum RegistrationStatus: String, Codable {
    case pending = "pending"
    case confirmed = "confirmed"
    case waitlisted = "waitlisted"
    case cancelled = "cancelled"
    case refunded = "refunded"
    case attended = "attended"
    case noShow = "no_show"
}

struct EventGuest: Codable {
    var name: String
    var email: String?
    var phone: String?
    var age: Int? // For age-restricted events
}

// MARK: - Firebase Service

class EventsService: ObservableObject {
    private let db = Firestore.firestore()
    private let eventsCollection = "events"
    private let registrationsCollection = "event_registrations"
    
    // MARK: - Create Event
    
    func createEvent(_ event: SlideEvent) async throws -> String {
        var eventToSave = event
        eventToSave.createdAt = Timestamp()
        eventToSave.updatedAt = Timestamp()
        eventToSave.currentAttendees = 0
        eventToSave.waitlistCount = 0
        eventToSave.viewCount = 0
        eventToSave.shareCount = 0
        eventToSave.favoriteCount = 0
        
        let docRef = try db.collection(eventsCollection).addDocument(from: eventToSave)
        return docRef.documentID
    }
    
    // MARK: - Update Event
    
    func updateEvent(_ event: SlideEvent) async throws {
        guard let eventId = event.id else {
            throw EventError.invalidEventId
        }
        
        var eventToUpdate = event
        eventToUpdate.updatedAt = Timestamp()
        
        try db.collection(eventsCollection).document(eventId).setData(from: eventToUpdate)
    }
    
    // MARK: - Fetch Events
    
    func fetchEventsForBusiness(businessId: String) async throws -> [SlideEvent] {
        let snapshot = try await db.collection(eventsCollection)
            .whereField("businessId", isEqualTo: businessId)
            .order(by: "startDate", descending: false)
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            var event = try document.data(as: SlideEvent.self)
            event.id = document.documentID
            return event
        }
    }
    
    func fetchUpcomingEvents(limit: Int = 50) async throws -> [SlideEvent] {
        let now = Timestamp()
        let snapshot = try await db.collection(eventsCollection)
            .whereField("status", isEqualTo: EventStatus.published.rawValue)
            .whereField("visibility", isEqualTo: EventVisibility.public_.rawValue)
            .whereField("startDate", isGreaterThan: now)
            .order(by: "startDate", descending: false)
            .limit(to: limit)
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            var event = try document.data(as: SlideEvent.self)
            event.id = document.documentID
            return event
        }
    }
    
    func fetchEventsByCategory(_ category: EventCategory, limit: Int = 50) async throws -> [SlideEvent] {
        let now = Timestamp()
        let snapshot = try await db.collection(eventsCollection)
            .whereField("category", isEqualTo: category.rawValue)
            .whereField("status", isEqualTo: EventStatus.published.rawValue)
            .whereField("startDate", isGreaterThan: now)
            .order(by: "startDate", descending: false)
            .limit(to: limit)
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            var event = try document.data(as: SlideEvent.self)
            event.id = document.documentID
            return event
        }
    }
    
    func searchEvents(query: String, limit: Int = 50) async throws -> [SlideEvent] {
        // Note: Firestore doesn't support full-text search natively
        // You might want to use Algolia or implement a more sophisticated search
        let snapshot = try await db.collection(eventsCollection)
            .whereField("status", isEqualTo: EventStatus.published.rawValue)
            .whereField("visibility", isEqualTo: EventVisibility.public_.rawValue)
            .limit(to: limit)
            .getDocuments()
        
        let allEvents = try snapshot.documents.compactMap { document -> SlideEvent? in
            var event = try document.data(as: SlideEvent.self)
            event.id = document.documentID
            return event
        }
        
        // Client-side filtering - consider server-side search for production
        return allEvents.filter { event in
            event.title.localizedCaseInsensitiveContains(query) ||
            event.description?.localizedCaseInsensitiveContains(query) == true ||
            event.tags?.contains { $0.localizedCaseInsensitiveContains(query) } == true
        }
    }
    
    // MARK: - Event Registration
    
    func registerForEvent(eventId: String, registration: EventRegistration) async throws -> String {
        var registrationToSave = registration
        registrationToSave.registrationDate = Timestamp()
        registrationToSave.status = .confirmed
        registrationToSave.confirmationCode = generateConfirmationCode()
        
        let docRef = try db.collection(registrationsCollection).addDocument(from: registrationToSave)
        
        // Update event attendee count
        try await updateEventAttendeeCount(eventId: eventId, change: registration.quantity)
        
        return docRef.documentID
    }
    
    func cancelRegistration(registrationId: String) async throws {
        let registrationRef = db.collection(registrationsCollection).document(registrationId)
        let registration = try await registrationRef.getDocument(as: EventRegistration.self)
        
        // Update registration status
        try await registrationRef.updateData([
            "status": RegistrationStatus.cancelled.rawValue,
            "cancelledDate": Timestamp()
        ])
        
        // Update event attendee count
        try await updateEventAttendeeCount(eventId: registration.eventId, change: -registration.quantity)
    }
    
    func fetchRegistrationsForEvent(eventId: String) async throws -> [EventRegistration] {
        let snapshot = try await db.collection(registrationsCollection)
            .whereField("eventId", isEqualTo: eventId)
            .order(by: "registrationDate", descending: true)
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            var registration = try document.data(as: EventRegistration.self)
            registration.id = document.documentID
            return registration
        }
    }
    
    // MARK: - Helper Methods
    
    private func updateEventAttendeeCount(eventId: String, change: Int) async throws {
        let eventRef = db.collection(eventsCollection).document(eventId)
        try await eventRef.updateData([
            "currentAttendees": FieldValue.increment(Int64(change))
        ])
    }
    
    private func generateConfirmationCode() -> String {
        return String(format: "%06d", Int.random(in: 100000...999999))
    }
    
    // MARK: - Delete Event
    
    func deleteEvent(eventId: String) async throws {
        // First, cancel all registrations
        let registrations = try await fetchRegistrationsForEvent(eventId: eventId)
        for registration in registrations {
            if let regId = registration.id {
                try await cancelRegistration(registrationId: regId)
            }
        }
        
        // Then delete the event
        try await db.collection(eventsCollection).document(eventId).delete()
    }
}

// MARK: - Errors

enum EventError: Error, LocalizedError {
    case invalidEventId
    case eventNotFound
    case registrationFull
    case registrationClosed
    case invalidTicketType
    case paymentRequired
    case insufficientPermissions
    
    var errorDescription: String? {
        switch self {
        case .invalidEventId:
            return "Invalid event ID"
        case .eventNotFound:
            return "Event not found"
        case .registrationFull:
            return "Event is full"
        case .registrationClosed:
            return "Registration is closed"
        case .invalidTicketType:
            return "Invalid ticket type"
        case .paymentRequired:
            return "Payment is required for this event"
        case .insufficientPermissions:
            return "You don't have permission to perform this action"
        }
    }
}

// MARK: - Extensions for Business Integration

extension SlideBusiness {
    var upcomingEventsQuery: Query {
        let db = Firestore.firestore()
        let now = Timestamp()
        
        return db.collection("events")
            .whereField("businessId", isEqualTo: self.id ?? "")
            .whereField("status", isEqualTo: EventStatus.published.rawValue)
            .whereField("startDate", isGreaterThan: now)
            .order(by: "startDate")
    }
}

// MARK: - Sample Usage

/*
// Create a new event
let newEvent = SlideEvent(
    businessId: "business123",
    title: "Live Jazz Night",
    description: "Join us for an evening of smooth jazz featuring local artists.",
    startDate: Timestamp(date: Date().addingTimeInterval(86400 * 7)), // Next week
    endDate: Timestamp(date: Date().addingTimeInterval(86400 * 7 + 3600 * 3)), // 3 hours later
    timezone: "America/New_York",
    isAllDay: false,
    isRecurring: false,
    location: EventLocation(
        name: "Main Stage",
        address: "123 Music Ave, New York, NY 10001",
        coordinates: GeoPoint(latitude: 40.7128, longitude: -74.0060)
    ),
    isVirtual: false,
    category: .music,
    tags: ["jazz", "live music", "drinks"],
    capacity: 100,
    currentAttendees: 0,
    waitlistCount: 0,
    ticketTypes: [
        TicketType(
            name: "General Admission",
            description: "Includes entry and one drink",
            price: 25.0,
            currency: "USD",
            quantity: 80,
            sold: 0,
            isActive: true
        )
    ],
    isFree: false,
    currency: "USD",
    status: .published,
    visibility: .public_,
    isPublished: true,
    requiresRegistration: true,
    allowWaitlist: true,
    autoApproveRegistration: true,
    createdAt: Timestamp(),
    updatedAt: Timestamp(),
    viewCount: 0,
    shareCount: 0,
    favoriteCount: 0
)

// Usage with EventsService
let eventsService = EventsService()
Task {
    do {
        let eventId = try await eventsService.createEvent(newEvent)
        print("Event created with ID: \(eventId)")
    } catch {
        print("Error creating event: \(error)")
    }
}
*/
