//
//  OnboardingViewModel.swift
//  Slide
//
//  Created by Nick Rogers on 7/29/25.
//


import SwiftUI
import CoreLocation
import PhotosUI
import Combine

// MARK: - Onboarding View Model
@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var currentStep: OnboardingStep = .welcome
    @Published var profile: OnboardingProfile = OnboardingProfile()
    @Published var selectedCategories: Set<BusinessCategory> = []
    @Published var selectedSubcategories: Set<BusinessSubCategory> = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var currentUser: UserProfile?
    
    private let userService = UserService()
    private let authService: AuthService
    private let locationManager = CLLocationManager()
    
    init(authService: AuthService) {
        self.authService = authService
        self.currentUser = authService.currentUser
    }
    
    func nextStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            switch currentStep {
            case .welcome:
                currentStep = .personalInfo
            case .personalInfo:
                currentStep = .interests
            case .interests:
                currentStep = .location
            case .location:
                currentStep = .notifications
            case .notifications:
                currentStep = .complete
            case .complete:
                break
            }
        }
    }
    
    func previousStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            switch currentStep {
            case .welcome:
                break
            case .personalInfo:
                currentStep = .welcome
            case .interests:
                currentStep = .personalInfo
            case .location:
                currentStep = .interests
            case .notifications:
                currentStep = .location
            case .complete:
                currentStep = .notifications
            }
        }
    }
    
    @MainActor
    func completeOnboarding() async {
        isLoading = true
        error = nil
        
        do {
            // Update the user's profile with onboarding data
            guard var userProfile = authService.currentUser else {
                throw OnboardingError.userNotFound
            }
            self.currentUser = userProfile
            guard var user = currentUser else {
                throw OnboardingError.userNotFound
            }
            
            // Update personal info
            if !profile.bio.isEmpty {
                user.personalInfo.bio = profile.bio
            }
            if !profile.phoneNumber.isEmpty {
                user.personalInfo.phoneNumber = profile.phoneNumber
            }
            if let birthDate = profile.birthDate {
                user.personalInfo.dateOfBirth = birthDate
            }
            
            // Fix: Use the selectedSubcategories from the view model, not from profile
            // Convert BusinessSubCategory to String array (assuming interests is [String])
            user.personalInfo.interests = Array(selectedSubcategories)
            
            // Update location settings if permission granted
            if profile.locationPermissionGranted {
                user.locationSettings.isLocationTrackingEnabled = true
                user.locationSettings.isLocationTrackingEnabled = profile.shareLocation
            }
            
            // Update notification settings
            user.personalInfo.enableNotifications = profile.notificationsEnabled
            
            // Mark onboarding as complete
            user.personalInfo.isOnboardingComplete = true
            
            // Save to Firestore
            try await userService.updateUserProfile(user)
            
            // Update local auth service
            authService.currentUser = user
            
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
        profile.locationPermissionGranted = true
    }
    
    func requestNotificationPermission() async {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            profile.notificationsEnabled = granted
        } catch {
            print("Notification permission error: \(error)")
        }
    }
}

// MARK: - Onboarding Data Model
struct OnboardingProfile {
    var bio: String = ""
    var phoneNumber: String = ""
    var birthDate: Date?
    var interests: Set<String> = []
    var locationPermissionGranted: Bool = false
    var shareLocation: Bool = false
    var notificationsEnabled: Bool = false
    var expandedCategories: Set<BusinessCategory> = []
}

enum OnboardingStep: CaseIterable {
    case welcome
    case personalInfo
    case interests
    case location
    case notifications
    case complete
    
    var title: String {
        switch self {
        case .welcome: return "Welcome!"
        case .personalInfo: return "Tell us about yourself"
        case .interests: return "What are you interested in?"
        case .location: return "Location Services"
        case .notifications: return "Stay Connected"
        case .complete: return "You're all set!"
        }
    }
    
    var subtitle: String {
        switch self {
        case .welcome: return "Let's get you set up with a great experience"
        case .personalInfo: return "Help others get to know you better"
        case .interests: return "We'll personalize your experience"
        case .location: return "Find venues and friends nearby"
        case .notifications: return "Get notified about important updates"
        case .complete: return "Welcome to the community!"
        }
    }
}

enum OnboardingError: LocalizedError {
    case userNotFound
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User profile not found"
        }
    }
}

// MARK: - Main Onboarding View
struct OnboardingView: View {
    @StateObject private var viewModel: OnboardingViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(authService: AuthService) {
        self._viewModel = StateObject(wrappedValue: OnboardingViewModel(authService: authService))
    }
    
    
    
    var body: some View {
//        NavigationView {
        ZStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Content
                    TabView(selection: $viewModel.currentStep) {
                        WelcomeStepView()
                            .tag(OnboardingStep.welcome)
                        
                        PersonalInfoStepView(profile: $viewModel.profile)
                            .tag(OnboardingStep.personalInfo)
                        
                        BouncingCirclesView(viewModel: viewModel)
                        //                        BubbleInterestsStepView(profile: $viewModel.profile)
                            .tag(OnboardingStep.interests)
                            .ignoresSafeArea()
                        
                        LocationStepView(profile: $viewModel.profile, viewModel: viewModel)
                            .tag(OnboardingStep.location)
                        
                        NotificationsStepView(profile: $viewModel.profile, viewModel: viewModel)
                            .tag(OnboardingStep.notifications)
                        
                        CompleteStepView()
                            .tag(OnboardingStep.complete)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
                    //                    .ignoresSafeArea()
                    
                }
                
                
                
            }
            .ignoresSafeArea()
            VStack {
                if viewModel.currentStep != .interests {
                    // Progress indicator
                    OnboardingProgressView(currentStep: viewModel.currentStep)
                        .padding(.horizontal)
                        .padding(.top)
                        .transition(.opacity)
                }
                Spacer()
                // Navigation buttons
                OnboardingNavigationView(viewModel: viewModel)
                    .padding()
            }
        }
        .tint(.accent)
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") {
                viewModel.error = nil
            }
        } message: {
            Text(viewModel.error ?? "")
        }
    }
}

// MARK: - Progress View
struct OnboardingProgressView: View {
    let currentStep: OnboardingStep
    
    private var progress: Double {
        let allSteps = OnboardingStep.allCases
        guard let currentIndex = allSteps.firstIndex(of: currentStep) else { return 0 }
        return Double(currentIndex) / Double(allSteps.count - 1)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Step \(OnboardingStep.allCases.firstIndex(of: currentStep)! + 1) of \(OnboardingStep.allCases.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .accent))
        }
    }
}

// MARK: - Welcome Step
struct WelcomeStepView: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // App icon or illustration
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            VStack(spacing: 16) {
                Text(OnboardingStep.welcome.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(OnboardingStep.welcome.subtitle)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
        }
    }
}

// MARK: - Personal Info Step
struct PersonalInfoStepView: View {
    @Binding var profile: OnboardingProfile
    @State private var showingDatePicker = false
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Text(OnboardingStep.personalInfo.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(OnboardingStep.personalInfo.subtitle)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 20) {
                // Bio field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Bio")
                        .font(.headline)
                    
                    TextField("Tell us a bit about yourself...", text: $profile.bio, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                }
                
                // Phone number field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Phone Number (Optional)")
                        .font(.headline)
                    
                    TextField("Your phone number", text: $profile.phoneNumber)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.phonePad)
                }
                
                // Birth date field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Birth Date (Optional)")
                        .font(.headline)
                    
                    Button(action: { showingDatePicker.toggle() }) {
                        HStack {
                            Text(profile.birthDate?.formatted(date: .abbreviated, time: .omitted) ?? "Select your birth date")
                                .foregroundColor(profile.birthDate == nil ? .secondary : .primary)
                            Spacer()
                            Image(systemName: "calendar")
                                .foregroundColor(.blue)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding(.top, 60)
        .sheet(isPresented: $showingDatePicker) {
            NavigationView {
                DatePicker(
                    "Birth Date",
                    selection: Binding(
                        get: { profile.birthDate ?? Date() },
                        set: { profile.birthDate = $0 }
                    ),
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(WheelDatePickerStyle())
                .navigationTitle("Birth Date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showingDatePicker = false
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Location Step
struct LocationStepView: View {
    @Binding var profile: OnboardingProfile
    let viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Image(systemName: "location.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text(OnboardingStep.location.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(OnboardingStep.location.subtitle)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            VStack(spacing: 16) {
                Button("Enable Location Services") {
                    viewModel.requestLocationPermission()
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(profile.locationPermissionGranted)
                
                if profile.locationPermissionGranted {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Location permission granted")
                            .foregroundColor(.secondary)
                    }
                    
                    Toggle("Share my location with friends", isOn: $profile.shareLocation)
                        .padding(.horizontal)
                }
                
                Button("Skip for now") {
                    // Skip location setup
                }
                .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Notifications Step
struct NotificationsStepView: View {
    @Binding var profile: OnboardingProfile
    let viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Image(systemName: "bell.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text(OnboardingStep.notifications.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(OnboardingStep.notifications.subtitle)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            VStack(spacing: 16) {
                Button("Enable Notifications") {
                    Task {
                        await viewModel.requestNotificationPermission()
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(profile.notificationsEnabled)
                
                if profile.notificationsEnabled {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Notifications enabled")
                            .foregroundColor(.secondary)
                    }
                }
                
                Button("Skip for now") {
                    // Skip notifications
                }
                .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Complete Step
struct CompleteStepView: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            VStack(spacing: 16) {
                Text(OnboardingStep.complete.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(OnboardingStep.complete.subtitle)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
        }
    }
}

// MARK: - Navigation View
struct OnboardingNavigationView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        HStack {
            // Back button
            if viewModel.currentStep != .welcome {
                Button("Back".uppercased()) {
                    viewModel.previousStep()
                }
                .font(.variableFont(14, axis: [FontVariations.weight.rawValue : 600]))
                .foregroundColor(Color("AccentColor"))
            } else {
                // Invisible placeholder to keep layout consistent
                Button("Back".uppercased()) {
                    viewModel.previousStep()
                }
                .font(.variableFont(14, axis: [FontVariations.weight.rawValue : 600]))
                .foregroundColor(Color("AccentColor"))
                .opacity(0)
            }
            
            Spacer()
            
            // Next/Complete button
            if viewModel.currentStep == .complete {
                Button("Get Started") {
                    Task {
                        await viewModel.completeOnboarding()
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(viewModel.isLoading)
            } else {
                Button {
                    viewModel.nextStep()
                } label: {
                    Text("Next".uppercased())
                        .font(.variableFont(12, axis: [FontVariations.weight.rawValue : 600]))
                        .frame(height: 25)
                        .padding(.horizontal)
                }
                .buttonStyle(.glassProminent)
            }
        }
    }
}

// MARK: - Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .background(Color.blue)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Usage Example
struct SampleContentView: View {
    @StateObject private var authService = AuthService()
//    @State private var showingOnboarding = false
    
    var body: some View {
        Group {
            if authService.isAuthenticated {
                if let user = authService.currentUser, !user.personalInfo.isOnboardingComplete {
                    OnboardingView(authService: authService)
                } else {
                    // Main app content
                    Text("Welcome to the main app!")
                }
            } else {
                // Login/signup view
                Text("Please sign in")
            }
        }
        .task {
            await authService.initialize()
        }
    }
}

// MARK: - Enhanced Onboarding Profile
struct EnhancedOnboardingProfile {
    var selectedCategories: Set<BusinessCategory> = []
    var selectedSubcategories: Set<BusinessSubCategory> = []
    var expandedCategories: Set<BusinessCategory> = []
    
    // Other existing properties...
    var bio: String = ""
    var phoneNumber: String = ""
    var birthDate: Date?
    var locationPermissionGranted: Bool = false
    var shareLocation: Bool = false
    var notificationsEnabled: Bool = false
}

enum CircleType {
    case category(BusinessCategory)
    case subcategory(BusinessSubCategory)
}

struct BouncingCircle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGVector
    var baseRadius: CGFloat
    var currentRadius: CGFloat
    var color: Color
    var isSelected: Bool = false
    let type: CircleType
}

struct BouncingCirclesView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var circles: [BouncingCircle] = []
    @State private var screenSize: CGSize = .zero

    let timer = Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(
                    colors: [Color("blueui").opacity(0.2), .accentColor.opacity(0.2)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ForEach(circles) { circle in
                    let normalizedY = max(0, min(1, circle.position.y / screenSize.height))
                    let opacity = 0.7 - (normalizedY * 0.8)
                    
                    ZStack {
                        Circle()
                            .fill(.clear)
                            .frame(width: circle.currentRadius * 2, height: circle.currentRadius * 2)
                            .glassEffect(
                                .regular.tint(
                                    circle.isSelected ?
                                    Color.secondary.opacity(0.2) :
                                        Color("AccentColor").opacity(opacity)
                                ),
                                in: .circle
                            )
                        
                        Text(displayName(for: circle))
                            .font(.variableFont(circle.isSelected ? 20 : 12, axis: [FontVariations.weight.rawValue : 600]))
//                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.5)
                            .frame(width: circle.currentRadius * 1.5)
                            .animation(.smooth, value: circle.isSelected)
                    }
                    .position(circle.position)
                    .onTapGesture {
                        toggleSelection(for: circle.id)
                    }
                }
            }
         
            .onAppear {
                screenSize = geometry.size
                setupCircles()
            }
            .onReceive(timer) { _ in
                updateCircles()
                updateCircleRadii()
            }
        }
//        .ignoresSafeArea()
    }
    
    // MARK: - Display Name
    private func displayName(for circle: BouncingCircle) -> String {
        switch circle.type {
        case .category(let cat): return cat.displayNameWithBreaks
        case .subcategory(let sub): return sub.displayName
        }
    }
    
    // MARK: - Setup
    private func setupCircles() {
        let colors: [Color] = [Color("AccentColor"), Color("blueui"), .green, .yellow, .purple]
        circles = []
        
        for (i, category) in BusinessCategory.allCases.enumerated() {
            let radius: CGFloat = 80
            let x = CGFloat.random(in: radius...(screenSize.width - radius))
            let y = CGFloat.random(in: radius...(screenSize.height - radius))
            let velocity = CGVector(dx: CGFloat.random(in: -50...50), dy: CGFloat.random(in: -50...50))
            let color = colors[i % colors.count]
            
            circles.append(BouncingCircle(
                position: CGPoint(x: x, y: y),
                velocity: velocity,
                baseRadius: radius,
                currentRadius: radius,
                color: color,
                type: .category(category)
            ))
        }
    }
    
    // MARK: - Toggle Selection
    private func toggleSelection(for circleId: UUID) {
        guard let index = circles.firstIndex(where: { $0.id == circleId }) else { return }
        let circle = circles[index]
        
        switch circle.type {
        case .category(let category):
            if circle.isSelected {
                viewModel.selectedCategories.remove(category)
                removeSubcategories(for: category)
            } else if viewModel.selectedCategories.count < 4 {
                viewModel.selectedCategories.insert(category)
                spawnSubcategories(for: category, around: circle.position)
            } else {
                return // Max parents
            }
        case .subcategory(let subcategory):
            if circle.isSelected {
                viewModel.selectedSubcategories.remove(subcategory)
            } else if viewModel.selectedSubcategories.count < 3 {
                viewModel.selectedSubcategories.insert(subcategory)
            } else {
                return // Max subcategories
            }
        }
        
        circles[index].isSelected.toggle()
    }
    
    // MARK: - Subcategories
    private func spawnSubcategories(for category: BusinessCategory, around center: CGPoint) {
        let subcategories = BusinessSubCategory.allCases.filter { $0.parentCategory == category }
        let angleStep = CGFloat.pi * 2 / CGFloat(subcategories.count)
        let subRadius: CGFloat = 40
        
        for (i, sub) in subcategories.enumerated() {
            let angle = angleStep * CGFloat(i)
            let distance: CGFloat = 100
            let x = center.x + cos(angle) * distance
            let y = center.y + sin(angle) * distance
            let velocity = CGVector(dx: CGFloat.random(in: -30...30), dy: CGFloat.random(in: -30...30))
            
            let subCircle = BouncingCircle(
                position: CGPoint(x: x, y: y),
                velocity: velocity,
                baseRadius: subRadius,
                currentRadius: subRadius,
                color: .white,
                type: .subcategory(sub)
            )
            
            DispatchQueue.main.async {
                withAnimation(.smooth) {
                    circles.append(subCircle)
                }
            }
        }
    }
    
    private func removeSubcategories(for category: BusinessCategory) {
        let subcategoriesToRemove = BusinessSubCategory.allCases.filter { $0.parentCategory == category }
        circles.removeAll {
            if case let .subcategory(sub) = $0.type {
                return subcategoriesToRemove.contains(sub)
            }
            return false
        }
        viewModel.selectedSubcategories.subtract(subcategoriesToRemove)
    }
    
    // MARK: - Radius Animation
    private func updateCircleRadii() {
        let hasSelected = circles.contains { $0.isSelected }
        for i in 0..<circles.count {
            let base = circles[i].baseRadius
            let target: CGFloat
            if hasSelected {
                target = circles[i].isSelected ? base * 1.5 : base * 0.8
            } else {
                target = base
            }
            circles[i].currentRadius += (target - circles[i].currentRadius) * 0.1
        }
    }
    
    // MARK: - Movement & Collisions
    private func updateCircles() {
        let dt: CGFloat = 1.0 / 60.0
        for i in 0..<circles.count {
            circles[i].position.x += circles[i].velocity.dx * dt
            circles[i].position.y += circles[i].velocity.dy * dt
            
            let r = circles[i].currentRadius
            if circles[i].position.x - r <= 0 {
                circles[i].position.x = r
                circles[i].velocity.dx = abs(circles[i].velocity.dx)
            }
            if circles[i].position.x + r >= screenSize.width {
                circles[i].position.x = screenSize.width - r
                circles[i].velocity.dx = -abs(circles[i].velocity.dx)
            }
            if circles[i].position.y - r <= 0 {
                circles[i].position.y = r
                circles[i].velocity.dy = abs(circles[i].velocity.dy)
            }
            if circles[i].position.y + r >= screenSize.height {
                circles[i].position.y = screenSize.height - r
                circles[i].velocity.dy = -abs(circles[i].velocity.dy)
            }
        }
        
        for i in 0..<circles.count {
            for j in (i + 1)..<circles.count {
                let dx = circles[j].position.x - circles[i].position.x
                let dy = circles[j].position.y - circles[i].position.y
                let dist = sqrt(dx*dx + dy*dy)
                let minDist = circles[i].currentRadius + circles[j].currentRadius
                if dist < minDist {
                    let angle = atan2(dy, dx)
                    let sinA = sin(angle)
                    let cosA = cos(angle)
                    
                    let v1x = circles[i].velocity.dx * cosA + circles[i].velocity.dy * sinA
                    let v1y = circles[i].velocity.dy * cosA - circles[i].velocity.dx * sinA
                    let v2x = circles[j].velocity.dx * cosA + circles[j].velocity.dy * sinA
                    let v2y = circles[j].velocity.dy * cosA - circles[j].velocity.dx * sinA
                    
                    let newV1x = v2x
                    let newV2x = v1x
                    
                    circles[i].velocity.dx = newV1x * cosA - v1y * sinA
                    circles[i].velocity.dy = v1y * cosA + newV1x * sinA
                    circles[j].velocity.dx = newV2x * cosA - v2y * sinA
                    circles[j].velocity.dy = v2y * cosA + newV2x * sinA
                    
                    let overlap = minDist - dist
                    let separationX = cosA * overlap * 0.5
                    let separationY = sinA * overlap * 0.5
                    
                    circles[i].position.x -= separationX
                    circles[i].position.y -= separationY
                    circles[j].position.x += separationX
                    circles[j].position.y += separationY
                }
            }
        }
    }
}



#Preview {
    OnboardingView(authService: AuthService())
       
}

