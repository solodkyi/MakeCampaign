import Dependencies
import UIKit
import SwiftUI

struct CampaignRenderer {
    enum Error: Swift.Error {
        case campaignIsNotReadyForRender
        case renderingCancelled
        case renderingFailed
    }
    let render: (Campaign) async throws -> UIImage
}

extension CampaignRenderer: DependencyKey {
    
    // MARK: - Option 1: Optimized UIHostingController (Quick Fix)
    // Minimal changes with immediate performance improvements
    /*
    static let liveValue = Self(
        render: { campaign in
            guard let template = campaign.template, 
                  let rawImage = campaign.image?.raw, 
                  let image = UIImage(data: rawImage) else {
                throw Error.campaignIsNotReadyForRender
            }
            
            let templateView = await CampaignTemplateView(
                campaign: campaign, 
                template: template, 
                image: image
            )

            return try await renderViewToUIImageOptimized(
                view: templateView, 
                size: CGSize(width: 1080, height: 1080)
            )
        }
    )
    */
    
    // MARK: - Option 2: Modern ImageRenderer API (Recommended for iOS 16+)
    // Most efficient approach using Apple's latest rendering API
    
    static let liveValue = Self(
        render: { campaign in
            guard let template = campaign.template, 
                  let rawImage = campaign.image?.raw, 
                  let image = UIImage(data: rawImage) else {
                throw Error.campaignIsNotReadyForRender
            }
            
            let templateView = await CampaignTemplateView(
                campaign: campaign, 
                template: template, 
                image: image
            )

            return try await renderViewWithImageRenderer(
                view: templateView, 
                size: CGSize(width: 1080, height: 1080)
            )
        }
    )
    
    
    // MARK: - Option 3: Background Threading with UIHostingController
    // Maximum optimization with off-main-thread processing
    /*
    static let liveValue = Self(
        render: { campaign in
            guard let template = campaign.template, 
                  let rawImage = campaign.image?.raw, 
                  let image = UIImage(data: rawImage) else {
                throw Error.campaignIsNotReadyForRender
            }
            
            let templateView = await CampaignTemplateView(
                campaign: campaign, 
                template: template, 
                image: image
            )

            return try await renderViewWithBackgroundProcessing(
                view: templateView, 
                size: CGSize(width: 1080, height: 1080)
            )
        }
    )
    */
    
    static let previewValue = Self(
        render: { _ in
            return UIImage()
        }
    )
    
    static let testValue = Self.previewValue
}

extension DependencyValues {
    var campaignRenderer: CampaignRenderer {
        get { self[CampaignRenderer.self] }
        set { self[CampaignRenderer.self] = newValue }
    }
}

// MARK: - Option 1 Implementation: Optimized UIHostingController

@MainActor
private func renderViewToUIImageOptimized<V: View>(view: V, size: CGSize) async throws -> UIImage {
    // Check for cancellation
    try Task.checkCancellation()
    
    let controller = UIHostingController(rootView: 
        view
            .frame(width: size.width, height: size.height)
            .edgesIgnoringSafeArea(.all)
    )
    
    controller.view.frame = CGRect(origin: .zero, size: size)
    controller.view.backgroundColor = .clear
    
    // Force layout synchronously (we're already on main thread)
    controller.view.setNeedsLayout()
    controller.view.layoutIfNeeded()
    
    // Yield to allow other tasks to run
    await Task.yield()
    
    // Check for cancellation again
    try Task.checkCancellation()
    
    let format = UIGraphicsImageRendererFormat()
    format.opaque = false
    format.scale = 2.0 // Use 2x scale for better quality
    
    let renderer = UIGraphicsImageRenderer(size: size, format: format)
    
    // Use afterScreenUpdates: false for better performance
    // This avoids waiting for the next screen refresh cycle
    let image = renderer.image { context in
        controller.view.drawHierarchy(
            in: CGRect(origin: .zero, size: size), 
            afterScreenUpdates: false
        )
    }
    
    // Verify we got a valid image
    guard image.size.width > 0 && image.size.height > 0 else {
        throw CampaignRenderer.Error.renderingFailed
    }
    
    return image
}

// MARK: - Option 2 Implementation: Modern ImageRenderer (iOS 16+)

@MainActor
private func renderViewWithImageRenderer<V: View>(view: V, size: CGSize) async throws -> UIImage {
    // Check for cancellation
    try Task.checkCancellation()
    
    // ImageRenderer is more efficient than UIHostingController
    let renderer = ImageRenderer(content: 
        view
            .frame(width: size.width, height: size.height)
    )
    
    // Configure rendering properties
    renderer.scale = 2.0 // 2x scale for retina displays
    renderer.isOpaque = false
    
    // Yield to allow other tasks
    await Task.yield()
    
    // Check for cancellation
    try Task.checkCancellation()
    
    // Render the image
    guard let image = renderer.uiImage else {
        throw CampaignRenderer.Error.renderingFailed
    }
    
    return image
}

// MARK: - Option 3 Implementation: Background Threading

@MainActor
private func renderViewWithBackgroundProcessing<V: View>(view: V, size: CGSize) async throws -> UIImage {
    // Check for cancellation
    try Task.checkCancellation()
    
    // Create the hosting controller on main thread
    let controller = UIHostingController(rootView: 
        view
            .frame(width: size.width, height: size.height)
            .edgesIgnoringSafeArea(.all)
    )
    
    controller.view.frame = CGRect(origin: .zero, size: size)
    controller.view.backgroundColor = .clear
    
    // Layout on main thread (required)
    controller.view.setNeedsLayout()
    controller.view.layoutIfNeeded()
    
    // Small delay to ensure layout is complete
    try await Task.sleep(for: .milliseconds(50))
    
    // Check for cancellation
    try Task.checkCancellation()
    
    // Prepare rendering parameters
    let bounds = CGRect(origin: .zero, size: size)
    let format = UIGraphicsImageRendererFormat()
    format.opaque = false
    format.scale = 2.0
    
    // Perform the actual rendering in a detached task to reduce main thread pressure
    // Note: We still need to call drawHierarchy on main thread, but this structure
    // allows better task prioritization
    let image: UIImage = try await withCheckedThrowingContinuation { continuation in
        // Use a slightly lower priority to not block UI
        Task(priority: .userInitiated) {
            do {
                try Task.checkCancellation()
                
                let renderer = UIGraphicsImageRenderer(size: size, format: format)
                let renderedImage = await MainActor.run {
                    renderer.image { context in
                        controller.view.drawHierarchy(
                            in: bounds, 
                            afterScreenUpdates: false
                        )
                    }
                }
                
                // Verify image
                guard renderedImage.size.width > 0 && renderedImage.size.height > 0 else {
                    continuation.resume(throwing: CampaignRenderer.Error.renderingFailed)
                    return
                }
                
                continuation.resume(returning: renderedImage)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    return image
}

// MARK: - Legacy Implementation (Original)

@MainActor
private func renderViewToUIImage<V: View>(view: V, size: CGSize) async -> UIImage {
    let controller = UIHostingController(rootView: 
        view
            .frame(width: size.width, height: size.height)
            .edgesIgnoringSafeArea(.all)
    )
    
    controller.view.frame = CGRect(origin: .zero, size: size)
    controller.view.backgroundColor = .clear
    
    controller.view.setNeedsLayout()
    controller.view.layoutIfNeeded()
    
    let format = UIGraphicsImageRendererFormat()
    format.opaque = false
    let renderer = UIGraphicsImageRenderer(size: size, format: format)
    
    let image = renderer.image { context in
        controller.view.drawHierarchy(in: CGRect(origin: .zero, size: size), afterScreenUpdates: true)
    }
    
    return image
}
