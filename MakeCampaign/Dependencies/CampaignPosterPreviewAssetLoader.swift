import CryptoKit
import Dependencies
import Foundation
import UIKit

struct CampaignPosterPreviewAssetInput: Equatable, Sendable {
    let photoData: Data?
    let qrPayload: String?

    init(photoData: Data?, qrPayload: String?) {
        self.photoData = photoData
        self.qrPayload = qrPayload
    }

    init(campaign: Campaign) {
        self.init(
            photoData: campaign.image?.raw,
            qrPayload: campaign.showsQRCode
                ? campaign.jar?.link.absoluteString
                : nil
        )
    }
}

struct CampaignPosterPreviewAssets: @unchecked Sendable {
    let photo: UIImage?
    let qrCode: UIImage?
    let signature: String

    static let empty = Self(photo: nil, qrCode: nil, signature: "empty")
}

struct CampaignPosterPreviewAssetBuffer {
    private(set) var assets = CampaignPosterPreviewAssets.empty
    private var requestedInput: CampaignPosterPreviewAssetInput?

    mutating func beginLoading(_ input: CampaignPosterPreviewAssetInput) {
        requestedInput = input
    }

    mutating func commit(
        _ assets: CampaignPosterPreviewAssets,
        for input: CampaignPosterPreviewAssetInput
    ) {
        guard requestedInput == input else { return }
        self.assets = assets
    }
}

struct CampaignPosterPreviewAssetLoader: Sendable {
    typealias Load = @Sendable (
        CampaignPosterPreviewAssetInput
    ) async throws -> CampaignPosterPreviewAssets

    let load: Load

    static func live(
        decodePhoto: @escaping @Sendable (Data) -> UIImage?,
        makeQRCode: @escaping @Sendable (String) -> UIImage?
    ) -> Self {
        Self { input in
            try Task.checkCancellation()
            let signature = signature(for: input)
            let assets = autoreleasepool {
                CampaignPosterPreviewAssets(
                    photo: input.photoData.flatMap(decodePhoto),
                    qrCode: input.qrPayload.flatMap(makeQRCode),
                    signature: signature
                )
            }
            try Task.checkCancellation()
            return assets
        }
    }

    private static func signature(
        for input: CampaignPosterPreviewAssetInput
    ) -> String {
        var hasher = SHA256()
        update(&hasher, marker: 0x01, data: input.photoData)
        update(
            &hasher,
            marker: 0x02,
            data: input.qrPayload.map { Data($0.utf8) }
        )
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }

    private static func update(
        _ hasher: inout SHA256,
        marker: UInt8,
        data: Data?
    ) {
        hasher.update(data: Data([marker, data == nil ? 0 : 1]))
        guard let data else { return }
        var length = UInt64(data.count).bigEndian
        withUnsafeBytes(of: &length) { bytes in
            hasher.update(bufferPointer: bytes)
        }
        hasher.update(data: data)
    }
}

extension CampaignPosterPreviewAssetLoader: DependencyKey {
    static var liveValue: Self {
        .live(
            decodePhoto: CampaignPosterAssetFactory.decodePhoto,
            makeQRCode: { CampaignPosterAssetFactory.makeQRCode($0) }
        )
    }

    static var previewValue: Self {
        Self { _ in .empty }
    }

    static var testValue: Self {
        previewValue
    }
}

extension DependencyValues {
    var campaignPosterPreviewAssetLoader: CampaignPosterPreviewAssetLoader {
        get { self[CampaignPosterPreviewAssetLoader.self] }
        set { self[CampaignPosterPreviewAssetLoader.self] = newValue }
    }
}
