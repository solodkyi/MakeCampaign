//
//  PosterFont.swift
//  MakeCampaign
//

import SwiftUI

/// Typefaces used by the poster templates.
///
/// Raw values are PostScript names, which is what `Font.custom(_:size:)` resolves.
/// They differ from the bundled file names for Playfair Display, whose instances
/// carry `PlayfairDisplayRoman` / `PlayfairDisplayItalic` prefixes.
enum PosterFont: String, CaseIterable {
    case oswaldRegular = "Oswald-Regular"
    case oswaldMedium = "Oswald-Medium"
    case oswaldSemiBold = "Oswald-SemiBold"
    case oswaldBold = "Oswald-Bold"

    case playfairBold = "PlayfairDisplayRoman-Bold"
    case playfairExtraBold = "PlayfairDisplayRoman-ExtraBold"
    case playfairBoldItalic = "PlayfairDisplayItalic-BoldItalic"

    case plexMonoRegular = "IBMPlexMono-Regular"
    case plexMonoMedium = "IBMPlexMono-Medium"
    case plexMonoSemiBold = "IBMPlexMono-SemiBold"

    /// The font at `size`, in points.
    func size(_ size: CGFloat) -> SwiftUI.Font {
        .custom(rawValue, size: size)
    }

    /// Whether the typeface is registered and resolvable at runtime.
    ///
    /// `Font.custom` silently falls back to the system font when a name does not
    /// resolve, so poster fidelity depends on this holding for every case.
    var isRegistered: Bool {
        UIFont(name: rawValue, size: 12) != nil
    }
}
