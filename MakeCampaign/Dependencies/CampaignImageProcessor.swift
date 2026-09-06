import Dependencies
import ImageIO
import UniformTypeIdentifiers

struct CampaignImageProcessor: Sendable {
    enum ProcessingError: Error, Equatable {
        case invalidImage
        case encodingFailed
    }

    static let maximumPixelDimension = 2_400

    var process: @Sendable (Data) async throws -> Data
}

extension CampaignImageProcessor: DependencyKey {
    static let liveValue = Self { data in
        try await Task.detached(priority: .userInitiated) {
            try Task.checkCancellation()
            let result: Data = try autoreleasepool {
                guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
                    throw ProcessingError.invalidImage
                }
                let options: [CFString: Any] = [
                    kCGImageSourceCreateThumbnailFromImageAlways: true,
                    kCGImageSourceCreateThumbnailWithTransform: true,
                    kCGImageSourceThumbnailMaxPixelSize: maximumPixelDimension,
                    kCGImageSourceShouldCacheImmediately: true,
                ]
                guard let image = CGImageSourceCreateThumbnailAtIndex(
                    source,
                    0,
                    options as CFDictionary
                ) else {
                    throw ProcessingError.invalidImage
                }

                let output = NSMutableData()
                guard let destination = CGImageDestinationCreateWithData(
                    output,
                    UTType.jpeg.identifier as CFString,
                    1,
                    nil
                ) else {
                    throw ProcessingError.encodingFailed
                }
                CGImageDestinationAddImage(
                    destination,
                    image,
                    [kCGImageDestinationLossyCompressionQuality: 0.88] as CFDictionary
                )
                guard CGImageDestinationFinalize(destination) else {
                    throw ProcessingError.encodingFailed
                }
                return output as Data
            }
            try Task.checkCancellation()
            return result
        }.value
    }

    static let testValue = Self { data in data }
}

extension DependencyValues {
    var campaignImageProcessor: CampaignImageProcessor {
        get { self[CampaignImageProcessor.self] }
        set { self[CampaignImageProcessor.self] = newValue }
    }
}
