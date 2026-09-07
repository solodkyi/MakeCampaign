//
//  PosterA06TemplateView.swift
//  MakeCampaign
//

import SwiftUI

/// Набір A, `tealPurpleRadial_roundedTrailing` — a smoked glass card floating on
/// a teal-to-indigo bloom, holding the title, the photo and an oversized goal.
struct PosterA06TemplateView: View {
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

            VStack(alignment: .leading, spacing: side * 0.035) {
                Text(purpose.uppercased())
                    .campaignPosterElement(.campaignTitle)
                    .font(PosterFont.oswaldMedium.size(side * 0.048))
                    .lineSpacing(side * 0.048 * 0.1)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.6)
                    .frame(maxWidth: .infinity, alignment: .leading)

                PosterPhoto(
                    RoundedRectangle(cornerRadius: side * 0.035, style: .continuous),
                    photo: viewProvider
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                caption(side: side)
            }
            .padding(side * 0.05)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(
                Color(red: 12/255, green: 8/255, blue: 24/255).opacity(0.72),
                in: RoundedRectangle(cornerRadius: side * 0.05, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: side * 0.05, style: .continuous)
                    .stroke(.white.opacity(0.16), lineWidth: side * 0.0025)
            }
            .padding(side * 0.05)
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(background(side: side))
        }
    }

    private func background(side: CGFloat) -> some View {
        RadialGradient(
            stops: [
                .init(color: Color(red: 23/255, green: 182/255, blue: 168/255), location: 0),
                .init(color: Color(red: 75/255, green: 46/255, blue: 143/255), location: 0.55),
                .init(color: Color(red: 21/255, green: 13/255, blue: 44/255), location: 1),
            ],
            center: UnitPoint(x: 0.8, y: 0.15),
            startRadius: 0,
            endRadius: side * 1.1
        )
    }

    @ViewBuilder
    private func caption(side: CGFloat) -> some View {
        if let goal {
            let labelSize = side * 0.024

            VStack(alignment: .leading, spacing: side * 0.008) {
                Text("ціль збору:")
                    .font(PosterFont.plexMonoRegular.size(labelSize))
                    .tracking(labelSize * 0.22)
                    .textCase(.uppercase)
                    .foregroundStyle(Self.mint)

                Text(goal)
                    .campaignPosterElement(.target)
                    .font(PosterFont.oswaldBold.size(side * 0.11))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
            }
        }
    }

    private static let mint = Color(red: 124/255, green: 238/255, blue: 222/255)
}

#Preview {
    PosterTemplatePreview { purpose, goal, photo in
        PosterA06TemplateView(purpose: purpose, goal: goal, viewProvider: photo)
    }
}
