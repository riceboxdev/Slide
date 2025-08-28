//
//  ConfirmDetailsView.swift
//  Slide
//
//  Created by Nick Rogers on 8/24/25.
//

import SwiftUI

struct ConfirmDetailsView: View {
    var place: PlaceDetailsResponse
    @State private var isVisible = false
    @State private var secondaryIsVisible = false
    @State private var index = 0
    
    let shortAnimationDuration: Double = 0.5
    
 
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                PlaceHeaderView(place: place)
                    .shadow(color: Color.black.opacity(0.15), radius: 14)
                
                PlaceContactInfoView(place: place)
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle(place.displayName?.text ?? "Details")
    }
    
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

#Preview {
    if let place = createPlaceDetailsFromJSON() {
        NavigationView {
            ConfirmDetailsView(place: place)
                .background {
                    VStack {
                        Image("demo5")
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
        }
    }
}


