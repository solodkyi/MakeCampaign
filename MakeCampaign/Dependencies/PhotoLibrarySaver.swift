import Dependencies
import UIKit
import Photos

struct PhotoLibrarySaver {
    let saveImage: (UIImage) async throws -> Void
    let requestPermission: () async -> PHAuthorizationStatus
}

extension PhotoLibrarySaver: DependencyKey {
    static let liveValue = Self(
        saveImage: { image in
            let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            guard status == .authorized else {
                throw PhotoLibrarySaverError.permissionDenied
            }
            
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                }) { success, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if success {
                        continuation.resume()
                    } else {
                        continuation.resume(throwing: PhotoLibrarySaverError.saveFailed)
                    }
                }
            }
        },
        requestPermission: {
            await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        }
    )
    
    static let previewValue = Self(
        saveImage: { _ in
            // Mock success for previews
        },
        requestPermission: {
            return .authorized
        }
    )
    
    static let testValue = Self.previewValue
}

extension DependencyValues {
    var photoLibrarySaver: PhotoLibrarySaver {
        get { self[PhotoLibrarySaver.self] }
        set { self[PhotoLibrarySaver.self] = newValue }
    }
}

enum PhotoLibrarySaverError: Error, LocalizedError {
    case invalidImageData
    case permissionDenied
    case saveFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidImageData:
            return "Не вдалося обробити дані зображення"
        case .permissionDenied:
            return "Немає дозволу на збереження в бібліотеку фото"
        case .saveFailed:
            return "Не вдалося зберегти зображення в бібліотеку фото"
        }
    }
} 
