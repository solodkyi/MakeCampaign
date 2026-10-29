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

/// A hexagon lying on its side: flat top and bottom edges, points at the left
/// and right. The counterpart to `PosterHexagon`.
struct PosterHexagonHorizontal: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.minX + rect.width * 0.25, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.75, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.75, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.25, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()

        return path
    }
}

/// The outline of a single character, scaled to fill its frame.
///
/// SwiftUI can fill text but not stroke it, so a glyph used as an outlined
/// watermark has to come through Core Text as a path.
struct PosterGlyph: Shape {
    let character: Character

    func path(in rect: CGRect) -> Path {
        let font = CTFontCreateWithName("Helvetica" as CFString, 100, nil)

        var characters = Array(String(character).utf16)
        var glyphs = [CGGlyph](repeating: 0, count: characters.count)
        guard CTFontGetGlyphsForCharacters(font, &characters, &glyphs, characters.count),
              let glyph = glyphs.first,
              let letter = CTFontCreatePathForGlyph(font, glyph, nil) else {
            return Path()
        }

        // Glyph paths are y-up, so the vertical flip is part of fitting them.
        let bounds = letter.boundingBoxOfPath
        guard bounds.width > 0, bounds.height > 0 else { return Path() }

        let scale = min(rect.width / bounds.width, rect.height / bounds.height)
        let scaled = Path(letter).applying(CGAffineTransform(scaleX: scale, y: -scale))
        let scaledBounds = scaled.boundingRect

        return scaled.applying(
            CGAffineTransform(
                translationX: rect.midX - scaledBounds.midX,
                y: rect.midY - scaledBounds.midY
            )
        )
    }
}
