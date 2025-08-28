//
//  CustomizePhotosView.swift
//  Slide
//
//  Created by Nick Rogers on 8/25/25.
//

import SwiftUI
import Combine
import PhotosUI

class PhotoUploadManager: ObservableObject {
    
}

struct CustomizePhotosView: View {
    @State var selectedBanner: PhotosPickerItem?
    @State var selectedProfile: PhotosPickerItem?
    @Binding var bannerPhoto: UIImage?
    @Binding var profilePhoto: UIImage?
    @State var showSheet = false
    
    var place: PlaceDetailsResponse?
    var uploadedPhotos: ([UIImage]) -> Void
    
    var body: some View {
        GeometryReader { geometry in
            let imageHeight = geometry.size.width * 9 / 16
            VStack(spacing: 0) {
                bannerView(height: imageHeight)
                    .overlay(alignment: .bottomLeading) {
                        profileView()
                    }
                if let displayName = place?.displayName?.text {
                    HStack {
                        Text(displayName)
                            .font(.largeTitle)
                            .bold()
                        Spacer()
                    }
                    .padding()
                }
                Spacer()
                bottomPickerButton()
               
            }
            .ignoresSafeArea()
        }
    }
    
    fileprivate func bannerView(height: CGFloat) -> some View {
        VStack {
            Group {
                if let banner = bannerPhoto {
                    Image(uiImage: banner)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: height)
                        .clipped()
                } else {
                    PhotosPicker(
                        selection: $selectedBanner,
                        matching: .images
                    ) {
                        Rectangle()
                            .fill(.quinary)
                            .frame(height: height)
                    }
                }
            }
            Rectangle()
                .fill(.clear)
                .frame(height: 50)
//                .border(.red)
        }
        .onChange(of: selectedBanner) { newItem in
            bannerPhoto = nil
            guard let item = newItem else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        bannerPhoto = image
                    }
                }
            }
        }
    }
    
    fileprivate func profileView() -> some View {
        Group {
            if let profile = profilePhoto {
                Image(uiImage: profile)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 130, height: 130)
                    .clipShape(.rect(cornerRadius: 20))
            } else {
                PhotosPicker(
                    selection: $selectedProfile,
                    matching: .images
                ) {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(UIColor.secondarySystemBackground))
                        .frame(width: 130, height: 130)
                       
                }
               
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20).fill(.clear)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 2)
        }
        .shadow(color: Color.black.opacity(0.2), radius: 16)
        .padding(.horizontal)
        .onChange(of: selectedProfile) { newItem in
            profilePhoto = nil
            guard let item = newItem else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        profilePhoto = image
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    func bottomPickerButton() -> some View {
         Menu {
            PhotosPicker(
                selection: $selectedProfile,
                matching: .images
            ) {
                Label("Select Profile Photo", systemImage: "person")
            }
            PhotosPicker(
                selection: $selectedBanner,
                matching: .images
            ) {
                Label("Select Banner", systemImage: "photo")
            }
        } label: {
            Text("Pick Photos")
                .font(.variableFont(14, axis: [FontVariations.weight.rawValue : 500]))
                .frame(height: 45)
                .padding(.horizontal)
                .glassEffect(.regular.tint(.accentColor.opacity(0.2)).interactive())
        }
        //                .shadow(radius: 10)
        .padding(.bottom, 100)
    }
}

#Preview {
    @Previewable @State var profilePhoto: UIImage?
    @Previewable @State var bannerPhoto: UIImage?
    
    if let place = createPlaceDetailsFromJSON() {
        NavigationView {
            CustomizePhotosView(
                bannerPhoto: $bannerPhoto,
                profilePhoto: $profilePhoto,
                place: place
            ) { images in
                
            }
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
