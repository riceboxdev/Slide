//
//  Color Shades.swift
//  BOOKD
//
//  Created by Nick Rogers on 7/11/25.
//

import Foundation
import SwiftUI

func generateColorShades(from baseColor: Color) -> [Color] {
    return [
        baseColor.opacity(0.3),  // Lightest shade (30% opacity)
        baseColor.opacity(0.6),  // Light shade (60% opacity)
        baseColor,  // Original color
        baseColor.brightness(-0.3),  // Darkest shade (30% darker)
    ]
}
// Alternative version using brightness adjustments
func generateColorShadesBrightness(from baseColor: Color) -> [Color] {
    return [
        baseColor.brightness(0.4),  // Lightest shade
        baseColor.brightness(0.2),  // Light shade
        baseColor,  // Original color
        baseColor.brightness(-0.3),  // Darkest shade
    ]
}

// Extension to Color for convenience
extension Color {
    /// Adjusts the brightness of the color
    /// - Parameter amount: The amount to adjust brightness (-1.0 to 1.0)
    /// - Returns: A new Color with adjusted brightness
    func brightness(_ amount: Double) -> Color {
        let uiColor = UIColor(self)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getHue(
            &hue,
            saturation: &saturation,
            brightness: &brightness,
            alpha: &alpha
        )

        let newBrightness = max(0, min(1, brightness + amount))

        return Color(
            UIColor(
                hue: hue,
                saturation: saturation,
                brightness: newBrightness,
                alpha: alpha
            )
        )
    }

    /// Generates 4 shades of the current color
    /// - Returns: An array of 4 Color shades
    func shades() -> [Color] {
        return generateColorShades(from: self)
    }
}
