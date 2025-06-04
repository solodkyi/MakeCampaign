import Dependencies
import UIKit

struct ImageCache {
    var image: @Sendable (NSData) -> UIImage?
    var insert: @Sendable (UIImage, NSData) -> Void
}

extension ImageCache: DependencyKey {
    static let liveValue: Self = {
        let cache = NSCache<NSData, UIImage>()
        return Self(
            image: { key in cache.object(forKey: key) },
            insert: { image, key in cache.setObject(image, forKey: key) }
        )
    }()

    static let previewValue = Self(
        image: { _ in nil },
        insert: { _, _ in }
    )

    static let testValue = Self.previewValue
}

extension DependencyValues {
    var imageCache: ImageCache {
        get { self[ImageCache.self] }
        set { self[ImageCache.self] = newValue }
    }
}
