//
//  PosterA14TemplateView.swift
//  MakeCampaign
//

import SwiftUI

/// Набір A, `radialMintIndigo_roundedTrailing` — a mint glow in the lower right
/// of a deep indigo field, an outlined hryvnia sign watermarked across the left
/// edge, and the photo in a plain circle.
struct PosterA14TemplateView: View {
    let purpose: String
    let goal: String?

    var viewProvider: () -> AnyView

    init(purpose: String, goal: String?, viewProvider: @escaping () -> some View = { Color.clear }) {
        self.purpose = purpose
        self.goal = goal
        self.viewProvider = { AnyView(viewProvider()) }
    }

    var body: some View {
        GeometryReader { geometry in
            let side = geometry.size.width

            VStack(alignment: .leading, spacing: 0) {
                Text(purpose.uppercased())
                    .campaignPosterElement(.campaignTitle)
                    .font(PosterFont.oswaldSemiBold.size(side * 0.054))
                    .lineSpacing(side * 0.054 * 0.06)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.6)
                    .frame(maxWidth: side * 0.68, alignment: .leading)

                PosterPhoto(Circle(), photo: viewProvider)
                    .aspectRatio(1.0, contentMode: .fit)
                    .frame(maxWidth: side * 0.56, maxHeight: side * 0.56)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .frame(maxHeight: .infinity)
                    .padding(.vertical, side * 0.04)

                caption(side: side)
            }
            .padding(side * 0.06)
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background {
                background(side: side).overlay(alignment: .bottomLeading) {
                    watermark(side: side)
                }
            }
        }
    }

    private func background(side: CGFloat) -> some View {
        RadialGradient(
            stops: [
                .init(color: Color(red: 159/255, green: 232/255, blue: 198/255), location: 0),
                .init(color: Color(red: 63/255, green: 75/255, blue: 184/255), location: 0.55),
                .init(color: Color(red: 25/255, green: 29/255, blue: 77/255), location: 1),
            ],
            center: UnitPoint(x: 0.85, y: 0.9),
            startRadius: 0,
            endRadius: side * 1.2
        )
    }

    private func watermark(side: CGFloat) -> some View {
        PosterGlyph(character: "₴")
            .stroke(.white.opacity(0.22), lineWidth: side * 0.0025)
            .frame(width: side * 0.3, height: side * 0.3)
            .offset(x: -side * 0.02, y: -side * 0.2)
            .allowsHitTesting(false)
    }

    @ViewBuilder
    private func caption(side: CGFloat) -> some View {
        if let goal {
            let labelSize = side * 0.023

            HStack(alignment: .firstTextBaseline, spacing: side * 0.022) {
                Text("ціль збору:")
                    .font(PosterFont.plexMonoRegular.size(labelSize))
                    .tracking(labelSize * 0.14)
                    .textCase(.uppercase)
                    .foregroundStyle(Self.periwinkle)

                Text(goal)
                    .campaignPosterElement(.target)
                    .font(PosterFont.oswaldBold.size(side * 0.066))
                    .foregroundStyle(Self.indigo)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .padding(.horizontal, side * 0.03)
            .padding(.vertical, side * 0.022)
            .background(.white, in: Capsule())
        }
    }

    private static let indigo = Color(red: 25/255, green: 29/255, blue: 77/255)
    private static let periwinkle = Color(red: 53/255, green: 64/255, blue: 127/255)
}

#Preview {
    PosterTemplatePreview { purpose, goal, photo in
        PosterA14TemplateView(purpose: purpose, goal: goal, viewProvider: photo)
    }
}
