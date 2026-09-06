import CustomDump
import Dependencies
import Testing
import UIKit

@testable import MakeCampaign

@MainActor
@Suite("Campaign poster preview assets", .serialized)
struct CampaignPosterPreviewAssetLoaderTests {
    @Test("Prepared photo stays visible until its replacement is ready")
    func replacementKeepsPreparedPhotoVisible() {
        let originalInput = CampaignPosterPreviewAssetInput(
            photoData: Data([1]),
            qrPayload: nil
        )
        let replacementInput = CampaignPosterPreviewAssetInput(
            photoData: Data([2]),
            qrPayload: nil
        )
        let originalPhoto = UIImage(systemName: "photo")!
        let replacementPhoto = UIImage(systemName: "photo.fill")!
        var buffer = CampaignPosterPreviewAssetBuffer()

        buffer.beginLoading(originalInput)
        buffer.commit(
            CampaignPosterPreviewAssets(
                photo: originalPhoto,
                qrCode: nil,
                signature: "original"
            ),
            for: originalInput
        )
        buffer.beginLoading(replacementInput)

        #expect(buffer.assets.photo === originalPhoto)
        expectNoDifference(buffer.assets.signature, "original")

        buffer.commit(
            CampaignPosterPreviewAssets(
                photo: replacementPhoto,
                qrCode: nil,
                signature: "replacement"
            ),
            for: replacementInput
        )

        #expect(buffer.assets.photo === replacementPhoto)
        expectNoDifference(buffer.assets.signature, "replacement")
    }

    @Test("Late preview completion cannot replace a newer request")
    func lateCompletionIsIgnored() {
        let staleInput = CampaignPosterPreviewAssetInput(
            photoData: Data([1]),
            qrPayload: nil
        )
        let currentInput = CampaignPosterPreviewAssetInput(
            photoData: Data([2]),
            qrPayload: nil
        )
        let stalePhoto = UIImage(systemName: "photo")!
        var buffer = CampaignPosterPreviewAssetBuffer()

        buffer.beginLoading(staleInput)
        buffer.beginLoading(currentInput)
        buffer.commit(
            CampaignPosterPreviewAssets(
                photo: stalePhoto,
                qrCode: nil,
                signature: "stale"
            ),
            for: staleInput
        )

        #expect(buffer.assets.photo == nil)
        expectNoDifference(buffer.assets.signature, "empty")
    }

    @Test("Campaign input omits QR payload while QR is disabled")
    func disabledQRInput() {
        var campaign = Campaign.mock1
        campaign.showsQRCode = false
        campaign.jar = .init(link: URL(string: "https://example.com/a")!)

        let input = CampaignPosterPreviewAssetInput(campaign: campaign)

        #expect(input.photoData == campaign.image?.raw)
        #expect(input.qrPayload == nil)
    }

    @Test("One load decodes photo and QR exactly once")
    func loadsEachAssetOnce() async throws {
        let photoCalls = LockIsolated(0)
        let qrCalls = LockIsolated(0)
        let expectedPhoto = UIImage(systemName: "photo")!
        let expectedQR = UIImage(systemName: "qrcode")!
        let loader = CampaignPosterPreviewAssetLoader.live(
            decodePhoto: { _ in
                photoCalls.withValue { $0 += 1 }
                return expectedPhoto
            },
            makeQRCode: { _ in
                qrCalls.withValue { $0 += 1 }
                return expectedQR
            }
        )

        let assets = try await loader.load(
            CampaignPosterPreviewAssetInput(
                photoData: Data([1, 2, 3]),
                qrPayload: "https://example.com"
            )
        )

        expectNoDifference(photoCalls.value, 1)
        expectNoDifference(qrCalls.value, 1)
        #expect(assets.photo === expectedPhoto)
        #expect(assets.qrCode === expectedQR)
        #expect(!assets.signature.isEmpty)
    }

    @Test("Disabled QR performs no QR generation")
    func disabledQRDoesNoWork() async throws {
        let qrCalls = LockIsolated(0)
        let loader = CampaignPosterPreviewAssetLoader.live(
            decodePhoto: { _ in nil },
            makeQRCode: { _ in
                qrCalls.withValue { $0 += 1 }
                return nil
            }
        )

        let assets = try await loader.load(
            CampaignPosterPreviewAssetInput(
                photoData: Data([1]),
                qrPayload: nil
            )
        )

        expectNoDifference(qrCalls.value, 0)
        #expect(assets.qrCode == nil)
    }

    @Test("Invalid preview photo becomes a missing prepared photo")
    func invalidPhotoIsTolerated() async throws {
        let loader = CampaignPosterPreviewAssetLoader.live(
            decodePhoto: { _ in nil },
            makeQRCode: { _ in nil }
        )

        let assets = try await loader.load(
            CampaignPosterPreviewAssetInput(
                photoData: Data("not an image".utf8),
                qrPayload: nil
            )
        )

        #expect(assets.photo == nil)
    }

    @Test("Asset signatures are deterministic and cover photo and QR input")
    func deterministicSignature() async throws {
        let loader = CampaignPosterPreviewAssetLoader.live(
            decodePhoto: { _ in nil },
            makeQRCode: { _ in nil }
        )
        let original = CampaignPosterPreviewAssetInput(
            photoData: Data([1, 2, 3]),
            qrPayload: "https://example.com/a"
        )

        let first = try await loader.load(original).signature
        let second = try await loader.load(original).signature
        let changedPhoto = try await loader.load(
            CampaignPosterPreviewAssetInput(
                photoData: Data([1, 2, 4]),
                qrPayload: original.qrPayload
            )
        ).signature
        let changedQR = try await loader.load(
            CampaignPosterPreviewAssetInput(
                photoData: original.photoData,
                qrPayload: "https://example.com/b"
            )
        ).signature
        let absent = try await loader.load(
            CampaignPosterPreviewAssetInput(photoData: nil, qrPayload: nil)
        ).signature

        expectNoDifference(first, second)
        #expect(first != changedPhoto)
        #expect(first != changedQR)
        #expect(first != absent)
    }

    @Test("Cancellation prevents asset preparation")
    func cancellationStopsPreparation() async {
        let photoCalls = LockIsolated(0)
        let loader = CampaignPosterPreviewAssetLoader.live(
            decodePhoto: { _ in
                photoCalls.withValue { $0 += 1 }
                return nil
            },
            makeQRCode: { _ in nil }
        )
        let task = Task {
            try await loader.load(
                CampaignPosterPreviewAssetInput(
                    photoData: Data([1]),
                    qrPayload: nil
                )
            )
        }
        task.cancel()

        await #expect(throws: CancellationError.self) {
            try await task.value
        }
        expectNoDifference(photoCalls.value, 0)
    }
}
