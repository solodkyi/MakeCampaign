//
//  CampaignDetails.swift
//  MakeCampaign
//
//  Created by Andrii Solodkyi on 5/2/25.
//
import SwiftUI
import ComposableArchitecture

@Reducer
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
            case link
        }
        
        @BindingState var focus: Field? = .name
        @BindingState var campaign: Campaign
 
        var alert: Alert?
        var selectedTemplate: Template.ID?
        var isEditing: Bool = false
        
        @PresentationState var templateSelection: TemplateSelectionFeature.State?
    }
    
    enum Action: BindableAction {
        case onPhotoSelected(URL?)
        case onImageTapped
        case onPhotoPermissionDenied
        case onAlertDisplayed(State.Alert)
        case onTemplateButtonTapped
        case templateSelection(PresentationAction<TemplateSelectionFeature.Action>)
        
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
            case .onTemplateButtonTapped:
                if let imageURL = state.campaign.imageURL {
                    state.templateSelection = TemplateSelectionFeature.State(
                        photoURL: imageURL,
                        selectedTemplateID: state.selectedTemplate
                    )
                } else {
                    state.alert = .error(.noPhotoSelected)
                }
                return .none
                
            case let .templateSelection(.presented(.delegate(.templateSelected(templateID)))):
                state.selectedTemplate = templateID
                state.campaign.template = templateID
                return .none
                
            case .templateSelection:
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
        .ifLet(\.$templateSelection, action: \.templateSelection) {
            TemplateSelectionFeature()
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
                                Button {
                                    viewStore.send(.onTemplateButtonTapped)
                                } label: {
                                    HStack {
                                        Image(systemName: "paintpalette.fill")
                                        Text("Обрати шаблон")
                                    }
                                }
                            }
                        } header: {
                            Text("Фото збору")
                        }
                    }
            }
            .bind(viewStore.$focus, to: self.$focus)
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
