//
//  AppCoordinator.swift
//  Slide
//
//  Created by Nick Rogers on 7/29/25.
//


import Combine
import Contacts
import CoreLocation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import Foundation
import MapKit
import SwiftUI
import UserNotifications

//import UserProfileManager

// MARK: - Main App Coordinator
@MainActor
class AppCoordinator: ObservableObject {

    // MARK: - Services
    @Published var isAdminMode = false
    @Published var authService: AuthService
    @Published var locationService: LocationService
    @Published var notificationService: NotificationService
    @Published var userService: UserService
    @Published var businessService: BusinessService
    //    @Published var venueService: VenueService
    @Published var imageService: ImageManager
//    @Published var networkService: NetworkService

    @Published var favoriteVenues: [Business] = []

    // MARK: - App State
    @Published var isAuthenticated = false
    @Published var currentUser: UserProfile?
    @Published var isLocationEnabled = false
    @Published var isNotificationEnabled = false
    @Published var appState: AppState = .loading

    // MARK: - Combine
    private var cancellables = Set<AnyCancellable>()
    private var proximitySubscription: AnyCancellable?

    // MARK: - User Profile Listener
    private var currentUserProfileListenerUserId: String?

    // MARK: - Initialization
    init() {
        // Initialize services
        self.authService = AuthService()
        self.locationService = LocationService()
        self.notificationService = NotificationService()
        self.userService = UserService()
        self.businessService = BusinessService()
        self.imageService = ImageManager.shared
//        self.networkService = NetworkService()

        setupBindings()
        initialize()
    }

    // MARK: - Setup
    private func setupBindings() {
        // Auth state binding
        authService.$isAuthenticated
            .filter { $0 }  // Only when true
            .sink { [weak self] _ in
                self?.onAuthenticated()
            }
            .store(in: &cancellables)

        authService.$currentUser
            .assign(to: \.currentUser, on: self)
            .store(in: &cancellables)

        // Location state binding
        locationService.$isLocationEnabled
            .assign(to: \.isLocationEnabled, on: self)
            .store(in: &cancellables)

        // Notification state binding
        notificationService.$isNotificationEnabled
            .assign(to: \.isNotificationEnabled, on: self)
            .store(in: &cancellables)

        // Listen for location updates to check proximity
        locationService.$currentLocation
            .compactMap { $0 }
            .sink { [weak self] location in
                self?.handleLocationUpdate(location)
            }
            .store(in: &cancellables)

//        venueService.$favoriteVenues
//            .receive(on: DispatchQueue.main)
//            .assign(to: \.favoriteVenues, on: self)
//            .store(in: &cancellables)

        // Update app state based on services
        Publishers.CombineLatest3(
            authService.$isAuthenticated,
            locationService.$isLocationEnabled,
            notificationService.$isNotificationEnabled
        )
        .map { [weak self] auth, location, notification in
            self?.determineAppState(
                auth: auth,
                location: location,
                notification: notification
            ) ?? .loading
        }
        .assign(to: \.appState, on: self)
        .store(in: &cancellables)
    }

    private func initialize() {
        Task {
            await authService.initialize()
            await locationService.initialize()
            await notificationService.initialize()
        }
    }

    private func onAuthenticated() {
        if let userId = Auth.auth().currentUser?.uid {
            currentUserProfileListenerUserId = userId
            userService.startUserProfileListener(userId: userId) {
                [weak self] profile in
                self?.currentUser = profile
            }
        }
        Task {
//            await businessService.listenToBusinesses(with:
//                BusinessQueryParameters(
//            )
//            await venueService.startFavoriteVenuesListener()
        }
    }

    // MARK: - App State Management
    private func determineAppState(
        auth: Bool,
        location: Bool,
        notification: Bool
    ) -> AppState {
        if !auth {
            return .unauthenticated
        }

        if !location {
            return .needsLocationPermission
        }

        if !notification {
            return .needsNotificationPermission
        }

        return .ready
    }

    // MARK: - Location Updates
    private func handleLocationUpdate(_ location: CLLocation) {
        guard let user = currentUser else { return }

        // Update user's location
        Task {
            await userService.updateUserLocation(location)
        }

        // Check for nearby venues if notifications are enabled
        if user.shouldReceiveProximityNotifications() {
            Task {
                await checkProximityNotifications(for: location)
            }
        }
    }

    private func checkProximityNotifications(for location: CLLocation) async {
           guard let user = currentUser else { return }
           
           // Cancel any existing proximity subscription
           proximitySubscription?.cancel()
           
           // Set up real-time listener for nearby businesses
           proximitySubscription = businessService.listenToBusinessesNearLocation(
               location.coordinate,
               radius: 10.0, // 10 kilometers (business service expects kilometers)
               limit: 50 // Adjust limit as needed
           )
           .receive(on: DispatchQueue.main)
           .sink(
               receiveCompletion: { completion in
                   if case .failure(let error) = completion {
                       print("Error listening to nearby businesses: \(error)")
                   }
               },
               receiveValue: { [weak self] businesses in
                   Task {
                       await self?.processNearbyBusinesses(businesses, userLocation: location)
                   }
               }
           )
       }
    
    private func processNearbyBusinesses(_ businesses: [Business], userLocation: CLLocation) async {
        for business in businesses {
            await notificationService.scheduleProximityNotification(
                for: business, // You may need to adapt this if your notification service expects a different type
                userLocation: userLocation
            )
        }
    }
    

    // MARK: - Public Methods
    // Clean up method to call when no longer needed
     func cleanupProximityListeners() {
         proximitySubscription?.cancel()
         proximitySubscription = nil
     }
    
    func requestLocationPermission() {
        locationService.requestLocationPermission()
    }

    func requestNotificationPermission() {
        Task {
            await notificationService.requestNotificationPermission()
        }
    }

    func signOut() {
        userService.stopUserProfileListener()
        currentUserProfileListenerUserId = nil
        authService.signOut()
    }
}

// MARK: - App State Enum
enum AppState {
    case loading
    case unauthenticated
    case needsLocationPermission
    case needsNotificationPermission
    case ready
}

// MARK: - Environment Key
struct AppCoordinatorKey: EnvironmentKey {
    static let defaultValue = AppCoordinator()
}

extension EnvironmentValues {
    var appCoordinator: AppCoordinator {
        get { self[AppCoordinatorKey.self] }
        set { self[AppCoordinatorKey.self] = newValue }
    }
}
