//
//  HomeView.swift
//  Slide
//
//  Created by Nick Rogers on 8/25/25.
//

import SwiftUI
import Combine

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @State var searchText: String = ""
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(viewModel.businesses) { business in
                                HomeHeroCardView(business: business, height: 180)
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.viewAligned)
                    .safeAreaPadding(.horizontal, 10)
                    
                    SearchBar(text: $searchText) { query in
                        
                    }
                    
                    
                    
                    ScrollView(.horizontal) {
                        HStack {
                            ZStack {
                                AsyncImageWithColor(
                                    imageRef: "257AC6EF-88A7-4897-8B09-02B3A7B47B7B",
                                    imageMetaData: .constant(nil)) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(height: 200)
                                            .clipped()
                                    } placeholder: {
                                        Rectangle()
                                            .fill(.quinary)
                                            .frame(height: 200)
                                    }
                                LinearGradient(colors: [.black.opacity(0.5), .clear], startPoint: .bottom, endPoint: .top)
                                VStack(alignment: .leading) {
                                    Spacer()
                                    Text("Taco Tuesday")
                                        .font(.variableFont(28, axis: [FontVariations.weight.rawValue : 600]))
                                        .hLeading()
                                    
                                    Text("Every Tuesday")
                                        .font(.variableFont(18, axis: [FontVariations.weight.rawValue : 400]))
                                }
                                .padding()
                            }
                            .frame(width: UIScreen.main.bounds.width * 0.7)
                            .clipShape(.rect(cornerRadius: 20))
                            .padding(10)
                            
                            ZStack {
                                AsyncImageWithColor(
                                    imageRef: "257AC6EF-88A7-4897-8B09-02B3A7B47B7B",
                                    imageMetaData: .constant(nil)) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(height: 200)
                                            .clipped()
                                    } placeholder: {
                                        Rectangle()
                                            .fill(.quinary)
                                            .frame(height: 200)
                                    }
                                LinearGradient(colors: [.black.opacity(0.5), .clear], startPoint: .bottom, endPoint: .top)
                                VStack(alignment: .leading) {
                                    Spacer()
                                    Text("Taco Tuesday")
                                        .font(.variableFont(28, axis: [FontVariations.weight.rawValue : 600]))
                                        .hLeading()
                                    
                                    Text("Every Tuesday")
                                        .font(.variableFont(18, axis: [FontVariations.weight.rawValue : 400]))
                                }
                                .padding()
                            }
                            .frame(width: UIScreen.main.bounds.width * 0.7)
                            .clipShape(.rect(cornerRadius: 20))
                            .padding(10)
                            
                            Spacer()
                        }
                    }
                    
                }
                
            }
            .navigationTitle("Home")
            .onAppear() {
                Task {
                    try await viewModel.getBusinesses()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("New", systemImage: "plus") {
                        self.viewModel.showBusinessOnboarding = true
                    }
                }
            }
            .fullScreenCover(isPresented: $viewModel.showBusinessOnboarding) {
                UpdatedBusinessOnboardingFlow()
            }
        }
    }
}

class HomeViewModel: ObservableObject {
    @Published var businesses: [SlideBusiness] = []
    @Published var showBusinessOnboarding = false
    
    let businessRepo = SlideBusinessManager()
    
    func getBusinesses() async throws {
        let fetchedData = try await businessRepo.fetchAllBusinesses()
        print("Fetched \(fetchedData.count) businesses")
        self.businesses = fetchedData
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
            BusinessEditorView(business: business)
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



#Preview {
    HomeView(viewModel: HomeViewModel())
}
