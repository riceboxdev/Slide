//
//  CustomizePhotosView.swift
//  Slide
//
//  Created by Nick Rogers on 8/25/25.
//

import SwiftUI
import Combine

class PhotoUploadManager: ObservableObject {
    
}

struct CustomizePhotosView: View {
    @State var bannerPhoto: UIImage?
    var uploadedPhotos: ([UIImage]) -> Void
    
    var body: some View {
        GeometryReader { geometry in
            let imageHeight = geometry.size.width * 9 / 16
            VStack {
                if let banner = bannerPhoto {
                    Image(uiImage: banner)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: imageHeight)
                } else {
                    Rectangle()
                        .fill(.quinary)
                        .frame(height: imageHeight)
                }
                Spacer()
            }
            .ignoresSafeArea()
            .onAppear() {
                self.bannerPhoto = UIImage(named: "doko1")
            }
        }
    }
}

#Preview {
    if let place = createPlaceDetailsFromJSON() {
        NavigationView {
            CustomizePhotosView() { images in
                
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
