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
    @Bindable var store: StoreOf<CampaignDetailsFeature>
    @FocusState var focus: CampaignDetailsFeature.State.Field?
    
    var body: some View {
        ZStack {
            mainContentView
            imageOverlayView
        }
        .focused($focus, equals: store.state.focus)
        .interactiveDismissDisabled(store.isPresentingImageOverlay)
        .alert($store.scope(
            state: \.destination?.alert,
            action: \.destination.alert
        )
        )
        .sheet(item: $store.scope(state: \.destination?.templateSelection, action: \.destination.templateSelection)) { store in
            NavigationStack {
                TemplateSelectionView(store: store)
                    .navigationTitle("Обрати шаблон")
            }
        }
    }
    
    @ViewBuilder
    private var mainContentView: some View {
        VStack {
            Form {
                purposeAndTargetSection
                
                if store.state.isEditing {
                    jarLinkSection
                }
                
                imageSection
                
                if store.state.isEditing {
                    deleteButton
                }
            }
            .toolbar {
                if !store.isPresentingImageOverlay {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Зберегти") {
                            store.send(.onSaveButtonTapped)
                        }
                        .disabled(!store.isCampaignChanged)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var purposeAndTargetSection: some View {
        Section {
            TextField("Призначення збору", text: $store.campaign.purpose)
                .focused($focus, equals: .name)
            if store.validationErrors.hasErrors(for: .name) {
                ForEach(store.validationErrors.errorMessages(for: .name), id: \.self) { message in
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            TextField("Сума збору (не обов'язково)", text: $store.campaign.formattedTarget)
                .focused($focus, equals: .target)
                .keyboardType(.decimalPad)
            
            if store.validationErrors.hasErrors(for: .target) {
                ForEach(store.validationErrors.errorMessages(for: .target), id: \.self) { message in
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        } header: {
            Text("Призначення та сума")
        }
    }
    
    @ViewBuilder
    private var jarLinkSection: some View {
        Section {
            TextField(
                "Банка збору (не обов'язково)",
                text: $store.campaign.jarURLString)
            .focused($focus, equals: .link)
            
            if store.validationErrors.hasErrors(for: .link) {
                ForEach(store.validationErrors.errorMessages(for: .link), id: \.self) { message in
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        } header: {
            Text("Посилання на банку")
        }
    }
    
    @ViewBuilder
    private var imageSection: some View {
        Section {
            photoPickerView
            
            if store.validationErrors.hasErrors(for: .image) {
                ForEach(store.validationErrors.errorMessages(for: .image), id: \.self) { message in
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            if let imageData = store.campaign.image?.raw,
               let uiImage = UIImage(data: imageData) {
                
                imagePreviewView(uiImage: uiImage)
                templateSelectionButton
                templateValidationErrors
            }
        } header: {
            Text("Фото збору")
        }
    }
    
    @ViewBuilder
    private var photoPickerView: some View {
        PhotosPicker(
            selection: $store.photoPickerBinding,
            matching: .images,
            photoLibrary: .shared()
        ) {
            Label("Обрати фото з бібліотеки", systemImage: "photo")
                .foregroundColor(.accentColor)
        }
    }
    
    @ViewBuilder
    private func imagePreviewView(uiImage: UIImage) -> some View {
        if let template = store.campaign.template {
            CampaignTemplateView(campaign: store.campaign, template: template, image: uiImage)
                .onTapGesture {
                    store.send(.onImageTapped)
                }
                .frame(width: 1080/4, height: 1080/4)
        } else {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(height: 200)
                .onTapGesture {
                    store.send(.onImageTapped)
                }
        }
    }
    
    @ViewBuilder
    private var templateSelectionButton: some View {
        Button {
            store.send(.onTemplateButtonTapped)
        } label: {
            let labelText: String = {
                guard let template = store.campaign.template else {
                    return "Обрати шаблон"
                }
                return template.name
            }()
            Label(labelText, systemImage: "paintpalette.fill")
                .foregroundColor(.accentColor)
        }
    }
    
    @ViewBuilder
    private var templateValidationErrors: some View {
        if store.validationErrors.hasErrors(for: .template) {
            ForEach(store.validationErrors.errorMessages(for: .template), id: \.self) { message in
                Text(message)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
    
    @ViewBuilder
    private var deleteButton: some View {
        Button(role: .destructive) {
            store.send(.onCampaignDeleteButtonTapped(store.state.campaign.id))
        } label: {
            Text("Видалити")
        }
    }
    
    @ViewBuilder
    private var imageOverlayView: some View {
        if store.isPresentingImageOverlay {
            if let imageData = store.campaign.image?.raw, let uiImage = UIImage(data: imageData) {
                ZStack {
                    Color.black.ignoresSafeArea()
                    VStack(alignment: .center) {
                        Spacer()
                        overlayImageContent(uiImage: uiImage)
                        Spacer()
                    }
                }
                .onTapGesture {
                    store.send(.imagePreviewCloseButtonTappped)
                }
                .statusBar(hidden: store.isPresentingImageOverlay)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: store.isPresentingImageOverlay)
                .navigationBarBackButtonHidden()
            }
        }
    }
    
    @ViewBuilder
    private func overlayImageContent(uiImage: UIImage) -> some View {
        if let template = store.campaign.template {
            CampaignTemplateView(
                campaign: store.campaign,
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
    }
}

#Preview {
    NavigationStack {
        CampaignDetailsFormView(store: Store(initialState: CampaignDetailsFeature.State(campaign: Shared(value: Campaign.mock2), isEditing: true), reducer: {
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

