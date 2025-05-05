//
//  CampaignDetails.swift
//  MakeCampaign
//
//  Created by Andrii Solodkyi on 5/2/25.
//
import SwiftUI
import ComposableArchitecture

struct CampaignDetailsFeature: Reducer {
    struct State: Equatable {
        
        enum Alert: Equatable {
            case error(Error)
            case photoWasSavedInLibrary
        }
    
        enum Error: Equatable {
            case noNameSpecified
            case noPhotoSelected
            case noTemplateSelected
            case noPhotoLibraryPermission
        }
        
        enum Field {
            case name
            case target
        }
        
        @BindingState var focus: Field? = .name
        @BindingState var campaign: Campaign
        
        var alert: Alert?
    }
    
    enum Action: BindableAction {
        case onSaveButtonTapped
        case onPhotoSelected(URL?)
        case onImageTapped
        case onPhotoPermissionDenied
        case onTemplateSelected(Template.ID)
        case onAlertDisplayed(State.Alert)
        
        case binding(BindingAction<State>)
    }
    
    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case let .onPhotoSelected(photoURL):
                if let photoURL = photoURL {
                    state.campaign.imageURL = photoURL
                }
                return .none
            case .onPhotoPermissionDenied:
                state.alert = .error(.noPhotoLibraryPermission)
                return .none
            case .onTemplateSelected(let id):
                state.campaign.template = id
                return .none
            case .onSaveButtonTapped:
                if state.campaign.purpose.isEmpty {
                    state.alert = .error(.noNameSpecified)
                    return .none
                }
                
                if state.campaign.imageURL == nil {
                    state.alert = .error(.noPhotoSelected)
                    return .none
                }
                
                if state.campaign.template == nil {
                    state.alert = .error(.noTemplateSelected)
                }
                // TODO: Persist in DB & save to photo library
                return .none
            case .binding(_): return .none
            case .onImageTapped:
                return .none
            case let .onAlertDisplayed(alert):
                if state.alert == alert {
                    state.alert = nil
                }
                return .none
            }
        }
    }
}

struct CampaignDetailsFormView: View {
    let store: StoreOf<CampaignDetailsFeature>
    @FocusState var focus: CampaignDetailsFeature.State.Field?
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            NavigationStack {
                VStack {
                    Form {
                        Section {
                            TextField("Назва збору", text: viewStore.$campaign.purpose)
                                .focused(self.$focus, equals: .name)
                            TextField("Ціль збору (не обов'язково)", text: viewStore.$campaign.formattedTarget)
                                .focused(self.$focus, equals: .target)
                        } header: {
                            Text("Ім'я та ціль")
                        }
                        Section {
                            Button {
                                viewStore.send(.onPhotoSelected(nil))
                            } label: {
                                HStack {
                                    Image(systemName: "photo")
                                    Text("Обрати фото з бібліотеки")
                                }
                            }
                            
                            if let imageURL = viewStore.campaign.imageURL,
                               let uiImage = UIImage(contentsOfFile: imageURL.path) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 200)
                                    .cornerRadius(12)
                            }
                            Button {
                                viewStore.send(.onTemplateSelected(UUID()))
                            } label: {
                                HStack {
                                    Image(systemName: "paintpalette.fill")
                                    Text("Обрати шаблон")
                                }
                            }
                        } header: {
                            Text("Фото збору")
                        }
                    }
                    Button("Зберегти") {
                        viewStore.send(.onSaveButtonTapped)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(Color.white)
                    .cornerRadius(10)
                    .padding([.horizontal, .bottom])
                }
                
                .navigationTitle("Новий збір")
            }
            .bind(viewStore.$focus, to: self.$focus)
        }
    }
}

#Preview {
    NavigationStack {
        CampaignDetailsFormView(store: Store(initialState: CampaignDetailsFeature.State(campaign: .mock2), reducer: {
            CampaignDetailsFeature()
                ._printChanges()
        }))
    }
}
