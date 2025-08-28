//
//  ContentView.swift
//  Slide
//
//  Created by Nick Rogers on 7/29/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    @State private var showingOnboarding = false

    var body: some View {
        NavigationView {
            Group {
                switch coordinator.appState {
                case .loading:
                    LoadingView()
                case .unauthenticated:
                    LoginView()
                case .needsLocationPermission:
                    LocationPermissionView()
                case .needsNotificationPermission:
                    NotificationPermissionView()
                case .ready:
                    if let user = coordinator.authService.currentUser, !user.personalInfo.isOnboardingComplete {
                        OnboardingView(authService: coordinator.authService)
                    } else {
                        MainTabView()
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
      
}
