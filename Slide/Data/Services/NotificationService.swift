//
//  NotificationService.swift
//  Slide
//
//  Created by Nick Rogers on 7/29/25.
//


import Combine
import CoreLocation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import Foundation
import MapKit
import SwiftUI
import UserNotifications

// MARK: - Notification Service
@MainActor
class NotificationService: ObservableObject {
    @Published var isNotificationEnabled = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var error: NotificationError?

    private let notificationCenter = UNUserNotificationCenter.current()
    private var cancellables = Set<AnyCancellable>()

    func initialize() async {
        let settings = await notificationCenter.notificationSettings()
        authorizationStatus = settings.authorizationStatus
        updateNotificationEnabled()
    }

    func requestNotificationPermission() async {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .badge, .sound])

            if granted {
                authorizationStatus = .authorized
            } else {
                authorizationStatus = .denied
                error = NotificationError.permissionDenied
            }

            updateNotificationEnabled()
        } catch {
            self.error = NotificationError.permissionRequestFailed(
                error.localizedDescription
            )
        }
    }

    private func updateNotificationEnabled() {
        isNotificationEnabled = authorizationStatus == .authorized
    }

    func scheduleProximityNotification(
        for business: Business,
        userLocation: CLLocation
    ) async {
        guard isNotificationEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "You're near \(business.name)!"
        content.body = business.description ?? "Check out this cool spot nearby"
        content.sound = .default
        content.userInfo = ["venueId": business.id, "type": "proximity"]

        let identifier = "proximity_\(business.id)"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil
        )

        do {
            try await notificationCenter.add(request)
        } catch {
            print("Error scheduling notification: \(error)")
        }
    }

    func scheduleWeeklyDigest() async {
        guard isNotificationEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Your Weekly Bookd Digest"
        content.body =
            "Discover new places and see what your friends are up to!"
        content.sound = .default

        // Schedule for every Sunday at 10 AM
        var dateComponents = DateComponents()
        dateComponents.weekday = 1  // Sunday
        dateComponents.hour = 10

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )
        let request = UNNotificationRequest(
            identifier: "weekly_digest",
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
        } catch {
            print("Error scheduling weekly digest: \(error)")
        }
    }
}

enum NotificationError: LocalizedError {
    case permissionDenied
    case permissionRequestFailed(String)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Notification permission denied"
        case .permissionRequestFailed(let message):
            return "Notification permission request failed: \(message)"
        }
    }
}
