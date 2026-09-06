import SwiftUI

enum CampaignPosterElement: String, CaseIterable, Hashable {
    case photo
    case campaignTitle = "campaign-title"
    case target
    case qr

    var accessibilityIdentifier: String {
        "poster-element-\(rawValue)"
    }
}

enum CampaignPosterHitTesting {
    private static let priority: [CampaignPosterElement] = [
        .qr,
        .campaignTitle,
        .target,
        .photo,
    ]

    static func element(
        at location: CGPoint,
        in regions: [CampaignPosterElement: CGRect]
    ) -> CampaignPosterElement? {
        priority.first { element in
            regions[element]?.contains(location) == true
        }
    }
}

extension CampaignPosterElement {
    var accessibilityLabel: String {
        switch self {
        case .photo: "Фото постера"
        case .campaignTitle: "Назва збору на постері"
        case .target: "Ціль збору на постері"
        case .qr: "QR-код на постері"
        }
    }

    var accessibilityEditActionName: String? {
        switch self {
        case .photo: "Замінити фото"
        case .campaignTitle: "Редагувати назву"
        case .target: "Редагувати ціль"
        case .qr: nil
        }
    }
}

private enum CampaignPosterCoordinateSpace {
    static let name = "campaign-poster-elements"
}

private struct CampaignPosterSelectionEnvironmentKey: EnvironmentKey {
    static let defaultValue: CampaignPosterElement? = nil
}

private struct CampaignPosterInteractivityEnvironmentKey: EnvironmentKey {
    static let defaultValue = false
}

private struct CampaignPosterRegionTrackingEnvironmentKey: EnvironmentKey {
    static let defaultValue = false
}

private struct CampaignPosterAccessibilityActions {
    var select: ((CampaignPosterElement) -> Void)?
    var edit: ((CampaignPosterElement) -> Void)?
}

private struct CampaignPosterAccessibilityActionsEnvironmentKey: EnvironmentKey {
    static let defaultValue = CampaignPosterAccessibilityActions()
}

extension EnvironmentValues {
    fileprivate var campaignPosterSelection: CampaignPosterElement? {
        get { self[CampaignPosterSelectionEnvironmentKey.self] }
        set { self[CampaignPosterSelectionEnvironmentKey.self] = newValue }
    }

    fileprivate var campaignPosterInteractivityEnabled: Bool {
        get { self[CampaignPosterInteractivityEnvironmentKey.self] }
        set { self[CampaignPosterInteractivityEnvironmentKey.self] = newValue }
    }

    fileprivate var campaignPosterRegionTrackingEnabled: Bool {
        get { self[CampaignPosterRegionTrackingEnvironmentKey.self] }
        set { self[CampaignPosterRegionTrackingEnvironmentKey.self] = newValue }
    }

    fileprivate var campaignPosterAccessibilityActions: CampaignPosterAccessibilityActions {
        get { self[CampaignPosterAccessibilityActionsEnvironmentKey.self] }
        set { self[CampaignPosterAccessibilityActionsEnvironmentKey.self] = newValue }
    }
}

struct CampaignPosterElementRegionPreferenceKey: PreferenceKey {
    static let defaultValue: [CampaignPosterElement: CGRect] = [:]

    static func reduce(
        value: inout [CampaignPosterElement: CGRect],
        nextValue: () -> [CampaignPosterElement: CGRect]
    ) {
        for (element, frame) in nextValue() {
            if let existing = value[element] {
                value[element] = existing.union(frame)
            } else {
                value[element] = frame
            }
        }
    }
}

private struct CampaignPosterElementRegionModifier: ViewModifier {
    @Environment(\.campaignPosterAccessibilityActions) private var accessibilityActions
    @Environment(\.campaignPhotoLayer) private var photoLayer
    @Environment(\.campaignPosterInteractivityEnabled) private var isInteractive
    @Environment(\.campaignPosterRegionTrackingEnabled) private var tracksRegion
    @Environment(\.campaignPosterSelection) private var selection

    let element: CampaignPosterElement

    @ViewBuilder
    func body(content: Content) -> some View {
        if exposesInteractiveElement {
            let measuredContent = content.background {
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: CampaignPosterElementRegionPreferenceKey.self,
                        value: trackedRegion(in: proxy)
                    )
                }
            }
            let accessibleContent = measuredContent
                .accessibilityElement(children: .combine)
                .accessibilityLabel(element.accessibilityLabel)
                .accessibilityIdentifier(element.accessibilityIdentifier)
                .accessibilityValue(selection == element ? "Вибрано" : "")
                .accessibilityAddTraits(.isButton)
                .accessibilityAction {
                    accessibilityActions.select?(element)
                }

            if let editActionName = element.accessibilityEditActionName {
                accessibleContent
                    .accessibilityAction(named: Text(editActionName)) {
                        accessibilityActions.edit?(element)
                    }
            } else {
                accessibleContent
            }
        } else {
            content
        }
    }

    private var exposesInteractiveElement: Bool {
        isInteractive && !(element == .photo && photoLayer == .overflow)
    }

    private func trackedRegion(
        in proxy: GeometryProxy
    ) -> [CampaignPosterElement: CGRect] {
        guard tracksRegion else { return [:] }
        return [
            element: proxy.frame(in: .named(CampaignPosterCoordinateSpace.name))
        ]
    }
}

extension View {
    func campaignPosterElement(_ element: CampaignPosterElement) -> some View {
        modifier(CampaignPosterElementRegionModifier(element: element))
    }

    func campaignPosterCoordinateSpace() -> some View {
        coordinateSpace(name: CampaignPosterCoordinateSpace.name)
    }

    func campaignPosterSelection(_ selection: CampaignPosterElement?) -> some View {
        environment(\.campaignPosterSelection, selection)
    }

    func campaignPosterInteractivityEnabled(_ isEnabled: Bool) -> some View {
        environment(\.campaignPosterInteractivityEnabled, isEnabled)
    }

    func campaignPosterRegionTrackingEnabled(_ isEnabled: Bool) -> some View {
        environment(\.campaignPosterRegionTrackingEnabled, isEnabled)
    }

    func campaignPosterAccessibilityActions(
        select: ((CampaignPosterElement) -> Void)?,
        edit: ((CampaignPosterElement) -> Void)?
    ) -> some View {
        environment(
            \.campaignPosterAccessibilityActions,
            CampaignPosterAccessibilityActions(select: select, edit: edit)
        )
    }
}
