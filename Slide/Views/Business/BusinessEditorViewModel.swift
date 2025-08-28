//
//  BusinessEditorViewModel.swift
//  Slide
//
//  Created by Nick Rogers on 8/25/25.
//


import SwiftUI
import FirebaseFirestore
import PhotosUI
import Combine

// MARK: - Business Editor View Model
@MainActor
class BusinessEditorViewModel: ObservableObject {
    @Published var business: SlideBusiness
    @Published var heroVideo: VideoItem?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isAdvancedMode = false
    @Published var showingVideoPicker = false
    @Published var selectedProfilePhoto: PhotosPickerItem?
    @Published var selectedBannerPhoto: PhotosPickerItem?
    
    private var imageLoader: FirebaseImageManager = .init()
    private var videoUploader: VideoUploadService = .init()
    private var videoDownloader: VideoRetrievalService = .init()
    
    private let db = Firestore.firestore()
    private var debounceTimer: Timer?
    
    init(business: SlideBusiness) {
        self.business = business
    }
    
    func initialize() {
        loadVideo()
    }
    
    // MARK: - Save to Firestore
    func saveToFirestore() {
        guard let businessId = business.id else { return }
        
        // Cancel previous timer
        debounceTimer?.invalidate()
        
        // Debounce saves to avoid excessive writes
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
            Task { @MainActor in
                do {
                    self.business.updatedAt = Timestamp()
                    try self.db.collection("businesses").document(businessId).setData(from: self.business, merge: true)
                } catch {
                    self.errorMessage = "Failed to save: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Video Methods
    func loadVideo() {
        guard let videoRef = business.videoReference else { return }
        
        videoDownloader.fetchVideo(by: videoRef) { [weak self] video in
            DispatchQueue.main.async {
                self?.heroVideo = video
            }
        }
    }
    
    func uploadVideo(with pickerItem: PhotosPickerItem?) {
        guard let pickerItem = pickerItem else {
            errorMessage = "No video selected"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Try to load as URL first (more efficient for large videos)
                if let videoURL = try await pickerItem.loadTransferable(type: URL.self) {
                    await MainActor.run {
                        self.uploadVideoFromURL(videoURL)
                    }
                } else {
                    // Fallback to loading as Data
                    guard let videoData = try await pickerItem.loadTransferable(type: Data.self) else {
                        await MainActor.run {
                            self.errorMessage = "Could not load video data"
                            self.isLoading = false
                        }
                        return
                    }
                    
                    // Create a temporary file URL
                    let tempDirectory = FileManager.default.temporaryDirectory
                    let tempFileName = UUID().uuidString + ".mp4"
                    let tempURL = tempDirectory.appendingPathComponent(tempFileName)
                    
                    // Write data to temporary file
                    try videoData.write(to: tempURL)
                    
                    await MainActor.run {
                        self.uploadVideoFromURL(tempURL, shouldCleanup: true)
                    }
                }
                
            } catch {
                await MainActor.run {
                    self.errorMessage = "Error processing video: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    private func uploadVideoFromURL(_ url: URL, shouldCleanup: Bool = false) {
        videoUploader.uploadVideo(
            videoURL: url,
            title: business.displayName?.text ?? "Business Video"
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                // Clean up temporary file if needed
                if shouldCleanup {
                    try? FileManager.default.removeItem(at: url)
                }
                
                switch result {
                case .success(let videoItem):
                    self.heroVideo = videoItem
                    self.business.videoReference = videoItem.id
                    self.saveToFirestore()
                    
                case .failure(let error):
                    self.errorMessage = "Upload failed: \(error.localizedDescription)"
                }
                
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Photo Upload Methods (unchanged)
    func uploadProfilePhoto() {
        guard let selectedItem = selectedProfilePhoto else { return }
        
        selectedItem.loadTransferable(type: Data.self) { result in
            Task { @MainActor in
                switch result {
                case .success(let data):
                    if let data = data, let uiImage = UIImage(data: data) {
                        await self.uploadPhoto(uiImage, type: .profile)
                    }
                case .failure(let error):
                    self.errorMessage = "Failed to load photo: \(error.localizedDescription)"
                }
                self.selectedProfilePhoto = nil
            }
        }
    }
    
    func uploadBannerPhoto() {
        guard let selectedItem = selectedBannerPhoto else { return }
        
        selectedItem.loadTransferable(type: Data.self) { result in
            Task { @MainActor in
                switch result {
                case .success(let data):
                    if let data = data, let uiImage = UIImage(data: data) {
                        await self.uploadPhoto(uiImage, type: .banner)
                    }
                case .failure(let error):
                    self.errorMessage = "Failed to load photo: \(error.localizedDescription)"
                }
                self.selectedBannerPhoto = nil
            }
        }
    }
    
    private func uploadPhoto(_ image: UIImage, type: PhotoType) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let metaData = try await imageLoader.uploadImageAsync(image)
            let photoId = metaData.id
            
            switch type {
            case .profile:
                business.profilePhoto = photoId
            case .banner:
                business.bannerPhoto = photoId
            }
            
            saveToFirestore()
        } catch {
            errorMessage = "Failed to upload photo: \(error.localizedDescription)"
        }
    }
    
    enum PhotoType {
        case profile, banner
    }
}

// MARK: - Main Business Editor View
struct BusinessEditorView: View {
    @StateObject private var viewModel: BusinessEditorViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedVideo: PhotosPickerItem? = nil
    
    init(business: SlideBusiness) {
        self._viewModel = StateObject(wrappedValue: BusinessEditorViewModel(business: business))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with mode toggle
                    headerSection
                    
                    // Photo sections
                    photoSection
                    
                    // Video Section
                    videoSection
                    
                    // Basic Information (always visible)
                    basicInfoSection
                    
                    // Contact Information
                    contactInfoSection
                    
                    // Hours Section
                    hoursSection
                    
                    if viewModel.isAdvancedMode {
                        // Advanced sections only in advanced mode
                        servicesSection
                        amenitiesSection
                        accessibilitySection
                        paymentParkingSection
                        fuelEvSection
                    }
                }
                .padding()
            }
            .onAppear() {
                
            }
            .navigationTitle("Edit Business")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .onChange(of: selectedVideo) { newValue in
                if let item = newValue {
                    viewModel.uploadVideo(with: item)
                    selectedVideo = nil
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Editing Mode")
                    .font(.headline)
                Spacer()
                
                Picker("Mode", selection: $viewModel.isAdvancedMode) {
                    Text("Basic").tag(false)
                    Text("Advanced").tag(true)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 160)
            }
            
            if viewModel.isAdvancedMode {
                Text("Advanced mode allows you to edit all business properties including services, amenities, and accessibility options.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6), in: .capsule)
        .cornerRadius(12)
    }
    
    // MARK: - Photo Section
    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Photos")
                .font(.headline)
            
            HStack(spacing: 20) {
                // Profile Photo
                VStack {
                    PhotosPicker(selection: $viewModel.selectedProfilePhoto, matching: .images) {
                        AsyncImageWithColor(imageRef: viewModel.business.profilePhoto ?? "", imageMetaData: .constant(nil)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.gray)
                                .font(.system(size: 60))
                        }
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.blue, lineWidth: 2))
                    }
                    .onChange(of: viewModel.selectedProfilePhoto) { _ in
                        viewModel.uploadProfilePhoto()
                    }
                    
                    Text("Profile Photo")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Banner Photo
                VStack {
                    PhotosPicker(selection: $viewModel.selectedBannerPhoto, matching: .images) {
                        AsyncImageWithColor(imageRef: viewModel.business.bannerPhoto ?? "", imageMetaData: .constant(nil)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Image(systemName: "photo.rectangle")
                                .foregroundColor(.gray)
                                .font(.system(size: 40))
                        }
                        .frame(width: 120, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.blue, lineWidth: 2))
                    }
                    .onChange(of: viewModel.selectedBannerPhoto) { _ in
                        viewModel.uploadBannerPhoto()
                    }
                    
                    Text("Banner Photo")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private var videoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Video")
                .font(.headline)
            
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.quinary)
                    if let loadedVideo = viewModel.heroVideo {
                        AsyncImageWithColor(imageRef: loadedVideo.thumbnailURL?.absoluteString ?? "", imageMetaData: .constant(nil)) { image in
                            image
                                .resizable()
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.secondary)
                                .aspectRatio(9/16, contentMode: .fit)
                        }
                    } else {
                        PhotosPicker(selection: $selectedVideo, matching: .videos) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            .black.opacity(0.5),
                                            .gray.opacity(0.2)
                                        ],
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                )
                                .aspectRatio(9/16, contentMode: .fit)
                                .overlay {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(.clear)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 2)
                                        Image(systemName: "arrow.up.circle.fill")
                                            .symbolRenderingMode(.hierarchical)
                                            .imageScale(.large)
                                            .foregroundStyle(.accent)
                                    }
                                }
                        }
                        .padding()
                    }
                }
                
                VStack {
                    Text("Upload a vertical video to showcase your business".uppercased())
                        .multilineTextAlignment(.center)
                        .font(.variableFont(12, axis: [FontVariations.weight.rawValue: 400]))
                    
                    Image(systemName: "iphone.gen2")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 60)
                        .padding(.vertical)
                }
                .padding(8)
            }
            .frame(height: 180)
        }
    }
    
    // MARK: - Basic Info Section
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Basic Information")
                .font(.headline)
            
            TextField("Business Name", text: Binding(
                get: { viewModel.business.displayName?.text ?? "" },
                set: { newValue in
                    if viewModel.business.displayName == nil {
                        viewModel.business.displayName = DisplayName(text: newValue, languageCode: "en")
                    } else {
                        viewModel.business.displayName?.text = newValue
                    }
                    viewModel.saveToFirestore()
                }
            ))
            .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextField("Address", text: Binding(
                get: { viewModel.business.formattedAddress ?? "" },
                set: { newValue in
                    viewModel.business.formattedAddress = newValue
                    viewModel.saveToFirestore()
                }
            ))
            .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Contact Info Section
    private var contactInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Contact Information")
                .font(.headline)
            
            TextField("Website", text: Binding(
                get: { viewModel.business.websiteUri ?? "" },
                set: { newValue in
                    viewModel.business.websiteUri = newValue.isEmpty ? nil : newValue
                    viewModel.saveToFirestore()
                }
            ))
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .keyboardType(.URL)
            
            TextField("Phone (National)", text: Binding(
                get: { viewModel.business.nationalPhoneNumber ?? "" },
                set: { newValue in
                    viewModel.business.nationalPhoneNumber = newValue.isEmpty ? nil : newValue
                    viewModel.saveToFirestore()
                }
            ))
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .keyboardType(.phonePad)
            
            TextField("Phone (International)", text: Binding(
                get: { viewModel.business.internationalPhoneNumber ?? "" },
                set: { newValue in
                    viewModel.business.internationalPhoneNumber = newValue.isEmpty ? nil : newValue
                    viewModel.saveToFirestore()
                }
            ))
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .keyboardType(.phonePad)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Hours Section
    private var hoursSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Hours")
                .font(.headline)
            
            OpeningHoursEditor(
                title: "Regular Hours",
                openingHours: $viewModel.business.regularOpeningHours,
                onSave: { viewModel.saveToFirestore() }
            )
            
            OpeningHoursEditor(
                title: "Current Hours",
                openingHours: $viewModel.business.currentOpeningHours,
                onSave: { viewModel.saveToFirestore() }
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Services Section (Advanced Mode)
    private var servicesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Services")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ToggleRow(title: "Takeout", isOn: Binding(
                    get: { viewModel.business.takeout ?? false },
                    set: { viewModel.business.takeout = $0; viewModel.saveToFirestore() }
                ))
                
                ToggleRow(title: "Delivery", isOn: Binding(
                    get: { viewModel.business.delivery ?? false },
                    set: { viewModel.business.delivery = $0; viewModel.saveToFirestore() }
                ))
                
                ToggleRow(title: "Dine In", isOn: Binding(
                    get: { viewModel.business.dineIn ?? false },
                    set: { viewModel.business.dineIn = $0; viewModel.saveToFirestore() }
                ))
                
                ToggleRow(title: "Curbside Pickup", isOn: Binding(
                    get: { viewModel.business.curbsidePickup ?? false },
                    set: { viewModel.business.curbsidePickup = $0; viewModel.saveToFirestore() }
                ))
                
                ToggleRow(title: "Reservable", isOn: Binding(
                    get: { viewModel.business.reservable ?? false },
                    set: { viewModel.business.reservable = $0; viewModel.saveToFirestore() }
                ))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Amenities Section (Advanced Mode)
    private var amenitiesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Food & Amenities")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ToggleRow(title: "Breakfast", isOn: Binding(
                    get: { viewModel.business.servesBreakfast ?? false },
                    set: { viewModel.business.servesBreakfast = $0; viewModel.saveToFirestore() }
                ))
                
                ToggleRow(title: "Lunch", isOn: Binding(
                    get: { viewModel.business.servesLunch ?? false },
                    set: { viewModel.business.servesLunch = $0; viewModel.saveToFirestore() }
                ))
                
                ToggleRow(title: "Dinner", isOn: Binding(
                    get: { viewModel.business.servesDinner ?? false },
                    set: { viewModel.business.servesDinner = $0; viewModel.saveToFirestore() }
                ))
                
                ToggleRow(title: "Brunch", isOn: Binding(
                    get: { viewModel.business.servesBrunch ?? false },
                    set: { viewModel.business.servesBrunch = $0; viewModel.saveToFirestore() }
                ))
                
                ToggleRow(title: "Beer", isOn: Binding(
                    get: { viewModel.business.servesBeer ?? false },
                    set: { viewModel.business.servesBeer = $0; viewModel.saveToFirestore() }
                ))
                
                ToggleRow(title: "Wine", isOn: Binding(
                    get: { viewModel.business.servesWine ?? false },
                    set: { viewModel.business.servesWine = $0; viewModel.saveToFirestore() }
                ))
                
                ToggleRow(title: "Vegetarian Food", isOn: Binding(
                    get: { viewModel.business.servesVegetarianFood ?? false },
                    set: { viewModel.business.servesVegetarianFood = $0; viewModel.saveToFirestore() }
                ))
                
                ToggleRow(title: "Outdoor Seating", isOn: Binding(
                    get: { viewModel.business.outdoorSeating ?? false },
                    set: { viewModel.business.outdoorSeating = $0; viewModel.saveToFirestore() }
                ))
                
                ToggleRow(title: "Live Music", isOn: Binding(
                    get: { viewModel.business.liveMusic ?? false },
                    set: { viewModel.business.liveMusic = $0; viewModel.saveToFirestore() }
                ))
                
                ToggleRow(title: "Restroom", isOn: Binding(
                    get: { viewModel.business.restroom ?? false },
                    set: { viewModel.business.restroom = $0; viewModel.saveToFirestore() }
                ))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Accessibility Section (Advanced Mode)
    private var accessibilitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Accessibility & Groups")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ToggleRow(title: "Good for Children", isOn: Binding(
                    get: { viewModel.business.goodForChildren ?? false },
                    set: { viewModel.business.goodForChildren = $0; viewModel.saveToFirestore() }
                ))
                
                ToggleRow(title: "Good for Groups", isOn: Binding(
                    get: { viewModel.business.goodForGroups ?? false },
                    set: { viewModel.business.goodForGroups = $0; viewModel.saveToFirestore() }
                ))
                
                ToggleRow(title: "Allows Dogs", isOn: Binding(
                    get: { viewModel.business.allowsDogs ?? false },
                    set: { viewModel.business.allowsDogs = $0; viewModel.saveToFirestore() }
                ))
            }
            
            Divider()
            
            // Accessibility Options
            AccessibilityOptionsEditor(
                accessibilityOptions: Binding(
                    get: { viewModel.business.accessibilityOptions ?? AccessibilityOptions() },
                    set: { viewModel.business.accessibilityOptions = $0; viewModel.saveToFirestore() }
                )
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Payment & Parking Section (Advanced Mode)
    private var paymentParkingSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Payment & Parking")
                .font(.headline)
            
            // Price Level Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Price Level")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Picker("Price Level", selection: Binding(
                    get: { viewModel.business.priceLevel ?? "" },
                    set: { viewModel.business.priceLevel = $0.isEmpty ? nil : $0; viewModel.saveToFirestore() }
                )) {
                    Text("Not specified").tag("")
                    Text("$ (Inexpensive)").tag("PRICE_LEVEL_INEXPENSIVE")
                    Text("$ (Moderate)").tag("PRICE_LEVEL_MODERATE")
                    Text("$$ (Expensive)").tag("PRICE_LEVEL_EXPENSIVE")
                    Text("$$ (Very Expensive)").tag("PRICE_LEVEL_VERY_EXPENSIVE")
                }
                .pickerStyle(MenuPickerStyle())
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Divider()
            
            // Payment Options
            PaymentOptionsEditor(
                paymentOptions: Binding(
                    get: { viewModel.business.paymentOptions ?? PaymentOptions() },
                    set: { viewModel.business.paymentOptions = $0; viewModel.saveToFirestore() }
                )
            )
            
            Divider()
            
            // Parking Options
            ParkingOptionsEditor(
                parkingOptions: Binding(
                    get: { viewModel.business.parkingOptions ?? ParkingOptions() },
                    set: { viewModel.business.parkingOptions = $0; viewModel.saveToFirestore() }
                )
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Fuel & EV Section (Advanced Mode)
    private var fuelEvSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Fuel & EV Charging")
                .font(.headline)
            
            // Fuel Options
            FuelOptionsEditor(
                fuelOptions: Binding(
                    get: { viewModel.business.fuelOptions ?? FuelOptions(fuelTypes: nil) },
                    set: { viewModel.business.fuelOptions = $0; viewModel.saveToFirestore() }
                )
            )
            
            Divider()
            
            // EV Charging Options
            EVChargeOptionsEditor(
                evChargeOptions: Binding(
                    get: { viewModel.business.evChargeOptions ?? EVChargeOptions(connectorCount: nil, connectorAggregation: nil) },
                    set: { viewModel.business.evChargeOptions = $0; viewModel.saveToFirestore() }
                )
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// MARK: - Opening Hours Editor
struct OpeningHoursEditor: View {
    let title: String
    @Binding var openingHours: OpeningHours?
    let onSave: () -> Void
    
    @State private var periods: [Period] = []
    @State private var openNow: Bool = false
    
    private let daysOfWeek = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button(openingHours == nil ? "Add Hours" : "Edit Hours") {
                    initializeHours()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            if openingHours != nil {
                Toggle("Currently Open", isOn: Binding(
                    get: { openingHours?.openNow ?? false },
                    set: { newValue in
                        if openingHours == nil {
                            openingHours = OpeningHours(openNow: newValue, periods: nil, weekdayDescriptions: nil)
                        } else {
                            openingHours?.openNow = newValue
                        }
                        onSave()
                    }
                ))
                .toggleStyle(SwitchToggleStyle())
                
                if let descriptions = openingHours?.weekdayDescriptions {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(descriptions.enumerated()), id: \.offset) { index, description in
                            Text("\(daysOfWeek[safe: index] ?? "Day \(index + 1)"): \(description)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
    
    private func initializeHours() {
        if openingHours == nil {
            openingHours = OpeningHours(openNow: false, periods: [], weekdayDescriptions: [])
        }
        onSave()
    }
}

// MARK: - Payment Options Editor
struct PaymentOptionsEditor: View {
    @Binding var paymentOptions: PaymentOptions
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Payment Options")
                .font(.subheadline)
                .fontWeight(.medium)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ToggleRow(title: "Credit Cards", isOn: Binding(
                    get: { paymentOptions.acceptsCreditCards ?? false },
                    set: { paymentOptions.acceptsCreditCards = $0 }
                ))
                
                ToggleRow(title: "Debit Cards", isOn: Binding(
                    get: { paymentOptions.acceptsDebitCards ?? false },
                    set: { paymentOptions.acceptsDebitCards = $0 }
                ))
                
                ToggleRow(title: "Cash Only", isOn: Binding(
                    get: { paymentOptions.acceptsCashOnly ?? false },
                    set: { paymentOptions.acceptsCashOnly = $0 }
                ))
                
                ToggleRow(title: "NFC/Contactless", isOn: Binding(
                    get: { paymentOptions.acceptsNfc ?? false },
                    set: { paymentOptions.acceptsNfc = $0 }
                ))
            }
        }
    }
}

// MARK: - Parking Options Editor
struct ParkingOptionsEditor: View {
    @Binding var parkingOptions: ParkingOptions
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Parking Options")
                .font(.subheadline)
                .fontWeight(.medium)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Paid Parking")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 6) {
                    ToggleRow(title: "Garage", isOn: Binding(
                        get: { parkingOptions.paidGarageParking ?? false },
                        set: { parkingOptions.paidGarageParking = $0 }
                    ))
                    
                    ToggleRow(title: "Lot", isOn: Binding(
                        get: { parkingOptions.paidLotParking ?? false },
                        set: { parkingOptions.paidLotParking = $0 }
                    ))
                    
                    ToggleRow(title: "Street", isOn: Binding(
                        get: { parkingOptions.paidStreetParking ?? false },
                        set: { parkingOptions.paidStreetParking = $0 }
                    ))
                    
                    ToggleRow(title: "Valet", isOn: Binding(
                        get: { parkingOptions.valetParking ?? false },
                        set: { parkingOptions.valetParking = $0 }
                    ))
                }
                
                Divider().padding(.vertical, 4)
                
                Text("Free Parking")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 6) {
                    ToggleRow(title: "Garage", isOn: Binding(
                        get: { parkingOptions.freeGarageParking ?? false },
                        set: { parkingOptions.freeGarageParking = $0 }
                    ))
                    
                    ToggleRow(title: "Lot", isOn: Binding(
                        get: { parkingOptions.freeLotParking ?? false },
                        set: { parkingOptions.freeLotParking = $0 }
                    ))
                    
                    ToggleRow(title: "Street", isOn: Binding(
                        get: { parkingOptions.freeStreetParking ?? false },
                        set: { parkingOptions.freeStreetParking = $0 }
                    ))
                }
            }
        }
    }
}

// MARK: - Accessibility Options Editor
struct AccessibilityOptionsEditor: View {
    @Binding var accessibilityOptions: AccessibilityOptions
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Wheelchair Accessibility")
                .font(.subheadline)
                .fontWeight(.medium)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ToggleRow(title: "Accessible Parking", isOn: Binding(
                    get: { accessibilityOptions.wheelchairAccessibleParking ?? false },
                    set: { accessibilityOptions.wheelchairAccessibleParking = $0 }
                ))
                
                ToggleRow(title: "Accessible Entrance", isOn: Binding(
                    get: { accessibilityOptions.wheelchairAccessibleEntrance ?? false },
                    set: { accessibilityOptions.wheelchairAccessibleEntrance = $0 }
                ))
                
                ToggleRow(title: "Accessible Restroom", isOn: Binding(
                    get: { accessibilityOptions.wheelchairAccessibleRestroom ?? false },
                    set: { accessibilityOptions.wheelchairAccessibleRestroom = $0 }
                ))
                
                ToggleRow(title: "Accessible Seating", isOn: Binding(
                    get: { accessibilityOptions.wheelchairAccessibleSeating ?? false },
                    set: { accessibilityOptions.wheelchairAccessibleSeating = $0 }
                ))
            }
        }
    }
}

// MARK: - Fuel Options Editor
struct FuelOptionsEditor: View {
    @Binding var fuelOptions: FuelOptions
    @State private var selectedFuelTypes: Set<String> = []
    
    private let availableFuelTypes = [
        "DIESEL", "REGULAR_UNLEADED", "MIDGRADE", "PREMIUM", "SP91", "SP91_E10", "SP92", "SP95", "SP95_E10", "SP98", "SP99", "SP100", "LPG", "E85", "TRUCK_DIESEL"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Fuel Types Available")
                .font(.subheadline)
                .fontWeight(.medium)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 6) {
                ForEach(availableFuelTypes, id: \.self) { fuelType in
                    HStack {
                        Text(fuelType.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(.caption)
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { fuelOptions.fuelTypes?.contains(fuelType) ?? false },
                            set: { isSelected in
                                var currentTypes = fuelOptions.fuelTypes ?? []
                                if isSelected {
                                    if !currentTypes.contains(fuelType) {
                                        currentTypes.append(fuelType)
                                    }
                                } else {
                                    currentTypes.removeAll { $0 == fuelType }
                                }
                                fuelOptions.fuelTypes = currentTypes.isEmpty ? nil : currentTypes
                            }
                        ))
                        .labelsHidden()
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .onAppear {
            selectedFuelTypes = Set(fuelOptions.fuelTypes ?? [])
        }
    }
}

// MARK: - EV Charge Options Editor
struct EVChargeOptionsEditor: View {
    @Binding var evChargeOptions: EVChargeOptions
    @State private var connectorAggregations: [ConnectorAggregation] = []
    
    private let connectorTypes = ["OTHER", "J1772", "TYPE_2", "CHAdeMO", "CCS_COMBO_1", "CCS_COMBO_2", "TESLA", "UNSPECIFIED"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("EV Charging Options")
                .font(.subheadline)
                .fontWeight(.medium)
            
            HStack {
                Text("Total Connectors")
                    .font(.caption)
                Spacer()
                TextField("Count", value: Binding(
                    get: { evChargeOptions.connectorCount ?? 0 },
                    set: { evChargeOptions.connectorCount = $0 == 0 ? nil : $0 }
                ), format: .number)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 80)
                .keyboardType(.numberPad)
            }
            
            if connectorAggregations.isEmpty {
                Button("Add Connector Type") {
                    addConnectorType()
                }
                .font(.caption)
                .foregroundColor(.blue)
            } else {
                ForEach(Array(connectorAggregations.enumerated()), id: \.offset) { index, connector in
                    ConnectorRow(
                        connector: Binding(
                            get: { connectorAggregations[index] },
                            set: { connectorAggregations[index] = $0; updateConnectors() }
                        ),
                        availableTypes: connectorTypes,
                        onDelete: { removeConnectorType(at: index) }
                    )
                }
                
                Button("Add Another Connector") {
                    addConnectorType()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .onAppear {
            connectorAggregations = evChargeOptions.connectorAggregation ?? []
        }
    }
    
    private func addConnectorType() {
        connectorAggregations.append(ConnectorAggregation(type: nil, maxChargeRateKw: nil, count: nil))
        updateConnectors()
    }
    
    private func removeConnectorType(at index: Int) {
        connectorAggregations.remove(at: index)
        updateConnectors()
    }
    
    private func updateConnectors() {
        evChargeOptions.connectorAggregation = connectorAggregations.isEmpty ? nil : connectorAggregations
    }
}

// MARK: - Connector Row
struct ConnectorRow: View {
    @Binding var connector: ConnectorAggregation
    let availableTypes: [String]
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Picker("Type", selection: Binding(
                    get: { connector.type ?? "OTHER" },
                    set: { connector.type = $0 }
                )) {
                    ForEach(availableTypes, id: \.self) { type in
                        Text(type.replacingOccurrences(of: "_", with: " ")).tag(type)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                
                Spacer()
                
                Button("Remove") {
                    onDelete()
                }
                .font(.caption)
                .foregroundColor(.red)
            }
            
            HStack(spacing: 12) {
                VStack(alignment: .leading) {
                    Text("Count")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    TextField("0", value: Binding(
                        get: { connector.count ?? 0 },
                        set: { connector.count = $0 == 0 ? nil : $0 }
                    ), format: .number)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .frame(width: 60)
                }
                
                VStack(alignment: .leading) {
                    Text("Max kW")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    TextField("0.0", value: Binding(
                        get: { connector.maxChargeRateKw ?? 0.0 },
                        set: { connector.maxChargeRateKw = $0 == 0.0 ? nil : $0 }
                    ), format: .number)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
                    .frame(width: 80)
                }
                
                Spacer()
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Array Extension for Safe Access
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Toggle Row Component
struct ToggleRow: View {
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 14))
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
struct BusinessEditorView_Previews: PreviewProvider {
    static var previews: some View {
        if let business = createSampleBusiness() {
            BusinessEditorView(business: business)
        }
    }
    
    static func createSampleBusiness() -> SlideBusiness? {
        let samplePlace = createPlaceDetailsFromJSON()
        if let business = samplePlace, let convertedPlace = convertPlaceToSlideBusiness(place: business) {
            return convertedPlace
        }
        return nil
    }
}

