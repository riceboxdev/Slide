//
//  LoginView.swift
//  Slide
//
//  Created by Nick Rogers on 7/29/25.
//


import SwiftUI

// MARK: - Login View
struct LoginView: View {
    @Environment(\.appCoordinator) var coordinator
    @State private var email = ""
    @State private var password = ""
    @State private var firstName = ""
    @State private var isSignUp = false
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 15) {
                        Image(systemName: "map.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white)

                        Text("Welcome to Bookd")
                            .font(
                                .system(
                                    size: 32,
                                    weight: .bold,
                                    design: .rounded
                                )
                            )
                            .foregroundColor(.white)

                        Text(
                            "Discover amazing places for lunch, entertainment, and fun!"
                        )
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    }
                    .padding(.top, 50)

                    // Form
                    VStack(spacing: 20) {
                        // Sign up first name field
                        if isSignUp {
                            CustomTextField(
                                text: $firstName,
                                placeholder: "First Name",
                                icon: "person.fill"
                            )
                        }

                        // Email field
                        CustomTextField(
                            text: $email,
                            placeholder: "Email",
                            icon: "envelope.fill"
                        )
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)

                        // Password field
                        CustomSecureField(
                            text: $password,
                            placeholder: "Password",
                            icon: "lock.fill"
                        )

                        // Auth button
                        Button(action: handleAuth) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.white)
                                    .frame(height: 55)

                                if coordinator.authService.isLoading {
                                    ProgressView()
                                        .progressViewStyle(
                                            CircularProgressViewStyle(
                                                tint: .purple
                                            )
                                        )
                                } else {
                                    Text(isSignUp ? "Sign Up" : "Sign In")
                                        .font(.headline)
                                        .foregroundColor(.purple)
                                }
                            }
                        }
                        .disabled(
                            coordinator.authService.isLoading || email.isEmpty
                                || password.isEmpty
                                || (isSignUp && firstName.isEmpty)
                        )

                        // Toggle auth mode
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isSignUp.toggle()
                            }
                        }) {
                            Text(
                                isSignUp
                                    ? "Already have an account? Sign In"
                                    : "Don't have an account? Sign Up"
                            )
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(.horizontal, 30)

                    Spacer()
                }
            }
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK") {}
        } message: {
            Text(alertMessage)
        }
        .onChange(of: coordinator.authService.error) { error in
            if let error = error {
                alertMessage = error.localizedDescription
                showingAlert = true
            }
        }
    }

    private func handleAuth() {
        Task {
            do {
                if isSignUp {
                    try await coordinator.authService.signUpWithEmail(
                        email,
                        password: password,
                        firstName: firstName
                    )
                } else {
                    try await coordinator.authService.signInWithEmail(
                        email,
                        password: password
                    )
                }
            } catch {
                // Error handling is done via the coordinator's error publisher
                self.alertMessage = error.localizedDescription
                self.showingAlert = true
            }
        }
    }
}
