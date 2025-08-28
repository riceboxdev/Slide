//
//  LoadingView.swift
//  Slide
//
//  Created by Nick Rogers on 7/29/25.
//



import SwiftUI

// MARK: - Loading View
struct LoadingView: View {
    @State private var isAnimating = false
    @State private var progress: CGFloat = 0

    let indicatorSize: CGFloat = 80

    var body: some View {
        ZStack {
            // Background gradient
            //            LinearGradient(
            //                colors: [Color.green.opacity(0.2), Color.clear],
            //                startPoint: .bottom,
            //                endPoint: .top
            //            )
            //            .ignoresSafeArea()
//            NeonMeshGradientView(duration: 8)
//                .ignoresSafeArea(edges: .top)
//                .opacity(0.2)

            VStack(spacing: 30) {
                // App logo/icon
                Image("Owned")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: indicatorSize, height: indicatorSize)
                    .opacity(isAnimating ? 1.0 : 0.7)
                    .scaleEffect(isAnimating ? 1.0 : 0.9)

                Text("Loading".uppercased())
                    .bold()
                    .opacity(0.5)

                //                // Loading indicator
                //                VStack(spacing: 15) {
                //                    ProgressView()
                //                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                //                        .scaleEffect(1.2)
                //
                //                    Text("Finding cool spots...")
                //                        .font(.subheadline)
                //                        .foregroundColor(.white.opacity(0.8))
                //                }
            }
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.0).repeatForever(autoreverses: true)
            ) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    LoadingView()
}
