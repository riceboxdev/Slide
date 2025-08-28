//
//  SlideApp.swift
//  Slide
//
//  Created by Nick Rogers on 7/29/25.
//

import FirebaseCore
import SwiftData
import SwiftUI
import GooglePlaces
import UIKit

// MARK: - App Delegate
class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Configure app launch settings here
        FirebaseApp.configure()
        let _ = GMSPlacesClient.provideAPIKey("AIzaSyCVZ3-wgVaPNQV2V4tuBr7ctJC4IP2FOYk")
        configureAppearance()
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        print("App became active")
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        print("App will resign active")
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        print("App entered background")
        // Save user data or pause operations
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        print("App will enter foreground")
        // Restart paused operations or refresh UI
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        print("App will terminate")
        // Save final data before app terminates
    }
    
    // MARK: - Push Notifications
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("Device token: \(tokenString)")
        // Send token to your server
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }
    
    // MARK: - URL Handling
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        print("App opened with URL: \(url)")
        // Handle deep links or URL schemes
        return true
    }
    
    // MARK: - Private Methods
    private func configureAppearance() {
        let appearance = UINavigationBarAppearance()
    
             // Create variable fonts for different title styles
             let largeTitleFont = createVariableUIFont(size: 34, variations: [
                 FontVariations.weight.rawValue: 800,  // Extra bold for large titles
                 FontVariations.width.rawValue: 100,   // Normal width
                 FontVariations.opticalSize.rawValue: 34
             ])
             
             let inlineTitleFont = createVariableUIFont(size: 17, variations: [
                 FontVariations.weight.rawValue: 600,  // Semi-bold for inline titles
                 FontVariations.width.rawValue: 100,
                 FontVariations.opticalSize.rawValue: 17
             ])
             
             appearance.largeTitleTextAttributes = [
                 .font: largeTitleFont,
                 .foregroundColor: UIColor.label
             ]
             
             appearance.titleTextAttributes = [
                 .font: inlineTitleFont,
                 .foregroundColor: UIColor.label
             ]
        
             
             UINavigationBar.appearance().standardAppearance = appearance
             UINavigationBar.appearance().compactAppearance = appearance
             UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
    
    private func createVariableUIFont(size: CGFloat, variations: [Int: Int]) -> UIFont {
            let descriptor = UIFontDescriptor(fontAttributes: [
                .name: "InterVariable",
                kCTFontVariationAttribute as UIFontDescriptor.AttributeName: variations
            ])
            return UIFont(descriptor: descriptor, size: size)
        }
}

@main
struct SlideApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var coordinator = AppCoordinator()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(coordinator)
                .onAppear {
                    if CommandLine.arguments.contains("-adminMode") {
                        coordinator.isAdminMode = true
                    }
                }
        }
    }
}
