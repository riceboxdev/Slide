//
//  FontVariations.swift
//  BOOKD
//
//  Created by Nick Rogers on 7/18/25.
//


import Foundation
import SwiftUI

public enum FontVariations: Int, CustomStringConvertible {
    case weight = 2003265652
    case width = 2003072104
    case opticalSize = 1869640570
    case grad = 1196572996
    case slant = 1936486004
    case xtra = 1481921089
    case xopq = 1481592913
    case yopq = 1498370129
    case ytlc = 1498696771
    case ytuc = 1498699075
    case ytas = 1498693971
    case ytde = 1498694725
    case ytfi = 1498695241

    public var description: String {
        switch self {
        case .weight:
            return "Weight"
        case .width:
            return "Width"
        case .opticalSize:
            return "Optical Size"
        case .grad:
            return "Grad"
        case .slant:
            return "Slant"
        case .xtra:
            return "Xtra"
        case .xopq:
            return "Xopq"
        case .yopq:
            return "Yopq"
        case .ytlc:
            return "Ytlc"
        case .ytuc:
            return "Ytuc"
        case .ytas:
            return "Ytas"
        case .ytde:
            return "Ytde"
        case .ytfi:
            return "Ytfi"
        }
    }

}

// MARK: - Font
public extension Font {
    static func variableFont(_ size: CGFloat, axis: [Int: Int] = [:]) -> Font {
        let uiFontDescriptor = UIFontDescriptor(fontAttributes: [.name: "InterVariable", kCTFontVariationAttribute as UIFontDescriptor.AttributeName: axis])
        let newUIFont = UIFont(descriptor: uiFontDescriptor, size: size)
        return Font(newUIFont)
    }
}


// MARK: Extensions for UI Designing
extension View{

    func hLeading()->some View{
        self
            .frame(maxWidth: .infinity,alignment: .leading)
    }

    func hTrailing()->some View{
        self
            .frame(maxWidth: .infinity,alignment: .trailing)
    }

    func hCenter()->some View{
        self
            .frame(maxWidth: .infinity,alignment: .center)
    }
}