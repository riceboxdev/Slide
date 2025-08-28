//
//  ViewModifier.swift
//  BOOKD
//
//  Created by Nick Rogers on 7/18/25.
//

import Foundation
import SwiftUI


// MARK: - Helper Extensions
extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content)
        -> some View
    {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}


