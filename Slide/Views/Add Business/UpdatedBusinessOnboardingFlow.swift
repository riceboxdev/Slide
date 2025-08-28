//
//  UpdatedBusinessOnboardingFlow.swift
//  Slide
//
//  Created by Nick Rogers on 8/23/25.
//

import Combine
import SwiftUI

struct UpdatedBusinessOnboardingFlow: View {
    @StateObject var model = UpdatedOnboardingFlowManager()

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
                    Group {
                        if let place = model.placeDetails {
                            FullPlaceDetailView(place: place)
                        } else {
                            ProgressView()
                        }
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
                    .id(OnboardingFlowStep.confirmDetails)
                    .transition(stepTransition)

                case .customize:
                    Text("")
                        .id(OnboardingFlowStep.customize)
                        .transition(stepTransition)
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
                if model.step != .search {
                    ToolbarItem(placement: .navigation) {
                        Button("", systemImage: "arrow.left") {
                            model.previousStep()
                        }
                    }
                }
            }
        }
    }
    
    func handleSelection(suggestion: AutocompleteSuggestion) {
        self.model.placesService.selectedPlace = suggestion
        if suggestion.isPlace, let placeId = suggestion.placeId
        {
            Task {
                let details = try await model.placesService
                    .getPlaceDetails(
                        placeId: placeId,
                        fields: PlaceDetailsField.allCases
                    )
                await MainActor.run {
                    model.placeDetails = details
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
    @Published var isNavigatingForeward = true
    @Published var placeDetails: PlaceDetailsResponse?

    let placesService: GooglePlacesService = GooglePlacesService(
        apiKey: "AIzaSyARxu6sVxRQ1JV097gqRhN7ierVoODA-4A",
        locationManager: LocationManager.shared
    )

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
            }
        }
    }
}

enum OnboardingFlowStep {
    case search
    case confirmDetails
    case customize
}

#Preview {
    UpdatedBusinessOnboardingFlow()
}
