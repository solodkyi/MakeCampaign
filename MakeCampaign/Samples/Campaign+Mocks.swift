//
//  Campaign+Mocks.swift
//  MakeCampaign
//
//  Created by Andrii Solodkyi on 5/2/25.
//

import Foundation
import ComposableArchitecture
import SwiftUI

extension Campaign {
    static let mock1 = Campaign(
        id: UUID(),
        imageURL: Bundle.main.url(forResource: "zbir1", withExtension: "png")!,
        purpose: "Збір на FPV",
        target: 100000,
        collected: 12.12
    )
    
    static let mock2 = Campaign(
        id: UUID(),
        imageURL: Bundle.main.url(forResource: "zbir2", withExtension: "png")!,
        purpose: "Збір на машину розмінування ZMIY",
        target: 50000,
        collected: 48900.54
    )
    
    static let mock3 = Campaign(
        id: UUID(),
        imageURL: Bundle.main.url(forResource: "zbir3", withExtension: "png")!,
        purpose: "Великодній кошик для окупантів",
        target: 30000,
        collected: 29500.88
    )

    static let mock4 = Campaign(
        id: UUID(),
        imageURL: Bundle.main.url(forResource: "zbir1", withExtension: "png")!,
        purpose: "Дрон для розвідки",
        target: 75000,
        collected: 18000
    )

    static let mock5 = Campaign(
        id: UUID(),
        imageURL: Bundle.main.url(forResource: "zbir2", withExtension: "png")!,
        purpose: "Аптечки для фронту",
        target: 20000,
        collected: 15000
    )

    static let mock6 = Campaign(
        id: UUID(),
        imageURL: Bundle.main.url(forResource: "zbir3", withExtension: "png")!,
        purpose: "Тепловізори в бліндажі",
        target: 60000,
        collected: 41234.56
    )

    static let mock7 = Campaign(
        id: UUID(),
        imageURL: Bundle.main.url(forResource: "zbir1", withExtension: "png")!,
        purpose: "Генератор для бригади",
        target: 45000,
        collected: 32700
    )

    static let mock8 = Campaign(
        id: UUID(),
        imageURL: Bundle.main.url(forResource: "zbir2", withExtension: "png")!,
        purpose: "Пікап для підрозділу",
        target: 80000,
        collected: 79000
    )

    static let mock9 = Campaign(
        id: UUID(),
        imageURL: Bundle.main.url(forResource: "zbir3", withExtension: "png")!,
        purpose: "Маскувальні сітки",
        target: 10000,
        collected: 9850.5
    )

    static let mock10 = Campaign(
        id: UUID(),
        imageURL: Bundle.main.url(forResource: "zbir1", withExtension: "png")!,
        purpose: "Шини для автівки",
        target: 12000,
        collected: 3500
    )
    
    static let mocks: IdentifiedArrayOf<Self> = [mock1, mock2, mock3, mock4, mock5, mock6, mock7, mock8, mock9, mock10]
}
