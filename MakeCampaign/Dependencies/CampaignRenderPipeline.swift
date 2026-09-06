import UIKit

struct CampaignRenderPipeline: Sendable {
    typealias Prepare = @Sendable (
        CampaignRenderRequest
    ) async throws -> CampaignPosterAssets
    typealias Snapshot = @MainActor @Sendable (
        CampaignRenderRequest,
        CampaignPosterAssets
    ) throws -> UIImage

    let prepare: Prepare
    let snapshot: Snapshot

    func render(_ campaign: Campaign) async throws -> UIImage {
        try Task.checkCancellation()
        let request = try CampaignRenderRequest(campaign: campaign)
        let assets = try await prepare(request)
        try Task.checkCancellation()
        return try await snapshot(request, assets)
    }
}
