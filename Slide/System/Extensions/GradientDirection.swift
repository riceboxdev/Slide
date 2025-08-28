//
//  GradientDirection.swift
//  Slide
//
//  Created by Nick Rogers on 8/23/25.
//


import SwiftUI

// MARK: - Gradient Direction Enum
enum GradientDirection {
    case topToBottom
    case bottomToTop
    
    var startPoint: UnitPoint {
        switch self {
        case .topToBottom:
            return .top
        case .bottomToTop:
            return .bottom
        }
    }
    
    var endPoint: UnitPoint {
        switch self {
        case .topToBottom:
            return .bottom
        case .bottomToTop:
            return .top
        }
    }
}

// MARK: - View Modifier
struct LinearGradientMask: ViewModifier {
    let direction: GradientDirection
    let colors: [Color]
    
    init(direction: GradientDirection, colors: [Color] = [.clear, .black]) {
        self.direction = direction
        self.colors = colors
    }
    
    func body(content: Content) -> some View {
        content
            .mask(
                LinearGradient(
                    colors: colors,
                    startPoint: direction.startPoint,
                    endPoint: direction.endPoint
                )
            )
    }
}

// MARK: - View Extension
extension View {
    func linearGradientMask(
        _ direction: GradientDirection,
        colors: [Color] = [.clear, .black]
    ) -> some View {
        modifier(LinearGradientMask(direction: direction, colors: colors))
    }
}