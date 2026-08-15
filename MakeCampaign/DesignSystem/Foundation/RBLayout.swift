//
//  RBLayout.swift
//  MakeCampaign
//

import SwiftUI

enum RBSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let base: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 40
    static let xxxl: CGFloat = 48
}

enum RBRadius {
    static let compact: CGFloat = 13
    static let field: CGFloat = 14
    static let control: CGFloat = 16
    static let chip: CGFloat = 18
    static let card: CGFloat = 20
    static let large: CGFloat = 24
    static let sheet: CGFloat = 26
    static let pill: CGFloat = .greatestFiniteMagnitude
}

struct RBShadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat

    static let card = RBShadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
    static let artwork = RBShadow(color: .black.opacity(0.10), radius: 30, x: 0, y: 10)
    static let editor = RBShadow(color: .black.opacity(0.14), radius: 34, x: 0, y: 14)
    static let floating = RBShadow(color: .black.opacity(0.22), radius: 26, x: 0, y: 10)
}
