//
//  BusinessView.swift
//  Slide
//
//  Created by Nick Rogers on 8/25/25.
//

import FirebaseFirestore
import MapKit
import SwiftUI

struct BusinessView: View {
    var business: SlideBusiness
    @StateObject var createPostModel: CreatePostViewModel = .init()
    @StateObject var postsModel: BusinessPostViewModel = .init()
    @State var heroVideo: VideoItem?
    @State var createPost: Bool = false
    @State var expandMedia: Bool = false
    @State var bannerMetadat: ImageMetadata?
    @State var isMuted: Bool = true
    @State var notificationsEnabled: Bool = false

    let screenWidth: CGFloat = UIScreen.main.bounds.width
    let spacing: CGFloat = 15
    
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
            setupView()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("", systemImage: "plus") {
                    self.createPost = true
                }
            }
        }
        .sheet(isPresented: $createPost) {
            CreatePostView(business: business)
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
                if let video = heroVideo {
                    UIVideoPlayerView(videoItem: video, height: height, isMuted: $isMuted)
//                        .frame(height: height)
                }
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
            Text(business.displayName?.text ?? "")
                .font(
                    .variableFont(
                        38,
                        axis: [FontVariations.weight.rawValue: 800]
                    )
                )
                .foregroundStyle(.white)

            if let type = business.primaryType {
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
                        if let address = business.formattedAddress {
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
                
                if business.isBlackOwned == true {
                    HStack {
                        Image(systemName: "staroflife.fill")
                            .foregroundStyle(.yellow)
                        Text("Black Owned".uppercased())
                            .font( .variableFont(14, axis: [FontVariations.weight.rawValue: 400]))
                        Spacer()
                    }
                    .padding(.horizontal)
                    .frame(height: 45)
                    .background(.quinary)
                }
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

            VStack {
                ForEach(postsModel.posts) { post in
                    BusinessPostCardView(business: business, post: post)
                }
            }
            .safeAreaPadding(.horizontal, 10)
            VStack(spacing: 25) {
                HStack {
                    Image(systemName: "phone")
                    Button(business.internationalPhoneNumber ?? "-") {
                        
                    }
                    Spacer()
                }
                
                HStack {
                    Image(systemName: "globe")
                    Button(business.websiteUri ?? "-") {
                        
                    }
                        .lineLimit(1)
                    Spacer()
                }
            }
            .padding()
            
            
            SlideBusinessMapPreview(business: business)
                .padding(.horizontal, 10)
        }
    }
    
    func setupView() {
        Task {
            getHeroVideo()
            guard let id = business.id else { return }
            await postsModel.loadPosts(
                for: id
            )
            print("POSTS: \(self.postsModel.posts.count)")
        }
    }
    
    @MainActor
    func getHeroVideo() {
        guard let videoRef = business.videoReference else { return }
        let videoLoader = VideoRetrievalService()
        
        videoLoader.fetchVideo(by: videoRef) { video in
            if let video = video {
                self.heroVideo = video
            }
        }
    }
}

struct BusinessPostCardView: View {
    @State var profileMetadata: ImageMetadata?
    @State var isLiked: Bool = false
    var business: SlideBusiness?
    var post: BusinessPost
    
    let profileImageHeight: CGFloat = 30
 
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            
            HStack {
                Group {
                    if let profilePhoto = business?.profilePhoto {
                        AsyncImageWithColor(
                            imageRef: profilePhoto,
                            imageMetaData: $profileMetadata
                        ) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            Circle()
                                .fill(.quinary)
                        }
                        
                    } else {
                        Circle()
                            .fill(.quinary)
                    }
                }
                .frame(width: profileImageHeight, height: profileImageHeight)
                .clipShape(.circle)
                
                VStack(alignment: .leading) {
                    Text(business?.displayName?.text ?? "")
                        .font(.variableFont(14, axis: [FontVariations.weight.rawValue: 600]))
                    Text((business?.username ?? business?.primaryType?.capitalized) ?? "")
                        .font(.variableFont(12, axis: [FontVariations.weight.rawValue: 600]))
                }
                
                Spacer()
                
                Image(systemName: post.postType.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(.secondary)
                    .frame(width: 15, height: 15)
                    .padding(6)
                    .background(.quinary, in: .rect(cornerRadius: 8))
            }
            
            Text(post.title)
                .font(.variableFont(22, axis: [FontVariations.weight.rawValue: 500]))
                .multilineTextAlignment(.leading)
                .hLeading()
            
            Text(post.content)
                .font(.variableFont(16, axis: [FontVariations.weight.rawValue: 400]))
                .multilineTextAlignment(.leading)
                .hLeading()
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(post.tags, id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.variableFont(14, axis: [FontVariations.weight.rawValue: 400]))
                            .padding(5)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            HStack {
                Spacer()
                Button {
                    self.isLiked.toggle()
                } label: {
                    Image(systemName: "heart.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 25)
                        .foregroundStyle(isLiked ? Color.red : Color.accentColor.opacity(0.3))
                }
                    
            }
            .frame(height: 40)
//            .border(.red)
        }
        .safeAreaPadding()
        .background(.quinary, in: .rect(cornerRadius: 30))
        .clipped()
    }
}

struct SlideBusinessMapPreview: View {
    var business: SlideBusiness
    let screenWidth: CGFloat = UIScreen.main.bounds.width
    var body: some View {
        if let location = business.location {
            Map(
                coordinateRegion: .constant(
                    MKCoordinateRegion(
                        center: CLLocationCoordinate2D(
                            latitude: location.latitude,
                            longitude: location.longitude
                        ),
                        span: MKCoordinateSpan(
                            latitudeDelta: 0.01,
                            longitudeDelta: 0.01
                        )
                    )
                ),
                annotationItems: [location]
            ) { location in
                MapPin(
                    coordinate: CLLocationCoordinate2D(
                        latitude: location.latitude,
                        longitude: location.longitude
                    )
                )
            }
            .frame(height: screenWidth / 2)
            .cornerRadius(30)
        }
    }
}



struct PullEffectScrollView<Content: View>: View {
    var dragDistance: CGFloat = 100
    var actionTopPadding: CGFloat = 0
    var leadingAction: PullEffectAction
    var centerAction: PullEffectAction
    var trailingAction: PullEffectAction
    @ViewBuilder var content: Content

    @State private var effectProgress: CGFloat = 0
    @GestureState private var isGestureActive: Bool = false
    @State private var scrollOffset: CGFloat = 0
    @State private var initialScroll0ffset: CGFloat?
    @State private var activePosition: ActionPosition?
    @State private var hapticsTrigger: Bool = false
    @State private var scaleEffect: Bool = false
    @Namespace private var animation

    var body: some View {
        ScrollView(.vertical) {
            content
        }
        .onScrollGeometryChange(
            for: CGFloat.self,
            of: {
                $0.contentOffset.y + $0.contentInsets.top
            },
            action: { oldValue, newValue in
                scrollOffset = newValue
            }
        )
        .onChange(of: isGestureActive) { oldValue, newValue in
            initialScroll0ffset = newValue ? scrollOffset.rounded() : nil
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .updating(
                    $isGestureActive,
                    body: { _, out, _ in
                        out = true
                    }
                )
                .onChanged { value in
                    guard initialScroll0ffset == 0 else { return }

                    let translationY = value.translation.height
                    let progress = min(max(translationY / dragDistance, 0), 1)
                    effectProgress = progress

                    guard translationY >= dragDistance else {
                        activePosition = nil
                        return
                    }
                    let translationX = value.translation.width
                    let indexProgress = translationX / dragDistance
                    let index: Int =
                        -indexProgress > 0.5
                        ? -1 : (indexProgress > 0.5 ? 1 : 0)
                    let landingAction = ActionPosition.allCases.first(where: {
                        $0.rawValue == index
                    })

                    if activePosition != landingAction {
                        hapticsTrigger.toggle()
                    }

                    activePosition = landingAction
                }
                .onEnded { value in
                    guard effectProgress != 0 else { return }
                    if let activePosition {
                        withAnimation(
                            .easeInOut(duration: 0.25),
                            completionCriteria:
                                .logicallyComplete
                        ) {
                            scaleEffect = true
                        } completion: {
                            scaleEffect = false
                            effectProgress = 0
                            self.activePosition = nil
                        }
                        switch activePosition {
                        case .leading: trailingAction.action()
                        case .center: centerAction.action()
                        case .trailing: trailingAction.action()
                        }
                    } else {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            effectProgress = 0
                        }
                    }
                },
            isEnabled: !scaleEffect
        )
        .overlay(alignment: .top) {
            ActionsView()
                .padding(.top, actionTopPadding * 2)

        }
        .sensoryFeedback(.impact, trigger: hapticsTrigger)
    }

    /// Actions View
    @ViewBuilder private func ActionsView() -> some View {
        HStack(spacing: 0) {
            let delayedProgress = (effectProgress - 0.7) / 0.3

            ActionButton(.leading)
                .offset(x: 30 * (1 - delayedProgress))
                .opacity(delayedProgress)

            ActionButton(.center)
                .blur(radius: 10 * (1 - effectProgress))
                .opacity(effectProgress)
            ActionButton(.trailing)
                .offset(x: -30 * (1 - delayedProgress))
                .opacity(delayedProgress)
        }
        .padding(.horizontal, 20)
        .opacity(scaleEffect ? 0 : 1)
    }
    /// Action Button
    @ViewBuilder
    private func ActionButton(_ position: ActionPosition) -> some View {
        let action =
            position == .center
            ? centerAction
            : position == .trailing ? trailingAction : leadingAction
        Text(action.symbol)
            .font(.caption)
            .multilineTextAlignment(.center)
            .foregroundStyle(.white)
            .opacity(scaleEffect ? 0 : 1)
            .animation(.linear(duration: 0.05), value: scaleEffect)
            .padding(.horizontal)
            .frame(height: 40)
            .background {
                if activePosition == position {
                    ZStack {
                        Rectangle()
                            .fill(.black.opacity(0.1))
                        Rectangle()
                            .fill(.black.opacity(0.1))
                    }
                    .clipShape(.rect(cornerRadius: scaleEffect ? 0 : 30))
                    .compositingGroup()
                    .matchedGeometryEffect(id: "INDICATOR", in: animation)
                    .scaleEffect(scaleEffect ? 20 : 1, anchor: .bottom)
                }
            }
            .frame(maxWidth: .infinity)
            .compositingGroup()
            .animation(.easeInOut(duration: 0.25), value: activePosition)
    }

    private enum ActionPosition: Int, CaseIterable {
        case leading = -1
        case center = 0
        case trailing = 1
    }
}

struct PullEffectAction {
    var symbol: String
    var action: () -> Void
}

// Building Custom ScrollView Using View Builder
struct CustomScrollView<Content: View>: View {
    // To hold our view or to capture the described view
    var content: Content
    @Binding var offset: CGPoint
    @State var startOffset: CGPoint = .zero
    var showIndicators: Bool
    var axis: Axis.Set
    // Since it will carry multiple views
    // so it will be a closure and it will return view
    init(
        offset: Binding<CGPoint>,
        showIndicators: Bool,
        axis: Axis.Set,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self._offset = offset
        self.showIndicators = showIndicators
        self.axis = axis
    }

    var body: some View {
        ScrollView(
            axis,
            showsIndicators: showIndicators,
            content: {
                content
                    .overlay(
                        // Using Geometry reader to get offset
                        GeometryReader { proxy -> Color in
                            let rect = proxy.frame(in: .global)
                            if self.startOffset == .zero {
                                DispatchQueue.main.async {
                                    self.startOffset = CGPoint(
                                        x: rect.minX,
                                        y: rect.minY
                                    )
                                }
                            }
                            DispatchQueue.main.async {
                                // Minus from current
                                self.offset = CGPoint(
                                    x: startOffset.x - rect.minX,
                                    y: startOffset.y - rect.minY
                                )
                            }
                            return Color.clear
                        }
                        // Since we're also fetching horizontal offset
                        // so setting width to full so that minX will be zero
                        .frame(width: UIScreen.main.bounds.width, height: 0)

                        ,
                        alignment: .top
                    )
            }
        )
    }
}

let sampleVideo = VideoItem(
    id: UUID().uuidString,
    url: URL(
        string:
            "https://firebasestorage.googleapis.com/v0/b/bookd-16634.firebasestorage.app/o/dev%2FSofi%20Stadium%20Inglewood.mp4?alt=media&token=0a9d227e-3e25-4d17-a109-04d80bd2a3ae"
    )!,
    thumbnailURL: URL(
        string:
            "https://firebasestorage.googleapis.com/v0/b/bookd-16634.firebasestorage.app/o/dev%2Fframe-1%20(1).png?alt=media&token=fd6cbe0b-2316-4139-8083-a56db3bb1e1d"
    ),
    title: "SoFi Stadium"
)

let sampleAnnouncementPost = BusinessPost(
    id: "post_announcement_001",
    businessId: "restaurant_123",
    authorId: "user_tony_owner",
    title: "🎉 Grand Opening of Our New Patio Dining Area!",
    content: """
        We're thrilled to announce the grand opening of our beautiful new patio dining area! 🌟

        After months of careful planning and construction, we're ready to welcome you to dine under the stars with:

        ✨ 20 additional outdoor tables
        🌿 Lush greenery and ambient lighting
        🍷 Full bar service on the patio
        🎵 Live acoustic music on weekends
        🔥 New wood-fired pizza oven for patio guests

        Join us this Friday, March 15th, for our patio launch celebration:
        • 20% off all patio dining from 5-9 PM
        • Complimentary appetizers with dinner orders
        • Live music by local artist Sarah Martinez starting at 7 PM
        • Special patio cocktail menu featuring seasonal favorites

        We can't wait to share this exciting new space with our community! Reserve your patio table today by calling us or booking online.

        Thank you for your continued support - we're so grateful to serve this amazing neighborhood! 🙏

        #PatioDining #GrandOpening #LiveMusic #OutdoorDining #Community
        """,
    postType: .announcement,
    status: .published,
    tags: [
        "grand opening", "patio dining", "live music", "outdoor seating",
        "celebration", "new features",
    ],
    mediaUrls: [
        "https://example.com/patio-construction.jpg",
        "https://example.com/patio-tables-setup.jpg",
        "https://example.com/patio-evening-lights.jpg",
        "https://example.com/wood-fired-oven.jpg",
    ],
    scheduledDate: nil,
    publishDate: Date(),
    expirationDate: Calendar.current.date(
        byAdding: .day,
        value: 30,
        to: Date()
    ),
    engagement: PostEngagement(
        views: 1247,
        likes: 89,
        shares: 23,
        comments: 15,
        clicks: 156
    ),
    metadata: PostMetadata(
        priority: 5,  // High priority for major announcements
        featured: true,
        allowComments: true,
        notifyFollowers: true,
        categories: ["facility updates", "events", "promotions"],
        targetAudience: ["local diners", "families", "couples", "music lovers"]
    ),
    createdAt: Timestamp(),
    updatedAt: Timestamp()
)

