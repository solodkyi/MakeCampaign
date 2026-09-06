import Dependencies
import SwiftUI

struct CampaignPosterThumbnail: View {
    let request: CampaignPosterThumbnailRequest

    @Dependency(\.campaignPosterThumbnailClient) private var thumbnailClient
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.secondary.opacity(0.08))

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFill()
                    .accessibilityIdentifier(
                        "campaign-poster-thumbnail-\(request.template.id)"
                    )
            } else {
                ProgressView()
                    .controlSize(.small)
                    .accessibilityLabel("Готуємо мініатюру")
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .task(id: request.key) {
            image = nil
            do {
                image = try await thumbnailClient.image(request)
            } catch is CancellationError {
                return
            } catch {
                image = nil
            }
        }
    }
}
