//
//  ImagePreview.swift
//  MakeCampaign
//
//  Created by AI Assistant on 25/6/25.
//

import SwiftUI

struct ImagePreviewView: View {
    let imageData: Data
    let onCancel: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()
            
            if let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .edgesIgnoringSafeArea(.all)
            }
        }
        .onTapGesture {
            onCancel()
        }
        .statusBar(hidden: true)
    }
}

#Preview {
    let mockData = UIImage(systemName: "photo")!.pngData()!
    return ImagePreviewView(imageData: mockData, onCancel: {})
}
