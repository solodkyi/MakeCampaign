//
//  PhotoLibraryFeature.swift
//  MakeCampaign
//
//  Created by Andrii Solodkyi on 5/9/25.
//

import SwiftUI
import PhotosUI
import ComposableArchitecture

struct PhotoLibraryFeature: Reducer {
    struct State: Equatable {
        var selectedImageData: Data?
        var selectedItem: PhotosPickerItem?
    }
    
    enum Action: Equatable {
        case setSelectedItem(PhotosPickerItem?)
        case delegate(Delegate)
        
        enum Delegate: Equatable {
            case didSelectImage(data: Data?)
        }
    }
    
    @Dependency(\.dismiss) var dismiss
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .setSelectedItem(item):
                state.selectedItem = item
                
                return .run { send in
                    if let item = item {
                        let data = try? await item.loadTransferable(type: Data.self)
                        
                        await send(.delegate(.didSelectImage(data: data)))
                    }
                }
            case let .delegate(.didSelectImage(data)):
                state.selectedImageData = data
                return .none
            }
        }
    }
}

struct PhotoLibraryView: View {
    let store: StoreOf<PhotoLibraryFeature>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack {
                if
                    let imageData = viewStore.selectedImageData,
                    let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 300)
                } else {
                    Text("No image selected")
                        .frame(height: 300)
                }
                
                PhotosPicker(
                    selection: viewStore.binding(
                        get: { _ in viewStore.selectedItem },
                        send: { .setSelectedItem($0) }
                    ),
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Text("Select a photo")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
        }
    }
}
