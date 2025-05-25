import Dependencies
import UIKit
import SwiftUI

struct CampaignRenderer {
    enum Error: Swift.Error {
        case campaignIsNotReadyForRender
    }
    let render: (Campaign) async throws -> UIImage
}

extension CampaignRenderer: DependencyKey {
    static let liveValue = Self(
        render: { campaign in
            guard let template = campaign.template, let rawImage = campaign.image?.raw, let image = UIImage(data: rawImage) else {
                throw Error.campaignIsNotReadyForRender
            }
            let templateView = await CampaignTemplateView(campaign: campaign, template: template, image: image)

            return await renderViewToUIImage(view: templateView, size: CGSize(width: 1080, height: 1080))
        }
    )
    
    static let previewValue = Self(
        render: { _ in
            return UIImage()
        }
    )
}

extension DependencyValues {
    var campaignRenderer: CampaignRenderer {
        get { self[CampaignRenderer.self] }
        set { self[CampaignRenderer.self] = newValue }
    }
}

@MainActor
private func renderViewToUIImage<V: View>(view: V, size: CGSize) async -> UIImage {
    let controller = UIHostingController(rootView: 
        view
            .frame(width: size.width, height: size.height)
            .edgesIgnoringSafeArea(.all)
    )
    
    controller.view.frame = CGRect(origin: .zero, size: size)
    controller.view.backgroundColor = .clear
    
    controller.view.setNeedsLayout()
    controller.view.layoutIfNeeded()
    
    let format = UIGraphicsImageRendererFormat()
    format.opaque = false
    let renderer = UIGraphicsImageRenderer(size: size, format: format)
    
    let image = renderer.image { context in
        controller.view.drawHierarchy(in: CGRect(origin: .zero, size: size), afterScreenUpdates: true)
    }
    
    return image
}
