//
//  PosterA13TemplateView.swift
//  MakeCampaign
//

import SwiftUI

/// Набір A, `radialAquaPurple_squareTrailing` — an aqua-to-violet bloom with the
/// photo hung from the top right, and the campaign data on a bone panel that
/// closes the poster off along the bottom.
struct PosterA13TemplateView: View {
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

            VStack(spacing: 0) {
                PosterPhoto(Rectangle(), photo: viewProvider)
                    .aspectRatio(1.0, contentMode: .fit)
                    .frame(maxWidth: side * 0.62, maxHeight: side * 0.62)
                    .shadow(
                        color: Color(red: 16/255, green: 8/255, blue: 44/255).opacity(0.4),
                        radius: side * 0.04,
                        x: 0,
                        y: side * 0.016
                    )
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(side * 0.06)

                panel(side: side)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(background(side: side))
        }
    }

    private func background(side: CGFloat) -> some View {
        RadialGradient(
            stops: [
                .init(color: Color(red: 53/255, green: 214/255, blue: 208/255), location: 0),
                .init(color: Color(red: 91/255, green: 59/255, blue: 189/255), location: 0.6),
                .init(color: Color(red: 32/255, green: 17/255, blue: 84/255), location: 1),
            ],
            center: UnitPoint(x: 0.2, y: 0.2),
            startRadius: 0,
            endRadius: side
        )
    }

    private func panel(side: CGFloat) -> some View {
        let purposeSize = side * 0.052

        return VStack(alignment: .leading, spacing: side * 0.024) {
            Text(purpose)
                .campaignPosterElement(.campaignTitle)
                .font(PosterFont.oswaldSemiBold.size(purposeSize))
                .lineSpacing(purposeSize * 0.08)
                .foregroundStyle(Self.ink)
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let goal {
                let labelSize = side * 0.024

                HStack(alignment: .firstTextBaseline, spacing: side * 0.024) {
                    Text("ціль збору:")
                        .font(PosterFont.plexMonoRegular.size(labelSize))
                        .tracking(labelSize * 0.16)
                        .textCase(.uppercase)
                        .foregroundStyle(Self.mauve)

                    Text(goal)
                        .campaignPosterElement(.target)
                        .font(PosterFont.oswaldBold.size(side * 0.09))
                        .foregroundStyle(Self.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                .padding(.trailing, side * 0.26)
            }
        }
        .padding(.horizontal, side * 0.06)
        .padding(.top, side * 0.05)
        .padding(.bottom, side * 0.06)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Self.bone)
    }

    private static let bone = Color(red: 247/255, green: 246/255, blue: 242/255)
    private static let ink = Color(red: 27/255, green: 20/255, blue: 54/255)
    private static let mauve = Color(red: 75/255, green: 63/255, blue: 109/255)
}

#Preview {
    PosterTemplatePreview { purpose, goal, photo in
        PosterA13TemplateView(purpose: purpose, goal: goal, viewProvider: photo)
    }
}
