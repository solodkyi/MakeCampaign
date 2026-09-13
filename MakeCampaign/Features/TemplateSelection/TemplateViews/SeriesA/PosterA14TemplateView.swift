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
        if funding.isFinished {
            finished(side: side)
        } else if let goal = funding.goal {
            collecting(goal: goal, side: side)
        }
    }

    private func collecting(goal: String, side: CGFloat) -> some View {
        let labelSize = side * 0.031

        return VStack(alignment: .leading, spacing: side * 0.014) {
            HStack(alignment: .firstTextBaseline, spacing: side * 0.022) {
                Text(funding.goalLabel)
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
            .modifier(Pill(side: side))

            if let fraction = funding.fraction {
                progress(fraction: fraction, side: side)
            }
        }
    }

    /// Смужка теж капсула — плакат складений із заокруглених форм, тож
    /// прямокутник тут читався б як чуже тіло.
    private func progress(fraction: Double, side: CGFloat) -> some View {
        let labelSize = side * 0.027

        return VStack(alignment: .leading, spacing: side * 0.008) {
            PosterProgressBar(
                fraction: fraction,
                height: side * 0.012,
                track: .white.opacity(0.24),
                fill: .white
            )

            if let collected = funding.collected {
                Text("зібрано \(collected)")
                    .campaignPosterFundingElement(.collected)
                    .font(PosterFont.plexMonoRegular.size(labelSize))
                    .tracking(labelSize * 0.14)
                    .textCase(.uppercase)
                    .foregroundStyle(.white.opacity(0.72))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
        .padding(.horizontal, side * 0.03)
        .frame(maxWidth: side * 0.62, alignment: .leading)
    }

    /// Збір закрито: біла капсула лишається білою, але тепер несе вигук, а
    /// сума виходить із неї назовні — на індиго.
    private func finished(side: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: side * 0.014) {
            Text(CampaignPosterFunding.finishedLabel)
                .campaignPosterFundingElement(.finished)
                .font(PosterFont.oswaldBold.size(side * 0.05))
                .foregroundStyle(Self.indigo)
                .modifier(Pill(side: side))

            if let collected = funding.collected {
                Text(collected)
                    .campaignPosterFundingElement(.collected)
                    .font(PosterFont.oswaldBold.size(side * 0.066))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(.horizontal, side * 0.03)
            }
        }
    }

    private struct Pill: ViewModifier {
        let side: CGFloat

        func body(content: Content) -> some View {
            content
                .padding(.horizontal, side * 0.03)
                .padding(.vertical, side * 0.022)
                .background(.white, in: Capsule())
        }
    }

    private static let indigo = Color(red: 25/255, green: 29/255, blue: 77/255)
    private static let periwinkle = Color(red: 53/255, green: 64/255, blue: 127/255)
}

#Preview {
    PosterTemplatePreview { purpose, funding, photo in
        PosterA14TemplateView(purpose: purpose, funding: funding, viewProvider: photo)
    }
}
