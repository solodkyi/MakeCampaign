//
//  CampaignDetails.swift
//  MakeCampaign
//
//  Created by Andrii Solodkyi on 5/2/25.
//
import SwiftUI
import ComposableArchitecture
import PhotosUI

struct CampaignDetailsFeature: Reducer {
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
        
        @BindingState var focus: Field?
        @BindingState var campaign: Campaign
        @PresentationState var destination: Destination.State?
        
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

        enum Delegate {
            case deleteCampaign(Campaign.ID)
            case saveCampaign(Campaign)
        }
    }
    
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.openSettings) var openSettings
    @Dependency(\.validationClient) var validationClient
    @Dependency(\.mainQueue) var mainQueue
    
    struct Destination: Reducer {
        enum State: Equatable {
            case alert(AlertState<Action.Alert>)
            case templateSelection(TemplateSelectionFeature.State)
        }
        
        enum Action: Equatable {
            case alert(Alert)
            case templateSelection(TemplateSelectionFeature.Action)
            
            enum Alert {
                case confirmDeleteCampaign
                case openAppSettings
                case photoWasSavedInLibrary
                case photoSavingFailed
            }
        }
        
        var body: some ReducerOf<Self> {
            Scope(state: /State.templateSelection, action: /Action.templateSelection) {
                TemplateSelectionFeature()
            }
        }
    }
    
    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .destination(.presented(.alert(.confirmDeleteCampaign))):
                return .run { [id = state.campaign.id] send in
                    await send(.delegate(.deleteCampaign(id)))
                    await self.dismiss()
                }
            case .destination(.presented(.alert(.openAppSettings))):
                return .run { send in
                    await openSettings()
                }
            case let .destination(.presented(.templateSelection(.delegate(.templateApplied(template, forCampaign: _))))):
                state.campaign.template = template
                state.destination = nil
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
                            await dismiss()
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
        .ifLet(\.$destination, action: /CampaignDetailsFeature.Action.destination) {
            Destination()
        }
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
}

struct CampaignDetailsFormView: View {
    let store: StoreOf<CampaignDetailsFeature>
    @FocusState var focus: CampaignDetailsFeature.State.Field?
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            ZStack {
                VStack {
                    Form {
                        Section {
                            TextField("Призначення збору", text: viewStore.$campaign.purpose)
                                .focused($focus, equals: .name)
                            
                            if viewStore.validationErrors.hasErrors(for: .name) {
                                ForEach(viewStore.validationErrors.errorMessages(for: .name), id: \.self) { message in
                                    Text(message)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                            
                            TextField("Сума збору (не обов'язково)", text: viewStore.$campaign.formattedTarget)
                                .focused($focus, equals: .target)
                                .keyboardType(.decimalPad)
                            
                            if viewStore.validationErrors.hasErrors(for: .target) {
                                ForEach(viewStore.validationErrors.errorMessages(for: .target), id: \.self) { message in
                                    Text(message)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                        } header: {
                            Text("Призначення та сума")
                        }
                        if viewStore.state.isEditing {
                            Section {
                                TextField(
                                    "Банка збору (не обов'язково)",
                                    text: viewStore.$campaign.jarURLString)
                                .focused($focus, equals: .link)
                                
                                if viewStore.validationErrors.hasErrors(for: .link) {
                                    ForEach(viewStore.validationErrors.errorMessages(for: .link), id: \.self) { message in
                                        Text(message)
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                }
                            } header: {
                                Text("Посилання на банку")
                            }
                        }
                        
                        Section {
                            PhotosPicker(
                                selection: viewStore.binding(
                                    get: { _ in viewStore.selectedImage?.pickerItem },
                                    send: { .setSelectedItem($0) }
                                ),
                                matching: .images,
                                photoLibrary: .shared()
                            ) {
                                Label("Обрати фото з бібліотеки", systemImage: "photo")
                                    .foregroundColor(.accentColor)
                            }
                            if viewStore.validationErrors.hasErrors(for: .image) {
                                ForEach(viewStore.validationErrors.errorMessages(for: .image), id: \.self) { message in
                                    Text(message)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                            
                            if let imageData = viewStore.campaign.image?.raw,
                               let uiImage = UIImage(data: imageData) {
                                
                                if let template = viewStore.campaign.template {
                                    CampaignTemplateView(campaign: viewStore.campaign, template: template, image: uiImage)
                                        .onTapGesture {
                                            viewStore.send(.onImageTapped)
                                        }
                                        .frame(width: 1080/4, height: 1080/4)
                                } else {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 200)
                                        .onTapGesture {
                                            viewStore.send(.onImageTapped)
                                        }
                                }
                                
                                Button {
                                    viewStore.send(.onTemplateButtonTapped)
                                } label: {
                                    let labelText: String = {
                                        guard let template = viewStore.campaign.template else {
                                            return "Обрати шаблон"
                                        }
                                        return template.name
                                    }()
                                    Label(labelText, systemImage: "paintpalette.fill")
                                        .foregroundColor(.accentColor)
                                }
                                if viewStore.validationErrors.hasErrors(for: .template) {
                                    ForEach(viewStore.validationErrors.errorMessages(for: .template), id: \.self) { message in
                                        Text(message)
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                        } header: {
                            Text("Фото збору")
                        }
                        if viewStore.state.isEditing {
                            Button(role: .destructive) {
                                viewStore.send(.onCampaignDeleteButtonTapped(viewStore.state.campaign.id))
                            } label: {
                                Text("Видалити")
                            }
                        }
                    }
                    .toolbar {
                        if !viewStore.isPresentingImageOverlay {
                            ToolbarItem(placement: .primaryAction) {
                                Button("Зберегти") {
                                    viewStore.send(.onSaveButtonTapped)
                                }
                                .disabled(!viewStore.isCampaignChanged)
                            }
                        }
                    }
                }
                if viewStore.isPresentingImageOverlay {
                    if let imageData = viewStore.campaign.image?.raw, let uiImage = UIImage(data: imageData) {
                        ZStack {
                            Color.black.ignoresSafeArea()
                            VStack(alignment: .center) {
                                Spacer()
                                if let template = viewStore.campaign.template {
                                    CampaignTemplateView(
                                        campaign: viewStore.campaign,
                                        template: template,
                                        image: uiImage
                                    )
                                    .frame(maxWidth: 1080/3, maxHeight: 1080/3)
                                    .edgesIgnoringSafeArea(.all)
                                } else {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .edgesIgnoringSafeArea(.all)
                                }
                                Spacer()
                            }
                        }
                        .onTapGesture {
                            viewStore.send(.imagePreviewCloseButtonTappped)
                        }
                        .statusBar(hidden: viewStore.isPresentingImageOverlay)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.2), value: viewStore.isPresentingImageOverlay)
                        .navigationBarBackButtonHidden()
                    }
                }
            }
            .bind(viewStore.$focus, to: self.$focus)
            .interactiveDismissDisabled(viewStore.isPresentingImageOverlay)
            .alert(
                store: self.store.scope(state: \.$destination, action: { .destination($0) }),
                state: /CampaignDetailsFeature.Destination.State.alert,
                action: CampaignDetailsFeature.Destination.Action.alert
            )
            .sheet(
                store: self.store.scope(state: \.$destination, action: { .destination($0) }),
                state: /CampaignDetailsFeature.Destination.State.templateSelection,
                action: CampaignDetailsFeature.Destination.Action.templateSelection
            ) { store in
                NavigationStack {
                    TemplateSelectionView(store: store)
                        .navigationTitle("Обрати шаблон")
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        CampaignDetailsFormView(store: Store(initialState: CampaignDetailsFeature.State(campaign: .mock2, isEditing: true), reducer: {
            CampaignDetailsFeature()
                ._printChanges()
        }))
    }
}

extension CampaignDetailsFeature.State.SelectedImage {
    var imageData: Data? {
        guard case let .data(data) = self else {
            return nil
        }
        return data
    }
    
    
    var pickerItem: PhotosPickerItem? {
        guard case let .item(photosPickerItem) = self else {
            return nil
        }
        return photosPickerItem
    }
}
