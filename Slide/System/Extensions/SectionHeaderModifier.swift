//
//  SectionHeaderModifier.swift
//  BOOKD
//
//  Created by Nick Rogers on 7/18/25.
//


import SwiftUI

struct SectionHeaderModifier<ActionButton: View>: ViewModifier {
    let title: String
    let actionButton: ActionButton
    
    init(title: String, @ViewBuilder actionButton: () -> ActionButton) {
        self.title = title
        self.actionButton = actionButton()
    }
    
    func body(content: Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title.uppercased())
                    .font(.caption)
                Spacer()
                actionButton
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            content
        }
    }
}

extension View {
    func sectionHeader<ActionButton: View>(
        title: String,
        @ViewBuilder actionButton: @escaping () -> ActionButton
    ) -> some View {
        self.modifier(SectionHeaderModifier(title: title, actionButton: actionButton))
    }
}
