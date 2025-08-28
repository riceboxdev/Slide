//
//  SearchBar.swift
//  Slide
//
//  Created by Nick Rogers on 8/26/25.
//

import SwiftUI


struct SearchBar: View {
//    @EnvironmentObject var coordinator: AppCoordinator
    @Binding var text: String
    @FocusState private var isFocused
    
    var onSubmit: (String) -> Void

    var body: some View {
        VStack {
            ZStack(alignment: .center) {
                PastelMeshGradientView()
                    .frame(height: 60)
                    .clipShape(.capsule)
                    .blur(radius: 16)
                    .opacity(isFocused ? 0.9 : 0.3)
                HStack {
                    Image(systemName: "staroflife.fill")
                        .imageScale(.large)
                        .foregroundStyle(.black.opacity(0.2))
                        .overlay {
                            TwilightMeshGradientView()
                                .opacity(1)
                                .saturation(2)
                                .mask(
                                    Image(systemName: "staroflife.fill")
                                        .imageScale(.large)
                                )
                        }
                    TextField("What do you want to do?", text: $text)
                        .focused($isFocused)
                        .onSubmit {
                            onSubmit(text)
                        }
                }
                .padding(.horizontal, 12)
                .frame(height: 50)
                .glassEffect(.regular.interactive())
                .padding(.horizontal, 6)
            }
            .tint(.blackui)
            .padding(.horizontal, 10)
        }
    }
}

#Preview {
    @Previewable @State var text = ""
    SearchBar(text: $text) { _ in
        
    }
}
