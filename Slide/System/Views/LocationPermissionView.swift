//
//  LocationPermissionView.swift
//  Slide
//
//  Created by Nick Rogers on 7/29/25.
//


import SwiftUI

// MARK: - Location Permission View
struct LocationPermissionView: View {
    @Environment(\.appCoordinator) var coordinator
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color.green.opacity(0.8), Color.blue.opacity(0.6)],
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

                    Image(systemName: "location.fill")
                        .font(.system(size: 70))
                        .foregroundColor(.white)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                }

                // Content
                VStack(spacing: 20) {
                    Text("Enable Location")
                        .font(
                            .system(size: 32, weight: .bold, design: .rounded)
                        )
                        .foregroundColor(.white)

                    Text(
                        "We need your location to find amazing places nearby and send you notifications when you're close to cool spots!"
                    )
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                }

                // Benefits
                VStack(spacing: 15) {
                    PermissionBenefit(
                        icon: "bell.fill",
                        title: "Smart Notifications",
                        description: "Get notified when you're near great spots"
                    )

                    PermissionBenefit(
                        icon: "map.fill",
                        title: "Personalized Recommendations",
                        description: "Discover places based on your location"
                    )

                    PermissionBenefit(
                        icon: "heart.fill",
                        title: "Save Favorites",
                        description: "Keep track of places you love"
                    )
                }

                // Action button
                Button(action: {
                    coordinator.requestLocationPermission()
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.white)
                            .frame(height: 55)

                        Text("Allow Location Access")
                            .font(.headline)
                            .foregroundColor(.green)
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
