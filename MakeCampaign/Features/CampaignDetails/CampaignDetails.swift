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
        
        enum Field {
            case name
            case target
            case link
        }
        
        @BindingState var focus: Field? = .name
        @BindingState var campaign: Campaign
        @PresentationState var destination: Destination.State?
        
        var isEditing: Bool = false
        var selectedImageData: Data?
        var selectedItem: PhotosPickerItem?
    }
    
    enum Action: BindableAction {
        case onImageTapped
        case onTemplateButtonTapped
        case onCampaignDeleteButtonTapped(Campaign.ID)
        case destination(PresentationAction<Destination.Action>)
        case setSelectedItem(PhotosPickerItem?)
        
        case binding(BindingAction<State>)
        case delegate(Delegate)

        enum Delegate {
            case campaignUpdated(Campaign)
            case deleteCampaign(Campaign.ID)
            case didSelectImage(data: Data?, campaignId: Campaign.ID)
        }
    }
    
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.openSettings) var openSettings
    
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
            case .destination: return .none
            case .onTemplateButtonTapped:
                state.destination = .templateSelection(TemplateSelectionFeature.State(
                    campaign: state.campaign
                ))
                
                return .none
            case .binding:
                return .send(.delegate(.campaignUpdated(state.campaign)))
                
            case .delegate: return .none
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
                return .none
            case let .setSelectedItem(item):
                state.selectedItem = item
                
                return .run { [state] send in
                    if let item = item {
                        let data = try? await item.loadTransferable(type: Data.self)
                        
                        await send(.delegate(.didSelectImage(data: data, campaignId: state.campaign.id)))
                    }
                }
            case let .delegate(.didSelectImage(data, _)):
                state.selectedImageData = data
                return .none
            }
        }
        .ifLet(\.$destination, action: /CampaignDetailsFeature.Action.destination) {
            Destination()
        }
    }
}

struct CampaignDetailsFormView: View {
    let store: StoreOf<CampaignDetailsFeature>
    @FocusState var focus: CampaignDetailsFeature.State.Field?
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            VStack {
                Form {
                    Section {
                        TextField("Назва збору", text: viewStore.$campaign.purpose)
                            .focused(self.$focus, equals: .name)
                        TextField("Ціль збору (не обов'язково)", text: viewStore.$campaign.formattedTarget)
                            .focused(self.$focus, equals: .target)
                            .keyboardType(.decimalPad)
                    } header: {
                        Text("Ім'я та ціль")
                    }
                    if viewStore.state.isEditing {
                        Section {
                            TextField(
                                "Банка збору (не обов'язково)",
                                text: viewStore.$campaign.jarURLString)
                            .focused(self.$focus, equals: .link)
                        } header: {
                            Text("Посилання на монобанку")
                        }
                    }
                    
                    Section {
                        PhotosPicker(
                            selection: viewStore.binding(
                                get: { _ in viewStore.selectedItem },
                                send: { .setSelectedItem($0) }
                            ),
                            matching: .images,
                            photoLibrary: .shared()
                        ) {
                            Label("Обрати фото з бібліотеки", systemImage: "photo")
                                .foregroundColor(.accentColor)
                        }
                        
                        if let imageData = viewStore.campaign.imageData,
                           let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .cornerRadius(12)
                            
                            NavigationLink(
                                state: AppFeature.Path.State.templateSelection(TemplateSelectionFeature.State(campaign: viewStore.campaign))
                            ) {
                                let labelText: String = {
                                    guard let template = viewStore.campaign.template else {
                                        return "Обрати шаблон"
                                    }
                                    return template.name
                                }()
                                Label(labelText, systemImage: "paintpalette.fill")
                                    .foregroundColor(.accentColor)
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
            }
            .bind(viewStore.$focus, to: self.$focus)
            .alert(
                store: self.store.scope(state: \.$destination, action: { .destination($0) }),
                state: /CampaignDetailsFeature.Destination.State.alert,
                action: CampaignDetailsFeature.Destination.Action.alert
            )
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
