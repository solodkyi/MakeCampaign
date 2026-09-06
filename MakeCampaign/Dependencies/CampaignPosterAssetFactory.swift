import UIKit

struct CampaignPosterAssets: @unchecked Sendable {
    let photo: UIImage
    let qrCode: UIImage?
}

enum CampaignPosterAssetFactory {
    static func decodePhoto(_ data: Data) -> UIImage? {
        UIImage(data: data)
    }

    static func makeQRCode(_ payload: String?) -> UIImage? {
        payload.flatMap(QRCodeGenerator.image(for:))
    }

    static func prepare(
        _ request: CampaignRenderRequest
    ) async throws -> CampaignPosterAssets {
        try Task.checkCancellation()

        let assets = try autoreleasepool {
            guard let photo = decodePhoto(request.photoData) else {
                throw CampaignRenderer.Error.invalidPhotoData
            }

            let qrCode = makeQRCode(request.qrPayload)
            if request.qrPayload != nil, qrCode == nil {
                throw CampaignRenderer.Error.invalidQRCode
            }

            return CampaignPosterAssets(photo: photo, qrCode: qrCode)
        }

        try Task.checkCancellation()
        return assets
    }
}
