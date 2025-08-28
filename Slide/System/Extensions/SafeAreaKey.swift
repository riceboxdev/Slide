//
//  SafeAreaKey.swift
//  BOOKD
//
//  Created by Nick Rogers on 7/15/25.
//

import SwiftUI
import UIKit

#if canImport(UIKit)
    extension UIEdgeInsets {

        fileprivate var edgeInsets: EdgeInsets {
            .init(top: top, leading: left, bottom: bottom, trailing: right)
        }
    }
#endif

private struct SafeAreaInsetsKey: EnvironmentKey {

    static var defaultValue: EdgeInsets {
        #if os(iOS) || os(tvOS)
            let keyWindow = UIApplication.shared.keyWindow
            return keyWindow?.safeAreaInsets.edgeInsets ?? EdgeInsets()
        #else
            EdgeInsets()
        #endif
    }
}

extension EnvironmentValues {

    public var safeAreaInsets: EdgeInsets {
        self[SafeAreaInsetsKey.self]
    }
}
