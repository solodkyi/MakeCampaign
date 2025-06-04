//
//  CampaignDetailsFeature.swift
//  MakeCampaign
//
//  Created by andriisolodkyi on 29.05.2025.
//

import SwiftUI
import ComposableArchitecture
import PhotosUI

@Reducer
struct CampaignDetailsFeature {
    @ObservableState
    struct State: Equatable {
        enum Error: Equatable {
            case noNameSpecified
            case noPhotoSelected
            case noTemplateSelected
            case noPhotoLibraryPermission
        }
        
        enum Field: Equatable {
            case name
            case target
            case link
            case image
            case template
        }
        
        struct ValidationErrors: Equatable {
            var name: [ValidationError] = []
            var target: [ValidationError] = []
            var link: [ValidationError] = []
            var image: [ValidationError] = []
            var template: [ValidationError] = []
            
            var isEmpty: Bool {
                name.isEmpty && target.isEmpty && link.isEmpty && image.isEmpty && template.isEmpty
            }
            
            mutating func clear(_ field: Field) {
                switch field {
                case .name: name = []
                case .target: target = []
                case .link: link = []
                case .image: image = []
                case .template: template = []
                }
            }
            
            mutating func set(_ field: Field, errors: [ValidationError]) {
                switch field {
                case .name: name = errors
                case .target: target = errors
                case .link: link = errors
                case .image: image = errors
                case .template: template = errors
                }
            }
            
            func hasErrors(for field: Field) -> Bool {
                switch field {
                case .name: return !name.isEmpty
                case .target: return !target.isEmpty
                case .link: return !link.isEmpty
                case .image: return !image.isEmpty
                case .template: return !template.isEmpty
                }
            }
            
            func errorMessages(for field: Field) -> [String] {
                switch field {
                case .name: return name.map { $0.message }
                case .target: return target.map { $0.message }
                case .link: return link.map { $0.message }
                case .image: return image.map { $0.message }
                case .template: return template.map { $0.message }
                }
            }
        }
        
        enum SelectedImage: Equatable {
            case data(Data?)
            case item(PhotosPickerItem?)
        }
        
        var focus: Field?
        var campaign: Campaign
        @Presents var destination: Destination.State?
        
        var isEditing: Bool = false
        var isPresentingImageOverlay: Bool = false
        
        var selectedImage: SelectedImage?
        var validationErrors = ValidationErrors()
        var isFormValid: Bool = false
        
        var initialCampaign: Campaign
        
        var isCampaignChanged: Bool {
            campaign != initialCampaign
        }
        
        init(
            campaign: Campaign,
            destination: Destination.State? = nil,
            isEditing: Bool = false,
            isPresentingImageOverlay: Bool = false,
            selectedImage: SelectedImage? = nil,
            validationErrors: ValidationErrors = ValidationErrors(),
            isFormValid: Bool = false
        ) {
            
            if isEditing {
                self.focus = nil
            } else {
                self.focus = .name
            }
            self.initialCampaign = campaign
            self.campaign = campaign
            self.destination = destination
            self.isEditing = isEditing
            self.isPresentingImageOverlay = isPresentingImageOverlay
            self.selectedImage = selectedImage
            self.validationErrors = validationErrors
            self.isFormValid = isFormValid
        }
    }
    
    enum Action: BindableAction {
        case onImageTapped
        case onTemplateButtonTapped
        case onCampaignDeleteButtonTapped(Campaign.ID)
        case onSaveButtonTapped
        case onSelectImageDataConverted(Data)
        case destination(PresentationAction<Destination.Action>)
        case setSelectedItem(PhotosPickerItem?)
        case onPhotoLibraryPermissionResponse(PHAuthorizationStatus)
        case onPhotoSavingFailed
        case imagePreviewCloseButtonTappped
        
        case binding(BindingAction<State>)
        case validateForm
        case delegate(Delegate)

        @CasePathable
        @dynamicMemberLookup
        enum Delegate {
            case deleteCampaign(Campaign.ID)
            case saveCampaign(Campaign)
        }
    }
    
    @Dependency(\.isPresented) var isPresented
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.openSettings) var openSettings
    @Dependency(\.validationClient) var validationClient
    @Dependency(\.mainQueue) var mainQueue
    
    @Reducer(state: .equatable)
    enum Destination {
        enum Action: Equatable {
            case alert(Alert)
            case templateSelection(TemplateSelectionFeature.Action)
            
            @CasePathable
            enum Alert {
                case confirmDeleteCampaign
                case openAppSettings
                case photoWasSavedInLibrary
                case photoSavingFailed
            }
        }
        case alert(AlertState<Action.Alert>)
        case templateSelection(TemplateSelectionFeature)
    }
    
    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .destination(.presented(.alert(.confirmDeleteCampaign))):
                return .run { [id = state.campaign.id] send in
                    await send(.delegate(.deleteCampaign(id)))
                    await self.dismissIfPresented()
                }
            case .destination(.presented(.alert(.openAppSettings))):
                return .run { send in
                    await openSettings()
                }
            case let .destination(.presented(.templateSelection(.delegate(.templateApplied(template, forCampaign: _))))):
                state.campaign.template = template
                state.destination = nil
                
                validateField(.template, &state)
                return .none
            case let .destination(.presented(.templateSelection(.delegate(.imageRepositioned(scale, offset, containerSize, forCampaign: _))))):
                state.campaign.imageScale = scale
                state.campaign.imageOffset = offset
                state.campaign.imageReferenceSize = containerSize
                return .none
            case .destination: return .none
            case .onTemplateButtonTapped:
                state.destination = .templateSelection(TemplateSelectionFeature.State(
                    campaign: state.campaign
                ))
                
                return .none
                
            case .onSaveButtonTapped:
                validateForm(&state)
                
                if state.validationErrors.isEmpty {
                    return .run { send in
                        @Dependency(\.photoLibrarySaver) var saver
                        await send(.onPhotoLibraryPermissionResponse(saver.requestPermission()))
                    }
                }
                
                state.focus = nil
        
                return .none
            
            case let .onPhotoLibraryPermissionResponse(authorizationStatus):
                switch authorizationStatus {
                case .authorized, .limited:
                    return .run { [campaign = state.campaign] send in
                        @Dependency(\.campaignRenderer) var renderer
                        @Dependency(\.photoLibrarySaver) var saver
                        do {
                            let image = try await renderer.render(campaign)
                            try await saver.saveImage(image)
                            
                            await send(.delegate(.saveCampaign(campaign)))
                            await dismissIfPresented()
                        } catch {
                            await send(.onPhotoSavingFailed)
                        }
                    }
                case .denied, .restricted:
                    state.destination = .alert(AlertState(title: {
                        TextState("Немає доступу")
                    }, actions: {
                        ButtonState(role: .cancel) {
                            TextState("Закрити")
                        }
                        ButtonState(role: .destructive, action: .openAppSettings) {
                            TextState("Налаштування")
                        }
                    }, message: {
                        TextState("Додатку необхідний доступ для збереження зображення у вашій бібліотеці")
                    }))
                    return .none
                default: return .none
                }
            case .binding:
                return .none
                
            case .validateForm:
                validateForm(&state)
                
                return .none
                
            case .onCampaignDeleteButtonTapped:
                state.destination = .alert(
                    AlertState {
                        TextState("Ви впевнені, що хочете видалити збір?")
                    } actions: {
                        ButtonState(role: .destructive, action: .confirmDeleteCampaign) {
                            TextState("Видалити")
                        }
                    }
                )
                return .none
            case .onImageTapped:
                state.isPresentingImageOverlay.toggle()
                state.focus = nil
                return .none
            case .imagePreviewCloseButtonTappped:
                state.isPresentingImageOverlay.toggle()
                return .none
            case let .setSelectedItem(item):
                state.selectedImage = .item(item)

                return .run { send in
                    if let item = item {
                        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
                        
                        await send(.onSelectImageDataConverted(data))
                    }
                }
            case let .onSelectImageDataConverted(data):
                state.selectedImage = .data(data)
                state.campaign.image = .init(raw: data)
                validateField(.image, &state)
                
                return .none
            case .delegate: return .none
            case .onPhotoSavingFailed:
                state.destination = .alert(AlertState(title: {
                    TextState("Збереження зображення не вдалося")
                }, actions: {
                    ButtonState(role: .cancel) {
                        TextState("Закрити")
                    }
                }, message: {
                    TextState("Спробуйте ще раз пізніше або переконайтеся, що у вас є доступ до фотобібліотеки.")
                }))
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
    
    private func validateField(_ field: State.Field?, _ state: inout State) {
        if let field = field {
            state.validationErrors.clear(field)
            
            let errors = validationClient.validateField(field, state)
            state.validationErrors.set(field, errors: errors)
            
        } else {
            validateForm(&state)
        }
        
        state.isFormValid = state.validationErrors.isEmpty
    }
    
    private func validateForm(_ state: inout State) {
        state.validationErrors = State.ValidationErrors()
        
        let nameErrors = validationClient.validateName(state.campaign.purpose)
        state.validationErrors.name = nameErrors
        
        let imageErrors = validationClient.validateImage(state.campaign.image?.raw)
        state.validationErrors.image.append(contentsOf: imageErrors)
        
        let targetErrors = validationClient.validateTarget(state.campaign.formattedTarget)
        state.validationErrors.target = targetErrors
        
        let linkErrors = validationClient.validateLink(state.campaign.jarURLString)
        state.validationErrors.link = linkErrors
        
        let templateErrors = validationClient.validateTemplate(state.campaign.template)
        state.validationErrors.template = templateErrors
        
        state.isFormValid = state.validationErrors.isEmpty
    }
    
    private func dismissIfPresented() async {
        if isPresented {
            await dismiss()
        }
    }
}

extension StoreOf<CampaignDetailsFeature> {
    var photoPickerBinding: PhotosPickerItem? {
        get {
            state.selectedImage?.pickerItem
        }
        set {
            send(.setSelectedItem(newValue))
        }
    }
}
