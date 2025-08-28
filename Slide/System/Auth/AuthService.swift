//
//  AuthService.swift
//  Slide
//
//  Created by Nick Rogers on 7/29/25.
//


import Combine
import Firebase
import FirebaseAuth
import FirebaseFirestore
import Foundation
import SwiftUI

// MARK: - Auth Service
@MainActor
class AuthService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: UserProfile?
    @Published var isLoading = false
    @Published var error: AuthError?

    private var authStateHandle: AuthStateDidChangeListenerHandle?
    private var cancellables = Set<AnyCancellable>()

    func initialize() async {
        authStateHandle = Auth.auth().addStateDidChangeListener {
            [weak self] _, user in
            Task { @MainActor in
                self?.handleAuthStateChange(user)
            }
        }
    }

    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    private func handleAuthStateChange(_ user: User?) {
        if let user = user {
            isAuthenticated = true
            Task {
                await loadUserProfile(for: user)
            }
        } else {
            isAuthenticated = false
            currentUser = nil
        }
    }

    private func loadUserProfile(for user: User) async {
        do {
            let userService = UserService()
            currentUser = try await userService.getUserProfile(userId: user.uid)
        } catch {
            print("Error loading user profile: \(error)")
        }
    }

    func signInWithEmail(_ email: String, password: String) async throws {
        isLoading = true
        error = nil

        do {
            let authResult = try await Auth.auth().signIn(
                withEmail: email,
                password: password
            )
            print("Signed In: \(authResult.user.uid)")
        } catch {
            self.error = AuthError.signInFailed(error.localizedDescription)
            throw error
        }

        isLoading = false
    }

    func signUpWithEmail(_ email: String, password: String, firstName: String)
        async throws
    {
        isLoading = true
        error = nil

        do {
            let result = try await Auth.auth().createUser(
                withEmail: email,
                password: password
            )

            // Create user profile
            let userID = result.user.uid
            let userProfile = UserProfile.createDefault(
                firstName: firstName,
                email: email,
                id: userID,
                username: "",
                avatar: ""
            )
            let userService = UserService()
            try await userService.createUserProfile(
                userId: userID,
                profile: userProfile
            )

        } catch {
            self.error = AuthError.signUpFailed(error.localizedDescription)
            throw error
        }

        isLoading = false
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Error signing out: \(error)")
        }
    }
}

enum AuthError: LocalizedError, Equatable {
    case signInFailed(String)
    case signUpFailed(String)
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .signInFailed(let message):
            return "Sign in failed: \(message)"
        case .signUpFailed(let message):
            return "Sign up failed: \(message)"
        case .notAuthenticated:
            return "User not authenticated"
        }
    }
}
