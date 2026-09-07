//
//  PosterA03TemplateView.swift
//  MakeCampaign
//

import SwiftUI

/// Набір A, `linearPurple_topCenter` — an editorial page: cream stock under a
/// faint dot screen, the photo filling the upper half, and the title set large
/// in Playfair with the goal ruled off beneath it in italic.
struct PosterA03TemplateView: View {
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
                PosterPhoto(Rectangle(), photo: viewProvider)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, side * 0.05)
                    .padding(.top, side * 0.05)

                caption(side: side)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background {
                Self.cream.overlay {
                    PosterDotScreen(
                        color: Self.violet,
                        pitch: side * 0.026,
                        radius: side * 0.0024
                    )
                    .opacity(0.14)
                }
            }
        }
    }

    private func caption(side: CGFloat) -> some View {
        let purposeSize = side * 0.086

        return VStack(alignment: .leading, spacing: 0) {
            Text(purpose)
                .campaignPosterElement(.campaignTitle)
                .font(PosterFont.playfairExtraBold.size(purposeSize))
                .foregroundStyle(Self.violet)
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.5)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let goal {
                let labelSize = side * 0.026

                HStack(alignment: .firstTextBaseline, spacing: side * 0.024) {
                    Text("ціль збору:")
                        .font(PosterFont.plexMonoRegular.size(labelSize))
                        .tracking(labelSize * 0.14)
                        .textCase(.uppercase)
                        .foregroundStyle(Self.aubergine)

                    Text(goal)
                        .campaignPosterElement(.target)
                        .font(PosterFont.playfairBoldItalic.size(side * 0.08))
                        .foregroundStyle(Self.nearBlack)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                .padding(.top, side * 0.022)
                .padding(.trailing, side * 0.26)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Self.violet)
                        .frame(height: side * 0.005)
                }
                .padding(.top, side * 0.026)
            }
        }
        .padding(.horizontal, side * 0.05)
        .padding(.top, side * 0.04)
        .padding(.bottom, side * 0.05)
    }

    private static let cream = Color(red: 246/255, green: 241/255, blue: 224/255)
    private static let violet = Color(red: 107/255, green: 47/255, blue: 122/255)
    private static let aubergine = Color(red: 58/255, green: 32/255, blue: 54/255)
    private static let nearBlack = Color(red: 34/255, green: 18/255, blue: 25/255)
}

#Preview {
    PosterTemplatePreview { purpose, goal, photo in
        PosterA03TemplateView(purpose: purpose, goal: goal, viewProvider: photo)
    }
}
