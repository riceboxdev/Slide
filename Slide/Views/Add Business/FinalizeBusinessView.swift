//
//  FinalizeBusinessView.swift
//  Slide
//
//  Created by Nick Rogers on 8/25/25.
//

import SwiftUI

struct FinalizeBusinessView: View {
    @State var isVisible = false
    var place: PlaceDetailsResponse?
    var body: some View {
        VStack {
            HStack {
                Text("Press finish to continue")
                Spacer()
            }
            .padding(.horizontal)
            
            FinalizePlaceDetailsCard(place: place)
                .opacity(isVisible ?  1 : 0)
                .blur(radius: isVisible ? 0 : 10)
            
            if let place = place {
                PlaceContactInfoView(place: place)
                    .padding(.horizontal)
            }
            
            Spacer()
        }
        .navigationTitle("Finish Setup")
        .onAppear() {
            withAnimation(.smooth(duration: 1.5)) {
                isVisible = true
            }
        }
    }
}

struct FinalizePlaceDetailsCard: View {
    let place: PlaceDetailsResponse?
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                if let displayName = place?.displayName?.text {
                    Text(displayName)
                        .font(.variableFont(20, axis: [FontVariations.weight.rawValue : 600]))
                        .multilineTextAlignment(.leading)
                }
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.accent)
                    .imageScale(.small)
                Spacer()
                
            }
            if let address = place?.formattedAddress {
                HStack {
                    Text(address)
                        .font(.variableFont(14, axis: [FontVariations.weight.rawValue : 400]))
                        .multilineTextAlignment(.leading)
                        
                    Spacer()
                }
                .frame(maxWidth: 200)
            }
            
            if let category = place?.types?.first {
                HStack {
                    Text(category.uppercased())
                        .font(.variableFont(12, axis: [FontVariations.weight.rawValue : 600]))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.quaternary, in: .capsule)
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 20))
        .padding()
    }
}

#Preview {
    NavigationView {
        FinalizeBusinessView(place: createPlaceDetailsFromJSON())
            .background {
                VStack {
                    Image("demo6")
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
