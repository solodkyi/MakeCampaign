//
//  PosterA02TemplateView.swift
//  MakeCampaign
//

import SwiftUI

/// Набір A, `cyanMagentaRadial_squareTrailing` — the goal figure carries the
/// poster: set enormous and glowing at the top, with the title beneath it as a
/// subtitle and the photo tucked into the bottom corner.
struct PosterA02TemplateView: View {
    let purpose: String
    let funding: CampaignPosterFunding

    var viewProvider: () -> AnyView

    init(
        purpose: String,
        funding: CampaignPosterFunding,
        viewProvider: @escaping () -> some View = { Color.clear }
    ) {
        self.purpose = purpose
        self.funding = funding
        self.viewProvider = { AnyView(viewProvider()) }
    }

    var body: some View {
        GeometryReader { geometry in
            let side = geometry.size.width
            let labelSize = side * 0.031

            VStack(alignment: .leading, spacing: 0) {
                Text("ціль збору:")
                    .font(PosterFont.plexMonoRegular.size(labelSize))
                    .tracking(labelSize * 0.3)
                    .textCase(.uppercase)
                    .foregroundStyle(.white.opacity(0.85))

                if funding.isFinished {
                    finished(side: side)
                } else if let goal = funding.goal {
                    collecting(goal: goal, side: side)
                }

                Text(purpose)
                    .campaignPosterElement(.campaignTitle)
                    .font(PosterFont.oswaldMedium.size(side * 0.046))
                    .lineSpacing(side * 0.046 * 0.12)
                    .foregroundStyle(Self.lilac)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.6)
                    .frame(maxWidth: side * 0.66, alignment: .leading)
                    .padding(.top, side * 0.03)

                PosterPhoto(Rectangle(), photo: viewProvider)
                    .aspectRatio(1.0, contentMode: .fit)
                    .frame(maxWidth: side * 0.56, maxHeight: side * 0.56)
                    .shadow(color: Self.cyan.opacity(0.45), radius: side * 0.06)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .padding(.top, side * 0.04)
            }
            .padding(side * 0.06)
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(background(side: side))
        }
    }

    private func background(side: CGFloat) -> some View {
        RadialGradient(
            stops: [
                .init(color: Self.cyan, location: 0),
                .init(color: Color(red: 75/255, green: 31/255, blue: 158/255), location: 0.48),
                .init(color: Color(red: 10/255, green: 6/255, blue: 22/255), location: 1),
            ],
            center: UnitPoint(x: 0.18, y: 0.12),
            startRadius: 0,
            endRadius: side * 1.2
        )
    }

    private func collecting(goal: String, side: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: side * 0.016) {
            Text(goal)
                .campaignPosterElement(.target)
                .font(PosterFont.oswaldBold.size(side * 0.15))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .padding(.top, side * 0.01)
                .modifier(Glow(side: side))

            if let fraction = funding.fraction {
                progress(fraction: fraction, side: side)
            }
        }
    }

    /// Смужка світиться так само, як цифра над нею: бірюза на тлі й ореол
    /// довкола — інакше на цьому плакаті вона б згасла.
    private func progress(fraction: Double, side: CGFloat) -> some View {
        let labelSize = side * 0.030

        return VStack(alignment: .leading, spacing: side * 0.01) {
            PosterProgressBar(
                fraction: fraction,
                height: side * 0.012,
                track: .white.opacity(0.14),
                fill: Self.cyan
            )
            .shadow(color: Self.cyan.opacity(0.7), radius: side * 0.02)

            if let collected = funding.collected {
                Text("зібрано \(collected)")
                    .campaignPosterFundingElement(.collected)
                    .font(PosterFont.plexMonoRegular.size(labelSize))
                    .tracking(labelSize * 0.14)
                    .textCase(.uppercase)
                    .foregroundStyle(Self.lilac.opacity(0.8))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
        .frame(maxWidth: side * 0.66, alignment: .leading)
    }

    /// Збір закрито: вигук займає місце цифри й світиться тим самим ореолом,
    /// а сума відходить під нього моноширинною.
    private func finished(side: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: side * 0.012) {
            Text(CampaignPosterFunding.finishedLabel.uppercased())
                .campaignPosterFundingElement(.finished)
                .font(PosterFont.oswaldBold.size(side * 0.13))
                .foregroundStyle(Self.cyan)
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .padding(.top, side * 0.01)
                .modifier(Glow(side: side))

            if let collected = funding.collected {
                Text(collected)
                    .campaignPosterFundingElement(.collected)
                    .font(PosterFont.oswaldBold.size(side * 0.07))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
    }

    private struct Glow: ViewModifier {
        let side: CGFloat

        func body(content: Content) -> some View {
            content
                .shadow(color: Self.cyan.opacity(0.85), radius: side * 0.04)
                .shadow(color: .white.opacity(0.35), radius: side * 0.1)
        }

        private static let cyan = Color(red: 26/255, green: 209/255, blue: 224/255)
    }

    private static let cyan = Color(red: 26/255, green: 209/255, blue: 224/255)
    private static let lilac = Color(red: 243/255, green: 230/255, blue: 255/255)
}

#Preview {
    PosterTemplatePreview { purpose, funding, photo in
        PosterA02TemplateView(purpose: purpose, funding: funding, viewProvider: photo)
    }
}
