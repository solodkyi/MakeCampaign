import Dependencies
import Foundation
import SwiftUI
import UIKit

enum CampaignPosterThumbnailComposition: Hashable, Sendable {
    case poster
    case templateOnly
}

struct CampaignPosterThumbnailKey: Hashable, Sendable {
    let templateID: Template.ID
    let composition: CampaignPosterThumbnailComposition
    let purpose: String
    let target: Double?
    let isSupportingJar: Bool
    let personalTarget: Double?
    let collected: Double?
    let isFinished: Bool
    let imageScale: CGFloat
    let imageOffset: CGSize
    let imageReferenceSize: CGSize
    let contentMode: String
    let showsQRCode: Bool
    let assetSignature: String
    let pointSize: CGSize
    let displayScale: CGFloat
    let usesDarkColorScheme: Bool
    let localeIdentifier: String
}

struct CampaignPosterThumbnailRefreshKey: Hashable, Sendable {
    let templateID: Template.ID
    let composition: CampaignPosterThumbnailComposition
    let purpose: String
    let target: Double?
    let isSupportingJar: Bool
    let personalTarget: Double?
    let collected: Double?
    let isFinished: Bool
    let contentMode: String
    let showsQRCode: Bool
    let assetSignature: String
    let pointSize: CGSize
    let displayScale: CGFloat
    let usesDarkColorScheme: Bool
    let localeIdentifier: String
}

struct CampaignPosterThumbnailRequest: @unchecked Sendable {
    let campaign: Campaign
    let template: Template
    let composition: CampaignPosterThumbnailComposition
    let assets: CampaignPosterPreviewAssets
    let pointSize: CGSize
    let displayScale: CGFloat
    let colorScheme: ColorScheme
    let locale: Locale

    var key: CampaignPosterThumbnailKey {
        CampaignPosterThumbnailKey(
            templateID: template.id,
            composition: composition,
            purpose: campaign.purpose,
            target: campaign.target,
            isSupportingJar: campaign.isSupportingJar,
            personalTarget: campaign.personalTarget,
            collected: campaign.collected,
            isFinished: campaign.isFinished,
            imageScale: campaign.imageScale,
            imageOffset: campaign.imageOffset,
            imageReferenceSize: campaign.imageReferenceSize,
            contentMode: campaign.image?.contentMode.rawValue
                ?? Campaign.Image.ContentMode.fill.rawValue,
            showsQRCode: campaign.showsQRCode,
            assetSignature: assets.signature,
            pointSize: pointSize,
            displayScale: displayScale,
            usesDarkColorScheme: colorScheme == .dark,
            localeIdentifier: locale.identifier
        )
    }

    var refreshKey: CampaignPosterThumbnailRefreshKey {
        CampaignPosterThumbnailRefreshKey(
            templateID: template.id,
            composition: composition,
            purpose: campaign.purpose,
            target: campaign.target,
            isSupportingJar: campaign.isSupportingJar,
            personalTarget: campaign.personalTarget,
            collected: campaign.collected,
            isFinished: campaign.isFinished,
            contentMode: campaign.image?.contentMode.rawValue
                ?? Campaign.Image.ContentMode.fill.rawValue,
            showsQRCode: campaign.showsQRCode,
            assetSignature: assets.signature,
            pointSize: pointSize,
            displayScale: displayScale,
            usesDarkColorScheme: colorScheme == .dark,
            localeIdentifier: locale.identifier
        )
    }

    static func templateSelection(
        campaign: Campaign,
        template: Template,
        pointSize: CGSize,
        displayScale: CGFloat,
        colorScheme: ColorScheme,
        locale: Locale
    ) -> Self {
        Self(
            campaign: campaign,
            template: template,
            composition: .templateOnly,
            assets: .empty,
            pointSize: pointSize,
            displayScale: displayScale,
            colorScheme: colorScheme,
            locale: locale
        )
    }
}

enum CampaignRowPosterThumbnailRequest {
    static func make(
        campaign: Campaign,
        assets: CampaignPosterPreviewAssets,
        containerSize: CGSize,
        displayScale: CGFloat,
        colorScheme: ColorScheme,
        locale: Locale
    ) -> CampaignPosterThumbnailRequest? {
        guard let template = campaign.template else { return nil }

        return CampaignPosterThumbnailRequest(
            campaign: campaign,
            template: template,
            composition: .poster,
            assets: assets,
            pointSize: CampaignPosterLayout.previewSize(
                for: campaign.posterFormat,
                in: containerSize
            ),
            displayScale: displayScale,
            colorScheme: colorScheme,
            locale: locale
        )
    }
}

struct CampaignPosterThumbnailBatch {
    let requests: [CampaignPosterThumbnailRequest]
    private let refreshKeys: [CampaignPosterThumbnailRefreshKey]

    init(requests: [CampaignPosterThumbnailRequest]) {
        self.requests = requests
        self.refreshKeys = requests.map(\.refreshKey)
    }

    func retainedRequests(
        matching currentRequests: [CampaignPosterThumbnailRequest]
    ) -> [CampaignPosterThumbnailRequest]? {
        guard refreshKeys == currentRequests.map(\.refreshKey) else {
            return nil
        }
        return requests
    }
}

struct CampaignPosterThumbnailClient: Sendable {
    enum Error: Swift.Error, Equatable {
        case renderingFailed
    }

    var image: @MainActor @Sendable (
        CampaignPosterThumbnailRequest
    ) async throws -> UIImage
    var prewarm: @MainActor @Sendable (
        [CampaignPosterThumbnailRequest]
    ) async -> Void
}

@MainActor
final class CampaignPosterThumbnailStore {
    typealias Snapshot = @MainActor @Sendable (
        CampaignPosterThumbnailRequest
    ) throws -> UIImage

    let countLimit: Int
    let totalCostLimit: Int

    private let cache = NSCache<CampaignPosterThumbnailCacheKey, UIImage>()
    private var inFlight: [CampaignPosterThumbnailKey: Task<UIImage, Swift.Error>] = [:]
    private let snapshot: Snapshot

    init(
        countLimit: Int = 48,
        totalCostLimit: Int = 24 * 1_024 * 1_024,
        snapshot: @escaping Snapshot
    ) {
        self.countLimit = countLimit
        self.totalCostLimit = totalCostLimit
        self.snapshot = snapshot
        cache.countLimit = countLimit
        cache.totalCostLimit = totalCostLimit
    }

    convenience init(
        countLimit: Int = 48,
        totalCostLimit: Int = 24 * 1_024 * 1_024
    ) {
        self.init(
            countLimit: countLimit,
            totalCostLimit: totalCostLimit,
            snapshot: Self.render
        )
    }

    func image(
        for request: CampaignPosterThumbnailRequest
    ) async throws -> UIImage {
        try Task.checkCancellation()
        let cacheKey = CampaignPosterThumbnailCacheKey(request.key)
        if let cached = cache.object(forKey: cacheKey) {
            return cached
        }

        if let task = inFlight[request.key] {
            let image = try await task.value
            try Task.checkCancellation()
            return image
        }

        let snapshot = self.snapshot
        let task = Task { @MainActor in
            try Task.checkCancellation()
            await Task.yield()
            try Task.checkCancellation()
            return try snapshot(request)
        }
        inFlight[request.key] = task

        do {
            let image = try await task.value
            try Task.checkCancellation()
            inFlight[request.key] = nil
            cache.setObject(
                image,
                forKey: cacheKey,
                cost: Self.decodedByteCost(of: image)
            )
            return image
        } catch {
            inFlight[request.key] = nil
            throw error
        }
    }

    func prewarm(
        _ requests: [CampaignPosterThumbnailRequest]
    ) async {
        var visited: Set<CampaignPosterThumbnailKey> = []
        for request in requests where visited.insert(request.key).inserted {
            guard !Task.isCancelled else { return }
            _ = try? await image(for: request)
            await Task.yield()
        }
    }

    private static func decodedByteCost(of image: UIImage) -> Int {
        guard let cgImage = image.cgImage else { return 0 }
        return cgImage.bytesPerRow * cgImage.height
    }

    private static func render(
        _ request: CampaignPosterThumbnailRequest
    ) throws -> UIImage {
        var candidate = request.campaign
        candidate.template = request.template

        let content: AnyView
        switch request.composition {
        case .poster:
            content = AnyView(
                CampaignPosterArtwork(
                    campaign: candidate,
                    qrCode: request.assets.qrCode
                ) {
                    CampaignPosterThumbnailPhoto(
                        campaign: candidate,
                        photo: request.assets.photo,
                        usesPosterPlaceholder: true
                    )
                }
            )
        case .templateOnly:
            content = AnyView(
                CampaignTemplateArtwork(
                    campaign: request.campaign,
                    template: request.template
                ) {
                    CampaignPosterThumbnailPhoto(
                        campaign: request.campaign,
                        photo: request.assets.photo,
                        usesPosterPlaceholder: false
                    )
                }
            )
        }

        let renderer = ImageRenderer(
            content: content
                .environment(\.colorScheme, request.colorScheme)
                .environment(\.locale, request.locale)
                .frame(
                    width: request.pointSize.width,
                    height: request.pointSize.height
                )
        )
        renderer.scale = request.displayScale
        renderer.isOpaque = false
        guard let image = renderer.uiImage else {
            throw CampaignPosterThumbnailClient.Error.renderingFailed
        }
        return image
    }
}

private final class CampaignPosterThumbnailCacheKey: NSObject {
    let value: CampaignPosterThumbnailKey

    init(_ value: CampaignPosterThumbnailKey) {
        self.value = value
    }

    override var hash: Int { value.hashValue }

    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? CampaignPosterThumbnailCacheKey else {
            return false
        }
        return value == other.value
    }
}

private struct CampaignPosterThumbnailPhoto: View {
    let campaign: Campaign
    let photo: UIImage?
    let usesPosterPlaceholder: Bool

    @ViewBuilder
    var body: some View {
        if let photo {
            DisplayImageView(
                image: photo,
                scale: campaign.imageScale,
                offset: campaign.imageOffset,
                referenceSize: campaign.imageReferenceSize,
                contentMode: campaign.image?.contentMode ?? .fill
            )
        } else if usesPosterPlaceholder {
            CampaignPosterPlaceholder(campaign: campaign)
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .center
                )
        } else {
            Color.white
        }
    }
}

@MainActor
private enum CampaignPosterThumbnailLiveStore {
    static let shared = CampaignPosterThumbnailStore()
}

extension CampaignPosterThumbnailClient: DependencyKey {
    static var liveValue: Self {
        Self(
            image: { request in
                try await CampaignPosterThumbnailLiveStore.shared.image(for: request)
            },
            prewarm: { requests in
                await CampaignPosterThumbnailLiveStore.shared.prewarm(requests)
            }
        )
    }

    static var previewValue: Self {
        Self(
            image: { request in
                let format = UIGraphicsImageRendererFormat()
                format.scale = request.displayScale
                format.opaque = false
                return UIGraphicsImageRenderer(
                    size: request.pointSize,
                    format: format
                ).image { _ in }
            },
            prewarm: { _ in }
        )
    }

    static var testValue: Self {
        previewValue
    }
}

extension DependencyValues {
    var campaignPosterThumbnailClient: CampaignPosterThumbnailClient {
        get { self[CampaignPosterThumbnailClient.self] }
        set { self[CampaignPosterThumbnailClient.self] = newValue }
    }
}
