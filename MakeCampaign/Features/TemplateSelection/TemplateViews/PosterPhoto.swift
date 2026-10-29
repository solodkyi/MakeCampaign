//
//  PosterPhoto.swift
//  MakeCampaign
//

import SwiftUI

/// The campaign photo, clipped to `shape` and sized to the space its container
/// gives it — never more.
///
/// A `scaledToFill` image reports the source image's natural size as its ideal
/// size, which is far larger than any poster. Placed directly in a stack it wins
/// the layout negotiation against the surrounding text and pushes the title or
/// goal off the poster; `.frame(maxHeight: .infinity)` bounds it but leaves that
/// oversized ideal intact. Laying the photo over a `Color.clear`, whose ideal
/// size is zero, inverts that: the photo takes what is left rather than what it
/// would like.
struct PosterPhoto<PhotoShape: Shape>: View {
    private let shape: PhotoShape
    private let photo: () -> AnyView

    init(_ shape: PhotoShape, photo: @escaping () -> AnyView) {
        self.shape = shape
        self.photo = photo
    }

    var body: some View {
        Color.clear
            .overlay { photo() }
            .campaignPhotoFrame(shape)
    }
}
