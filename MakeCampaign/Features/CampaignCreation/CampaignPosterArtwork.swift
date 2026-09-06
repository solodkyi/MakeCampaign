import SwiftUI

struct CampaignPosterArtwork<PhotoContent: View>: View {
    let campaign: Campaign
    let qrCode: UIImage?
    private let photoContent: PhotoContent

    init(
        campaign: Campaign,
        qrCode: UIImage?,
        @ViewBuilder photoContent: () -> PhotoContent
    ) {
        self.campaign = campaign
        self.qrCode = qrCode
        self.photoContent = photoContent()
    }

    var body: some View {
        GeometryReader { proxy in
            let shortestSide = min(proxy.size.width, proxy.size.height)
            let qrSide = CampaignPosterLayout.qrSideLength(for: shortestSide)

            ZStack(alignment: .bottomTrailing) {
                Color(red: 0.95, green: 0.94, blue: 0.91)

                if let template = campaign.template {
                    CampaignTemplateArtwork(
                        campaign: campaign,
                        template: template
                    ) {
                        photoContent
                    }
                } else {
                    photoContent.campaignPosterElement(.photo)
                }

                qrOverlay(shortestSide: shortestSide, qrSide: qrSide)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        .clipped()
    }

    @ViewBuilder
    private func qrOverlay(shortestSide: CGFloat, qrSide: CGFloat) -> some View {
        if campaign.showsQRCode, let qrCode {
            VStack(alignment: .trailing, spacing: shortestSide * 0.017) {
                Image(uiImage: qrCode)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .padding(shortestSide * 0.015)
                    .background(.white)
                    .frame(width: qrSide, height: qrSide)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: shortestSide * 0.025,
                            style: .continuous
                        )
                    )
                Text("ПІДТРИМАТИ")
                    .font(
                        .system(
                            size: shortestSide * 0.026,
                            weight: .black,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(.white)
                    .padding(.horizontal, shortestSide * 0.023)
                    .padding(.vertical, shortestSide * 0.014)
                    .background(.black.opacity(0.78), in: Capsule())
            }
            .campaignPosterElement(.qr)
            .padding(shortestSide * 0.05)
        }
    }
}
