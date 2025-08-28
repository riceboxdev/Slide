//
//  AdaptiveTextColor.swift
//  BOOKD
//
//  Created by Nick Rogers on 7/9/25.
//

import Foundation
import SwiftUI

extension Color {
    func luminance() -> Double {
        // 1. Convert SwiftUI Color to UIColor
        let uiColor = UIColor(self)

        // 2. Extract RGB values
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: nil)

        // 3. Compute luminance.
        return 0.2126 * Double(red) + 0.7152 * Double(green) + 0.0722
            * Double(blue)
    }
}

extension Color {
    func isLight() -> Bool {
        return luminance() > 0.5
    }
}

extension Color {
    func adaptedTextColor() -> Color {
        return isLight() ? Color.black : Color.white
    }
}
