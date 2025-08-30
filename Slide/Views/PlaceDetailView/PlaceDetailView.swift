//
//  PlaceDetailView.swift
//  Slide
//
//  Created by Nick Rogers on 8/28/25.
//

import SwiftUI
import Foundation
import Combine
import ColorKit

struct PlaceDetailView: View {
    var place: Place
    let spacing: CGFloat = 10
    @StateObject var viewModel: PlaceDetailViewModel
    @State var expandMedia: Bool = false
    @State var notificationsEnabled: Bool = false
    
    init(place: Place) {
        self.place = place
        self._viewModel = StateObject(wrappedValue: PlaceDetailViewModel(place: place))
    }
    
    var body: some View {
        GeometryReader { geo in
            let safeAreaInsets = geo.safeAreaInsets

            PullEffectScrollView(
                actionTopPadding: safeAreaInsets.top + 35,
                leadingAction: PullEffectAction(symbol: "", action: {}),
                centerAction: PullEffectAction(
                    symbol: expandMedia
                        ? "Release To Collapse" : "Release To Expand",
                    action: {
                        withAnimation(.smooth) {
                            expandMedia.toggle()
                        }
                    }
                ),
                trailingAction: PullEffectAction(symbol: "", action: {})
            ) {
                VStack(spacing: 0) {

                    videoHeader()  // initial header frame

                    PageContent()
                }
                .ignoresSafeArea()

            }
            .coordinateSpace(name: "scroll")
        }
        .ignoresSafeArea()
        .background(.green.opacity(0.05))
        .onAppear {
            viewModel.setupView()
        }
        }
    
    @ViewBuilder
    func videoHeader() -> some View {
        GeometryReader { headerGeo in
            let minY = headerGeo.frame(in: .named("scroll")).minY  // 👈 fix
            let baseHeight: CGFloat = expandMedia ? 500 : 250
            let height = max(
                baseHeight,
                baseHeight + (minY > 0 ? minY : 0)
            )
            
            ZStack {
                if let image = viewModel.loadedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                     
                } else {
                    ProgressView()
                }
//                if let video = heroVideo {
//                    UIVideoPlayerView(videoItem: video, height: height, isMuted: $isMuted)
////                        .frame(height: height)
//                }
                if !expandMedia {
                    LinearGradient(
                        colors: [
                            .clear,
                            .black.opacity(0.3),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            }
            .animation(nil, value: height)
            .frame(width: headerGeo.size.width, height: height)
                .clipped()
                .overlay(alignment: .bottomLeading) {
                    mediaOverlay()
                }
                .offset(y: minY > 0 ? -minY : 0)  // <-- keeps it pinned
        }
        .frame(height: expandMedia ? 500 : 250)
    }
    
    @ViewBuilder
    func mediaOverlay() -> some View {
        VStack(alignment: .leading) {
            Text(place.displayName?.text ?? "")
                .font(
                    .variableFont(
                        38,
                        axis: [FontVariations.weight.rawValue: 800]
                    )
                )
                .foregroundStyle(.white)

            if let type = place.primaryType {
                Text(type.capitalized)
                    .font(.variableFont(16, axis: [FontVariations.weight.rawValue: 500]))
                    .foregroundStyle(.accent)
            }
        }
        .shadow(radius: 10)
        .padding()
        .opacity(expandMedia ? 0 : 1)
    }

    @ViewBuilder
    func PageContent() -> some View {
        VStack(alignment: .leading, spacing: spacing) {
            VStack(spacing: 0) {
                HStack {
                    VStack {
                        if let address = place.formattedAddress {
                            Text(address)
                                .font(.variableFont(16, axis: [FontVariations.weight.rawValue: 500]))
                                .fixedSize(horizontal: false, vertical: true)  // prevents collapsing
                                .frame(maxWidth: 250, alignment: .leading)
                                .multilineTextAlignment(.leading)
                                .hLeading()
                        }
                        
                    }
                    
                    Button {
                        self.notificationsEnabled.toggle()
                    } label: {
                        Image(systemName: "bell.and.waves.left.and.right")
                            .frame(width: 30, height: 30)
                            .padding(10)
                        //                        .background(
                        //                            !notificationsEnabled ?
                        //                            Color.secondary.opacity(0.1) : Color.clear, in: .circle
                        //                        )
                            .foregroundStyle(notificationsEnabled ? .accent : .secondary)
                    }
                    .sensoryFeedback(.selection, trigger: notificationsEnabled)
                }
                .padding(.horizontal)
                .frame(height: 70)
                .background(Color.secondary.opacity(0.2))
                
//                if business.isBlackOwned == true {
//                    HStack {
//                        Image(systemName: "staroflife.fill")
//                            .foregroundStyle(.yellow)
//                        Text("Black Owned".uppercased())
//                            .font( .variableFont(14, axis: [FontVariations.weight.rawValue: 400]))
//                        Spacer()
//                    }
//                    .padding(.horizontal)
//                    .frame(height: 45)
//                    .background(.quinary)
//                }
            }
            HStack {
                Button("Info") {
                    
                }
                .buttonStyle(.glass)
                .tint(.accent)
                .font(.variableFont(16, axis: [FontVariations.weight.rawValue: 500]))
                Button("Rewards") {
                    
                }
                .buttonStyle(.glass)
                .font(.variableFont(16, axis: [FontVariations.weight.rawValue: 500]))
                Spacer()
            }
            .padding(.horizontal)
            
            VStack {
                Text("Updates")
                    .font(.variableFont(14, axis: [FontVariations.weight.rawValue: 400]))

            }
            .padding(.horizontal)

//            VStack {
//                ForEach(postsModel.posts) { post in
//                    BusinessPostCardView(business: business, post: post)
//                }
//            }
//            .safeAreaPadding(.horizontal, 10)
            
            VStack(spacing: 25) {
                HStack {
                    Image(systemName: "phone")
                    Button(place.internationalPhoneNumber ?? "-") {
                        
                    }
                    Spacer()
                }
                
                HStack {
                    Image(systemName: "globe")
                    Button(place.websiteUri ?? "-") {
                        
                    }
                        .lineLimit(1)
                    Spacer()
                }
            }
            .padding()
            
            
//            SlideBusinessMapPreview(business: business)
//                .padding(.horizontal, 10)
        }
    }
    
  
    
   
    
//    @MainActor
//    func getHeroVideo() {
//        guard let videoRef = business.videoReference else { return }
//        let videoLoader = VideoRetrievalService()
//        
//        videoLoader.fetchVideo(by: videoRef) { video in
//            if let video = video {
//                self.heroVideo = video
//            }
//        }
//    }
}

struct SectionView: View {
    let title: String
    let items: [String]
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            FlowLayout(items: items) { item in
                Text(item)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(color.opacity(0.15))
                    .foregroundColor(color)
                    .cornerRadius(12)
            }
        }
    }
}

// MARK: - Flow Layout for Chips
struct FlowLayout<Content: View>: View {
    let items: [String]
    let content: (String) -> Content
    
    @State private var totalHeight = CGFloat.zero
    
    var body: some View {
        GeometryReader { geo in
            self.generateContent(in: geo)
        }
        .frame(height: totalHeight)
    }
    
    private func generateContent(in geo: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        
        return ZStack(alignment: .topLeading) {
            ForEach(items, id: \.self) { item in
                content(item)
                    .padding([.horizontal, .vertical], 4)
                    .alignmentGuide(.leading, computeValue: { d in
                        if abs(width - d.width) > geo.size.width {
                            width = 0
                            height -= d.height
                        }
                        let result = width
                        if item == items.last {
                            width = 0
                        } else {
                            width -= d.width
                        }
                        return result
                    })
                    .alignmentGuide(.top, computeValue: { _ in
                        let result = height
                        if item == items.last {
                            height = 0
                        }
                        return result
                    })
            }
        }
        .background(GeometryReader {
            Color.clear.preference(key: HeightPreferenceKey.self,
                                   value: -$0.frame(in: .local).origin.y)
        })
        .onPreferenceChange(HeightPreferenceKey.self) { totalHeight = $0 }
    }
}

private struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}



@MainActor
class PlaceDetailViewModel: ObservableObject {
    @Published private(set) var place: Place
    @Published var color: Color = .clear
    @Published var loadedImage: UIImage? = nil
    
    let imageFetcher = PlacePhotoService(apiKey: "AIzaSyARxu6sVxRQ1JV097gqRhN7ierVoODA-4A")
    
    init(place: Place) {
        self.place = place
    }
    
    var name: String { place.displayNameText }
    var type: String { place.primaryTypeDisplayText }
    
    var rating: Double? { place.rating }
    var ratingText: String? { place.ratingText }
    var ratingCount: String? { place.ratingCountText }
    
    var address: String? { place.formattedAddress }
    var phone: String? { place.nationalPhoneNumber }
    var website: URL? {
        guard let uri = place.websiteUri else { return nil }
        return URL(string: uri)
    }
    
    var isOpenText: String {
        guard let open = place.isOpen else { return "Unknown hours" }
        return open ? "Open Now" : "Closed"
    }
    
    var isOpenColor: Color {
        guard let open = place.isOpen else { return .gray }
        return open ? .green : .red
    }
    
    var servingOptions: [String] { place.servingOptions }
    var mealOptions: [String] { place.mealOptions }
    var amenities: [String] { place.amenities }
    
    var heroPhotoURL: URL? {
        // Example: use first photo’s URI if available
        if let url = place.photos?.first?.googleMapsUri {
            return URL(string: url)
        }
        return nil
    }
    
    func setupView() {
        Task {
            await loadPhotoIfNeeded()
//            getHeroVideo()
//            guard let id = business.id else { return }
//            await postsModel.loadPosts(
//                for: id
//            )
//            print("POSTS: \(self.postsModel.posts.count)")
        }
    }
    
    private func loadPhotoIfNeeded() async {
        if loadedImage == nil, let firstPhoto = place.photos?.first?.name {
            loadedImage = try? await imageFetcher.fetchPhoto(photoName: firstPhoto)
        }
    }
    
    func getColor(for uiimage: UIImage) async {
        let color = try? uiimage.averageColor()
        guard let avgColor = color else { return }
        self.color = Color(avgColor)
    }
}


#Preview {
    @Previewable @StateObject var places = PlacesAPIService(apiKey: "AIzaSyARxu6sVxRQ1JV097gqRhN7ierVoODA-4A")
    @Previewable @State var place: Place?
    
    Group {
        if let place = place {
            PlaceDetailView(place: place)
        } else {
            ProgressView()
        }
    }
    .onAppear() {
        Task {
            let allPlaces = try await places.searchNearbyPlaces(latitude: 29.851543617698105, longitude: -95.29943226837116)
            place = allPlaces.first
        }
    }
}
