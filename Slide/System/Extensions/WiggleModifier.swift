//
//  WiggleModifier.swift
//  BOOKD
//
//  Created by Nick Rogers on 7/13/25.
//

import SwiftUI

// MARK: - Wiggle Modifier
struct WiggleModifier: ViewModifier {
    @State private var isWiggling = false
    var isEnabled: Bool

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(isWiggling ? randomRotation() : 0))
            .animation(
                isEnabled
                    ? Animation.easeInOut(duration: 0.1)
                        .repeatForever(autoreverses: true)
                    : Animation.easeInOut(duration: 0.2),
                value: isWiggling
            )
            .onAppear {
                if isEnabled {
                    // Start wiggling with a random delay to make it feel more natural
                    DispatchQueue.main.asyncAfter(
                        deadline: .now() + Double.random(in: 0...0.5)
                    ) {
                        isWiggling = true
                    }
                }
            }
            .onChange(of: isEnabled) { oldValue, newValue in
                if newValue {
                    DispatchQueue.main.asyncAfter(
                        deadline: .now() + Double.random(in: 0...0.3)
                    ) {
                        isWiggling = true
                    }
                } else {
                    isWiggling = false
                }
            }
    }

    private func randomRotation() -> Double {
        Double.random(in: -2...2)
    }
}



// MARK: - View Extension
extension View {
    func wiggle(isEnabled: Bool) -> some View {
        self.modifier(WiggleModifier(isEnabled: isEnabled))
    }
}
