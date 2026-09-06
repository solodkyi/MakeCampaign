//
//  YellowBlueGradientTemplateView.swift
//  MakeCampaign
//

import SwiftUI

/// `angularYellowBlue_trailing` — a hard diagonal splits the poster: navy above
/// the cut, saturated yellow below it, with the photo straddling the seam inside
/// a navy ring.
///
/// The split is a hard stop rather than a blend; softening it would lose the
/// flag-like edge the composition is built on.
struct YellowBlueGradientTemplateView: View {
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
                    .font(PosterFont.oswaldBold.size(side * 0.068))
                    .lineSpacing(side * 0.068 * 0.02)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.6)
                    .frame(maxWidth: side * 0.62, alignment: .leading)

                photo(side: side)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .frame(maxHeight: .infinity)
                    .padding(.vertical, side * 0.04)

                caption(side: side)
            }
            .padding(side * 0.06)
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background {
                Self.navy.overlay(wedge)
            }
        }
    }

    /// The 115° cut from the design, as a hard stop at 52%.
    private var wedge: some View {
        LinearGradient(
            stops: [
                .init(color: .clear, location: 0.52),
                .init(color: Self.yellow, location: 0.52),
            ],
            startPoint: UnitPoint(x: 0.05, y: 0.29),
            endPoint: UnitPoint(x: 0.95, y: 0.71)
        )
    }

    private func photo(side: CGFloat) -> some View {
        PosterPhoto(Circle(), photo: viewProvider)
            .aspectRatio(1.0, contentMode: .fit)
                    .frame(maxWidth: side * 0.52, maxHeight: side * 0.52)
            .overlay {
                Circle()
                    .strokeBorder(Self.navy, lineWidth: side * 0.012)
            }
    }

    @ViewBuilder
    private func caption(side: CGFloat) -> some View {
        if let goal {
            let labelSize = side * 0.023

            VStack(alignment: .leading, spacing: side * 0.006) {
                Text("ціль збору:")
                    .font(PosterFont.plexMonoRegular.size(labelSize))
                    .tracking(labelSize * 0.18)
                    .textCase(.uppercase)
                    .foregroundStyle(Self.yellow)

                Text(goal)
                    .campaignPosterElement(.target)
                    .font(PosterFont.oswaldBold.size(side * 0.074))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .padding(.horizontal, side * 0.03)
            .padding(.vertical, side * 0.024)
            .frame(maxWidth: side * 0.7, alignment: .leading)
            .background(Self.navy)
        }
    }

    private static let navy = Color(red: 16/255, green: 48/255, blue: 125/255)
    private static let yellow = Color(red: 255/255, green: 214/255, blue: 10/255)
}

#Preview {
    PosterTemplatePreview { purpose, goal, photo in
        YellowBlueGradientTemplateView(purpose: purpose, goal: goal, viewProvider: photo)
    }
}
