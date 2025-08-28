//
//  PlaceDetailsResponse.swift
//  Slide
//
//  Created by Nick Rogers on 8/23/25.
//



import Foundation
import Combine
import SwiftUI
import _MapKit_SwiftUI


// MARK: - Main Detail View
struct FullPlaceDetailView: View {
    let place: PlaceDetailsResponse
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                // Header Section
                PlaceHeaderView(place: place)
                
                // Basic Information
                if hasBasicInfo {
                    PlaceBasicInfoView(place: place)
                }
                
                // Contact Information
                if hasContactInfo {
                    PlaceContactInfoView(place: place)
                }
                
                // Hours & Status
                if hasHoursInfo {
                    PlaceHoursView(place: place)
                }
                
                // Services & Amenities
                if hasServicesInfo {
                    PlaceServicesView(place: place)
                }
                
                // Accessibility & Parking
                if hasAccessibilityInfo {
                    PlaceAccessibilityView(place: place)
                }
                
                // Payment & Fuel Options
                if hasPaymentInfo {
                    PlacePaymentOptionsView(place: place)
                }
                
                // Reviews Section
                if let reviews = place.reviews, !reviews.isEmpty {
                    PlaceReviewsView(reviews: reviews)
                }
                
                // Photos Section
                if let photos = place.photos, !photos.isEmpty {
                    PlacePhotosView(photos: photos)
                }
                
                // Location & Address Details
                if hasLocationInfo {
                    PlaceLocationView(place: place)
                }
            }
            .padding()
        }
        .navigationTitle(place.displayName?.text ?? place.name ?? "Place Details")
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - Computed Properties for Conditional Sections
    private var hasBasicInfo: Bool {
        place.rating != nil || place.userRatingCount != nil ||
        place.priceLevel != nil || place.primaryType != nil ||
        place.editorialSummary != nil || place.generativeSummary != nil
    }
    
    private var hasContactInfo: Bool {
        place.nationalPhoneNumber != nil || place.internationalPhoneNumber != nil ||
        place.websiteUri != nil || place.googleMapsUri != nil
    }
    
    private var hasHoursInfo: Bool {
        place.regularOpeningHours != nil || place.currentOpeningHours != nil ||
        place.businessStatus != nil
    }
    
    private var hasServicesInfo: Bool {
        place.takeout == true || place.delivery == true || place.dineIn == true ||
        place.curbsidePickup == true || place.reservable == true ||
        place.servesBreakfast == true || place.servesLunch == true ||
        place.servesDinner == true || place.servesBrunch == true ||
        place.servesVegetarianFood == true || place.servesBeer == true ||
        place.servesWine == true
    }
    
    private var hasAccessibilityInfo: Bool {
        place.accessibilityOptions != nil || place.parkingOptions != nil ||
        place.goodForChildren == true || place.goodForGroups == true ||
        place.allowsDogs == true || place.outdoorSeating == true ||
        place.liveMusic == true || place.restroom == true
    }
    
    private var hasPaymentInfo: Bool {
        place.paymentOptions != nil || place.fuelOptions != nil || place.evChargeOptions != nil
    }
    
    private var hasLocationInfo: Bool {
        place.location != nil || place.formattedAddress != nil ||
        place.addressComponents != nil || place.plusCode != nil
    }
}

// MARK: - Header View
struct PlaceHeaderView: View {
    let place: PlaceDetailsResponse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(place.displayName?.text ?? place.name ?? "Unknown Place")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let primaryType = place.primaryTypeDisplayName?.text ?? place.primaryType {
                        Text(primaryType.capitalized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if let rating = place.rating {
                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            Text(String(format: "%.1f", rating))
                                .fontWeight(.semibold)
                        }
                        
                        if let count = place.userRatingCount {
                            Text("(\(count))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            if let address = place.shortFormattedAddress ?? place.formattedAddress {
                Label(address, systemImage: "location")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Status indicators
            HStack {
                if let businessStatus = place.businessStatus, businessStatus.lowercased() == "operational" {
                    StatusBadge(text: "Open", color: .green)
                } else if let businessStatus = place.businessStatus {
                    StatusBadge(text: businessStatus, color: .red)
                }
                
                if let priceLevel = place.priceLevel {
                    StatusBadge(text: getPriceLevelText(priceLevel), color: .blue)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 30))
    }
    
    private func getPriceLevelText(_ priceLevel: String) -> String {
        switch priceLevel.uppercased() {
        case "PRICE_LEVEL_FREE": return "Free"
        case "PRICE_LEVEL_INEXPENSIVE": return "$"
        case "PRICE_LEVEL_MODERATE": return "$$"
        case "PRICE_LEVEL_EXPENSIVE": return "$$$"
        case "PRICE_LEVEL_VERY_EXPENSIVE": return "$$$$"
        default: return priceLevel
        }
    }
}

// MARK: - Basic Info Section
struct PlaceBasicInfoView: View {
    let place: PlaceDetailsResponse
    
    var body: some View {
        SectionView(title: "About", icon: "info.circle") {
            VStack(alignment: .leading, spacing: 12) {
                if let summary = place.generativeSummary?.overview?.text {
                    Text(summary)
                        .font(.body)
                        .padding()
                        .background(Color(.accent).opacity(0.1))
                        .cornerRadius(20)
                }
                
                if let editorial = place.editorialSummary?.text {
                    Text(editorial)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                if let types = place.types, !types.isEmpty {
                    FlowLayout {
                        ForEach(types, id: \.self) { type in
                            Text(type.replacingOccurrences(of: "_", with: " ").capitalized)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.systemGray5), in: .capsule)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Contact Information
struct PlaceContactInfoView: View {
    let place: PlaceDetailsResponse
    
    var body: some View {
        SectionView(title: "Contact", icon: "phone") {
            VStack(spacing: 8) {
                if let phone = place.nationalPhoneNumber ?? place.internationalPhoneNumber {
                    ContactRow(icon: "phone", text: phone, action: {
                        if let url = URL(string: "tel:\(phone)") {
                            UIApplication.shared.open(url)
                        }
                    })
                }
                
                if let website = place.websiteUri {
                    ContactRow(icon: "globe", text: "Visit Website", action: {
                        if let url = URL(string: website) {
                            UIApplication.shared.open(url)
                        }
                    })
                }
                
                if let mapsUri = place.googleMapsUri {
                    ContactRow(icon: "map", text: "Open in Maps", action: {
                        if let url = URL(string: mapsUri) {
                            UIApplication.shared.open(url)
                        }
                    })
                }
            }
        }
    }
}

// MARK: - Hours View
struct PlaceHoursView: View {
    let place: PlaceDetailsResponse
    
    var body: some View {
        SectionView(title: "Hours", icon: "clock") {
            VStack(alignment: .leading, spacing: 8) {
                if let openingHours = place.regularOpeningHours {
                    if let isOpen = openingHours.openNow {
                        HStack {
                            Circle()
                                .fill(isOpen ? Color.green : Color.red)
                                .frame(width: 8, height: 8)
                            Text(isOpen ? "Open now" : "Closed now")
                                .fontWeight(.medium)
                        }
                    }
                    
                    if let descriptions = openingHours.weekdayDescriptions {
                        ForEach(descriptions, id: \.self) { description in
                            Text(description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                if let currentHours = place.currentOpeningHours,
                   let descriptions = currentHours.weekdayDescriptions {
                    Text("Current Hours:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.top, 8)
                    
                    ForEach(descriptions, id: \.self) { description in
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Services View
struct PlaceServicesView: View {
    let place: PlaceDetailsResponse
    
    var body: some View {
        SectionView(title: "Services & Dining", icon: "fork.knife") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ServiceItem(title: "Takeout", isAvailable: place.takeout)
                ServiceItem(title: "Delivery", isAvailable: place.delivery)
                ServiceItem(title: "Dine In", isAvailable: place.dineIn)
                ServiceItem(title: "Curbside Pickup", isAvailable: place.curbsidePickup)
                ServiceItem(title: "Reservations", isAvailable: place.reservable)
                ServiceItem(title: "Breakfast", isAvailable: place.servesBreakfast)
                ServiceItem(title: "Lunch", isAvailable: place.servesLunch)
                ServiceItem(title: "Dinner", isAvailable: place.servesDinner)
                ServiceItem(title: "Brunch", isAvailable: place.servesBrunch)
                ServiceItem(title: "Vegetarian", isAvailable: place.servesVegetarianFood)
                ServiceItem(title: "Beer", isAvailable: place.servesBeer)
                ServiceItem(title: "Wine", isAvailable: place.servesWine)
            }
        }
    }
}

// MARK: - Accessibility View
struct PlaceAccessibilityView: View {
    let place: PlaceDetailsResponse
    
    var body: some View {
        SectionView(title: "Accessibility & Amenities", icon: "figure.walk") {
            VStack(spacing: 12) {
                // Accessibility options
                if let accessibility = place.accessibilityOptions {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Accessibility")
                            .font(.headline)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                            ServiceItem(title: "Wheelchair Parking", isAvailable: accessibility.wheelchairAccessibleParking)
                            ServiceItem(title: "Wheelchair Entrance", isAvailable: accessibility.wheelchairAccessibleEntrance)
                            ServiceItem(title: "Wheelchair Restroom", isAvailable: accessibility.wheelchairAccessibleRestroom)
                            ServiceItem(title: "Wheelchair Seating", isAvailable: accessibility.wheelchairAccessibleSeating)
                        }
                    }
                }
                
                // Parking options
                if let parking = place.parkingOptions {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Parking")
                            .font(.headline)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                            ServiceItem(title: "Paid Garage", isAvailable: parking.paidGarageParking)
                            ServiceItem(title: "Paid Lot", isAvailable: parking.paidLotParking)
                            ServiceItem(title: "Paid Street", isAvailable: parking.paidStreetParking)
                            ServiceItem(title: "Valet", isAvailable: parking.valetParking)
                            ServiceItem(title: "Free Garage", isAvailable: parking.freeGarageParking)
                            ServiceItem(title: "Free Lot", isAvailable: parking.freeLotParking)
                            ServiceItem(title: "Free Street", isAvailable: parking.freeStreetParking)
                        }
                    }
                }
                
                // General amenities
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ServiceItem(title: "Good for Children", isAvailable: place.goodForChildren)
                    ServiceItem(title: "Good for Groups", isAvailable: place.goodForGroups)
                    ServiceItem(title: "Dog Friendly", isAvailable: place.allowsDogs)
                    ServiceItem(title: "Outdoor Seating", isAvailable: place.outdoorSeating)
                    ServiceItem(title: "Live Music", isAvailable: place.liveMusic)
                    ServiceItem(title: "Restroom", isAvailable: place.restroom)
                }
            }
        }
    }
}

// MARK: - Payment Options View
struct PlacePaymentOptionsView: View {
    let place: PlaceDetailsResponse
    
    var body: some View {
        SectionView(title: "Payment & Fuel", icon: "creditcard") {
            VStack(spacing: 12) {
                if let payment = place.paymentOptions {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Payment Options")
                            .font(.headline)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                            ServiceItem(title: "Credit Cards", isAvailable: payment.acceptsCreditCards)
                            ServiceItem(title: "Debit Cards", isAvailable: payment.acceptsDebitCards)
                            ServiceItem(title: "Cash Only", isAvailable: payment.acceptsCashOnly)
                            ServiceItem(title: "NFC Payment", isAvailable: payment.acceptsNfc)
                        }
                    }
                }
                
                if let fuel = place.fuelOptions, let types = fuel.fuelTypes {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Fuel Types")
                            .font(.headline)
                        
                        FlowLayout {
                            ForEach(types, id: \.self) { type in
                                Text(type)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(.systemGreen).opacity(0.2))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                
                if let ev = place.evChargeOptions {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("EV Charging")
                            .font(.headline)
                        
                        if let count = ev.connectorCount {
                            Text("\(count) connectors available")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Reviews View
struct PlaceReviewsView: View {
    let reviews: [Review]
    
    var body: some View {
        SectionView(title: "Reviews", icon: "star.bubble") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(Array(reviews.prefix(5).enumerated()), id: \.offset) { index, review in
                        ReviewCard(review: review)
                            .frame(width: 280)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Photos View
struct PlacePhotosView: View {
    let photos: [Photo]
    
    var body: some View {
        SectionView(title: "Photos", icon: "photo") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(photos.prefix(10).enumerated()), id: \.offset) { index, photo in
                        AsyncImage(url: URL(string: photo.googleMapsUri ?? "")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(Color(.systemGray4))
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(.secondary)
                                )
                        }
                        .frame(width: 120, height: 120)
                        .cornerRadius(8)
                        .clipped()
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Location View
struct PlaceLocationView: View {
    let place: PlaceDetailsResponse
    
    var body: some View {
        SectionView(title: "Location", icon: "location") {
            VStack(alignment: .leading, spacing: 12) {
                if let location = place.location {
                    Map(coordinateRegion: .constant(MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude),
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )), annotationItems: [location]) { location in
                        MapPin(coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude))
                    }
                    .frame(height: 200)
                    .cornerRadius(8)
                }
                
                if let address = place.formattedAddress {
                    Text(address)
                        .font(.subheadline)
                }
                
                if let plusCode = place.plusCode?.globalCode {
                    HStack {
                        Text("Plus Code:")
                            .fontWeight(.medium)
                        Text(plusCode)
                            .font(.monospaced(.subheadline)())
                            .foregroundColor(.secondary)
                    }
                }
                
                if let components = place.addressComponents, !components.isEmpty {
                    DisclosureGroup("Address Components") {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(Array(components.enumerated()), id: \.offset) { index, component in
                                HStack {
                                    Text(component.longText)
                                    Spacer()
                                    Text(component.types.joined(separator: ", "))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.top, 8)
                    }
                }
            }
        }
    }
}

// MARK: - Helper Views
struct SectionView<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.orange)
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            content
        }
        .padding()
        .background(Color(.gray).opacity(0.2))
        .cornerRadius(30)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct StatusBadge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2), in: .capsule)
            .foregroundColor(color)
    }
}

struct ServiceItem: View {
    let title: String
    let isAvailable: Bool?
    
    var body: some View {
        HStack {
            Image(systemName: isAvailable == true ? "checkmark.circle.fill" :
                  isAvailable == false ? "xmark.circle" : "questionmark.circle")
                .foregroundColor(isAvailable == true ? .green :
                               isAvailable == false ? .red : .gray)
            
            Text(title)
                .font(.caption)
                .foregroundColor(isAvailable == nil ? .secondary : .primary)
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}

struct ContactRow: View {
    let icon: String
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                
                Text(text)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

struct ReviewCard: View {
    let review: Review
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let author = review.authorAttribution?.displayName {
                    Text(author)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                if let rating = review.rating {
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= rating ? "star.fill" : "star")
                                .font(.caption)
                                .foregroundColor(.yellow)
                        }
                    }
                }
            }
            
            if let text = review.text?.text {
                Text(text)
                    .font(.caption)
                    .lineLimit(4)
                    .multilineTextAlignment(.leading)
            }
            
            if let publishTime = review.relativePublishTimeDescription {
                Text(publishTime)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct FlowLayout: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews
        )
        return result.bounds
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX,
                                    y: bounds.minY + result.frames[index].minY),
                         proposal: ProposedViewSize(result.frames[index].size))
        }
    }
    
    struct FlowResult {
        var bounds = CGSize.zero
        var frames: [CGRect] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + 8
                    lineHeight = 0
                }
                
                frames.append(CGRect(x: x, y: y, width: size.width, height: size.height))
                
                lineHeight = max(lineHeight, size.height)
                x += size.width + 8
                bounds.width = max(bounds.width, x - 8)
            }
            
            bounds.height = y + lineHeight
        }
    }
}

// MARK: - Preview
struct PlaceDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            if let place = createPlaceDetailsFromJSON() {
                FullPlaceDetailView(place: place)
            }
        }
    }
    
    static var samplePlace: PlaceDetailsResponse {
        PlaceDetailsResponse(
            id: "sample-id",
            name: "Sample Restaurant",
            displayName: DisplayName(text: "Sample Restaurant", languageCode: "en"),
            formattedAddress: "123 Main St, City, State 12345",
            location: GeoLocation(latitude: 37.7749, longitude: -122.4194),
            plusCode: PlusCode(globalCode: "849VCWC8+R9", compoundCode: nil),
            types: ["restaurant", "food", "establishment"],
            businessStatus: "OPERATIONAL",
            rating: 4.5,
            userRatingCount: 150,
            websiteUri: "https://example.com",
            nationalPhoneNumber: "(555) 123-4567",
            internationalPhoneNumber: "+1 555-123-4567",
            addressComponents: nil,
            addressDescriptor: nil,
            photos: nil,
            viewport: nil,
            googleMapsUri: "https://maps.google.com",
            regularOpeningHours: OpeningHours(
                openNow: true,
                periods: nil,
                weekdayDescriptions: ["Monday: 9:00 AM – 10:00 PM", "Tuesday: 9:00 AM – 10:00 PM"]
            ),
            currentOpeningHours: nil,
            primaryType: "restaurant",
            primaryTypeDisplayName: DisplayName(text: "Restaurant", languageCode: "en"),
            shortFormattedAddress: "123 Main St",
            editorialSummary: DisplayName(text: "A great place to eat!", languageCode: "en"),
            reviews: nil,
            paymentOptions: PaymentOptions(
                acceptsCreditCards: true,
                acceptsDebitCards: true,
                acceptsCashOnly: false,
                acceptsNfc: true
            ),
            parkingOptions: nil,
            accessibilityOptions: nil,
            fuelOptions: nil,
            evChargeOptions: nil,
            generativeSummary: nil,
            priceLevel: "PRICE_LEVEL_MODERATE",
            userRatingsTotal: nil,
            utcOffset: nil,
            adrFormatAddress: nil,
            businessStatus_: nil,
            iconMaskBaseUri: nil,
            iconBackgroundColor: nil,
            takeout: true,
            delivery: true,
            dineIn: true,
            curbsidePickup: false,
            reservable: true,
            servesBreakfast: true,
            servesLunch: true,
            servesDinner: true,
            servesBeer: true,
            servesWine: true,
            servesBrunch: true,
            servesVegetarianFood: true,
            outdoorSeating: true,
            liveMusic: false,
            restroom: true,
            goodForChildren: true,
            goodForGroups: true,
            allowsDogs: false,
            googleMapsLinks: nil,
            reviewSummary: nil,
            postalAddress: nil
        )
    }
}


struct PlaceDetailsView: View {
    @StateObject private var placesService = GooglePlacesService(apiKey: "AIzaSyARxu6sVxRQ1JV097gqRhN7ierVoODA-4A", locationManager: LocationManager.shared)
    @State private var placeDetails: PlaceDetailsResponse?
    @State private var selectedDetailType = DetailType.allFields
    var placeId: String
    
    enum DetailType: String, CaseIterable {
           case basic = "Basic"
           case essential = "Essential"
           case pro = "Pro"
           case enterprise = "Enterprise"
           case addressDescriptors = "Address Descriptors"
           case allFields = "All Fields"
       }
    
    
    var body: some View {
        Group {
            if let place = placeDetails {
                FullPlaceDetailView(place: place)
            } else {
                ProgressView()
            }
        }
        .onAppear() {
            Task {
                await fetchPlaceDetails()
            }
        }
    }
    
    @MainActor
      private func fetchPlaceDetails() async {
          do {
              switch selectedDetailType {
              case .basic:
                  placeDetails = try await placesService.getBasicDetails(placeId: placeId)
              case .essential:
                  placeDetails = try await placesService.getEssentialDetails(placeId: placeId)
              case .pro:
                  placeDetails = try await placesService.getProDetails(placeId: placeId)
              case .enterprise:
                  placeDetails = try await placesService.getEnterpriseDetails(placeId: placeId)
              case .addressDescriptors:
                  placeDetails = try await placesService.getAddressDescriptors(placeId: placeId)
              case .allFields:
                  placeDetails = try await placesService.getPlaceDetails(
                      placeId: placeId,
                      fields: PlaceDetailsField.allCases
                  )
              }
          } catch {
              print("Error fetching place details: \(error)")
          }
      }
}
