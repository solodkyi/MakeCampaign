import Dependencies
import SwiftUI
import UIKit

struct CampaignRenderer: Sendable {
    enum Error: Swift.Error, Equatable {
        case missingTemplate
        case missingPhotoData
        case invalidPhotoData
        case missingQRCode
        case invalidQRCode
        case renderingFailed
    }

    let render: @Sendable (Campaign) async throws -> UIImage

    init(
        render: @escaping @Sendable (Campaign) async throws -> UIImage
    ) {
        self.render = render
    }
}

extension CampaignRenderer: DependencyKey {
    static let liveValue: Self = {
        let pipeline = CampaignRenderPipeline(
            prepare: { request in
                try await CampaignPosterAssetFactory.prepare(request)
            },
            snapshot: { request, assets in
                try autoreleasepool {
                    let photo = DisplayImageView(
                        image: assets.photo,
                        scale: request.campaign.imageScale,
                        offset: request.campaign.imageOffset,
                        referenceSize: request.campaign.imageReferenceSize,
                        contentMode: request.campaign.image?.contentMode ?? .fill
                    )
                    let artwork = CampaignPosterArtwork(
                        campaign: request.campaign,
                        qrCode: assets.qrCode
                    ) {
                        photo
                    }
                    let renderer = ImageRenderer(
                        content: artwork.frame(
                            width: request.outputSize.width,
                            height: request.outputSize.height
                        )
                    )
                    renderer.scale = 1
                    renderer.isOpaque = false

                    guard let image = renderer.uiImage,
                          image.scale == 1,
                          let raster = image.cgImage,
                          raster.width == Int(request.outputSize.width),
                          raster.height == Int(request.outputSize.height) else {
                        throw Error.renderingFailed
                    }

                    return image
                }
            }
        )

        return Self { campaign in
            try await pipeline.render(campaign)
        }
    }()

    static let previewValue = Self { _ in UIImage() }
    static let testValue = previewValue
}

extension DependencyValues {
    var campaignRenderer: CampaignRenderer {
        get { self[CampaignRenderer.self] }
        set { self[CampaignRenderer.self] = newValue }
    }
}
