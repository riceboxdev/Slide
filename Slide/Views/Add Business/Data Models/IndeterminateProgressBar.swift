//
//  IndeterminateProgressBar.swift
//  Slide
//
//  Created by Nick Rogers on 8/23/25.
//


import SwiftUI

struct IndeterminateProgressBar: View {
    @State private var isAnimating = false
    
    var color: Color = .accentColor
    let barWidth: CGFloat = 100
    let animationDuration: Double = 1.2
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 6)
                    .cornerRadius(3)
                
                // Animated progress bar
                Rectangle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [
                            color.opacity(0.8),
                            color,
                            color.opacity(0.8)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(width: barWidth, height: 6)
                    .cornerRadius(3)
                    .offset(x: isAnimating ? geometry.size.width - barWidth : -barWidth)
                    .animation(
                        Animation
                            .easeInOut(duration: animationDuration)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
        .onDisappear {
            isAnimating = false
        }
    }
}

// Alternative version with more Windows-like behavior
struct WindowsStyleProgressBar: View {
    @State private var animationPhase = 0
    
    let barWidth: CGFloat = 120
    let animationDuration: Double = 2.0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(UIColor.systemGray5))
                    .frame(height: 4)
                
                // Moving progress indicator
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.accentColor)
                    .frame(width: barWidth, height: 4)
                    .offset(x: offsetForPhase(animationPhase, containerWidth: geometry.size.width))
                    .animation(
                        Animation.easeInOut(duration: animationDuration)
                            .repeatForever(autoreverses: false),
                        value: animationPhase
                    )
            }
        }
        .onAppear {
            withAnimation {
                animationPhase = 1
            }
        }
    }
    
    private func offsetForPhase(_ phase: Int, containerWidth: CGFloat) -> CGFloat {
        switch phase {
        case 0:
            return -barWidth
        case 1:
            return containerWidth - barWidth
        default:
            return -barWidth
        }
    }
}

// Usage example with both styles
struct ProgressBarPreview: View {
    var body: some View {
        VStack(spacing: 40) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Bouncing Style")
                    .font(.headline)
                IndeterminateProgressBar()
                    .frame(height: 6)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Windows Style")
                    .font(.headline)
                WindowsStyleProgressBar()
                    .frame(height: 4)
            }
            
            Spacer()
        }
        .padding()
    }
}

// Preview
struct ProgressBarView_Previews: PreviewProvider {
    static var previews: some View {
        ProgressBarPreview()
    }
}
