import ComposableArchitecture
import Foundation
import UIKit

@Reducer
struct CampaignCreationFeature {
    @ObservableState
    struct State: Equatable {
        enum Tab: String, CaseIterable, Equatable, Identifiable {
            case template
            case photo
            case data
            case qr

            var id: Self { self }

            var title: String {
                switch self {
                case .photo: "Фото"
                case .data: "Текст"
                case .template: "Шаблон"
                case .qr: "QR"
                }
            }

            var systemImage: String {
                switch self {
                case .photo: "photo"
                case .data: "text.alignleft"
                case .template: "square.grid.2x2"
                case .qr: "qrcode"
                }
            }
        }

        enum PhotoPhase: Equatable {
            case idle
            case processing
            case failed(String)
        }

        struct Validation: Equatable {
            var title: String?
            var photo: String?
            var template: String?
            var qrLink: String?

            var isValid: Bool {
                title == nil && photo == nil && template == nil && qrLink == nil
            }
        }

        struct SharePayload: Equatable, Identifiable {
            let id: Campaign.ID
            let pngData: Data
            let caption: String
        }

        enum Presentation: Equatable, Identifiable {
            case export
            case share(SharePayload)

            var id: String {
                switch self {
                case .export: "export"
                case let .share(payload): "share-\(payload.id.uuidString)"
                }
            }
        }

        @Shared var campaigns: IdentifiedArrayOf<Campaign>
        var campaign: Campaign
        var initialCampaign: Campaign
        var isNew: Bool
        var selectedTab: Tab = .template
        var isPhotoPickerExpanded = false
        var photoPhase: PhotoPhase = .idle
        var validation = Validation()
        var isRendering = false
        var renderError: String?
        var presentation: Presentation?
        var pendingSharePayload: SharePayload?

        var isExportPresented: Bool {
            get {
                guard case .export = presentation else { return false }
                return true
            }
            set {
                if newValue {
                    presentation = .export
                } else if isExportPresented {
                    presentation = nil
                }
            }
        }

        var sharePayload: SharePayload? {
            if case let .share(payload) = presentation {
                return payload
            }
            return pendingSharePayload
        }

        init(
            campaign: Campaign,
            campaigns: Shared<IdentifiedArrayOf<Campaign>>? = nil,
            isNew: Bool
        ) {
            if let campaigns {
                self._campaigns = campaigns
            } else {
                self._campaigns = Shared(.campaigns)
            }
            self.campaign = campaign
            self.initialCampaign = campaign
            self.isNew = isNew
        }
    }

    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case tabSelected(State.Tab)
        case photoPickerExpansionButtonTapped
        case photoPickerExpansionDragEnded(CGFloat)
        case photoPicked(Data)
        case photoProcessed(Data)
        case photoProcessingFailed
        case templateSelected(Template)
        case contentModeSelected(Campaign.Image.ContentMode)
        case imageTransformEnded(scale: CGFloat, offset: CGSize, referenceSize: CGSize)
        case exportOptionsButtonTapped
        case exportSheetDismissed
        case exportButtonTapped
        case renderSucceeded(Data)
        case renderFailed
        case presentationDismissed
        case shareDismissed
    }

    @Dependency(\.date.now) var now
    @Dependency(\.campaignImageProcessor) var imageProcessor
    @Dependency(\.campaignRenderer) var renderer

    private enum CancelID {
        case photoProcessing
    }

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                autosave(&state)
                return .none

            case let .tabSelected(tab):
                state.selectedTab = tab
                state.isPhotoPickerExpanded = false
                return .none

            case .photoPickerExpansionButtonTapped:
                guard state.selectedTab == .photo else { return .none }
                state.isPhotoPickerExpanded.toggle()
                return .none

            case let .photoPickerExpansionDragEnded(translation):
                guard state.selectedTab == .photo else { return .none }
                if translation < -20 {
                    state.isPhotoPickerExpanded = true
                } else if translation > 20 {
                    state.isPhotoPickerExpanded = false
                }
                return .none

            case let .photoPicked(data):
                state.photoPhase = .processing
                return .run { send in
                    do {
                        let data = try await imageProcessor.process(data)
                        try Task.checkCancellation()
                        await send(.photoProcessed(data))
                    } catch is CancellationError {
                        return
                    } catch {
                        await send(.photoProcessingFailed)
                    }
                }
                .cancellable(id: CancelID.photoProcessing, cancelInFlight: true)

            case let .photoProcessed(data):
                let contentMode = state.campaign.image?.contentMode ?? .fill
                state.photoPhase = .idle
                state.isPhotoPickerExpanded = false
                state.campaign.image = .init(raw: data, contentMode: contentMode)
                state.validation.photo = nil
                autosave(&state)
                return .none

            case .photoProcessingFailed:
                state.photoPhase = .failed("Не вдалося завантажити фото. Спробуйте ще раз.")
                return .none

            case let .templateSelected(template):
                state.campaign.template = template
                state.campaign.imageOffset = .zero
                state.campaign.imageScale = 1
                state.validation.template = nil
                autosave(&state)
                return .none

            case let .contentModeSelected(contentMode):
                if state.campaign.image == nil {
                    state.campaign.image = .init(raw: nil, contentMode: contentMode)
                } else {
                    state.campaign.image?.contentMode = contentMode
                }
                autosave(&state)
                return .none

            case let .imageTransformEnded(scale, offset, referenceSize):
                state.campaign.imageScale = max(0.5, min(scale, 5))
                state.campaign.imageOffset = offset
                state.campaign.imageReferenceSize = referenceSize
                autosave(&state)
                return .none

            case .exportOptionsButtonTapped:
                state.pendingSharePayload = nil
                state.isExportPresented = true
                return .none

            case .exportSheetDismissed:
                state.isExportPresented = false
                return .none

            case .exportButtonTapped:
                state.validation = validation(for: state.campaign)
                state.renderError = nil
                guard state.validation.isValid else { return .none }
                state.isRendering = true
                return .run { [campaign = state.campaign] send in
                    do {
                        let image = try await renderer.render(campaign)
                        guard let data = image.pngData() else {
                            await send(.renderFailed)
                            return
                        }
                        await send(.renderSucceeded(data))
                    } catch {
                        await send(.renderFailed)
                    }
                }

            case let .renderSucceeded(data):
                state.isRendering = false
                state.campaign.status = .active
                persist(&state)
                state.initialCampaign = state.campaign
                state.isNew = false
                state.pendingSharePayload = .init(
                    id: state.campaign.id,
                    pngData: data,
                    caption: shareCaption(for: state.campaign)
                )
                state.presentation = nil
                return .none

            case .renderFailed:
                state.isRendering = false
                state.renderError = "Не вдалося створити постер. Перевірте дані та спробуйте ще раз."
                return .none

            case .presentationDismissed:
                guard let payload = state.pendingSharePayload else { return .none }
                state.pendingSharePayload = nil
                state.presentation = .share(payload)
                return .none

            case .shareDismissed:
                state.presentation = nil
                state.pendingSharePayload = nil
                return .none
            }
        }
    }

    private func autosave(_ state: inout State) {
        guard state.campaign != state.initialCampaign else { return }
        if state.campaign.status != .active {
            state.campaign.status = .draft
        }
        persist(&state)
    }

    private func persist(_ state: inout State) {
        state.campaign.markUpdated(at: now)
        let campaign = state.campaign
        state.$campaigns.withLock {
            if $0[id: campaign.id] == nil {
                $0.append(campaign)
            } else {
                $0[id: campaign.id] = campaign
            }
        }
    }

    private func validation(for campaign: Campaign) -> State.Validation {
        var validation = State.Validation()
        if campaign.purpose.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validation.title = "Додайте назву збору."
        }
        if campaign.image?.raw.flatMap(UIImage.init(data:)) == nil {
            validation.photo = "Оберіть фото для постера."
        }
        if campaign.template == nil {
            validation.template = "Оберіть шаблон постера."
        }
        if campaign.showsQRCode && !isValidWebURL(campaign.jar?.link) {
            validation.qrLink = "Додайте повне посилання на банку для QR-коду."
        }
        return validation
    }

    private func isValidWebURL(_ url: URL?) -> Bool {
        guard let url, let scheme = url.scheme?.lowercased(), url.host != nil else { return false }
        return scheme == "https" || scheme == "http"
    }

    private func shareCaption(for campaign: Campaign) -> String {
        let custom = campaign.shareCaption.trimmingCharacters(in: .whitespacesAndNewlines)
        guard custom.isEmpty else { return custom }
        if let link = campaign.jar?.link.absoluteString {
            return "Підтримайте збір «\(campaign.purpose)»\n\(link)"
        }
        return "Підтримайте збір «\(campaign.purpose)»"
    }
}
