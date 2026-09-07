//
//  PosterShapes.swift
//  MakeCampaign
//

import SwiftUI

/// The hexagon the gold and emerald templates clip their photo to: points at the
/// top and bottom, with vertical sides running between a quarter and
/// three-quarters of the height.
struct PosterHexagon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.25))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.75))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.75))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.25))
        path.closeSubpath()

        return path
    }
}

/// A single horizontal line across its frame, for rules that need a dash
/// pattern. Stroking a `Rectangle` would draw its sides as well, and a
/// zero-height one draws nothing at all.
struct PosterRule: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))

        return path
    }
}

/// A banner with a chevron bitten out of one or both vertical edges.
struct PosterNotchedBanner: Shape {
    var notch: CGFloat
    var notchesLeading = false
    var notchesTrailing = true

    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        if notchesTrailing {
            path.addLine(to: CGPoint(x: rect.maxX - notch, y: rect.midY))
        }
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        if notchesLeading {
            path.addLine(to: CGPoint(x: rect.minX + notch, y: rect.midY))
        }
        path.closeSubpath()

        return path
    }
}
