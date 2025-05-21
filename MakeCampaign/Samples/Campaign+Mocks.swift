import Foundation
import IdentifiedCollections

extension Campaign {
    static let mock1 = Campaign(
        id: UUID(),
        image: .init(raw: Bundle.main.url(forResource: "zbir1", withExtension: "png").flatMap { try? Data(contentsOf: $0) }),
        purpose: "Збір на FPV",
        target: 100000
    )
    
    static let mock2 = Campaign(
        id: UUID(),
        image: .init(raw: Bundle.main.url(forResource: "zbir2", withExtension: "png").flatMap { try? Data(contentsOf: $0) }),
        purpose: "Збір на машину розмінування ZMIY",
        target: 50000
    )
    
    static let mock3 = Campaign(
        id: UUID(),
        image: .init(raw: Bundle.main.url(forResource: "zbir3", withExtension: "png").flatMap { try? Data(contentsOf: $0) }),
        purpose: "Великодній кошик для окупантів",
        target: 30000
    )

    static let mock4 = Campaign(
        id: UUID(),
        image: .init(raw: Bundle.main.url(forResource: "zbir1", withExtension: "png").flatMap { try? Data(contentsOf: $0) }),
        purpose: "Дрон для розвідки",
        target: 75000
    )

    static let mock5 = Campaign(
        id: UUID(),
        image: .init(raw: Bundle.main.url(forResource: "zbir2", withExtension: "png").flatMap { try? Data(contentsOf: $0) }),
        purpose: "Аптечки для фронту",
        target: 20000
    )

    static let mock6 = Campaign(
        id: UUID(),
        image: .init(raw: Bundle.main.url(forResource: "zbir3", withExtension: "png").flatMap { try? Data(contentsOf: $0) }),
        purpose: "Тепловізори в бліндажі",
        target: 60000
    )

    static let mock7 = Campaign(
        id: UUID(),
        image: .init(raw: Bundle.main.url(forResource: "zbir1", withExtension: "png").flatMap { try? Data(contentsOf: $0) }),
        purpose: "Генератор для бригади",
        target: 45000
    )

    static let mock8 = Campaign(
        id: UUID(),
        image: .init(raw: Bundle.main.url(forResource: "zbir2", withExtension: "png").flatMap { try? Data(contentsOf: $0) }),
        purpose: "Пікап для підрозділу",
        target: 80000
    )

    static let mock9 = Campaign(
        id: UUID(),
        image: .init(raw: Bundle.main.url(forResource: "zbir3", withExtension: "png").flatMap { try? Data(contentsOf: $0) }),
        purpose: "Маскувальні сітки",
        target: 10000
    )

    static let mock10 = Campaign(
        id: UUID(),
        image: .init(raw: Bundle.main.url(forResource: "zbir1", withExtension: "png").flatMap { try? Data(contentsOf: $0) }),
        purpose: "Шини для автівки",
        target: 12000
    )
    
    static let mocks: IdentifiedArrayOf<Self> = [mock1, mock2, mock3, mock4, mock5, mock6, mock7, mock8, mock9, mock10]
}
