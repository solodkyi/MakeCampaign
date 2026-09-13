#!/usr/bin/env swift
//
//  generate_app_icon.swift
//  Renders the 1024x1024 AppIcon masters for the three iOS 26 appearances
//  (default / dark / tinted) straight from the "РобиЗбір Redesign" spec,
//  section 6 "iOS 26 · Liquid Glass".
//
//  The graphic is deliberately full-bleed and flat: no corner rounding, no
//  drop shadow, no baked specular highlight. iOS 26 draws the mask, the glass
//  and the highlight itself (design rule 01).
//
//  Usage: swift Scripts/generate_app_icon.swift <output-directory>
//

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

// MARK: - Geometry, as fractions of the icon's side

private enum Geometry {
    /// Side of one frame.
    static let frame = 0.40
    /// Stroke width. Never below 5%: in Clear mode the frames are pure outline.
    static let stroke = 0.052
    /// Corner radius of a frame — not of the icon, which the system masks.
    static let radius = 0.055
    /// Top-left origin of each frame, back to front.
    static let origins = [
        CGPoint(x: 0.53, y: 0.155),
        CGPoint(x: 0.30, y: 0.300),
        CGPoint(x: 0.07, y: 0.445),
    ]
    /// Angle of the background gradient, in CSS degrees.
    static let backgroundAngle = 155.0
}

// MARK: - Colour helpers

private struct RGBA {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double

    init(_ red: Double, _ green: Double, _ blue: Double, _ alpha: Double = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    /// `hex("E0562A")` — the notation the design document uses.
    init(hex: String, alpha: Double = 1) {
        let value = UInt32(hex, radix: 16)!
        self.init(
            Double((value >> 16) & 0xFF) / 255,
            Double((value >> 8) & 0xFF) / 255,
            Double(value & 0xFF) / 255,
            alpha
        )
    }

    /// A neutral grey — the only colour the tinted appearance is allowed.
    init(white: Double, alpha: Double = 1) {
        self.init(white, white, white, alpha)
    }

    var components: [CGFloat] { [red, green, blue, alpha].map { CGFloat($0) } }

    var cgColor: CGColor { CGColor(colorSpace: .sRGB, components: components)! }
}

private extension CGColorSpace {
    static let sRGB = CGColorSpace(name: CGColorSpace.sRGB)!
}

// MARK: - Appearance description

private struct Frame {
    var stroke: RGBA
    var fill: RGBA
}

private struct Appearance {
    var name: String
    /// Background gradient stops, as (colour, location) pairs.
    var background: [(RGBA, Double)]
    /// Frames back to front.
    var frames: [Frame]
}

private let appearances = [
    // Default. The paper-white stack the rest of the app is built on.
    Appearance(
        name: "AppIcon-Default-1024",
        background: [
            (RGBA(hex: "FFFEFC"), 0.00),
            (RGBA(hex: "F4F1EA"), 0.58),
            (RGBA(hex: "E9E4DA"), 1.00),
        ],
        frames: [
            Frame(stroke: RGBA(hex: "141413", alpha: 0.30), fill: RGBA(hex: "F4F1EA")),
            Frame(stroke: RGBA(hex: "141413", alpha: 0.60), fill: RGBA(hex: "F7F4EE")),
            Frame(stroke: RGBA(hex: "E0562A"), fill: RGBA(hex: "FBF9F5")),
        ]
    ),
    // Dark. The accent lifts to #F0703F — #E0562A goes muddy on black.
    Appearance(
        name: "AppIcon-Dark-1024",
        background: [
            (RGBA(hex: "26251F"), 0.00),
            (RGBA(hex: "15150F"), 0.62),
            (RGBA(hex: "0C0C08"), 1.00),
        ],
        frames: [
            Frame(stroke: RGBA(hex: "FAF9F7", alpha: 0.26), fill: RGBA(hex: "191910")),
            Frame(stroke: RGBA(hex: "FAF9F7", alpha: 0.54), fill: RGBA(hex: "141410")),
            Frame(stroke: RGBA(hex: "F0703F"), fill: RGBA(hex: "101008")),
        ]
    ),
    // Tinted. Greyscale only: iOS maps luminance onto the user's tint, so the
    // orange has to go and the hierarchy rides on brightness alone — 26/50/82%.
    Appearance(
        name: "AppIcon-Tinted-1024",
        background: [
            (RGBA(white: 0.10), 0.00),
            (RGBA(white: 0.06), 0.62),
            (RGBA(white: 0.03), 1.00),
        ],
        frames: [
            Frame(stroke: RGBA(white: 0.26), fill: RGBA(white: 0.12)),
            Frame(stroke: RGBA(white: 0.50), fill: RGBA(white: 0.10)),
            Frame(stroke: RGBA(white: 0.82), fill: RGBA(white: 0.08)),
        ],
    ),
]

// MARK: - Drawing

/// Start and end point of a CSS `linear-gradient(<angle>deg, …)` over `size`,
/// in a top-left-origin coordinate space.
private func gradientLine(angle: Double, size: Double) -> (CGPoint, CGPoint) {
    let radians = angle * .pi / 180
    let direction = CGPoint(x: sin(radians), y: -cos(radians))
    let length = abs(size * sin(radians)) + abs(size * cos(radians))
    let center = CGPoint(x: size / 2, y: size / 2)
    let half = length / 2
    return (
        CGPoint(x: center.x - direction.x * half, y: center.y - direction.y * half),
        CGPoint(x: center.x + direction.x * half, y: center.y + direction.y * half)
    )
}

private func draw(_ appearance: Appearance, side: Double) -> CGImage {
    let pixels = Int(side)
    let context = CGContext(
        data: nil,
        width: pixels,
        height: pixels,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: .sRGB,
        // Opaque: an App Store icon may not carry an alpha channel.
        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
    )!
    // Flip to a top-left origin so the spec's CSS offsets transfer verbatim.
    context.translateBy(x: 0, y: CGFloat(side))
    context.scaleBy(x: 1, y: -1)
    context.setShouldAntialias(true)
    context.interpolationQuality = .high

    let gradient = CGGradient(
        colorsSpace: .sRGB,
        colors: appearance.background.map { $0.0.cgColor } as CFArray,
        locations: appearance.background.map { CGFloat($0.1) }
    )!
    let (start, end) = gradientLine(angle: Geometry.backgroundAngle, size: side)
    context.drawLinearGradient(gradient, start: start, end: end, options: [])

    let frameSide = Geometry.frame * side
    let stroke = Geometry.stroke * side
    let radius = Geometry.radius * side

    for (origin, frame) in zip(Geometry.origins, appearance.frames) {
        let box = CGRect(
            x: origin.x * side,
            y: origin.y * side,
            width: frameSide,
            height: frameSide
        )
        // CSS `box-sizing: border-box`: the fill reaches the outer edge and the
        // stroke is drawn inside it, so a frame occludes whatever sits behind.
        context.setFillColor(frame.fill.cgColor)
        context.addPath(CGPath(roundedRect: box, cornerWidth: radius, cornerHeight: radius, transform: nil))
        context.fillPath()

        let inset = box.insetBy(dx: stroke / 2, dy: stroke / 2)
        context.setStrokeColor(frame.stroke.cgColor)
        context.setLineWidth(CGFloat(stroke))
        context.addPath(CGPath(
            roundedRect: inset,
            cornerWidth: radius - stroke / 2,
            cornerHeight: radius - stroke / 2,
            transform: nil
        ))
        context.strokePath()
    }

    return context.makeImage()!
}

// MARK: - Entry point

let arguments = CommandLine.arguments
guard arguments.count == 2 else {
    FileHandle.standardError.write(Data("usage: generate_app_icon.swift <output-directory>\n".utf8))
    exit(64)
}
let directory = URL(fileURLWithPath: arguments[1], isDirectory: true)

for appearance in appearances {
    let url = directory.appendingPathComponent("\(appearance.name).png")
    let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, draw(appearance, side: 1024), nil)
    guard CGImageDestinationFinalize(destination) else {
        FileHandle.standardError.write(Data("failed to write \(url.path)\n".utf8))
        exit(1)
    }
    print("wrote \(url.lastPathComponent)")
}
