import Foundation
import IdentifiedCollections

extension Campaign {
    static let mock1 = Campaign(
        id: UUID(),
        image: .init(raw: Bundle.main.url(forResource: "zbir1", withExtension: "png").flatMap { try? Data(contentsOf: $0) }),
        template: .init(name: "1", gradient: .linearPurple, imagePlacement: .topCenter),
        purpose: "Збір на FPV",
        target: 100000
    )
    
    static let mock2 = Campaign(
        id: UUID(),
        image: .init(raw: Bundle.main.url(forResource: "zbir2", withExtension: "png").flatMap { try? Data(contentsOf: $0) }),
        template: .init(name: "2", gradient: .blueLinear, imagePlacement: .center),
        purpose: "Збір на машину розмінування ZMIY",
        target: 50000,
    )
    
    static let mock3 = Campaign(
        id: UUID(),
        image: .init(raw: Bundle.main.url(forResource: "zbir3", withExtension: "png").flatMap { try? Data(contentsOf: $0) }),
        template: .init(name: "3", gradient: .cyanMagentaRadial, imagePlacement: .squareTrailing),
        purpose: "Великодній кошик для окупантів",
        target: 30000
    )

    static let mock4 = Campaign(
        id: UUID(),
        image: .init(raw: Bundle.main.url(forResource: "zbir1", withExtension: "png").flatMap { try? Data(contentsOf: $0) }),
        template: .init(name: "4", gradient: .goldBlackLinear, imagePlacement: .hexagonTrailing),
        purpose: "Дрон для розвідки",
        target: 75000
    )

    static let mock5 = Campaign(
        id: UUID(),
        image: .init(raw: Bundle.main.url(forResource: "zbir2", withExtension: "png").flatMap { try? Data(contentsOf: $0) }),
        template: .init(name: "5", gradient: .pinkAngular, imagePlacement: .topCenter),
        purpose: "Аптечки для фронту",
        target: 20000
    )

    static let mock6 = Campaign(
        id: UUID(),
        image: .init(raw: Bundle.main.url(forResource: "zbir3", withExtension: "png").flatMap { try? Data(contentsOf: $0) }),
        template: .init(name: "6", gradient: .tealPurpleRadial, imagePlacement: .roundedTrailing),
        purpose: "Тепловізори в бліндажі",
        target: 60000
    )

    static let mock7 = Campaign(
        id: UUID(),
        image: .init(raw: Bundle.main.url(forResource: "zbir1", withExtension: "png").flatMap { try? Data(contentsOf: $0) }),
        template: .init(name: "7", gradient: .linearGreen, imagePlacement: .topToBottomTrailing),
        purpose: "Генератор для бригади",
        target: 45000
    )

    static let mock8 = Campaign(
        id: UUID(),
        image: .init(raw: Bundle.main.url(forResource: "zbir2", withExtension: "png").flatMap { try? Data(contentsOf: $0) }),
        template: .init(name: "8", gradient: .angularYellowBlue, imagePlacement: .trailing),
        purpose: "Пікап для підрозділу",
        target: 80000
    )

    static let mock9 = Campaign(
        id: UUID(),
        image: .init(raw: Bundle.main.url(forResource: "zbir3", withExtension: "png").flatMap { try? Data(contentsOf: $0) }),
        template: .init(name: "9", gradient: .linearSilverBlue, imagePlacement: .trailingToEdge),
        purpose: "Маскувальні сітки",
        target: 10000
    )

    static let mock10 = Campaign(
        id: UUID(),
        image: .init(raw: Bundle.main.url(forResource: "zbir1", withExtension: "png").flatMap { try? Data(contentsOf: $0) }),
        template: .init(name: "10", gradient: .radialRedBlack, imagePlacement: .topToEdge),
        purpose: "Шини для автівки",
        target: 12000
    )
    
    static let mocks: IdentifiedArrayOf<Self> = [mock1, mock2, mock3, mock4, mock5, mock6, mock7, mock8, mock9, mock10]
}
