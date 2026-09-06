//
//  Campaign.swift
//  MakeCampaign
//
//  Created by Andrii Solodkyi on 5/1/25.
//

import Foundation
import ComposableArchitecture

struct Campaign: Codable, Equatable, Identifiable, Sendable {
    enum Status: String, Codable, Equatable, Sendable {
        case draft
        case active
    }

    enum PosterFormat: String, CaseIterable, Codable, Equatable, Identifiable, Sendable {
        case square
        case portrait
        case story

        var id: Self { self }

        var pixelSize: CGSize {
            switch self {
            case .square:
                CGSize(width: 1_080, height: 1_080)
            case .portrait:
                CGSize(width: 1_080, height: 1_350)
            case .story:
                CGSize(width: 1_080, height: 1_920)
            }
        }
    }

    struct Image: Codable, Equatable, Sendable {
        enum ContentMode: String, Codable, Equatable, Sendable {
            case fill
            case fit
        }

        let raw: Data?
        var offset: CGSize = .zero
        var scale: CGFloat = 1.0
        var referenceSize: CGSize = CGSize(width: 300, height: 300)
        var contentMode: ContentMode = .fill

        private enum CodingKeys: String, CodingKey {
            case raw, offset, scale, referenceSize, contentMode
        }

        init(
            raw: Data?,
            offset: CGSize = .zero,
            scale: CGFloat = 1.0,
            referenceSize: CGSize = CGSize(width: 300, height: 300),
            contentMode: ContentMode = .fill
        ) {
            self.raw = raw
            self.offset = offset
            self.scale = scale
            self.referenceSize = referenceSize
            self.contentMode = contentMode
        }

        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            raw = try values.decodeIfPresent(Data.self, forKey: .raw)
            offset = try values.decodeIfPresent(CGSize.self, forKey: .offset) ?? .zero
            scale = try values.decodeIfPresent(CGFloat.self, forKey: .scale) ?? 1
            referenceSize = try values.decodeIfPresent(CGSize.self, forKey: .referenceSize)
                ?? CGSize(width: 300, height: 300)
            contentMode = try values.decodeIfPresent(ContentMode.self, forKey: .contentMode) ?? .fill
        }

        func encode(to encoder: Encoder) throws {
            var values = encoder.container(keyedBy: CodingKeys.self)
            try values.encodeIfPresent(raw, forKey: .raw)
            try values.encode(offset, forKey: .offset)
            try values.encode(scale, forKey: .scale)
            try values.encode(referenceSize, forKey: .referenceSize)
            try values.encode(contentMode, forKey: .contentMode)
        }
    }
    
    struct JarInfo: Equatable, Codable, Sendable {
        var link: URL
        var details: JarDetails?
    }
    
    let id: UUID
    var image: Image?
    var template: Template?
    var purpose: String
    var target: Double?
    var jar: JarInfo?
    var status: Status
    var posterFormat: PosterFormat
    var showsQRCode: Bool
    var shareCaption: String
    var createdAt: Date
    var updatedAt: Date
    
    private var rawTargetInput: String = ""
    private var rawJarLinkInput: String = ""
    
    init(
        id: UUID,
        image: Image? = nil,
        template: Template? = nil,
        purpose: String = "",
        target: Double? = nil,
        jar: JarInfo? = nil,
        status: Status = .active,
        posterFormat: PosterFormat = .square,
        showsQRCode: Bool = false,
        shareCaption: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.image = image
        self.template = template
        self.purpose = purpose
        self.target = target
        self.jar = jar
        self.status = status
        self.posterFormat = posterFormat
        self.showsQRCode = showsQRCode
        self.shareCaption = shareCaption
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    private enum CodingKeys: String, CodingKey {
        case id, image, template, purpose, target, jar
        case status, posterFormat, showsQRCode, shareCaption
        case createdAt, updatedAt
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(UUID.self, forKey: .id)
        image = try values.decodeIfPresent(Image.self, forKey: .image)
        template = try values.decodeIfPresent(Template.self, forKey: .template)
        purpose = try values.decode(String.self, forKey: .purpose)
        target = try values.decodeIfPresent(Double.self, forKey: .target)
        jar = try values.decodeIfPresent(JarInfo.self, forKey: .jar)
        status = try values.decodeIfPresent(Status.self, forKey: .status) ?? .active
        posterFormat = try values.decodeIfPresent(PosterFormat.self, forKey: .posterFormat) ?? .square
        showsQRCode = try values.decodeIfPresent(Bool.self, forKey: .showsQRCode) ?? false
        shareCaption = try values.decodeIfPresent(String.self, forKey: .shareCaption) ?? ""
        let fallbackDate = Date.now
        createdAt = try values.decodeIfPresent(Date.self, forKey: .createdAt) ?? fallbackDate
        updatedAt = try values.decodeIfPresent(Date.self, forKey: .updatedAt) ?? createdAt
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(id, forKey: .id)
        try values.encodeIfPresent(image, forKey: .image)
        try values.encodeIfPresent(template, forKey: .template)
        try values.encode(purpose, forKey: .purpose)
        try values.encodeIfPresent(target, forKey: .target)
        try values.encodeIfPresent(jar, forKey: .jar)
        try values.encode(status, forKey: .status)
        try values.encode(posterFormat, forKey: .posterFormat)
        try values.encode(showsQRCode, forKey: .showsQRCode)
        try values.encode(shareCaption, forKey: .shareCaption)
        try values.encode(createdAt, forKey: .createdAt)
        try values.encode(updatedAt, forKey: .updatedAt)
    }
}

extension Campaign {
    var progress: Progress? {
        guard let target, let collected = jar?.details?.amountInHryvnias else { return nil }

        let progress = Progress(totalUnitCount: Int64(target * 100))
        progress.completedUnitCount = Int64(collected * 100)
        return progress
    }

    mutating func markUpdated(at date: Date = .now) {
        updatedAt = date
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

struct JarDetails: Equatable, Codable, Sendable {
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
