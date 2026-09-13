//
//  PosterTemplatePreview.swift
//  MakeCampaign
//

import SwiftUI

/// Shared preview scaffold for the poster templates.
///
/// Renders a template across the three ratios the designs are drawn for —
/// square, portrait and story — then across the funding states, which are the
/// branches most easily broken when a layout is tuned for the common case: no
/// goal at all, a goal with no jar behind it, a jar part-way there, and a
/// finished collection.
struct PosterTemplatePreview<Template: View>: View {
    private let template: (String, CampaignPosterFunding, @escaping () -> AnyView) -> Template

    init(
        @ViewBuilder template: @escaping (
            String,
            CampaignPosterFunding,
            @escaping () -> AnyView
        ) -> Template
    ) {
        self.template = template
    }

    private static var purpose: String { "Збір на пікап для 160-ї ОМБр" }

    private static var goalOnly: CampaignPosterFunding {
        CampaignPosterFunding(
            goal: "250 000 грн.",
            collected: nil,
            fraction: nil,
            isFinished: false
        )
    }

    private static var partway: CampaignPosterFunding {
        CampaignPosterFunding(
            goal: "250 000 грн.",
            collected: "162 500 грн.",
            fraction: 0.65,
            isFinished: false
        )
    }

    private static var barelyStarted: CampaignPosterFunding {
        CampaignPosterFunding(
            goal: "250 000 грн.",
            collected: "7 500 грн.",
            fraction: 0.03,
            isFinished: false
        )
    }

    private static var finished: CampaignPosterFunding {
        CampaignPosterFunding(
            goal: "250 000 грн.",
            collected: "250 000 грн.",
            fraction: 1,
            isFinished: true
        )
    }

    private static var formats: [(name: String, size: CGSize)] {
        [
            ("square 1080×1080", CGSize(width: 300, height: 300)),
            ("portrait 1080×1350", CGSize(width: 300, height: 375)),
            ("story 1080×1920", CGSize(width: 280, height: 498)),
        ]
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                ForEach(Self.formats, id: \.name) { format in
                    labelled(format.name) {
                        template(Self.purpose, Self.partway) { AnyView(photo) }
                            .frame(width: format.size.width, height: format.size.height)
                    }
                }

                labelled("square · ціль без банки") {
                    square(Self.goalOnly)
                }

                labelled("square · щойно почали") {
                    square(Self.barelyStarted)
                }

                labelled("square · зібрано") {
                    square(Self.finished)
                }

                labelled("story · зібрано") {
                    template(Self.purpose, Self.finished) { AnyView(photo) }
                        .frame(width: 280, height: 498)
                }

                labelled("square · без цілі") {
                    square(.none)
                }

                labelled("square · довга назва") {
                    template(
                        "Збір на евакуаційний транспорт та тепловізори для 160-ї окремої механізованої бригади",
                        Self.partway
                    ) { AnyView(photo) }
                        .frame(width: 300, height: 300)
                }
            }
            .padding()
        }
    }

    private func square(_ funding: CampaignPosterFunding) -> some View {
        template(Self.purpose, funding) { AnyView(photo) }
            .frame(width: 300, height: 300)
    }

    private func labelled(_ name: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(spacing: 8) {
            Text(name)
                .font(.caption)
                .foregroundStyle(.secondary)
            content()
        }
    }

    @ViewBuilder
    private var photo: some View {
        if let data = Campaign.mock1.image?.raw, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            Color.gray
        }
    }
}
