//
//  CampaignDetails.swift
//  MakeCampaign
//
//  Created by Andrii Solodkyi on 5/2/25.
//
import SwiftUI
import ComposableArchitecture
import PhotosUI

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
                store: self.store.scope(
                    state: \.$destination.alert,
                    action: \.destination.alert
                )
            )
            .sheet(
                store: self.store.scope(
                    state: \.$destination.templateSelection,
                    action: \.destination.templateSelection
                )
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
