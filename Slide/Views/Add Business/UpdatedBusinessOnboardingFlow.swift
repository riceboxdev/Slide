//
//  UpdatedBusinessOnboardingFlow.swift
//  Slide
//
//  Created by Nick Rogers on 8/23/25.
//

import Combine
import SwiftUI
import FirebaseFirestore

struct UpdatedBusinessOnboardingFlow: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var model = UpdatedOnboardingFlowManager()

    var body: some View {
        NavigationView {
            ZStack {
                switch model.step {
                case .search:
                    AddressAutocompleteView(placesService: model.placesService)
                    { suggestion in
                        handleSelection(suggestion: suggestion)
                    }
                    .id(OnboardingFlowStep.search)
                    .transition(stepTransition)

                case .confirmDetails:
                    FullPlaceDetailView(place: model.placeDetails)
                        .toolbar {
                            ToolbarSpacer(placement: .bottomBar)
                            ToolbarItem(placement: .bottomBar) {
                                Button("Next") {
                                    model.nextStep()
                                }
                                .buttonStyle(.glassProminent)
                            }
                        }
                        .id(OnboardingFlowStep.confirmDetails)
                        .transition(stepTransition)

                case .customize:
                    CustomizePhotosView(
                        bannerPhoto: $model.bannerPhoto,
                        profilePhoto: $model.profilePhoto,
                        place: model.placeDetails
                    ) { photos in

                    }
                    .toolbar {
                        ToolbarSpacer(placement: .bottomBar)
                        ToolbarItem(placement: .bottomBar) {
                            Button("Next") {
                                model.nextStep()
                            }
                            .buttonStyle(.glassProminent)
                        }
                    }
                    .id(OnboardingFlowStep.customize)
                    .transition(stepTransition)
                case .finalize:
                    FinalizeBusinessView(place: model.placeDetails)
                        .toolbar {
                            ToolbarSpacer(placement: .bottomBar)
                            ToolbarItem(placement: .bottomBar) {
                                Button("Next") {
                                    Task {
                                        try await model.finishOnboarding()
                                    }
                                }
                                .buttonStyle(.glassProminent)
                            }
                        }
                }
            }
            .animation(.smooth, value: model.step)
            .background {
                VStack {
                    Image("demo4")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 300)
                        .clipped()
                        .linearGradientMask(.bottomToTop)
                        .ignoresSafeArea()
                    Spacer()
                }
                .background(.green.opacity(0.05))
            }
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                if model.step != .search {
                    ToolbarSpacer(.fixed, placement: .navigation)
                    ToolbarItem(placement: .navigation) {
                        Button("", systemImage: "arrow.left") {
                            model.previousStep()
                        }
                    }
                }
            }
        }
    }

    var stepTransition: AnyTransition {
        if model.isNavigatingForeward {
            return .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
        } else {
            return .asymmetric(
                insertion: .move(edge: .leading).combined(with: .opacity),
                removal: .move(edge: .trailing).combined(with: .opacity)
            )
        }
    }

    func handleSelection(suggestion: AutocompleteSuggestion) {
        self.model.placesService.selectedPlace = suggestion
        if suggestion.isPlace, let placeId = suggestion.placeId {
            Task {
                let details = try await model.placesService
                    .getPlaceDetails(
                        placeId: placeId,
                        fields: PlaceDetailsField.allCases
                    )
                await MainActor.run {
                    model.placeDetails = details
                    model.createdBusiness = convertPlaceToSlideBusiness(place: details)
                    hideKeyboard()
                    model.nextStep()
                }
            }
        } else {
            model.placesService.placeDetails = nil
            hideKeyboard()
        }
    }
}

class UpdatedOnboardingFlowManager: ObservableObject {
    @Published var step: OnboardingFlowStep = .search
    @Published var isLoading = false
    @Published var isNavigatingForeward = true
    @Published var placeDetails: PlaceDetailsResponse?
    @Published var profilePhoto: UIImage?
    @Published var bannerPhoto: UIImage?
    @Published var createdBusiness: SlideBusiness?

    let placesService: GooglePlacesService = GooglePlacesService(
        apiKey: "AIzaSyARxu6sVxRQ1JV097gqRhN7ierVoODA-4A",
        locationManager: LocationManager.shared
    )
    let photoUploader: FirebaseImageManager = FirebaseImageManager()

    func finishOnboarding() async throws {
        guard let createdBusiness else {
            throw BusinessOnboardingError.noBusinessCreatedYet
        }
        try await uploadPhotos()
        try await saveBusinessToFirestore(business: createdBusiness)
    }
    
    private func saveBusinessToFirestore(business: SlideBusiness) async throws {
        let manager = SlideBusinessManager()
        guard let slideBusiness = createdBusiness else {
            throw BusinessOnboardingError.noBusinessCreatedYet
        }
        self.isLoading = true
        
        _ = try await manager.addBusiness(slideBusiness)
        
        self.isLoading = false
        
    }
    
    private func uploadPhotos() async throws {
        guard let profilePhoto, let bannerPhoto else {
            return
        }
        let profileUpload = try await photoUploader.uploadImageAsync(profilePhoto)
        let bannerUpload = try await photoUploader.uploadImageAsync(bannerPhoto)
        
        createdBusiness?.profilePhoto = profileUpload.id
        createdBusiness?.bannerPhoto = bannerUpload.id
    }

    @MainActor
    func nextStep() {
        withAnimation(.smooth) {
            self.isNavigatingForeward = true
            switch step {
            case .search:
                self.step = .confirmDetails
            case .confirmDetails:
                self.step = .customize
            case .customize:
                self.step = .finalize
            case .finalize:
                break
            }
        }
    }

    @MainActor
    func previousStep() {
        withAnimation(.smooth) {
            self.isNavigatingForeward = false
            switch step {
            case .search:
                break
            case .confirmDetails:
                self.step = .search
            case .customize:
                self.step = .confirmDetails
            case .finalize:
                self.step = .customize
            }
        }
    }
}

enum BusinessOnboardingError: Error {
    case noPlaceSelected
    case noBusinessCreatedYet
}

enum OnboardingFlowStep {
    case search
    case confirmDetails
    case customize
    case finalize
}

func convertPlaceToSlideBusiness(place: PlaceDetailsResponse)
    -> SlideBusiness?
{
    return SlideBusiness(
        id: "7A470EA3-3C3B-421F-BEC0-878840C4309A",
        displayName: place.displayName,
        formattedAddress: place.formattedAddress,
        location: place.location,
        plusCode: place.plusCode,
        types: place.types,
        businessStatus: place.businessStatus,
        rating: place.rating,
        userRatingCount: place.userRatingCount,
        websiteUri: place.websiteUri,
        nationalPhoneNumber: place.nationalPhoneNumber,
        internationalPhoneNumber: place.internationalPhoneNumber,
        addressComponents: place.addressComponents,
        addressDescriptor: place.addressDescriptor,
        photos: place.photos,
        viewport: place.viewport,
        googleMapsUri: place.googleMapsUri,
        regularOpeningHours: place.regularOpeningHours,
        currentOpeningHours: place.currentOpeningHours,
        primaryType: place.primaryType,
        primaryTypeDisplayName: place.primaryTypeDisplayName,
        shortFormattedAddress: place.shortFormattedAddress,
        editorialSummary: place.editorialSummary,
        reviews: place.reviews,
        paymentOptions: place.paymentOptions,
        parkingOptions: place.parkingOptions,
        accessibilityOptions: place.accessibilityOptions,
        fuelOptions: place.fuelOptions,
        evChargeOptions: place.evChargeOptions,
        generativeSummary: place.generativeSummary,
        priceLevel: place.priceLevel,
        userRatingsTotal: place.userRatingCount,
        utcOffset: place.utcOffset,
        adrFormatAddress: place.adrFormatAddress,
        businessStatus_: place.businessStatus_,
        iconMaskBaseUri: place.iconMaskBaseUri,
        iconBackgroundColor: place.iconBackgroundColor,
        takeout: place.takeout,
        delivery: place.delivery,
        dineIn: place.delivery,
        curbsidePickup: place.curbsidePickup,
        reservable: place.reservable,
        servesBreakfast: place.servesBreakfast,
        servesLunch: place.servesLunch,
        servesDinner: place.servesDinner,
        servesBeer: place.servesBeer,
        servesWine: place.servesWine,
        servesBrunch: place.servesBrunch,
        servesVegetarianFood: place.servesVegetarianFood,
        outdoorSeating: place.outdoorSeating,
        liveMusic: place.liveMusic,
        restroom: place.restroom,
        goodForChildren: place.goodForChildren,
        goodForGroups: place.goodForGroups,
        allowsDogs: place.allowsDogs,
        googleMapsLinks: place.googleMapsLinks,
        reviewSummary: place.reviewSummary,
        postalAddress: place.postalAddress,
        profilePhoto: "8D49AAC8-3561-467B-AA3E-E9C05279B00C",
        bannerPhoto: "5D09982F-E836-4805-963D-294D064B324C",
        createdAt: Timestamp(date: Date.now),
        updatedAt: Timestamp(date: Date.now)
    )
}

#Preview {
    UpdatedBusinessOnboardingFlow()
}
