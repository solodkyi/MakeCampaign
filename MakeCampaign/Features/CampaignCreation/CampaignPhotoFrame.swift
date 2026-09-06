import SwiftUI

enum CampaignPhotoLayer {
    case framed
    case overflow
}

private struct CampaignPhotoLayerEnvironmentKey: EnvironmentKey {
    static let defaultValue = CampaignPhotoLayer.framed
}

private struct CampaignPhotoOverflowPreviewEnvironmentKey: EnvironmentKey {
    static let defaultValue = false
}

private struct CampaignPhotoTransformActivityEnvironmentKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var campaignPhotoLayer: CampaignPhotoLayer {
        get { self[CampaignPhotoLayerEnvironmentKey.self] }
        set { self[CampaignPhotoLayerEnvironmentKey.self] = newValue }
    }

    fileprivate var campaignPhotoOverflowPreviewEnabled: Bool {
        get { self[CampaignPhotoOverflowPreviewEnvironmentKey.self] }
        set { self[CampaignPhotoOverflowPreviewEnvironmentKey.self] = newValue }
    }

    fileprivate var campaignPhotoTransformIsActive: Bool {
        get { self[CampaignPhotoTransformActivityEnvironmentKey.self] }
        set { self[CampaignPhotoTransformActivityEnvironmentKey.self] = newValue }
    }
}

private struct CampaignPhotoFrameModifier<FrameShape: Shape>: ViewModifier {
    @Environment(\.campaignPhotoOverflowPreviewEnabled) private var environmentSupportsOverflow
    @Environment(\.campaignPhotoTransformIsActive) private var environmentIsTransforming

    let shape: FrameShape
    let supportsOverflowPreview: Bool?
    let isTransforming: Bool?

    private var showsOverflowLayer: Bool {
        supportsOverflowPreview ?? environmentSupportsOverflow
    }

    private var overflowOpacity: Double {
        (isTransforming ?? environmentIsTransforming) ? 0.5 : 0
    }

    @ViewBuilder
    func body(content: Content) -> some View {
        if showsOverflowLayer {
            ZStack {
                content
                    .environment(\.campaignPhotoLayer, .overflow)
                    .opacity(overflowOpacity)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)

                content
                    .environment(\.campaignPhotoLayer, .framed)
                    .clipShape(shape)
            }
        } else {
            content.clipShape(shape)
        }
    }
}

extension View {
    func campaignPhotoFrame<FrameShape: Shape>(
        _ shape: FrameShape,
        supportsOverflowPreview: Bool? = nil,
        isTransforming: Bool? = nil
    ) -> some View {
        modifier(
            CampaignPhotoFrameModifier(
                shape: shape,
                supportsOverflowPreview: supportsOverflowPreview,
                isTransforming: isTransforming
            )
        )
    }

    func campaignPhotoOverflowPreviewEnabled(_ isEnabled: Bool) -> some View {
        environment(\.campaignPhotoOverflowPreviewEnabled, isEnabled)
    }

    func campaignPhotoTransformIsActive(_ isActive: Bool) -> some View {
        environment(\.campaignPhotoTransformIsActive, isActive)
    }
}
