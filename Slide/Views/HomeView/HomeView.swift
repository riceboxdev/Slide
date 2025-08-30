//
//  HomeView.swift
//  Slide
//
//  Created by Nick Rogers on 8/25/25.
//

import SwiftUI
import Combine
import MapKit
import CoreLocation
import ColorKit
import FoundationModels

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @StateObject var placesManager: PlacesAPIService = .init(apiKey: "AIzaSyARxu6sVxRQ1JV097gqRhN7ierVoODA-4A")
//    @StateObject var placeDetailsService: MainGooglePlacesService

    
    init(viewModel: HomeViewModel) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
//        self._placeDetailsService = StateObject(wrappedValue: MainGooglePlacesService(apiKey: "AIzaSyARxu6sVxRQ1JV097gqRhN7ierVoODA-4A", locationManager: LocationManager.shared))
    }
    
//    let locationManager = LocationManager.shared
    @State var searchText: String = "Where can I go for pasta?"
    @State private var showTripPlan: Bool = false
    @State private var showTestView: Bool = true
    
    let heroHeight: CGFloat = 250
    
    let location = LocationManager.shared
    fileprivate func sectionTitleRow(text: String) -> some View {
        return
        HStack {Text(text)
                .font(.variableFont(18, axis: [FontVariations.weight.rawValue: 400]))
             Spacer()
                Image(systemName: "arrow.right")
        }
        .padding()
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 10) {
                    // Hero Section
                    Group {
                        if !viewModel.featuredPlaces.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(viewModel.featuredPlaces) { place in
                                        NavigationLink {
                                            PlaceDetailView(place: place)
                                        } label: {
                                            NewHeroCardView(place: place, height: heroHeight)
                                        }
                                        .buttonStyle(.plain)
                                        
                                    }
                                }
                                .scrollTargetLayout()
                            }
                            .scrollTargetBehavior(.viewAligned)
                            .safeAreaPadding(.horizontal, 10)
                        } else {
                            ProgressView()
                                .frame(height: heroHeight)
                        }
                    }
                    
                    // Search Bar
                    SearchBar(text: $searchText) { query in
                       showTestView = true
                    }
                    
                    // Food Row
                    sectionTitleRow(text: "Eat Something New")
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(viewModel.restaraunts.prefix(8)) { place in
                                NavigationLink {
                                    PlaceDetailView(place: place)
                                } label: {
                                    RegularPlaceCardView(place: place, locationManager: viewModel.locationManager)
                                }
                                .buttonStyle(.plain)
                            }
                            
                            if !viewModel.restaraunts.isEmpty {
                                Button {
                                    
                                } label: {
                                    Image(systemName: "chevron.right")
                                        .imageScale(.large)
                                        .padding()
                                        .background(.tertiary, in: .circle)
                                        .padding(.horizontal)
                                }
                            }
                            
                        }
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.viewAligned)
                    .safeAreaPadding(.horizontal, 10)
    
                    // Vices
                    sectionTitleRow(text: "Puff, Puff, Laugh")
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(viewModel.smokeShops.prefix(8)) { place in
                                NavigationLink {
                                    PlaceDetailView(place: place)
                                } label: {
                                    NewHeroCardView(place: place, height: 150)
                                }
                                .buttonStyle(.plain)
                            }
                            
                            if !viewModel.restaraunts.isEmpty {
                                Button {
                                    
                                } label: {
                                    Image(systemName: "chevron.right")
                                        .imageScale(.large)
                                        .padding()
                                        .background(.tertiary, in: .circle)
                                        .padding(.horizontal)
                                }
                            }
                            
                        }
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.viewAligned)
                    .safeAreaPadding(.horizontal, 10)
                    
                }
                
            }
            .safeAreaPadding(.bottom, 30)
            .onChange(of: placesManager.places) { newValue in
                print("Place: \(newValue.first)")
            }
            .navigationTitle("Home")
            .onAppear() {
                Task {
                    viewModel.loadData()
                }
    
            }
            .onChange(of: searchText) { newValue in
                showTestView = true
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("New", systemImage: "plus") {
//                        self.viewModel.showBusinessOnboarding = true
                    }
                }
            }
            .sheet(isPresented: $showTripPlan) {
//                if let plan = activeTripPlan {
//                    TripPlanView(plan: plan, placesById: activeCandidatePlaces)
//                }
            }
            .sheet(isPresented: $showTestView) {
//                TripView(locationManager: location, searchText: $searchText)
            }
        }
    }
}

struct RegularPlaceCardView: View {
    var place: Place
    var height: CGFloat = 180
    @StateObject var imageFetcher = PlacePhotoService(apiKey: "AIzaSyARxu6sVxRQ1JV097gqRhN7ierVoODA-4A")
    @State private var color: Color?
    @State private var loadedImage: UIImage? = nil
    var locationManager: LocationManager = .shared
    var body: some View {
        ZStack {
            if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                 
            } else {
                ProgressView()
            }
            
            LinearGradient(colors: [.clear, color ?? .clear], startPoint: .top, endPoint: .bottom)
                .frame(height: height)
            
            VStack {
                if let location = place.location, let distance = locationManager.formattedDistance(from: location) {
                    Text(distance)
                        .font(.variableFont(12, axis: [FontVariations.weight.rawValue : 600]))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(.thinMaterial, in: .capsule)
                        .hTrailing()
                }
                Spacer()
                Text(place.displayNameText)
                    .font(.variableFont(30, axis: [FontVariations.weight.rawValue : 600]))
                    .lineLimit(2)
                    .hLeading()
            }
            .padding()
            .containerRelativeFrame(.horizontal, count: 2, spacing: 10)
            .frame(height: height)
        }
        .clipped()
        .containerRelativeFrame(.horizontal, count: 2, spacing: 10)
        .frame(height: height)
        .clipShape(.rect(cornerRadius: 30))
        .onAppear() {
            Task {
                await loadPhotoIfNeeded()
            }
        }
        .onChange(of: loadedImage) { newImage in
            if let image = newImage {
                Task {
                    await getColor(for: image)
                }
            }
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
    
    func getPlaceDetails() async {
//        repo.getPlaceDetails(placeId: place.)
    }
}

struct NewHeroCardView: View {
    var place: Place
    var height: CGFloat = 250
    @StateObject var imageFetcher = PlacePhotoService(apiKey: "AIzaSyARxu6sVxRQ1JV097gqRhN7ierVoODA-4A")
    @State private var color: Color?
    @State private var loadedImage: UIImage? = nil
    var body: some View {
        ZStack {
            if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                 
            } else {
                ProgressView()
            }
            
            LinearGradient(colors: [.clear, color ?? .clear], startPoint: .top, endPoint: .bottom)
                .frame(height: height)
            
            VStack {
                Spacer()
                Text(place.displayNameText)
                    .font(.variableFont(30, axis: [FontVariations.weight.rawValue : 600]))
                    .lineLimit(2)
                    .hLeading()
            }
            .padding()
            .containerRelativeFrame(.horizontal, count: 1, spacing: 10)
            .frame(height: height)
        }
        .clipped()
        .containerRelativeFrame(.horizontal, count: 1, spacing: 10)
        .frame(height: height)
        .clipShape(.rect(cornerRadius: 30))
        .onAppear() {
            Task {
                await loadPhotoIfNeeded()
            }
        }
        .onChange(of: loadedImage) { newImage in
            if let image = newImage {
                Task {
                    await getColor(for: image)
                }
            }
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
    
    func getPlaceDetails() async {
//        repo.getPlaceDetails(placeId: place.)
    }
}

class HomeViewModel: ObservableObject {
    @Published var featuredPlaces: [Place] = []
    @Published var nightlifeSection: [Place] = []
    @Published var restaraunts: [Place] = []
    @Published var smokeShops: [Place] = []
    
    
    let nearbyPlacesService = PlacesAPIService(apiKey: "AIzaSyARxu6sVxRQ1JV097gqRhN7ierVoODA-4A")
    let locationManager = LocationManager.shared
    let places = CombinedPlacesService()
    
    func loadData() {
        Task {
            await getFeaturedPlaces()
            await getRestaraunts()
            await getSmokeShops()
        }
    }
    
    func getFeaturedPlaces() async {
        if let location = LocationManager.shared.location {
            do {
                self.featuredPlaces = try await nearbyPlacesService.searchNearbyPlaces(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            } catch {
                
            }
        }
    }
    
    func getRestaraunts() async {
        guard let location = locationManager.location else { return }
        
        let includedTypes: [String] = [
            GoogleMapsPlaceType.restaurant.rawValue
        ]
        
        let excludedTypes: [String] = [
            GoogleMapsPlaceType.fastFoodRestaurant.rawValue
         ]
        
        do {
            self.restaraunts = try await nearbyPlacesService.searchNearbyPlaces(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                includedTypes: includedTypes,
                excludedTypes: excludedTypes
            )
        } catch {
            
        }
    }
    
    func getSmokeShops() async {
        guard let location = locationManager.location else { return }
        
        let userLocation = GeoCircle(
            center: LatLng(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude, cityName: nil),
            radius: 2000 // meters
        )
        do {
            let shops = try await places.searchText(
                query: "Smoke Shop",
                locationBias: LocationBias(circle: userLocation),
                includedTypes: []
            
            )
            if let results = shops.places {
                self.smokeShops = results
            }
        } catch {
            print(error.localizedDescription)
        }
    }
}

struct HomeHeroCardView: View {
    var business: SlideBusiness
    var height: CGFloat = 200
    @State var metaData: ImageMetadata?
    @State var showEditSheet: Bool = false
    var body: some View {
        NavigationLink {
            BusinessView(business: business)
        } label: {
            cardView()
        }
    }
    
    @ViewBuilder
    func cardView() -> some View {
        ZStack {
            if let banner = business.bannerPhoto {
                AsyncImageWithColor(
                    imageRef: banner,
                    imageMetaData: $metaData,
                    showOverlay: true,
                    image: { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                          
                        
                    },
                    placeholder: {
                        Rectangle()
                            .fill(.quinary)
                        
                    }
                )
                .frame(height: height)
            }
          
            VStack {
                Spacer()
                HStack {
                    if let name = business.displayName?.text {
                        Text(name)
                            .font(.variableFont(30, axis: [FontVariations.weight.rawValue : 600]))
                            .foregroundStyle(
                                metaData?.colorAnalysis.palette?.contrastLevel == "acceptable" ?
                                    .black : .white
                            )
                            .shadow(radius: 5)
                            .transition(.opacity)
                    }
                    Spacer()
                }
              
            }
            .padding()
            .frame(height: height)
        }
        .frame(height: height)
        .containerRelativeFrame(.horizontal, count: 1, spacing: 10)
        .clipShape(.rect(cornerRadius: 30))
        .background(
            .ultraThinMaterial,
            in: .rect(cornerRadius: 20)
        )
        .contextMenu {
            Button {
                self.showEditSheet = true
            } label: {
                Label("Edit", systemImage: "pencil")
            }
        }
        .sheet(isPresented: $showEditSheet) {
//            BusinessEditorView(business: business)
        }
    }
}

struct AsyncImageWithColor<ImageContent: View, Placeholder: View>: View {
    @Binding var imageMetaData: ImageMetadata?
    var imageRef: String
    var showOverlay: Bool = false
    var image: (Image) -> ImageContent
    var placeholder: () -> Placeholder
    
    @State var url: URL?
    @State var metaData: ImageMetadata?
    @State private var imageLoaded = false

    let imageManager = FirebaseImageManager()

    init(imageRef: String, imageMetaData: Binding<ImageMetadata?>, showOverlay: Bool = false, @ViewBuilder image: @escaping (Image) -> ImageContent, @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.imageRef = imageRef
        self._imageMetaData = imageMetaData
        self.showOverlay = showOverlay
        self.image = image
        self.placeholder = placeholder
    }

    var body: some View {
        ZStack {
            AsyncImage(url: url) { image in
                self.image(image)
                    .opacity(imageLoaded ? 1 : 0)
                    .onAppear { withAnimation { imageLoaded = true } }
               
            } placeholder: {
                placeholder()
                    .opacity(imageLoaded ? 0 : 1)
            }
            if showOverlay {
                if let color = metaData?.colorAnalysis.averageColor {
                    LinearGradient(
                        colors: [
                            .clear,
                            Color(hex: color)
                            
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            }
        }
        .animation(.easeInOut(duration: 0.35), value: imageLoaded)
        .onAppear() {
            Task {
                try await getPhoto()
              
            }
        }
    }
    
    func getPhoto() async throws {
        let meta = try await imageManager.getImageById(imageRef)
        if let downloadURL = meta?.downloadURL {
            withAnimation(.smooth) {
                self.url = URL(string: downloadURL)
            }
        }
        withAnimation(.easeInOut) {
            self.metaData = meta
            self.imageMetaData = meta
        }
    }
}

//// MARK: - UI for displaying PlacesPlan and PlanOption
//
//struct PlacesPlanView: View {
//    let plan: PlacesPlan
//    var body: some View {
//        VStack(alignment: .leading, spacing: 16) {
//            Text(plan.summary)
//                .font(.title2)
//                .fontWeight(.semibold)
//            ForEach(Array(plan.options.enumerated()), id: \.offset) { idx, option in
//                PlanOptionView(option: option)
//                    .padding(.vertical, 6)
//                    .background(.thinMaterial, in: .rect(cornerRadius: 18))
//            }
//        }
//        .padding()
//    }
//}
//
//struct PlanOptionView: View {
//    let option: PlanOption
//    var body: some View {
//        switch option {
//        case .singleVenue(let place):
//            VStack(alignment: .leading, spacing: 8) {
//                Text("Single Venue")
//                    .font(.headline)
//                    .foregroundStyle(.secondary)
//                PlaceSummaryView(place: place)
//            }
//        case .twoStops(let first, let second, let distance):
//            VStack(alignment: .leading, spacing: 8) {
//                Text("Two Stop Plan")
//                    .font(.headline)
//                    .foregroundStyle(.secondary)
//                PlaceSummaryView(place: first)
//                Image(systemName: "arrow.down")
//                    .foregroundStyle(.tertiary)
//                PlaceSummaryView(place: second)
//                if let meters = distance {
//                    Text(String(format: "Walk: %.0f m", Double(meters)))
//                        .font(.caption)
//                        .foregroundStyle(.tertiary)
//                        .padding(.top, 2)
//                }
//            }
//        }
//    }
//}



// ---
// Usage: In TripView, replace the existing plan summary rendering block with:
// if let plan = planner.plan {
//     PlacesPlanView(plan: plan)
// }

// This will render all plan options cleanly in the UI.


#Preview {
    HomeView(viewModel: HomeViewModel())
}

//#Preview {
//    TripResultView(tripPlan: samplePlacesPlan.asPartiallyGenerated())
//}

