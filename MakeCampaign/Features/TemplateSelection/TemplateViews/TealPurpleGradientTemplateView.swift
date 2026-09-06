//
//  TealPurpleGradientTemplateView.swift
//  MakeCampaign
//

import SwiftUI

/// `tealPurpleRadial_roundedTrailing` — a teal glow rising from the lower left
/// into deep indigo, with the photo held in a full-height pill and the kicker
/// set vertically up the left edge.
struct TealPurpleGradientTemplateView: View {
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

            HStack(alignment: .bottom, spacing: side * 0.04) {
                kicker(side: side)

                VStack(alignment: .leading, spacing: side * 0.035) {
                    Text(purpose)
                        .campaignPosterElement(.campaignTitle)
                        .font(PosterFont.oswaldMedium.size(side * 0.054))
                        .lineSpacing(side * 0.054 * 0.1)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                        .minimumScaleFactor(0.6)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    PosterPhoto(Capsule(), photo: viewProvider)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    caption(side: side)
                }
            }
            .padding(side * 0.06)
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(background(side: side))
        }
    }

    private func background(side: CGFloat) -> some View {
        RadialGradient(
            stops: [
                .init(color: Self.teal, location: 0),
                .init(color: Self.indigo, location: 0.6),
                .init(color: Self.midnight, location: 1),
            ],
            center: UnitPoint(x: 0.15, y: 0.85),
            startRadius: 0,
            endRadius: side * 1.2
        )
    }

    private func kicker(side: CGFloat) -> some View {
        let size = side * 0.024

        return Text("збір")
            .font(PosterFont.plexMonoRegular.size(size))
            .tracking(size * 0.34)
            .textCase(.uppercase)
            .foregroundStyle(Self.mint)
            .fixedSize()
            .rotationEffect(.degrees(-90))
            .frame(width: size * 2, height: size * 10)
    }

    @ViewBuilder
    private func caption(side: CGFloat) -> some View {
        if let goal {
            let labelSize = side * 0.022

            HStack(alignment: .firstTextBaseline, spacing: side * 0.02) {
                Text("ціль збору:")
                    .font(PosterFont.plexMonoRegular.size(labelSize))
                    .tracking(labelSize * 0.14)
                    .textCase(.uppercase)
                    .foregroundStyle(Self.deepTeal)

                Text(goal)
                    .campaignPosterElement(.target)
                    .font(PosterFont.oswaldBold.size(side * 0.062))
                    .foregroundStyle(Self.midnight)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                Spacer(minLength: 0)
            }
            .padding(.leading, side * 0.034)
            .padding(.trailing, side * 0.26)
            .padding(.vertical, side * 0.022)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white, in: Capsule())
        }
    }

    private static let teal = Color(red: 35/255, green: 200/255, blue: 182/255)
    private static let indigo = Color(red: 42/255, green: 26/255, blue: 110/255)
    private static let midnight = Color(red: 18/255, green: 11/255, blue: 51/255)
    private static let mint = Color(red: 143/255, green: 240/255, blue: 227/255)
    private static let deepTeal = Color(red: 29/255, green: 95/255, blue: 87/255)
}

#Preview {
    PosterTemplatePreview { purpose, goal, photo in
        TealPurpleGradientTemplateView(purpose: purpose, goal: goal, viewProvider: photo)
    }
}
