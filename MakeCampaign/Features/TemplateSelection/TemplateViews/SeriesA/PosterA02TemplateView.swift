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
            let labelSize = side * 0.023

            VStack(alignment: .leading, spacing: 0) {
                Text("ціль збору:")
                    .font(PosterFont.plexMonoRegular.size(labelSize))
                    .tracking(labelSize * 0.3)
                    .textCase(.uppercase)
                    .foregroundStyle(.white.opacity(0.85))

                if let goal {
                    Text(goal)
                        .campaignPosterElement(.target)
                        .font(PosterFont.oswaldBold.size(side * 0.15))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.4)
                        .padding(.top, side * 0.01)
                        .shadow(color: Self.cyan.opacity(0.85), radius: side * 0.04)
                        .shadow(color: .white.opacity(0.35), radius: side * 0.1)
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

    private static let cyan = Color(red: 26/255, green: 209/255, blue: 224/255)
    private static let lilac = Color(red: 243/255, green: 230/255, blue: 255/255)
}

#Preview {
    PosterTemplatePreview { purpose, goal, photo in
        PosterA02TemplateView(purpose: purpose, goal: goal, viewProvider: photo)
    }
}
