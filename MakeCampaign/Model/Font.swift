//
//  Font.swift
//  MakeCampaign
//
//  Created by Andrii Solodkyi on 6/9/25.
//
import Foundation

struct Font: Equatable, Codable, Identifiable {
    var name: String
    var size: CGFloat?
    
    var id: String {
        "\(name)_\(String(describing: size))"
    }
}
