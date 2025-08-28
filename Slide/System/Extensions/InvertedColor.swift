//
//  Inverted Color.swift
//  BOOKD
//
//  Created by Nick Rogers on 7/9/25.
//

import Foundation
import SwiftUI

// MARK: - UIColor Extension
extension UIColor {
    /// Returns the inverted color by inverting RGB values
    var inverted: UIColor {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        // Extract RGBA components
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        // Invert RGB values (1.0 - original value)
        return UIColor(
            red: 1.0 - red,
            green: 1.0 - green,
            blue: 1.0 - blue,
            alpha: alpha
        )
    }
}

// MARK: - Color Extension
extension Color {
    /// Returns the inverted color by inverting RGB values
    var inverted: Color {
        // Convert SwiftUI Color to UIColor, invert it, then back to Color
        return Color(UIColor(self).inverted)
    }
}
