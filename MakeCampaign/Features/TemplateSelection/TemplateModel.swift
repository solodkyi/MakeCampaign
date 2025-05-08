import Foundation
import SwiftUI
import ComposableArchitecture

struct Template: Codable, Equatable, Identifiable {
    let id: UUID
    let name: String
    
    init(
        id: UUID = UUID(),
        name: String
    ) {
        self.id = id
        self.name = name
    }
    
    enum TemplateLayout: Codable, Equatable {
        case bottom
        case overlay
        case side
        case minimal
        case banner
    }
    
    enum CornerStyle: Codable, Equatable {
        case none
        case rounded(CGFloat)
    }
    
    static var mockTemplates: IdentifiedArrayOf<Template> {
        IdentifiedArrayOf(uniqueElements: [
            Template(name: "Стандартний"),
            Template(name: "Мінімалістичний"),
            Template(name: "Яскравий"),
            Template(name: "Класичний"),
            Template(name: "Сучасний")
        ])
    }
}
