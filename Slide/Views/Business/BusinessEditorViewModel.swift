import SwiftUI
import FirebaseFirestore
import PhotosUI

// MARK: - Business Editor View Model
@MainActor
class BusinessEditorViewModel: ObservableObject {
    @Published var business: SlideBusiness
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isAdvancedMode = false
    @Published var selectedProfilePhoto: PhotosPickerItem?
    @Published var selectedBannerPhoto: PhotosPickerItem?
    
    private let db = Firestore.firestore()
    private var debounceTimer: Timer?
    
    init(business: SlideBusiness) {
        self.business = business
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
    
    // MARK: - Photo Upload Methods
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
        // Assuming you have a photo upload service
        // Replace with your actual photo upload implementation
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Mock upload - replace with actual implementation
            let photoURL = "https://example.com/photo_\(UUID().uuidString).jpg"
            
            switch type {
            case .profile:
                business.profilePhoto = photoURL
            case .banner:
                business.bannerPhoto = photoURL
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
        .background(Color(.systemGray6))
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
                        AsyncImage(url: URL(string: viewModel.business.profilePhoto ?? "")) { image in
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
                        AsyncImage(url: URL(string: viewModel.business.bannerPhoto ?? "")) { image in
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
            
            // Note: This is a simplified implementation
            // You'll need to implement proper opening hours editing based on your OpeningHours structure
            Text("Regular Hours")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Current Hours")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Add your opening hours editing components here
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
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Payment & Parking Section (Advanced Mode)
    private var paymentParkingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
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
                    Text("$$ (Moderate)").tag("PRICE_LEVEL_MODERATE")
                    Text("$$$ (Expensive)").tag("PRICE_LEVEL_EXPENSIVE")
                    Text("$$$$ (Very Expensive)").tag("PRICE_LEVEL_VERY_EXPENSIVE")
                }
                .pickerStyle(MenuPickerStyle())
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Note: PaymentOptions and ParkingOptions would need custom UI based on their structure
            Text("Payment Options")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Parking Options")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Fuel & EV Section (Advanced Mode)
    private var fuelEvSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Fuel & EV Charging")
                .font(.headline)
            
            // Note: FuelOptions and EVChargeOptions would need custom UI based on their structure
            Text("Fuel Options")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("EV Charging Options")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
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
        let sampleBusiness = SlideBusiness(
            id: "sample-id",
            displayName: DisplayName(text: "Sample Business", languageCode: "en"),
            formattedAddress: "123 Main St, City, State",
            createdAt: Timestamp(),
            updatedAt: Timestamp()
        )
        
        BusinessEditorView(business: sampleBusiness)
    }
}