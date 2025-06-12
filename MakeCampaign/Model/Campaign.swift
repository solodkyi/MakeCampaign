//
//  Campaign.swift
//  MakeCampaign
//
//  Created by Andrii Solodkyi on 5/1/25.
//

import Foundation
import ComposableArchitecture

struct Campaign: Codable, Equatable, Identifiable {
    struct Image: Codable, Equatable {
        let raw: Data?
        var offset: CGSize = .zero
        var scale: CGFloat = 1.0
        var referenceSize: CGSize = CGSize(width: 300, height: 300)
    }
    
    struct JarInfo: Equatable, Codable {
        var link: URL
        var details: JarDetails?
    }
    
    let id: UUID
    var image: Image?
    var template: Template?
    var purpose: String
    var target: Double?
    var jar: JarInfo?
    
    private var rawTargetInput: String = ""
    private var rawJarLinkInput: String = ""
    
    init(id: UUID, image: Image? = nil, template: Template? = nil, purpose: String = "", target: Double? = nil, jar: JarInfo? = nil) {
        self.id = id
        self.image = image
        self.template = template
        self.purpose = purpose
        self.target = target
        self.jar = jar
    }
}

extension Campaign {
    var progress: Progress? {
        guard let target, let collected = jar?.details?.amountInHryvnias else { return nil }

        let progress = Progress(totalUnitCount: Int64(target * 100))
        progress.completedUnitCount = Int64(collected * 100)
        return progress
    }
    
    var formattedTarget: String {
        get {
            if !rawTargetInput.isEmpty && target == nil {
                return rawTargetInput
            }
            
            guard let target else { return "" }
            return target.formattedAmount
        } set {
            rawTargetInput = newValue
            
            target = newValue.asCurrencyDouble
        }
    }
    
    var jarURLString: String {
        get {
            if !rawJarLinkInput.isEmpty && jar?.link == nil {
                return rawJarLinkInput
            }
            
            guard let jarLink = jar?.link else { return "" }
            return jarLink.absoluteString
        } set {
            rawJarLinkInput = newValue
            
            guard let url = URL(string: newValue) else {
                jar = nil
                return
            }
            if jar == nil {
                jar = .init(link: url)
            } else {
                jar?.link = url
            }
        }
    }
    
    var imageScale: CGFloat {
        get {
            return image?.scale ?? 1.0
        } set {
            if image == nil {
                image = Image(raw: nil, scale: newValue)
            } else {
                image?.scale = newValue
            }
        }
    }
    
    var imageOffset: CGSize {
        get {
            return image?.offset ?? .zero
        } set {
            if image == nil {
                image = Image(raw: nil, offset: newValue)
            } else {
                image?.offset = newValue
            }
        }
    }
    
    var imageReferenceSize: CGSize {
        get {
            return image?.referenceSize ?? CGSize(width: 300, height: 300)
        } set {
            if image == nil {
                image = Image(raw: nil, referenceSize: newValue)
            } else {
                image?.referenceSize = newValue
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
    
    var amountInHryvnias: Double {
        return Double(jarAmount) / 100.0
    }
    
    var currencyFormatted: String {
        return amountInHryvnias.formattedAmount + " грн."
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

extension Font {
    static let standard: Self = .init(name: "Roboto-Bold", size: nil)
}
