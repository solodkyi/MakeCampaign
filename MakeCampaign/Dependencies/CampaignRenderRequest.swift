import Foundation

struct CampaignRenderRequest: Sendable {
    let campaign: Campaign
    let template: Template
    let photoData: Data
    let outputSize: CGSize
    let qrPayload: String?

    init(campaign: Campaign) throws {
        guard let template = campaign.template else {
            throw CampaignRenderer.Error.missingTemplate
        }
        guard let photoData = campaign.image?.raw else {
            throw CampaignRenderer.Error.missingPhotoData
        }

        let qrPayload: String?
        if campaign.showsQRCode {
            guard let url = campaign.jar?.link else {
                throw CampaignRenderer.Error.missingQRCode
            }
            guard let scheme = url.scheme?.lowercased(),
                  scheme == "http" || scheme == "https",
                  let host = url.host,
                  !host.isEmpty else {
                throw CampaignRenderer.Error.invalidQRCode
            }
            qrPayload = url.absoluteString
        } else {
            qrPayload = nil
        }

        self.campaign = campaign
        self.template = template
        self.photoData = photoData
        self.outputSize = campaign.posterFormat.pixelSize
        self.qrPayload = qrPayload
    }
}
