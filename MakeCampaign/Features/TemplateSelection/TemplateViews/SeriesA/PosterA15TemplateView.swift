//
//  PosterA15TemplateView.swift
//  MakeCampaign
//

import SwiftUI

/// Набір A, `linearCoralTeal_trailing` — coral washing diagonally into teal, the
/// title set very large down the left, and the goal in a dark teal pill.
struct PosterA15TemplateView: View {
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
                    .frame(width: geometry.size.width * 0.58, alignment: .leading)

                PosterPhoto(Rectangle(), photo: viewProvider)
                    .frame(width: geometry.size.width * 0.42)
                    .frame(maxHeight: .infinity)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(background)
        }
    }

    private var background: some View {
        LinearGradient(
            stops: [
                .init(color: Color(red: 255/255, green: 106/255, blue: 77/255), location: 0),
                .init(color: Color(red: 224/255, green: 74/255, blue: 60/255), location: 0.4),
                .init(color: Color(red: 15/255, green: 111/255, blue: 116/255), location: 1),
            ],
            startPoint: UnitPoint(x: 0.05, y: 0.29),
            endPoint: UnitPoint(x: 0.95, y: 0.71)
        )
    }

    private func copy(side: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(purpose.uppercased())
                .campaignPosterElement(.campaignTitle)
                .font(PosterFont.oswaldBold.size(side * 0.076))
                .foregroundStyle(Self.shell)
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.5)
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
            let labelSize = side * 0.022

            VStack(alignment: .leading, spacing: 0) {
                Text("ціль збору:")
                    .font(PosterFont.plexMonoRegular.size(labelSize))
                    .tracking(labelSize * 0.16)
                    .textCase(.uppercase)
                    .foregroundStyle(Self.seafoam)

                Text(goal)
                    .campaignPosterElement(.target)
                    .font(PosterFont.oswaldBold.size(side * 0.064))
                    .lineSpacing(side * 0.064 * 0.02)
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.5)
            }
            .padding(.horizontal, side * 0.03)
            .padding(.vertical, side * 0.024)
            .background(Self.deepTeal, in: Capsule())
        }
    }

    private static let shell = Color(red: 255/255, green: 246/255, blue: 240/255)
    private static let deepTeal = Color(red: 4/255, green: 52/255, blue: 58/255)
    private static let seafoam = Color(red: 143/255, green: 224/255, blue: 216/255)
}

#Preview {
    PosterTemplatePreview { purpose, goal, photo in
        PosterA15TemplateView(purpose: purpose, goal: goal, viewProvider: photo)
    }
}
