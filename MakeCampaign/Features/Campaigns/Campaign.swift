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
    var imageURL: URL?
    var template: Template?
    var purpose: String = ""
    var jarLink: URL?
    var target: Double?
    var collected: Double?
    
    var progress: Progress? {
        guard let target, let collected else { return nil }

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
            guard let jarLink else { return "" }
            return jarLink.absoluteString
        } set {
            return jarLink = URL(string: newValue)
        }
    }
}
