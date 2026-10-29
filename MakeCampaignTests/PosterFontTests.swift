import Foundation
import Testing
import UIKit

@testable import MakeCampaign

@Suite("Poster fonts")
struct PosterFontTests {
    @Test("Every poster typeface is registered", arguments: PosterFont.allCases)
    func typefaceIsRegistered(_ font: PosterFont) {
        #expect(
            font.isRegistered,
            "\(font.rawValue) did not resolve; Font.custom would silently fall back to the system font"
        )
    }

    @Test("Poster typefaces cover the Cyrillic used by campaign copy", arguments: PosterFont.allCases)
    func typefaceCoversCyrillic(_ font: PosterFont) throws {
        let uiFont = try #require(UIFont(name: font.rawValue, size: 12))
        let characterSet = uiFont.fontDescriptor.object(
            forKey: .characterSet
        ) as? CharacterSet

        let coverage = try #require(characterSet)
        let sample = "збірцільЗБІРЦІЛЬїєґІЇЄҐ0123456789"

        for scalar in sample.unicodeScalars {
            #expect(
                coverage.contains(scalar),
                "\(font.rawValue) is missing U+\(String(scalar.value, radix: 16, uppercase: true))"
            )
        }
    }
}
