import Dependencies
import Foundation
import SwiftUI
import Testing
import UIKit

@testable import MakeCampaign

/// Стос порожнього стану малює зразки наперед. Якщо котрийсь не намалюється,
/// екран мовчки покаже заглушку замість обкладинки — саме те, чого око не
/// помічає, а користувач бачить першим.
@MainActor
@Suite("Empty-state cover rendering")
struct CampaignCoverRendererTests {
    @Test("Every showcase sample renders a cover")
    func everySampleRendersACover() async throws {
        let samples = CampaignCoverShowcase.samples

        let covers = await withDependencies {
            $0.campaignPosterPreviewAssetLoader = .liveValue
            $0.campaignPosterThumbnailClient = .liveValue
        } operation: { () async -> [CampaignCoverSample.ID: UIImage] in
            @Dependency(\.campaignPosterPreviewAssetLoader) var assetLoader
            @Dependency(\.campaignPosterThumbnailClient) var thumbnailClient

            return await CampaignCoverRenderer.covers(
                for: samples,
                side: 200,
                displayScale: 2,
                colorScheme: .light,
                locale: Locale(identifier: "uk_UA"),
                assetLoader: assetLoader,
                thumbnailClient: thumbnailClient
            )
        }

        for sample in samples {
            #expect(
                covers[sample.id] != nil,
                "Зразок «\(sample.purpose)» (\(sample.templateID)) не дав обкладинки"
            )
        }
    }

    @Test("Every showcase photo is actually in the bundle")
    func everySamplePhotoIsBundled() async {
        for sample in CampaignCoverShowcase.samples {
            let data = await CampaignCoverShowcase.photoData(named: sample.photoResource)

            #expect(
                data != nil,
                "Світлини \(sample.photoResource).png немає у бандлі"
            )
        }
    }
}
