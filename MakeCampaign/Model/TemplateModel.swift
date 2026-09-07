import Foundation
import SwiftUI

struct Template: Codable, Equatable, Identifiable, Sendable {
    let name: String
    let series: Series
    let gradient: Gradient
    let imagePlacement: ImagePlacement

    var id: String {
        return "\(series.rawValue)_\(String(describing: gradient))_\(String(describing: imagePlacement))"
    }

    /// Which of the two poster design sets an entry is drawn from.
    ///
    /// The sets are alternative treatments of the same fifteen
    /// gradient/placement pairs, so a pair alone no longer identifies a
    /// template — the series is part of its identity, and of the thumbnail
    /// cache key that follows from it.
    enum Series: String, Codable, Equatable, Sendable {
        /// Набір A — перша ітерація.
        case a
        /// Набір B — свіжий погляд.
        case b
    }

    enum Gradient: Codable, Equatable, Sendable {
        case linearPurple
        case linearGreen
        case angularYellowBlue
        case linearSilverBlue
        case radialRedBlack
        case radialAquaPurple
        case pinkAngular
        case tealPurpleRadial
        case cyanMagentaRadial
        case goldBlackLinear
        case blueLinear
        case linearIndigoOrange
        case linearEmeraldBlack
        case radialMintIndigo
        case linearCoralTeal
    }

    enum ImagePlacement: Codable, Equatable, Sendable {
        case topCenter
        case topToBottomTrailing
        case trailing
        case trailingToEdge
        case topToEdge
        case center
        case roundedTrailing
        case hexagonTrailing
        case squareTrailing
    }

    init(
        name: String,
        series: Series = .b,
        gradient: Gradient,
        imagePlacement: ImagePlacement
    ) {
        self.name = name
        self.series = series
        self.gradient = gradient
        self.imagePlacement = imagePlacement
    }

    private enum CodingKeys: String, CodingKey {
        case name, series, gradient, imagePlacement
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        gradient = try container.decode(Gradient.self, forKey: .gradient)
        imagePlacement = try container.decode(ImagePlacement.self, forKey: .imagePlacement)
        // Campaigns saved before a second design set existed carry no series.
        // The fifteen entries they hold are the ones series B now draws, so
        // that is what they must keep resolving to.
        series = try container.decodeIfPresent(Series.self, forKey: .series) ?? .b
    }
}
