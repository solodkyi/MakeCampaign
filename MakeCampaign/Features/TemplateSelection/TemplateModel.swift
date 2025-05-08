import Foundation
import SwiftUI
import ComposableArchitecture

struct Template: Equatable, Identifiable {
    let id: UUID
    let name: String
    
    // Styling properties
    let backgroundColor: Color
    let textColor: Color
    let font: Font
    let layout: TemplateLayout
    let cornerStyle: CornerStyle
    
    init(
        id: UUID = UUID(),
        name: String,
        backgroundColor: Color = .white,
        textColor: Color = .black,
        font: Font = .system(.headline),
        layout: TemplateLayout = .bottom,
        cornerStyle: CornerStyle = .rounded(12)
    ) {
        self.id = id
        self.name = name
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.font = font
        self.layout = layout
        self.cornerStyle = cornerStyle
    }
    
    enum TemplateLayout: Equatable {
        case bottom
        case overlay
        case side
        case minimal
        case banner
    }
    
    enum CornerStyle: Equatable {
        case none
        case rounded(CGFloat)
    }
    
    static var mockTemplates: IdentifiedArrayOf<Template> {
        IdentifiedArrayOf(uniqueElements: [
            Template(
                name: "Стандартний",
                backgroundColor: .white,
                textColor: .black,
                font: .system(.headline),
                layout: .bottom,
                cornerStyle: .rounded(12)
            ),
            Template(
                name: "Мінімалістичний",
                backgroundColor: .white.opacity(0.9),
                textColor: .black,
                font: .system(.headline, design: .rounded),
                layout: .minimal,
                cornerStyle: .rounded(8)
            ),
            Template(
                name: "Яскравий",
                backgroundColor: .blue,
                textColor: .white,
                font: .system(.headline, design: .default),
                layout: .overlay,
                cornerStyle: .rounded(16)
            ),
            Template(
                name: "Класичний",
                backgroundColor: .black.opacity(0.7),
                textColor: .white,
                font: .system(.title2, design: .serif),
                layout: .bottom,
                cornerStyle: .rounded(0)
            ),
            Template(
                name: "Сучасний",
                backgroundColor: .black.opacity(0.5),
                textColor: .white,
                font: .system(.headline, design: .monospaced),
                layout: .side,
                cornerStyle: .none
            )
        ])
    }
}

// Extension to apply the template to a campaign image
extension Template {
    func applyTemplateToImage(image: UIImage, campaign: Campaign) -> UIImage {
        // In a real implementation, this would compose the image and campaign details 
        // according to the template style, using Core Graphics to draw text, etc.
        
        // Example implementation would:
        // 1. Create a new context
        // 2. Draw the image
        // 3. Draw overlays according to layout
        // 4. Draw text with campaign details using the template's style properties
        // 5. Return the composed image
        
        // For preview purposes, just returning the original image
        return image
    }
} 
