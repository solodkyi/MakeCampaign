import SwiftUI
import UIKit

struct CampaignShareSheet: UIViewControllerRepresentable {
    let payload: CampaignCreationFeature.State.SharePayload

    func makeUIViewController(context: Context) -> UIActivityViewController {
        var items: [Any] = [payload.caption]
        if let image = UIImage(data: payload.pngData) {
            items.insert(image, at: 0)
        }
        return UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
