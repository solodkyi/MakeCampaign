import CustomDump
import CryptoKit
import Dependencies
import SwiftUI
import Testing
import UIKit

@testable import MakeCampaign

@MainActor
@Suite("Campaign poster thumbnails", .serialized)
struct CampaignPosterThumbnailTests {
    @Test("Identical visual inputs produce the same thumbnail key")
    func identicalInputsHaveEqualKeys() throws {
        let request = try makeRequest()

        expectNoDifference(request.key, request.key)
    }

    @Test("Every pixel-affecting input changes the thumbnail key")
    func pixelInputsChangeKey() throws {
        let original = try makeRequest()
        let anotherTemplate = try #require(Template.list.dropFirst().first)

        var changedPurpose = original.campaign
        changedPurpose.purpose = "Інша мета"
        var changedTarget = original.campaign
        changedTarget.target = 42_000
        var changedScale = original.campaign
        changedScale.image?.scale = 1.8
        var changedOffset = original.campaign
        changedOffset.image?.offset = CGSize(width: 17, height: -11)
        var changedReferenceSize = original.campaign
        changedReferenceSize.image?.referenceSize = CGSize(width: 320, height: 180)
        var changedContentMode = original.campaign
        changedContentMode.image?.contentMode = .fit
        var changedQRCodeVisibility = original.campaign
        changedQRCodeVisibility.showsQRCode.toggle()

        let variants = [
            try makeRequest(template: anotherTemplate),
            try makeRequest(composition: .templateOnly),
            try makeRequest(campaign: changedPurpose),
            try makeRequest(campaign: changedTarget),
            try makeRequest(campaign: changedScale),
            try makeRequest(campaign: changedOffset),
            try makeRequest(campaign: changedReferenceSize),
            try makeRequest(campaign: changedContentMode),
            try makeRequest(campaign: changedQRCodeVisibility),
            try makeRequest(assetSignature: "different-assets"),
            try makeRequest(pointSize: CGSize(width: 120, height: 120)),
            try makeRequest(displayScale: 2),
            try makeRequest(colorScheme: .dark),
            try makeRequest(locale: Locale(identifier: "en_US")),
        ]

        for variant in variants {
            #expect(variant.key != original.key)
        }
    }

    @Test("Selection and nonvisual campaign state do not invalidate a candidate tile")
    func nonvisualInputsKeepKey() throws {
        let candidate = try #require(Template.list.first)
        let original = try makeRequest(template: candidate)
        var changed = original.campaign
        changed.template = try #require(Template.list.last)
        changed.status = .active
        changed.shareCaption = "New caption"
        changed.createdAt = Date(timeIntervalSince1970: 1)
        changed.updatedAt = Date(timeIntervalSince1970: 2)

        let sameCandidate = try makeRequest(
            campaign: changed,
            template: candidate
        )

        expectNoDifference(sameCandidate.key, original.key)
    }

    @Test("Photo reframing retains the displayed template thumbnail batch")
    func photoReframingRetainsDisplayedBatch() throws {
        let original = try makeRequest()
        let batch = CampaignPosterThumbnailBatch(requests: [original])
        var reframedCampaign = original.campaign
        reframedCampaign.image?.scale = 2.1
        reframedCampaign.image?.offset = CGSize(width: -31, height: 24)
        reframedCampaign.image?.referenceSize = CGSize(width: 180, height: 120)
        let reframed = try makeRequest(campaign: reframedCampaign)

        let retained = try #require(
            batch.retainedRequests(matching: [reframed])
        )

        #expect(reframed.key != original.key)
        expectNoDifference(retained.map(\.key), [original.key])
    }

    @Test("Meaningful visual changes invalidate the displayed thumbnail batch")
    func visualChangesInvalidateDisplayedBatch() throws {
        let original = try makeRequest()
        let batch = CampaignPosterThumbnailBatch(requests: [original])
        var changedPurpose = original.campaign
        changedPurpose.purpose = "Інша мета"
        var changedContentMode = original.campaign
        changedContentMode.image?.contentMode = .fit
        let changedRequests = [
            try makeRequest(campaign: changedPurpose),
            try makeRequest(campaign: changedContentMode),
            try makeRequest(assetSignature: "new-photo"),
        ]

        for changed in changedRequests {
            #expect(batch.retainedRequests(matching: [changed]) == nil)
        }
    }

    @Test("Repeated identical requests snapshot once")
    func cacheHitDoesNotSnapshotAgain() async throws {
        let snapshots = LockIsolated(0)
        let output = UIImage(systemName: "photo")!
        let store = CampaignPosterThumbnailStore(snapshot: { _ in
            snapshots.withValue { $0 += 1 }
            return output
        })
        let request = try makeRequest()

        _ = try await store.image(for: request)
        _ = try await store.image(for: request)

        expectNoDifference(snapshots.value, 1)
    }

    @Test("Concurrent identical requests snapshot once")
    func concurrentRequestsCoalesce() async throws {
        let snapshots = LockIsolated(0)
        let output = UIImage(systemName: "photo")!
        let store = CampaignPosterThumbnailStore(snapshot: { _ in
            snapshots.withValue { $0 += 1 }
            return output
        })
        let request = try makeRequest()

        async let first = store.image(for: request)
        async let second = store.image(for: request)
        _ = try await (first, second)

        expectNoDifference(snapshots.value, 1)
    }

    @Test("Prewarming snapshots unique tiles before scrolling and makes later reads warm")
    func prewarmingPopulatesCache() async throws {
        let snapshots = LockIsolated(0)
        let output = UIImage(systemName: "photo")!
        let store = CampaignPosterThumbnailStore(snapshot: { _ in
            snapshots.withValue { $0 += 1 }
            return output
        })
        let first = try makeRequest()
        let second = try makeRequest(assetSignature: "second")

        await store.prewarm([first, first, second])
        expectNoDifference(snapshots.value, 2)

        _ = try await store.image(for: first)
        _ = try await store.image(for: second)
        expectNoDifference(snapshots.value, 2)
    }

    @Test("A changed key snapshots again")
    func changedKeyMissesCache() async throws {
        let snapshots = LockIsolated(0)
        let output = UIImage(systemName: "photo")!
        let store = CampaignPosterThumbnailStore(snapshot: { _ in
            snapshots.withValue { $0 += 1 }
            return output
        })

        _ = try await store.image(for: makeRequest())
        _ = try await store.image(
            for: makeRequest(assetSignature: "new-assets")
        )

        expectNoDifference(snapshots.value, 2)
    }

    @Test("An already-cancelled request does not snapshot")
    func cancellationSkipsSnapshot() async throws {
        let snapshots = LockIsolated(0)
        let store = CampaignPosterThumbnailStore(snapshot: { _ in
            snapshots.withValue { $0 += 1 }
            return UIImage()
        })
        let request = try makeRequest()
        let task = Task {
            try await store.image(for: request)
        }
        task.cancel()

        await #expect(throws: CancellationError.self) {
            try await task.value
        }
        expectNoDifference(snapshots.value, 0)
    }

    @Test("Thumbnail cache has bounded count and decoded-byte cost")
    func cacheLimitsAreBounded() {
        let store = CampaignPosterThumbnailStore(snapshot: { _ in UIImage() })

        expectNoDifference(store.countLimit, 48)
        expectNoDifference(store.totalCostLimit, 24 * 1_024 * 1_024)
    }

    @Test("Live thumbnail has exact point scale and backing dimensions")
    func exactOutputDimensions() async throws {
        let request = try makeRequest()
        let image = try await CampaignPosterThumbnailStore().image(for: request)
        let raster = try #require(image.cgImage)

        expectNoDifference(image.size, CGSize(width: 84, height: 84))
        expectNoDifference(image.scale, 3)
        expectNoDifference(raster.width, 252)
        expectNoDifference(raster.height, 252)
    }

    @Test("Poster thumbnails match the live preview for every template")
    func posterThumbnailsMatchPreview() async throws {
        let campaign = try visualCampaign()
        let assets = visualAssets(for: campaign)
        let store = CampaignPosterThumbnailStore()

        for template in Template.list {
            let request = try makeRequest(
                campaign: campaign,
                template: template,
                assets: assets
            )
            let thumbnail = try await store.image(for: request)
            var candidate = campaign
            candidate.template = template
            let expected = try render(
                CampaignPosterView(campaign: candidate, assets: assets),
                request: request
            )

            expectPixelsEqual(thumbnail, expected)
        }
    }

    @Test("Template-only thumbnails preserve the legacy white-photo tiles")
    func templateOnlyThumbnailsMatchLegacyTiles() async throws {
        let campaign = try visualCampaign()
        let store = CampaignPosterThumbnailStore()

        for template in Template.list {
            let request = try makeRequest(
                campaign: campaign,
                template: template,
                composition: .templateOnly,
                assets: .empty,
                pointSize: CGSize(width: 120, height: 120)
            )
            let thumbnail = try await store.image(for: request)
            let expected = try render(
                CampaignTemplateView(campaign: campaign, template: template),
                request: request
            )

            expectPixelsEqual(thumbnail, expected)
        }
    }

    @Test("Candidate template overrides the campaign's selected template")
    func candidateTemplateWins() async throws {
        var campaign = try visualCampaign()
        campaign.template = try #require(Template.list.first)
        let candidate = try #require(Template.list.last)
        let assets = visualAssets(for: campaign)
        let request = try makeRequest(
            campaign: campaign,
            template: candidate,
            assets: assets
        )

        let thumbnail = try await CampaignPosterThumbnailStore().image(for: request)
        campaign.template = candidate
        let expected = try render(
            CampaignPosterView(campaign: campaign, assets: assets),
            request: request
        )

        expectPixelsEqual(thumbnail, expected)
    }

    @Test("Fit, QR, dark appearance, locale, size, and scale preserve pixels")
    func visualVariantsPreservePixels() async throws {
        var campaign = try visualCampaign()
        campaign.image?.contentMode = .fit
        campaign.showsQRCode = true
        campaign.jar = .init(
            link: URL(string: "https://send.monobank.ua/jar/example")!
        )
        let assets = visualAssets(for: campaign)
        let request = try makeRequest(
            campaign: campaign,
            assets: assets,
            pointSize: CGSize(width: 96, height: 120),
            displayScale: 2,
            colorScheme: .dark,
            locale: Locale(identifier: "en_US")
        )

        let thumbnail = try await CampaignPosterThumbnailStore().image(for: request)
        let expected = try render(
            CampaignPosterView(campaign: campaign, assets: assets),
            request: request
        )

        expectPixelsEqual(thumbnail, expected)
    }

    @Test("Legacy template tiles request the lightweight white-photo composition")
    func legacyTemplateTileRequest() throws {
        let campaign = try makeCampaign()
        let template = try #require(Template.list.last)
        let request = CampaignPosterThumbnailRequest.templateSelection(
            campaign: campaign,
            template: template,
            pointSize: CGSize(width: 120, height: 120),
            displayScale: 2,
            colorScheme: .dark,
            locale: Locale(identifier: "uk_UA")
        )

        expectNoDifference(request.composition, .templateOnly)
        expectNoDifference(request.template.id, template.id)
        expectNoDifference(request.assets.signature, "empty")
        expectNoDifference(request.pointSize, CGSize(width: 120, height: 120))
        expectNoDifference(request.displayScale, 2)
        expectNoDifference(request.colorScheme, .dark)
        expectNoDifference(request.locale.identifier, "uk_UA")
    }

    private func makeRequest(
        campaign: Campaign? = nil,
        template: Template? = nil,
        composition: CampaignPosterThumbnailComposition = .poster,
        assetSignature: String = "assets",
        assets: CampaignPosterPreviewAssets? = nil,
        pointSize: CGSize = CGSize(width: 84, height: 84),
        displayScale: CGFloat = 3,
        colorScheme: ColorScheme = .light,
        locale: Locale = Locale(identifier: "uk_UA")
    ) throws -> CampaignPosterThumbnailRequest {
        let campaign = try campaign ?? makeCampaign()
        return CampaignPosterThumbnailRequest(
            campaign: campaign,
            template: try template ?? #require(Template.list.first),
            composition: composition,
            assets: assets ?? CampaignPosterPreviewAssets(
                photo: nil,
                qrCode: nil,
                signature: assetSignature
            ),
            pointSize: pointSize,
            displayScale: displayScale,
            colorScheme: colorScheme,
            locale: locale
        )
    }

    private func makeCampaign() throws -> Campaign {
        Campaign(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            image: .init(
                raw: Data([1, 2, 3]),
                offset: CGSize(width: 9, height: -7),
                scale: 1.25,
                referenceSize: CGSize(width: 240, height: 240),
                contentMode: .fill
            ),
            template: try #require(Template.list.first),
            purpose: "Аптечки",
            target: 20_000,
            jar: .init(link: URL(string: "https://example.com")!),
            status: .draft,
            posterFormat: .square,
            showsQRCode: false,
            shareCaption: "Caption",
            createdAt: Date(timeIntervalSince1970: 100),
            updatedAt: Date(timeIntervalSince1970: 200)
        )
    }

    private func visualCampaign() throws -> Campaign {
        let photo = UIGraphicsImageRenderer(
            size: CGSize(width: 32, height: 32)
        ).image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 16, height: 16))
            UIColor.green.setFill()
            context.fill(CGRect(x: 16, y: 0, width: 16, height: 16))
            UIColor.blue.setFill()
            context.fill(CGRect(x: 0, y: 16, width: 16, height: 16))
            UIColor.yellow.setFill()
            context.fill(CGRect(x: 16, y: 16, width: 16, height: 16))
        }
        var campaign = try makeCampaign()
        campaign.image = .init(
            raw: try #require(photo.pngData()),
            offset: CGSize(width: 9, height: -7),
            scale: 1.25,
            referenceSize: CGSize(width: 240, height: 240),
            contentMode: .fill
        )
        return campaign
    }

    private func visualAssets(
        for campaign: Campaign
    ) -> CampaignPosterPreviewAssets {
        CampaignPosterPreviewAssets(
            photo: campaign.image?.raw.flatMap(CampaignPosterAssetFactory.decodePhoto),
            qrCode: campaign.showsQRCode
                ? CampaignPosterAssetFactory.makeQRCode(campaign.jar?.link.absoluteString)
                : nil,
            signature: campaign.showsQRCode ? "visual-qr" : "visual"
        )
    }

    private func render<V: View>(
        _ view: V,
        request: CampaignPosterThumbnailRequest
    ) throws -> UIImage {
        let renderer = ImageRenderer(
            content: view
                .environment(\.colorScheme, request.colorScheme)
                .environment(\.locale, request.locale)
                .frame(
                    width: request.pointSize.width,
                    height: request.pointSize.height
                )
        )
        renderer.scale = request.displayScale
        renderer.isOpaque = false
        return try #require(renderer.uiImage)
    }

    private func expectPixelsEqual(_ actual: UIImage, _ expected: UIImage) {
        expectNoDifference(pixelDigest(actual), pixelDigest(expected))
    }

    private func pixelDigest(_ image: UIImage) -> [UInt8] {
        guard let source = image.cgImage else { return [] }
        let width = source.width
        let height = source.height
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        bytes.withUnsafeMutableBytes { storage in
            let context = CGContext(
                data: storage.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
            context?.draw(
                source,
                in: CGRect(x: 0, y: 0, width: width, height: height)
            )
        }
        return Array(SHA256.hash(data: Data(bytes)))
    }
}
