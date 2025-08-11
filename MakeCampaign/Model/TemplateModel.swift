import Foundation
import SwiftUI

struct Template: Codable, Equatable, Identifiable {
    let name: String
    let gradient: Gradient
    let imagePlacement: ImagePlacement
    
    var id: String {
        return "\(String(describing: gradient))_\(String(describing: imagePlacement))"
    }
    
    enum Gradient: Codable, Equatable {
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
    
    enum ImagePlacement: Codable, Equatable {
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
    
    init(name: String, gradient: Gradient, imagePlacement: ImagePlacement) {
        self.name = name
        self.gradient = gradient
        self.imagePlacement = imagePlacement
    }
}
