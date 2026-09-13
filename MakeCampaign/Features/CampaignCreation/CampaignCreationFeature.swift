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
                case .data: "Назва"
                case .template: "Шаблон"
                case .qr: "Ціль"
                }
            }

            var systemImage: String {
                switch self {
                case .photo: "photo"
                case .data: "text.alignleft"
                case .template: "square.grid.2x2"
                case .qr: "target"
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

        struct ExportNotice: Equatable, Identifiable {
            enum ID: Hashable {
                case renderFailed
                case saveFailed
                case saved
                case validationFailed
            }

            let id: ID
            let message: String?
            let title: String
        }

        enum Presentation: Equatable, Identifiable {
            case share(SharePayload)

            var id: String {
                switch self {
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
        var exportNotice: ExportNotice?
        var presentation: Presentation?

        var sharePayload: SharePayload? {
            if case let .share(payload) = presentation {
                return payload
            }
            return nil
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
            var campaign = campaign
            campaign.showsQRCode = false
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
        case saveButtonTapped
        case saveSucceeded
        case saveFailed
        case shareButtonTapped
        case shareRenderSucceeded(Data)
        case renderFailed
        case presentationDismissed
    }

    @Dependency(\.date.now) var now
    @Dependency(\.campaignImageProcessor) var imageProcessor
    @Dependency(\.campaignRenderer) var renderer
    @Dependency(\.photoLibrarySaver) var photoLibrarySaver

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

            case .saveButtonTapped:
                state.validation = validation(for: state.campaign)
                state.exportNotice = nil
                guard state.validation.isValid else {
                    state.exportNotice = validationNotice(for: state.validation)
                    return .none
                }
                state.isRendering = true
                return .run { [campaign = state.campaign] send in
                    do {
                        let image = try await renderer.render(campaign)
                        try await photoLibrarySaver.saveImage(image)
                        await send(.saveSucceeded)
                    } catch {
                        await send(.saveFailed)
                    }
                }

            case .saveSucceeded:
                state.isRendering = false
                completeExport(&state)
                state.exportNotice = .init(
                    id: .saved,
                    message: nil,
                    title: "Фото збережено"
                )
                return .none

            case .saveFailed:
                state.isRendering = false
                state.exportNotice = .init(
                    id: .saveFailed,
                    message: "Перевірте доступ до Фото та спробуйте ще раз.",
                    title: "Не вдалося зберегти фото"
                )
                return .none

            case .shareButtonTapped:
                state.validation = validation(for: state.campaign)
                state.exportNotice = nil
                guard state.validation.isValid else {
                    state.exportNotice = validationNotice(for: state.validation)
                    return .none
                }
                state.isRendering = true
                return .run { [campaign = state.campaign] send in
                    do {
                        let image = try await renderer.render(campaign)
                        guard let data = image.pngData() else {
                            await send(.renderFailed)
                            return
                        }
                        await send(.shareRenderSucceeded(data))
                    } catch {
                        await send(.renderFailed)
                    }
                }

            case let .shareRenderSucceeded(data):
                state.isRendering = false
                completeExport(&state)
                state.presentation = .share(.init(
                    id: state.campaign.id,
                    pngData: data,
                    caption: shareCaption(for: state.campaign)
                ))
                return .none

            case .renderFailed:
                state.isRendering = false
                state.exportNotice = .init(
                    id: .renderFailed,
                    message: "Перевірте дані та спробуйте ще раз.",
                    title: "Не вдалося створити постер"
                )
                return .none

            case .presentationDismissed:
                state.presentation = nil
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

    private func completeExport(_ state: inout State) {
        state.campaign.status = .active
        persist(&state)
        state.initialCampaign = state.campaign
        state.isNew = false
    }

    private func validationNotice(for validation: State.Validation) -> State.ExportNotice {
        let message = [
            validation.title,
            validation.photo,
            validation.template,
            validation.qrLink,
        ]
        .compactMap { $0 }
        .joined(separator: "\n")

        return .init(
            id: .validationFailed,
            message: message,
            title: "Щоб створити постер"
        )
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
