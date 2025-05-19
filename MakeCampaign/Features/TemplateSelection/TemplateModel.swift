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
}
