//
//  RBTheme.swift
//  MakeCampaign
//

import SwiftUI

enum RBTheme: Sendable {
    case system
    case light
    case dark

    func palette(for colorScheme: ColorScheme) -> RBThemePalette {
        switch self {
        case .system:
            colorScheme == .dark ? .dark : .light
        case .light:
            .light
        case .dark:
            .dark
        }
    }
}

struct RBThemePalette {
    let canvas: Color
    let app: Color
    let surface: Color
    let elevatedSurface: Color
    let field: Color
    let paper: Color
    let ink: Color
    let mutedInk: Color
    let border: Color
    let accent: Color
    let accentHover: Color
    let destructive: Color
    let steel: Color
    let iOSBlue: Color
    let iOSGreen: Color
    let groupedBackground: Color
    let telegram: Color

    static let light = RBThemePalette(
        canvas: RBColor.canvas,
        app: RBColor.app,
        surface: RBColor.surface,
        elevatedSurface: RBColor.elevatedSurface,
        field: RBColor.field,
        paper: RBColor.paper,
        ink: RBColor.ink,
        mutedInk: RBColor.mutedInk,
        border: RBColor.border,
        accent: RBColor.accent,
        accentHover: RBColor.accentHover,
        destructive: RBColor.destructive,
        steel: RBColor.steel,
        iOSBlue: RBColor.iOSBlue,
        iOSGreen: RBColor.iOSGreen,
        groupedBackground: RBColor.groupedBackground,
        telegram: RBColor.telegram
    )

    static let dark = RBThemePalette(
        canvas: RBColor.darkCanvas,
        app: RBColor.darkCanvas,
        surface: RBColor.darkSurface,
        elevatedSurface: RBColor.darkElevatedSurface,
        field: RBColor.darkField,
        paper: RBColor.darkSurface,
        ink: RBColor.darkInk,
        mutedInk: RBColor.darkMutedInk,
        border: RBColor.darkBorder,
        accent: RBColor.accent,
        accentHover: RBColor.accentHover,
        destructive: RBColor.destructive,
        steel: RBColor.steel,
        iOSBlue: RBColor.iOSBlue,
        iOSGreen: RBColor.iOSGreen,
        groupedBackground: RBColor.darkSurface,
        telegram: RBColor.telegram
    )
}

private struct RBThemeKey: EnvironmentKey {
    static let defaultValue: RBTheme = .system
}

extension EnvironmentValues {
    var rbTheme: RBTheme {
        get { self[RBThemeKey.self] }
        set { self[RBThemeKey.self] = newValue }
    }

    var rbThemePalette: RBThemePalette {
        rbTheme.palette(for: colorScheme)
    }
}

extension View {
    func rbTheme(_ theme: RBTheme) -> some View {
        environment(\.rbTheme, theme)
    }
}
