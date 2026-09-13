//
//  RedBlackGradientTemplateView.swift
//  MakeCampaign
//

import SwiftUI

/// `radialRedBlack_topToEdge` — the photo runs to the top edge under a red
/// halftone screen, with an oversized goal figure leading the block beneath it.
///
/// Here the goal is set above the title: the figure is the loudest element in
/// the composition and the title reads as its caption.
struct RedBlackGradientTemplateView: View {
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

            VStack(alignment: .leading, spacing: 0) {
                PosterPhoto(Rectangle(), photo: viewProvider)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay { halftone(side: side) }

                caption(side: side)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(Self.soot)
        }
    }

    /// The dot screen laid over the photo. Pitch scales with the poster so the
    /// texture reads the same from thumbnail to export.
    private func halftone(side: CGFloat) -> some View {
        let pitch = side * 0.024
        let radius = pitch * 0.11

        return Canvas { context, size in
            var y = pitch / 2
            while y < size.height + pitch {
                var x = pitch / 2
                while x < size.width + pitch {
                    context.fill(
                        Path(
                            ellipseIn: CGRect(
                                x: x - radius, y: y - radius,
                                width: radius * 2, height: radius * 2
                            )
                        ),
                        with: .color(Self.crimson)
                    )
                    x += pitch
                }
                y += pitch
            }
        }
        .opacity(0.55)
        .allowsHitTesting(false)
    }

    private func caption(side: CGFloat) -> some View {
        let purposeSize = side * 0.044

        return VStack(alignment: .leading, spacing: side * 0.024) {
            if funding.isFinished {
                finished(side: side)
            } else if let goal = funding.goal {
                collecting(goal: goal, side: side)
            }

            Text(purpose.uppercased())
                .campaignPosterElement(.campaignTitle)
                .font(PosterFont.oswaldRegular.size(purposeSize))
                .tracking(purposeSize * 0.04)
                .lineSpacing(purposeSize * 0.16)
                .foregroundStyle(Self.bone)
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, side * 0.06)
        .padding(.trailing, side * 0.3)
        .padding(.top, side * 0.05)
        .padding(.bottom, side * 0.06)
    }

    private func collecting(goal: String, side: CGFloat) -> some View {
        let labelSize = side * 0.031

        return VStack(alignment: .leading, spacing: side * 0.006) {
            Text("ціль збору:")
                .font(PosterFont.plexMonoRegular.size(labelSize))
                .tracking(labelSize * 0.2)
                .textCase(.uppercase)
                .foregroundStyle(Self.flare)

            Text(goal)
                .campaignPosterElement(.target)
                .font(PosterFont.oswaldBold.size(side * 0.1))
                .foregroundStyle(Self.crimson)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            if let fraction = funding.fraction {
                progress(fraction: fraction, side: side)
            }
        }
    }

    /// На сажі смужка йде від багряного до спалаху — той самий перехід, що
    /// веде око від цілі до назви.
    private func progress(fraction: Double, side: CGFloat) -> some View {
        let labelSize = side * 0.027

        return VStack(alignment: .leading, spacing: side * 0.01) {
            PosterProgressBar(
                fraction: fraction,
                shape: Rectangle(),
                height: side * 0.01,
                track: Self.bone.opacity(0.16),
                fill: Self.crimson
            )

            if let collected = funding.collected {
                Text("зібрано \(collected)")
                    .campaignPosterFundingElement(.collected)
                    .font(PosterFont.plexMonoRegular.size(labelSize))
                    .tracking(labelSize * 0.16)
                    .textCase(.uppercase)
                    .foregroundStyle(Self.flare)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
        .padding(.top, side * 0.012)
    }

    /// Збір закрито: багрянець із цифри перебирається на плашку, і вигук
    /// стоїть там, де щойно стояла ціль.
    private func finished(side: CGFloat) -> some View {
        let labelSize = side * 0.031

        return VStack(alignment: .leading, spacing: side * 0.012) {
            Text(CampaignPosterFunding.finishedLabel)
                .campaignPosterFundingElement(.finished)
                .font(PosterFont.plexMonoRegular.size(labelSize))
                .tracking(labelSize * 0.2)
                .textCase(.uppercase)
                .foregroundStyle(Self.soot)
                .padding(.horizontal, side * 0.02)
                .padding(.vertical, side * 0.009)
                .background(Self.crimson)

            if let collected = funding.collected {
                Text(collected)
                    .campaignPosterFundingElement(.collected)
                    .font(PosterFont.oswaldBold.size(side * 0.1))
                    .foregroundStyle(Self.bone)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
    }

    private static let soot = Color(red: 12/255, green: 10/255, blue: 10/255)
    private static let crimson = Color(red: 200/255, green: 32/255, blue: 44/255)
    private static let flare = Color(red: 255/255, green: 90/255, blue: 90/255)
    private static let bone = Color(red: 242/255, green: 239/255, blue: 233/255)
}

#Preview {
    PosterTemplatePreview { purpose, funding, photo in
        RedBlackGradientTemplateView(purpose: purpose, funding: funding, viewProvider: photo)
    }
}
