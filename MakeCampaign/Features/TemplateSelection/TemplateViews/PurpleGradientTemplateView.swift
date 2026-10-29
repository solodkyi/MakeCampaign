//
//  PurpleGradientTemplateView.swift
//  MakeCampaign
//

import SwiftUI

/// `linearPurple_topCenter` — the photo runs full bleed across the top under a
/// deepening plum scrim, with the campaign data set on solid plum beneath it.
///
/// The scrim is what makes the seam between photo and panel read as one surface,
/// so it darkens to nearly the panel colour at its foot.
struct PurpleGradientTemplateView: View {
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

            VStack(spacing: 0) {
                photo
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                caption(side: side)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(Self.plum)
        }
    }

    private var photo: some View {
        PosterPhoto(Rectangle(), photo: viewProvider)
            .overlay {
                LinearGradient(
                    colors: [Self.plum.opacity(0.25), Self.plum.opacity(0.85)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)
            }
    }

    private func caption(side: CGFloat) -> some View {
        let purposeSize = side * 0.056

        return VStack(alignment: .leading, spacing: side * 0.03) {
            Text(purpose)
                .campaignPosterElement(.campaignTitle)
                .font(PosterFont.oswaldMedium.size(purposeSize))
                .lineSpacing(purposeSize * 0.08)
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity, alignment: .leading)

            if funding.isFinished {
                finished(side: side)
            } else if let goal = funding.goal {
                collecting(goal: goal, side: side)
            }
        }
        .padding(.horizontal, side * 0.06)
        .padding(.top, side * 0.05)
        .padding(.bottom, side * 0.06)
    }

    private func collecting(goal: String, side: CGFloat) -> some View {
        let labelSize = side * 0.031

        return VStack(alignment: .leading, spacing: side * 0.026) {
            VStack(alignment: .leading, spacing: side * 0.008) {
                HStack(alignment: .firstTextBaseline, spacing: side * 0.03) {
                    Text(funding.goalLabel)
                        .font(PosterFont.plexMonoRegular.size(labelSize))
                        .tracking(labelSize * 0.2)
                        .textCase(.uppercase)
                        .foregroundStyle(Self.lilac)

                    Text(goal)
                        .campaignPosterElement(.target)
                        .font(PosterFont.oswaldBold.size(side * 0.08))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }

                if let supportingGoal = funding.supportingGoal {
                    Text(supportingGoal)
                        .font(PosterFont.plexMonoRegular.size(labelSize * 0.86))
                        .foregroundStyle(.white.opacity(0.72))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }

            if let fraction = funding.fraction {
                progress(fraction: fraction, side: side)
            }
        }
        .modifier(RuledPanel(side: side))
    }

    /// Смужка бузкова на плямі сливи — той самий акцент, яким набрана
    /// етикетка над сумою, тож поступ читається як частина панелі.
    private func progress(fraction: Double, side: CGFloat) -> some View {
        let labelSize = side * 0.028

        return VStack(alignment: .leading, spacing: side * 0.014) {
            PosterProgressBar(
                fraction: fraction,
                height: side * 0.014,
                track: .white.opacity(0.16),
                fill: Self.lilac
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
    }

    /// Збір закрито: панель віддає бузок під суцільну плашку, а «Зібрано!»
    /// стає тим написом, який раніше тримала етикетка цілі.
    private func finished(side: CGFloat) -> some View {
        let labelSize = side * 0.031

        return HStack(alignment: .firstTextBaseline, spacing: side * 0.03) {
            Text(CampaignPosterFunding.finishedLabel)
                .campaignPosterFundingElement(.finished)
                .font(PosterFont.plexMonoRegular.size(labelSize))
                .tracking(labelSize * 0.2)
                .textCase(.uppercase)
                .foregroundStyle(Self.plum)
                .padding(.horizontal, side * 0.024)
                .padding(.vertical, side * 0.012)
                .background(Self.lilac, in: Capsule())

            if let collected = funding.collected {
                Text(collected)
                    .campaignPosterFundingElement(.collected)
                    .font(PosterFont.oswaldBold.size(side * 0.08))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
        .modifier(RuledPanel(side: side))
    }

    /// Обидва стани висять під тією самою волосяною лінією, що відділяє суму
    /// від назви.
    private struct RuledPanel: ViewModifier {
        let side: CGFloat

        func body(content: Content) -> some View {
            content
                .padding(.top, side * 0.03)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(.white.opacity(0.35))
                        .frame(height: side * 0.002)
                }
        }
    }

    private static let plum = Color(red: 43/255, green: 17/255, blue: 80/255)
    private static let lilac = Color(red: 201/255, green: 166/255, blue: 255/255)
}

#Preview {
    PosterTemplatePreview { purpose, funding, photo in
        PurpleGradientTemplateView(purpose: purpose, funding: funding, viewProvider: photo)
    }
}
