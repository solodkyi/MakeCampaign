//
//  SilverBlueTemplateView.swift
//  MakeCampaign
//

import SwiftUI

/// `linearSilverBlue_trailingToEdge` — a ticket: brushed steel washing left to
/// right, the goal ruled off between dashed lines, and a full-height photo strip
/// running off the trailing edge.
struct SilverBlueTemplateView: View {
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

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: side * 0.03) {
                    header(side: side)

                    Spacer(minLength: 0)

                    caption(side: side)
                }
                .padding(.horizontal, side * 0.05)
                .padding(.vertical, side * 0.06)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                PosterPhoto(Rectangle(), photo: viewProvider)
                    .frame(width: side * 0.26)
                    .frame(maxHeight: .infinity)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(background)
        }
    }

    private var background: some View {
        LinearGradient(
            stops: [
                .init(color: Color(red: 240/255, green: 241/255, blue: 244/255), location: 0),
                .init(color: Color(red: 199/255, green: 207/255, blue: 218/255), location: 0.55),
                .init(color: Color(red: 123/255, green: 144/255, blue: 171/255), location: 1),
            ],
            startPoint: UnitPoint(x: 0.01, y: 0.41),
            endPoint: UnitPoint(x: 0.99, y: 0.59)
        )
    }

    private func header(side: CGFloat) -> some View {
        let kickerSize = side * 0.022
        let purposeSize = side * 0.054

        return VStack(alignment: .leading, spacing: side * 0.016) {
            Text("збір")
                .font(PosterFont.plexMonoRegular.size(kickerSize))
                .tracking(kickerSize * 0.3)
                .textCase(.uppercase)
                .foregroundStyle(Self.slate)

            Text(purpose)
                .campaignPosterElement(.campaignTitle)
                .font(PosterFont.oswaldMedium.size(purposeSize))
                .lineSpacing(purposeSize * 0.08)
                .foregroundStyle(Self.ink)
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
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
        let labelSize = side * 0.030

        return ruled(side: side) {
            VStack(spacing: side * 0.018) {
                row(label: funding.goalLabel, labelSize: labelSize, side: side) {
                    Text(goal)
                        .campaignPosterElement(.target)
                        .font(PosterFont.plexMonoSemiBold.size(side * 0.056))
                        .foregroundStyle(Self.deepInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }

                if let fraction = funding.fraction {
                    progress(fraction: fraction, side: side)
                }
            }
        }
    }

    /// Досьє не терпить заокруглень: смужка тут — прямий відрізок, а частку
    /// поруч набрано тією ж моноширинною, що й суми.
    private func progress(fraction: Double, side: CGFloat) -> some View {
        let labelSize = side * 0.027

        return HStack(spacing: side * 0.024) {
            PosterProgressBar(
                fraction: fraction,
                shape: Rectangle(),
                height: side * 0.008,
                track: Self.steel.opacity(0.24),
                fill: Self.slate
            )

            if let collected = funding.collected {
                Text(collected)
                    .campaignPosterFundingElement(.collected)
                    .font(PosterFont.plexMonoRegular.size(labelSize))
                    .foregroundStyle(Self.steel)
                    .lineLimit(1)
                    .fixedSize()
            }
        }
    }

    /// Збір закрито: рядок лишається на місці, лише ліворуч тепер стоїть
    /// висновок, а не запит.
    private func finished(side: CGFloat) -> some View {
        let labelSize = side * 0.030

        return ruled(side: side) {
            row(
                label: CampaignPosterFunding.finishedLabel,
                labelSize: labelSize,
                side: side
            ) {
                if let collected = funding.collected {
                    Text(collected)
                        .campaignPosterFundingElement(.collected)
                        .font(PosterFont.plexMonoSemiBold.size(side * 0.056))
                        .foregroundStyle(Self.deepInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }
            .campaignPosterFundingElement(.finished)
        }
    }

    /// Обидва стани — і запит, і висновок — стоять тим самим рядком: етикетка
    /// ліворуч, сума праворуч, між ними розпірка.
    private func row(
        label: String,
        labelSize: CGFloat,
        side: CGFloat,
        @ViewBuilder figure: () -> some View
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: side * 0.02) {
            Text(label)
                .font(PosterFont.plexMonoRegular.size(labelSize))
                .tracking(labelSize * 0.14)
                .textCase(.uppercase)
                .foregroundStyle(Self.steel)

            Spacer(minLength: 0)

            figure()
        }
    }

    /// Обидва стани лежать між тими самими пунктирними лініями, тож
    /// завершення збору не зсуває квиток.
    private func ruled(side: CGFloat, @ViewBuilder content: () -> some View) -> some View {
        content()
            .padding(.vertical, side * 0.024)
            .frame(maxWidth: .infinity)
            .overlay(alignment: .top) { rule(side: side) }
            .overlay(alignment: .bottom) { rule(side: side) }
    }

    private func rule(side: CGFloat) -> some View {
        PosterRule()
            .stroke(
                Self.steel,
                style: StrokeStyle(lineWidth: side * 0.004, dash: [side * 0.012, side * 0.012])
            )
            .frame(height: side * 0.004)
    }

    private static let ink = Color(red: 20/255, green: 32/255, blue: 46/255)
    private static let deepInk = Color(red: 16/255, green: 26/255, blue: 38/255)
    private static let slate = Color(red: 74/255, green: 90/255, blue: 112/255)
    private static let steel = Color(red: 70/255, green: 86/255, blue: 108/255)
}

#Preview {
    PosterTemplatePreview { purpose, funding, photo in
        SilverBlueTemplateView(purpose: purpose, funding: funding, viewProvider: photo)
    }
}
