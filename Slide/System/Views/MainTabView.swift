//
//  MainTabView.swift
//  Slide
//
//  Created by Nick Rogers on 7/29/25.
//


import SwiftUI
import FirebaseAuth

// MARK: - Main Tab View
struct MainTabView: View {
    @EnvironmentObject var coordinator: AppCoordinator

    var body: some View {
        TabView {
            // Discover Tab
//            Button {
//                Task {
//                    coordinator.authService.signOut()
//                }
//            } label: {
//                Text("Discover")
//            }
            UpdatedBusinessOnboardingFlow()
//            DiscoverView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "staroflife.fill")
                    Text("Discover")
                }

            // Favorites Tab
            Text("Favorites")
//            FavoritesView(venues: $coordinator.favoriteVenues)
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text("Favorites")
                }

            // Activity Tab
            Text("Activity")
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text("Activity")
                }

            // Profile Tab
            Group {
                if let user = coordinator.authService.currentUser {
                    ProfileView(profile: user)
                } else {
                    LoadingView()
                }
            }
            .tabItem {
                Image(systemName: "person.fill")
                Text("Profile")
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .accentColor(.primary)
    }
}
