//
//  ProfileView.swift
//  Slide
//
//  Created by Nick Rogers on 7/29/25.
//

import ColorKit
import Combine
import SwiftUI

struct ProfileView: View {
    let profile: UserProfile
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject var viewModel: ProfileViewModel
    @State var selectedTab: Int = 0
    
    @State var showAddBusiness = false
    
    init(profile: UserProfile) {
        self.profile = profile
        _viewModel = StateObject(wrappedValue: ProfileViewModel(user: profile))
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    ProfileHeaderView(viewModel: viewModel)
                        .overlay(alignment: .bottom) {
                            HStack {

                                ProfileActionsCard(
                                    label: "Saved",
                                    image: "bookmark"
                                ) {
                                    
                                }
                                ProfileActionsCard(
                                    label: "Stats",
                                    image: "chart.bar"
                                ) {
                                    coordinator.authService.signOut()
                                }
                                
                                ProfileActionsCard(label: "Add Business", image: "plus") {
                                    
                                }

                            }
                            .padding(.horizontal)

                        }
                    
//                    VStack {
//                        SlideSwitcher(labels: ["Reviews", "Media"], tab: $selectedTab)
//                    }
                    
                    VStack {
                        Text("Recently Viewed")
                            .font(
                                .variableFont(
                                    20,
                                    axis: [FontVariations.weight.rawValue: 600]
                                )
                            )
                            .hLeading()
                        BusinessRowCard(business: Business.sampleData[0])
                        BusinessRowCard(business: Business.sampleData[1])
                    }
                    .padding(.horizontal, 10)
                    
                    Spacer()
                     
                }
                .overlay(alignment: .bottom) {
                    HStack {

                    }
                }
            }
            .background(
                ZStack {
                    Color(UIColor.systemBackground)
                    viewModel.color?.opacity(0.3) ?? .clear
                }
            )
            .ignoresSafeArea(edges: [.top])
            .navigationTitle("@\(profile.username)")
            .navigationBarTitleDisplayMode(.inline)

        }
    }
}

struct SlideSwitcher: View {
    let labels: [String]
    @Binding var tab: Int
    
    var body: some View {
        HStack {
            ForEach(labels.indices, id: \.self) { idx in
                let label = labels[idx]
                Button {
                    withAnimation(.smooth) {
                        tab = idx
                    }
                } label: {
                    Text(label.uppercased())
                        .font(
                            .variableFont(
                                12,
                                axis: [FontVariations.weight.rawValue: 600]
                            )
                        )
                        .frame(maxWidth: .infinity)
                        .frame(height: 30)
                }
                .buttonStyle(.plain)
                .modifierConditional(idx == tab) { view in
                    view.glassEffect(.regular.interactive())
                }
            }
        }
        .padding(5)
        .background(Color.primary.opacity(0.3))
        .clipShape(.capsule)
        .padding(.horizontal, 10)
    }
}

extension View {
    @ViewBuilder
    func modifierConditional<Content: View>(_ condition: Bool, modifier: (Self) -> Content) -> some View {
        if condition {
            modifier(self)
        } else {
            self
        }
    }
}

struct BusinessRowCard: View {
    let business: Business
    var body: some View {
        VStack {
           
            HStack(spacing: 16) {
                CachedAsyncImage(
                    url: URL(
                        string: business.avatar ?? ""
                    )
                ) { image, uiImage in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                
                } placeholder: {
                    Color.gray
                }
                .frame(width: 50, height: 50)
                .clipShape(.rect(cornerRadius: 10))
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(business.name)
                        .font(
                            .variableFont(
                                18,
                                axis: [FontVariations.weight.rawValue: 600]
                            )
                        )
                    Text(business.primaryCategory.displayName)
                        .font(
                            .variableFont(
                                14,
                                axis: [FontVariations.weight.rawValue: 400]
                            )
                        )
                }
                
                Spacer()
                
                Image(systemName: "arrow.right")
            }
        }
        .padding(10)
        .background(.thinMaterial, in: .rect(cornerRadius: 25))
    }
}

struct ProfileActionsCard: View {
    let label: String
    let image: String
    var onTap: (() -> Void)
    var body: some View {
        Button {
            onTap()
        } label: {
            ZStack {
                VStack(spacing: 16) {
                    Spacer()
                    Text(label.uppercased())
                        .font(
                            .variableFont(
                                12,
                                axis: [FontVariations.weight.rawValue: 600]
                            )
                        )
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 60)
                }
                .padding(.bottom)
                Image(systemName: image)
                    .imageScale(.large)
                    .padding(.bottom, 25)
            }
        }
        .buttonStyle(.plain)
        .containerRelativeFrame(.horizontal, count: 4, spacing: 10)
        .frame(height: 100)
        //        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 30))
    }
}

struct ProfileHeaderView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @State private var hasLoadedImage = false

    var body: some View {
        VStack {
            CachedAsyncImage(
                url: URL(
                    string: viewModel.user.personalInfo.profileImageURL ?? ""
                )
            ) { image, uiImage in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .opacity(hasLoadedImage ? 1.0 : 0.0)  // Use the state variable
                    .onAppear {
                        viewModel.getColor(from: uiImage)
                        hasLoadedImage = true  // Remove withAnimation wrapper
                    }
            } placeholder: {
                Color.gray
                    .opacity(hasLoadedImage ? 0.0 : 1.0)  // Fade out placeholder
            }
            .frame(height: 350)
            .clipped()
            .mask {
                LinearGradient(
                    colors: [.black, .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .animation(.easeInOut(duration: 0.5), value: hasLoadedImage)  // Single animation modifier
            Spacer()
                .frame(height: 30)
        }
    }
}

class ProfileViewModel: ObservableObject {
    @Published var user: UserProfile
    @Published var color: Color?

    init(user: UserProfile) {
        self.user = user
    }

    func getColor(from image: UIImage) {
        let extractedColor = try? image.averageColor()
        self.color = Color(extractedColor ?? .clear)
    }
}

#Preview {
    let profile = UserProfile.createDefault(
        firstName: "Nick",
        email: "nickxrogers@outlook.com",
        id: UUID().uuidString,
        username: "nickrogers",
        avatar:
            "https://firebasestorage.googleapis.com/v0/b/bookd-16634.firebasestorage.app/o/users%2F8mDuOyT5MOaHgrFzXwfA2lr7ebP2%2Fprofile.jpg?alt=media&token=aa4b8d6d-6388-4446-af83-d5582f6f293b"
    )

    ProfileView(profile: profile)
}
