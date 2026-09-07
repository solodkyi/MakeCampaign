//
//  PosterA10TemplateView.swift
//  MakeCampaign
//

import SwiftUI

/// Набір A, `radialRedBlack_topToEdge` — the photo runs to the top edge and the
/// copy sits on a black foot that fades up into it, the title set in oblique
/// caps.
struct PosterA10TemplateView: View {
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

                caption(side: side)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(background(side: side))
        }
    }

    private func background(side: CGFloat) -> some View {
        RadialGradient(
            stops: [
                .init(color: Color(red: 200/255, green: 32/255, blue: 44/255), location: 0),
                .init(color: Color(red: 91/255, green: 10/255, blue: 18/255), location: 0.45),
                .init(color: Self.soot, location: 1),
            ],
            center: UnitPoint(x: 0.5, y: 0),
            startRadius: 0,
            endRadius: side * 0.9
        )
    }

    private func caption(side: CGFloat) -> some View {
        let purposeSize = side * 0.064

        return VStack(alignment: .leading, spacing: 0) {
            Text(purpose.uppercased())
                .campaignPosterElement(.campaignTitle)
                .font(PosterFont.oswaldBold.size(purposeSize))
                .italic()
                .lineSpacing(purposeSize * 0.02)
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let goal {
                let labelSize = side * 0.024

                HStack(alignment: .firstTextBaseline, spacing: side * 0.024) {
                    Text("ціль збору:")
                        .font(PosterFont.plexMonoRegular.size(labelSize))
                        .tracking(labelSize * 0.16)
                        .textCase(.uppercase)
                        .foregroundStyle(Self.flare)

                    Text(goal)
                        .campaignPosterElement(.target)
                        .font(PosterFont.oswaldBold.size(side * 0.086))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                .padding(.top, side * 0.024)
            }
        }
        .padding(.leading, side * 0.06)
        .padding(.trailing, side * 0.3)
        .padding(.top, side * 0.05)
        .padding(.bottom, side * 0.06)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            LinearGradient(
                stops: [
                    .init(color: Self.soot.opacity(0), location: 0),
                    .init(color: Self.soot, location: 0.22),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private static let soot = Color(red: 11/255, green: 7/255, blue: 8/255)
    private static let flare = Color(red: 255/255, green: 138/255, blue: 138/255)
}

#Preview {
    PosterTemplatePreview { purpose, goal, photo in
        PosterA10TemplateView(purpose: purpose, goal: goal, viewProvider: photo)
    }
}
