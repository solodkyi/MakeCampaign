import CoreImage
import CryptoKit
import CustomDump
import Dependencies
import SwiftUI
import Testing
import UIKit

@testable import MakeCampaign

@MainActor
@Suite("Campaign renderer", .serialized)
struct CampaignRendererTests {
    @Test("Render request rejects a missing template")
    func requestRejectsMissingTemplate() throws {
        var campaign = try validCampaign()
        campaign.template = nil

        #expect(throws: CampaignRenderer.Error.missingTemplate) {
            try CampaignRenderRequest(campaign: campaign)
        }
    }

    @Test("Render request rejects missing photo data")
    func requestRejectsMissingPhoto() throws {
        var campaign = try validCampaign()
        campaign.image = .init(raw: nil)

        #expect(throws: CampaignRenderer.Error.missingPhotoData) {
            try CampaignRenderRequest(campaign: campaign)
        }
    }

    @Test("QR-disabled request does not require a jar")
    func qrDisabledDoesNotRequireJar() throws {
        var campaign = try validCampaign()
        campaign.jar = nil
        campaign.showsQRCode = false

        #expect(try CampaignRenderRequest(campaign: campaign).qrPayload == nil)
    }

    @Test("QR-enabled request requires a web URL")
    func qrEnabledRequiresWebURL() throws {
        var campaign = try validCampaign()
        campaign.showsQRCode = true
        campaign.jar = nil

        #expect(throws: CampaignRenderer.Error.missingQRCode) {
            try CampaignRenderRequest(campaign: campaign)
        }

        campaign.jar = .init(link: URL(string: "mailto:help@example.com")!)
        #expect(throws: CampaignRenderer.Error.invalidQRCode) {
            try CampaignRenderRequest(campaign: campaign)
        }
    }

    @Test("Asset preparation rejects corrupt photo data")
    func preparationRejectsCorruptPhoto() async throws {
        var campaign = try validCampaign()
        campaign.image = .init(raw: Data("not an image".utf8))
        let request = try CampaignRenderRequest(campaign: campaign)

        await #expect(throws: CampaignRenderer.Error.invalidPhotoData) {
            try await CampaignPosterAssetFactory.prepare(request)
        }
    }

    @Test("Asset preparation omits QR when disabled")
    func preparationOmitsDisabledQR() async throws {
        let assets = try await CampaignPosterAssetFactory.prepare(
            CampaignRenderRequest(campaign: validCampaign())
        )

        #expect(assets.photo.cgImage != nil)
        #expect(assets.qrCode == nil)
    }

    @Test("Asset preparation creates QR for a valid web URL")
    func preparationCreatesEnabledQR() async throws {
        var campaign = try validCampaign()
        campaign.showsQRCode = true
        campaign.jar = .init(
            link: URL(string: "https://send.monobank.ua/jar/example")!
        )

        let assets = try await CampaignPosterAssetFactory.prepare(
            CampaignRenderRequest(campaign: campaign)
        )

        #expect(assets.qrCode?.cgImage != nil)
    }

    @Test("Shared template artwork preserves every template")
    func sharedTemplateArtworkPreservesTemplates() throws {
        let campaign = try validCampaign()
        let data = try #require(campaign.image?.raw)
        let photo = try #require(CampaignPosterAssetFactory.decodePhoto(data))

        for template in Template.list {
            let expected = try renderRGBA(
                CampaignTemplateView(
                    campaign: campaign,
                    template: template,
                    image: photo
                ),
                size: CGSize(width: 240, height: 240)
            )
            let actual = try renderRGBA(
                CampaignTemplateArtwork(
                    campaign: campaign,
                    template: template
                ) {
                    DisplayImageView(
                        image: photo,
                        scale: campaign.imageScale,
                        offset: campaign.imageOffset,
                        referenceSize: campaign.imageReferenceSize,
                        contentMode: campaign.image?.contentMode ?? .fill
                    )
                },
                size: CGSize(width: 240, height: 240)
            )

            expectPixelsEqual(actual, expected)
        }
    }

    @Test("Preview and artwork pixels match for every template")
    func previewAndArtworkMatchForEveryTemplate() throws {
        var campaign = try validCampaign()

        for template in Template.list {
            campaign.template = template
            try expectPreviewMatchesArtwork(
                campaign: campaign,
                size: CGSize(width: 240, height: 240)
            )
        }
    }

    @Test("Poster preview uses injected prepared assets")
    func previewUsesPreparedAssets() throws {
        let campaign = try validCampaign()
        let blue = UIGraphicsImageRenderer(
            size: CGSize(width: 32, height: 32)
        ).image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 32, height: 32))
        }
        let assets = CampaignPosterPreviewAssets(
            photo: blue,
            qrCode: nil,
            signature: "blue"
        )

        let preview = try renderRGBA(
            CampaignPosterView(campaign: campaign, assets: assets),
            size: CGSize(width: 240, height: 240)
        )
        let artwork = try renderRGBA(
            CampaignPosterArtwork(campaign: campaign, qrCode: nil) {
                DisplayImageView(
                    image: blue,
                    scale: campaign.imageScale,
                    offset: campaign.imageOffset,
                    referenceSize: campaign.imageReferenceSize,
                    contentMode: campaign.image?.contentMode ?? .fill
                )
            },
            size: CGSize(width: 240, height: 240)
        )

        expectPixelsEqual(preview, artwork)
    }

    @Test("Photo rendering avoids gesture-time offscreen rasterization")
    func photoRenderingAvoidsDrawingGroups() {
        let image = UIGraphicsImageRenderer(
            size: CGSize(width: 32, height: 32)
        ).image { context in
            UIColor.orange.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 32, height: 32))
        }
        let staticView = DisplayImageView(
            image: image,
            scale: 1,
            offset: .zero,
            referenceSize: CGSize(width: 100, height: 100),
            contentMode: .fill
        )
        let interactiveView = ImageTransformView(
            image: image,
            initialOffset: .zero,
            initialScale: 1,
            containerSize: CGSize(width: 100, height: 100),
            contentMode: .fill,
            onTransformEnd: { _, _, _ in }
        )

        let bodyTypes = [
            String(reflecting: type(of: staticView.body)),
            String(reflecting: type(of: interactiveView.body)),
        ]
        for bodyType in bodyTypes {
            #expect(!bodyType.localizedCaseInsensitiveContains("drawinggroup"))
        }
    }

    @Test("Manual framing shows translucent overflow and an opaque frame")
    func manualFramingShowsTranslucentOverflowAndOpaqueFrame() throws {
        let size = CGSize(width: 160, height: 160)
        let pixels = try renderRGBA(
            ZStack {
                Color.black
                Color.red
                    .frame(width: 120, height: 120)
                    .offset(x: 20)
                    .frame(width: 60, height: 60)
                    .campaignPhotoFrame(
                        Circle(),
                        supportsOverflowPreview: true,
                        isTransforming: true
                    )
            },
            size: size
        )

        let inside = rgbaPixel(pixels, at: CGPoint(x: 80, y: 80), size: size)
        let overflow = rgbaPixel(pixels, at: CGPoint(x: 130, y: 80), size: size)
        let outsidePhoto = rgbaPixel(pixels, at: CGPoint(x: 15, y: 80), size: size)

        #expect(inside.red > 245)
        #expect(abs(Int(overflow.red) * 2 - Int(inside.red)) <= 2)
        #expect(abs(Int(overflow.green) * 2 - Int(inside.green)) <= 2)
        #expect(abs(Int(overflow.blue) * 2 - Int(inside.blue)) <= 2)
        #expect(outsidePhoto.red < 10)
    }

    @Test("Manual framing hides overflow after the gesture ends")
    func manualFramingHidesOverflowAfterGestureEnds() throws {
        let size = CGSize(width: 160, height: 160)
        let pixels = try renderRGBA(
            ZStack {
                Color.black
                Color.red
                    .frame(width: 120, height: 120)
                    .offset(x: 20)
                    .frame(width: 60, height: 60)
                    .campaignPhotoFrame(
                        Circle(),
                        supportsOverflowPreview: true,
                        isTransforming: false
                    )
            },
            size: size
        )

        let inside = rgbaPixel(pixels, at: CGPoint(x: 80, y: 80), size: size)
        let overflow = rgbaPixel(pixels, at: CGPoint(x: 130, y: 80), size: size)

        #expect(inside.red > 245)
        #expect(overflow.red < 10)
        #expect(overflow.green < 10)
        #expect(overflow.blue < 10)
    }

    @Test("Manual framing photo can render beyond its frame bounds")
    func manualFramingPhotoCanRenderBeyondFrameBounds() throws {
        let size = CGSize(width: 160, height: 160)
        let image = UIGraphicsImageRenderer(
            size: CGSize(width: 60, height: 60)
        ).image { context in
            UIColor.red.setFill()
            context.fill(CGRect(origin: .zero, size: CGSize(width: 60, height: 60)))
        }
        let pixels = try renderRGBA(
            ZStack {
                Color.black
                DisplayImageView(
                    image: image,
                    scale: 1,
                    offset: CGSize(width: 50, height: 0),
                    referenceSize: CGSize(width: 60, height: 60),
                    contentMode: .fill,
                    clipsToBounds: false
                )
                .frame(width: 60, height: 60)
            },
            size: size
        )

        let overflow = rgbaPixel(pixels, at: CGPoint(x: 120, y: 80), size: size)

        #expect(overflow.red > 245)
        #expect(overflow.green < 10)
        #expect(overflow.blue < 10)
    }

    @Test("Preview and artwork preserve crop, QR, and aspect variants")
    func previewAndArtworkMatchVariants() throws {
        var fill = try validCampaign()
        fill.image?.contentMode = .fill

        var fit = try validCampaign(format: .portrait)
        fit.image?.contentMode = .fit

        var transformed = try validCampaign(format: .story)
        transformed.image?.scale = 1.7
        transformed.image?.offset = CGSize(width: 11, height: -7)
        transformed.image?.referenceSize = CGSize(width: 240, height: 240)

        var withQR = try validCampaign(format: .portrait)
        withQR.showsQRCode = true
        withQR.jar = .init(
            link: URL(string: "https://send.monobank.ua/jar/example")!
        )

        try expectPreviewMatchesArtwork(
            campaign: fill,
            size: CGSize(width: 240, height: 240)
        )
        try expectPreviewMatchesArtwork(
            campaign: fit,
            size: CGSize(width: 192, height: 240)
        )
        try expectPreviewMatchesArtwork(
            campaign: transformed,
            size: CGSize(width: 135, height: 240)
        )
        try expectPreviewMatchesArtwork(
            campaign: withQR,
            size: CGSize(width: 192, height: 240)
        )
    }

    @Test("Interactive resting preview matches exported artwork")
    func interactiveRestingPreviewMatchesExportedArtwork() throws {
        var campaign = try validCampaign(format: .portrait)
        campaign.image?.scale = 1.4
        campaign.image?.offset = CGSize(width: 9, height: -6)
        campaign.image?.referenceSize = CGSize(width: 96, height: 96)
        let assets = previewAssets(for: campaign)
        let photo = try #require(assets.photo)
        let preview = try renderRGBA(
            CampaignPosterView(
                campaign: campaign,
                assets: assets,
                allowsImageTransform: true,
                onImageTransformEnd: { _, _, _ in }
            ),
            size: CGSize(width: 192, height: 240)
        )
        let artwork = try renderRGBA(
            CampaignPosterArtwork(campaign: campaign, qrCode: assets.qrCode) {
                DisplayImageView(
                    image: photo,
                    scale: campaign.imageScale,
                    offset: campaign.imageOffset,
                    referenceSize: campaign.imageReferenceSize,
                    contentMode: campaign.image?.contentMode ?? .fill
                )
            },
            size: CGSize(width: 192, height: 240)
        )

        expectPixelsEqual(preview, artwork)
    }

    @Test("Pipeline prepares and snapshots exactly once")
    func pipelineRunsEachStageOnce() async throws {
        let campaign = try validCampaign()
        let request = try CampaignRenderRequest(campaign: campaign)
        let assets = try await CampaignPosterAssetFactory.prepare(request)
        let output = UIGraphicsImageRenderer(
            size: CGSize(width: 1, height: 1)
        ).image { _ in }
        let stages = LockIsolated<[String]>([])
        let pipeline = CampaignRenderPipeline(
            prepare: { request in
                stages.withValue {
                    $0.append("prepare:\(request.campaign.id.uuidString)")
                }
                return assets
            },
            snapshot: { request, _ in
                stages.withValue {
                    $0.append("snapshot:\(request.campaign.id.uuidString)")
                }
                return output
            }
        )

        _ = try await pipeline.render(campaign)

        expectNoDifference(stages.value, [
            "prepare:00000000-0000-0000-0000-000000000001",
            "snapshot:00000000-0000-0000-0000-000000000001",
        ])
    }

    @Test("Pipeline does not snapshot after cancellation between stages")
    func pipelineStopsBeforeSnapshotWhenCancelled() async throws {
        let campaign = try validCampaign()
        let request = try CampaignRenderRequest(campaign: campaign)
        let assets = try await CampaignPosterAssetFactory.prepare(request)
        let stages = LockIsolated<[String]>([])
        let pipeline = CampaignRenderPipeline(
            prepare: { _ in
                stages.withValue { $0.append("prepare") }
                withUnsafeCurrentTask { $0?.cancel() }
                return assets
            },
            snapshot: { _, _ in
                stages.withValue { $0.append("snapshot") }
                return UIImage()
            }
        )

        await #expect(throws: CancellationError.self) {
            try await pipeline.render(campaign)
        }
        expectNoDifference(stages.value, ["prepare"])
    }

    @Test("Pipeline does not snapshot after preparation failure")
    func pipelineStopsBeforeSnapshotWhenPreparationFails() async throws {
        let campaign = try validCampaign()
        let snapshots = LockIsolated(0)
        let pipeline = CampaignRenderPipeline(
            prepare: { _ in
                throw CampaignRenderer.Error.invalidPhotoData
            },
            snapshot: { _, _ in
                snapshots.withValue { $0 += 1 }
                return UIImage()
            }
        )

        await #expect(throws: CampaignRenderer.Error.invalidPhotoData) {
            try await pipeline.render(campaign)
        }
        expectNoDifference(snapshots.value, 0)
    }

    @Test(
        "Live export matches preview with exact pixels and scale",
        arguments: Campaign.PosterFormat.allCases
    )
    func liveRendererMatchesPreview(
        format: Campaign.PosterFormat
    ) async throws {
        let campaign = try validCampaign(format: format)
        let image = try await CampaignRenderer.liveValue.render(campaign)
        let raster = try #require(image.cgImage)

        expectNoDifference(image.scale, 1)
        expectNoDifference(raster.width, Int(format.pixelSize.width))
        expectNoDifference(raster.height, Int(format.pixelSize.height))

        let preview = try renderRGBA(
            CampaignPosterView(
                campaign: campaign,
                assets: previewAssets(for: campaign)
            ),
            size: format.pixelSize
        )
        let export = try normalizedRGBA(image, size: format.pixelSize)
        expectPixelsEqual(export, preview)
    }

    @Test("Live export preserves transformed photo and QR pixels")
    func liveRendererPreservesTransformAndQR() async throws {
        var campaign = try validCampaign(format: .portrait)
        campaign.image?.contentMode = .fit
        campaign.image?.scale = 1.7
        campaign.image?.offset = CGSize(width: 13, height: -9)
        campaign.image?.referenceSize = CGSize(width: 240, height: 300)
        campaign.showsQRCode = true
        campaign.jar = .init(
            link: URL(string: "https://send.monobank.ua/jar/example")!
        )

        let exportImage = try await CampaignRenderer.liveValue.render(campaign)
        let preview = try renderRGBA(
            CampaignPosterView(
                campaign: campaign,
                assets: previewAssets(for: campaign)
            ),
            size: campaign.posterFormat.pixelSize
        )
        let export = try normalizedRGBA(
            exportImage,
            size: campaign.posterFormat.pixelSize
        )

        expectPixelsEqual(export, preview)
    }

    @Test("Live renderer propagates cancellation")
    func liveRendererPropagatesCancellation() async throws {
        let campaign = try validCampaign()
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await CampaignRenderer.liveValue.render(campaign)
        }

        await #expect(throws: CancellationError.self) {
            try await task.value
        }
    }

    @Test("Live renderer can be reused sequentially")
    func liveRendererCanBeReused() async throws {
        let campaign = try validCampaign()

        for _ in 0..<3 {
            let image = try await CampaignRenderer.liveValue.render(campaign)
            expectNoDifference(image.cgImage?.width, 1_080)
            expectNoDifference(image.cgImage?.height, 1_080)
        }
    }

    @Test("Live renderer reports corrupt photo data")
    func liveRendererRejectsCorruptPhoto() async throws {
        var campaign = try validCampaign()
        campaign.image = .init(raw: Data("not an image".utf8))

        await #expect(throws: CampaignRenderer.Error.invalidPhotoData) {
            try await CampaignRenderer.liveValue.render(campaign)
        }
    }

    @Test("Live renderer reports invalid required QR")
    func liveRendererRejectsInvalidQR() async throws {
        var campaign = try validCampaign()
        campaign.showsQRCode = true
        campaign.jar = .init(link: URL(string: "mailto:help@example.com")!)

        await #expect(throws: CampaignRenderer.Error.invalidQRCode) {
            try await CampaignRenderer.liveValue.render(campaign)
        }
    }

    private func validCampaign(
        format: Campaign.PosterFormat = .square,
        template: Template? = Template.list.first
    ) throws -> Campaign {
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

        return Campaign(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            image: .init(raw: try #require(photo.pngData())),
            template: template,
            purpose: "Аптечки",
            target: 20_000,
            status: .draft,
            posterFormat: format
        )
    }

    private func renderRGBA<V: View>(
        _ view: V,
        size: CGSize
    ) throws -> [UInt8] {
        let renderer = ImageRenderer(
            content: view.frame(width: size.width, height: size.height)
        )
        renderer.scale = 1
        renderer.isOpaque = false

        let image = try #require(renderer.uiImage)
        return try normalizedRGBA(image, size: size)
    }

    private func normalizedRGBA(
        _ image: UIImage,
        size: CGSize
    ) throws -> [UInt8] {
        let source = try #require(image.cgImage)
        let width = Int(size.width)
        let height = Int(size.height)
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        try bytes.withUnsafeMutableBytes { storage in
            let context = try #require(
                CGContext(
                    data: storage.baseAddress,
                    width: width,
                    height: height,
                    bitsPerComponent: 8,
                    bytesPerRow: width * 4,
                    space: colorSpace,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                )
            )
            context.draw(source, in: CGRect(origin: .zero, size: size))
        }

        return bytes
    }

    private func expectPreviewMatchesArtwork(
        campaign: Campaign,
        size: CGSize
    ) throws {
        let photo = try #require(
            campaign.image?.raw.flatMap(CampaignPosterAssetFactory.decodePhoto)
        )
        let qrCode = campaign.showsQRCode
            ? CampaignPosterAssetFactory.makeQRCode(campaign.jar?.link.absoluteString)
            : nil
        let preview = try renderRGBA(
            CampaignPosterView(
                campaign: campaign,
                assets: CampaignPosterPreviewAssets(
                    photo: photo,
                    qrCode: qrCode,
                    signature: "preview"
                )
            ),
            size: size
        )
        let artwork = try renderRGBA(
            CampaignPosterArtwork(campaign: campaign, qrCode: qrCode) {
                DisplayImageView(
                    image: photo,
                    scale: campaign.imageScale,
                    offset: campaign.imageOffset,
                    referenceSize: campaign.imageReferenceSize,
                    contentMode: campaign.image?.contentMode ?? .fill
                )
            },
            size: size
        )

        expectPixelsEqual(artwork, preview)
    }

    private func previewAssets(
        for campaign: Campaign
    ) -> CampaignPosterPreviewAssets {
        CampaignPosterPreviewAssets(
            photo: campaign.image?.raw.flatMap(CampaignPosterAssetFactory.decodePhoto),
            qrCode: campaign.showsQRCode
                ? CampaignPosterAssetFactory.makeQRCode(campaign.jar?.link.absoluteString)
                : nil,
            signature: "preview"
        )
    }

    private func expectPixelsEqual(_ actual: [UInt8], _ expected: [UInt8]) {
        expectNoDifference(actual.count, expected.count)
        expectNoDifference(
            Array(SHA256.hash(data: Data(actual))),
            Array(SHA256.hash(data: Data(expected)))
        )
    }

    private func rgbaPixel(
        _ pixels: [UInt8],
        at point: CGPoint,
        size: CGSize
    ) -> (red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) {
        let width = Int(size.width)
        let index = (Int(point.y) * width + Int(point.x)) * 4
        return (
            red: pixels[index],
            green: pixels[index + 1],
            blue: pixels[index + 2],
            alpha: pixels[index + 3]
        )
    }
}
