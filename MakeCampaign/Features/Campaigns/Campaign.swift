//
//  Campaign.swift
//  MakeCampaign
//
//  Created by Andrii Solodkyi on 5/1/25.
//

import Foundation
import ComposableArchitecture

struct Campaign: Codable, Equatable, Identifiable {
    let id: UUID
    var imageData: Data?
    var template: Template?
    var purpose: String = ""
    var target: Double?
    var jar: JarInfo?
    
    struct JarInfo: Equatable, Codable {
        var link: URL
        var details: JarDetails?
    }
    
    var progress: Progress? {
        guard let target, let collected = jar?.details?.amountInHryvnias else { return nil }

        let progress = Progress(totalUnitCount: Int64(target * 100))
        progress.completedUnitCount = Int64(collected * 100)
        return progress
    }
    
    var formattedTarget: String {
        get {
            guard let target else { return "" }
            return target.currencyFormatted
        } set {
            return target = newValue.asCurrencyDouble
        }
    }
    
    var jarURLString: String {
        get {
            guard let jarLink = jar?.link else { return "" }
            return jarLink.absoluteString
        } set {
            guard let url = URL(string: newValue) else { return }
            if jar == nil {
                jar = .init(link: url)
            } else {
                jar?.link = url
            }
        }
    }
}

struct JarDetails: Equatable, Codable {
    let jarAmount: Int
    let jarStatus: String
    
    enum CodingKeys: String, CodingKey {
        case jarAmount
        case jarStatus
    }
    
    init(jarAmount: Int, jarStatus: String) {
        self.jarAmount = jarAmount
        self.jarStatus = jarStatus
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        jarAmount = try container.decode(Int.self, forKey: .jarAmount)
        jarStatus = try container.decode(String.self, forKey: .jarStatus)
    }
    
    var amountInHryvnias: Double {
        return Double(jarAmount) / 100.0
    }
    
    var formattedAmount: String {
        return amountInHryvnias.currencyFormatted + " грн."
    }
    
    var isActive: Bool {
        return jarStatus == "ACTIVE"
    }
}

extension JarDetails {
    static let mock = Self (
        jarAmount: 10000,
        jarStatus: "ACTIVE"
    )
}
