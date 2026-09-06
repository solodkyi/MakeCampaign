//
//  GreenGradientTemplateView.swift
//  MakeCampaign
//

import SwiftUI

/// `linearGreen_topToBottomTrailing` — a voucher: forest-green header carrying
/// the title, a perforated tear line, then the goal and photo side by side on
/// pale card stock.
struct GreenGradientTemplateView: View {
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
                header(side: side)

                perforation(side: side)

                HStack(alignment: .center, spacing: side * 0.04) {
                    caption(side: side)

                    PosterPhoto(Rectangle(), photo: viewProvider)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .padding(side * 0.05)
                .frame(maxHeight: .infinity)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(Self.card)
        }
    }

    private func header(side: CGFloat) -> some View {
        let kickerSize = side * 0.023
        let purposeSize = side * 0.056

        return VStack(alignment: .leading, spacing: side * 0.02) {
            Text("збір")
                .font(PosterFont.plexMonoRegular.size(kickerSize))
                .tracking(kickerSize * 0.3)
                .textCase(.uppercase)
                .foregroundStyle(Self.lime)

            Text(purpose)
                .campaignPosterElement(.campaignTitle)
                .font(PosterFont.oswaldSemiBold.size(purposeSize))
                .lineSpacing(purposeSize * 0.06)
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, side * 0.06)
        .padding(.top, side * 0.06)
        .padding(.bottom, side * 0.05)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Self.forest)
    }

    /// The tear line: equal marks and gaps, so the header reads as a stub that
    /// could be pulled away from the card below it.
    private func perforation(side: CGFloat) -> some View {
        let dash = side * 0.03
        let count = Int((side / (dash * 2)).rounded(.up)) + 1

        return HStack(spacing: dash) {
            ForEach(0..<count, id: \.self) { _ in
                Rectangle()
                    .fill(Self.forest)
                    .frame(width: dash)
            }
        }
        .frame(height: dash)
        .frame(maxWidth: .infinity, alignment: .leading)
        .clipped()
    }

    @ViewBuilder
    private func caption(side: CGFloat) -> some View {
        if let goal {
            let labelSize = side * 0.022
            let goalSize = side * 0.06

            VStack(alignment: .leading, spacing: side * 0.008) {
                Spacer(minLength: 0)

                Text("ціль збору:")
                    .font(PosterFont.plexMonoRegular.size(labelSize))
                    .tracking(labelSize * 0.16)
                    .textCase(.uppercase)
                    .foregroundStyle(Self.moss)

                Text(goal)
                    .campaignPosterElement(.target)
                    .font(PosterFont.oswaldBold.size(goalSize))
                    .lineSpacing(goalSize * 0.02)
                    .foregroundStyle(Self.darkLeaf)
                    .minimumScaleFactor(0.5)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        }
    }

    private static let card = Color(red: 242/255, green: 245/255, blue: 233/255)
    private static let forest = Color(red: 20/255, green: 61/255, blue: 34/255)
    private static let lime = Color(red: 182/255, green: 224/255, blue: 106/255)
    private static let moss = Color(red: 61/255, green: 107/255, blue: 51/255)
    private static let darkLeaf = Color(red: 20/255, green: 41/255, blue: 26/255)
}

#Preview {
    PosterTemplatePreview { purpose, goal, photo in
        GreenGradientTemplateView(purpose: purpose, goal: goal, viewProvider: photo)
    }
}
