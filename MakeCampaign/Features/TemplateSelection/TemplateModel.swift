import Foundation
import SwiftUI
import ComposableArchitecture

struct Template: Codable, Equatable, Identifiable {
    let id: UUID
    let name: String
    let gradient: Gradient
    let imagePlacement: ImagePlacement
    
    enum Gradient: Codable, Equatable {
        case linearPurple
        case linearGreen
        case angularYellowBlue
        case linearSilverBlue
        case radialRedBlack
    }
    
    enum ImagePlacement: Codable, Equatable {
        case topCenter
        case topToBottomTrailing
        case trailing
        case trailingToEdge
        case topToEdge
    }
    
    init(id: UUID = UUID(), name: String, gradient: Gradient, imagePlacement: ImagePlacement) {
        self.id = id
        self.name = name
        self.gradient = gradient
        self.imagePlacement = imagePlacement
    }
}
