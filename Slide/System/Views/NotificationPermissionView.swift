//
//  NotificationPermissionView.swift
//  Slide
//
//  Created by Nick Rogers on 7/29/25.
//


import SwiftUI

// MARK: - Notification Permission View
struct NotificationPermissionView: View {
    @Environment(\.appCoordinator) var coordinator
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color.orange.opacity(0.8), Color.red.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 150, height: 150)

                    Image(systemName: "bell.fill")
                        .font(.system(size: 70))
                        .foregroundColor(.white)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                }

                // Content
                VStack(spacing: 20) {
                    Text("Enable Notifications")
                        .font(
                            .system(size: 32, weight: .bold, design: .rounded)
                        )
                        .foregroundColor(.white)

                    Text(
                        "Get notified about amazing places nearby and never miss out on great experiences!"
                    )
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                }

                // Benefits
                VStack(spacing: 15) {
                    PermissionBenefit(
                        icon: "location.fill",
                        title: "Proximity Alerts",
                        description: "Know when you're near cool spots"
                    )

                    PermissionBenefit(
                        icon: "calendar.fill",
                        title: "Weekly Digest",
                        description: "Get a summary of new places to explore"
                    )

                    PermissionBenefit(
                        icon: "person.2.fill",
                        title: "Friend Activity",
                        description: "See what your friends are discovering"
                    )
                }

                // Action buttons
                VStack(spacing: 15) {
                    Button(action: {
                        coordinator.requestNotificationPermission()
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.white)
                                .frame(height: 55)

                            Text("Allow Notifications")
                                .font(.headline)
                                .foregroundColor(.orange)
                        }
                    }

                    Button(action: {
                        // Skip for now - this would set a flag to not ask again
                        coordinator.appState = .ready
                    }) {
                        Text("Maybe Later")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 30)

                Spacer()
            }
            .padding(.top, 80)
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 2.0).repeatForever(autoreverses: true)
            ) {
                isAnimating = true
            }
        }
    }
}
