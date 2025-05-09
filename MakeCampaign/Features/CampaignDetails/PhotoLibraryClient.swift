//
//  PhotoLibraryClient.swift
//  MakeCampaign
//
//  Created by Andrii Solodkyi on 5/9/25.
//

import Foundation
import Photos
import PhotosUI
import Dependencies

struct PhotoLibraryClient {
    var authorizationStatus: (PHAccessLevel) -> PHAuthorizationStatus
    var requestAuthorization: @Sendable () async -> PHAuthorizationStatus
    var requestAssets: @Sendable () async -> [PHAsset]
}

extension PhotoLibraryClient: DependencyKey {
    static let liveValue = Self(
        authorizationStatus: {
            PHPhotoLibrary.authorizationStatus(for: $0)
        },
        requestAuthorization: {
            await withCheckedContinuation { continuation in
                PHPhotoLibrary.requestAuthorization { status in
                    continuation.resume(returning: status)
                }
            }
        },
        requestAssets: {
            await withCheckedContinuation { continuation in
                let fetchResult = PHAsset.fetchAssets(with: .image, options: nil)
                var assets: [PHAsset] = []
                fetchResult.enumerateObjects { asset, _, _ in
                    assets.append(asset)
                }
                continuation.resume(returning: assets)
            }
        }
    )
}

extension DependencyValues {
    var photoLibrary: PhotoLibraryClient {
        get { self[PhotoLibraryClient.self] }
        set { self[PhotoLibraryClient.self] = newValue }
    }
}
