//
//  PosterA09TemplateView.swift
//  MakeCampaign
//

import SwiftUI

/// Набір A, `linearSilverBlue_trailingToEdge` — pale steel deepening to slate,
/// the copy down the left with the goal in large Playfair italic, and an inset
/// photo panel casting a shadow back across the page.
struct PosterA09TemplateView: View {
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

            HStack(spacing: 0) {
                copy(side: side)
                    .frame(width: geometry.size.width * 0.52, alignment: .leading)

                PosterPhoto(Rectangle(), photo: viewProvider)
                    .frame(width: geometry.size.width * 0.48)
                    .frame(maxHeight: .infinity)
                    .padding(.vertical, side * 0.06)
                    .shadow(
                        color: Color(red: 23/255, green: 34/255, blue: 47/255).opacity(0.25),
                        radius: side * 0.04,
                        x: -side * 0.01,
                        y: 0
                    )
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(background)
        }
    }

    private var background: some View {
        LinearGradient(
            stops: [
                .init(color: Color(red: 232/255, green: 234/255, blue: 238/255), location: 0),
                .init(color: Color(red: 185/255, green: 195/255, blue: 209/255), location: 0.46),
                .init(color: Color(red: 74/255, green: 108/255, blue: 150/255), location: 1),
            ],
            startPoint: UnitPoint(x: 0.07, y: 0.25),
            endPoint: UnitPoint(x: 0.93, y: 0.75)
        )
    }

    private func copy(side: CGFloat) -> some View {
        let purposeSize = side * 0.056

        return VStack(alignment: .leading, spacing: 0) {
            Text(purpose)
                .campaignPosterElement(.campaignTitle)
                .font(PosterFont.oswaldSemiBold.size(purposeSize))
                .lineSpacing(purposeSize * 0.06)
                .foregroundStyle(Self.ink)
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: side * 0.04)

            caption(side: side)
        }
        .padding(.leading, side * 0.06)
        .padding(.trailing, side * 0.04)
        .padding(.vertical, side * 0.06)
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private func caption(side: CGFloat) -> some View {
        if let goal {
            let labelSize = side * 0.023

            VStack(alignment: .leading, spacing: side * 0.008) {
                Text("ціль збору:")
                    .font(PosterFont.plexMonoRegular.size(labelSize))
                    .tracking(labelSize * 0.2)
                    .textCase(.uppercase)
                    .foregroundStyle(Self.slate)

                Text(goal)
                    .campaignPosterElement(.target)
                    .font(PosterFont.playfairBoldItalic.size(side * 0.1))
                    .foregroundStyle(Self.deepInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
            }
        }
    }

    private static let ink = Color(red: 23/255, green: 34/255, blue: 47/255)
    private static let deepInk = Color(red: 16/255, green: 25/255, blue: 34/255)
    private static let slate = Color(red: 44/255, green: 61/255, blue: 82/255)
}

#Preview {
    PosterTemplatePreview { purpose, goal, photo in
        PosterA09TemplateView(purpose: purpose, goal: goal, viewProvider: photo)
    }
}
