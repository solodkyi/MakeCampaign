//
//  PosterTemplatePreview.swift
//  MakeCampaign
//

import SwiftUI

/// Shared preview scaffold for the poster templates.
///
/// Renders a template across the three ratios the designs are drawn for —
/// square, portrait and story — plus the goal-less variant, which is the branch
/// most easily broken when a layout is tuned for the common case.
struct PosterTemplatePreview<Template: View>: View {
    private let template: (String, String?, @escaping () -> AnyView) -> Template

    init(@ViewBuilder template: @escaping (String, String?, @escaping () -> AnyView) -> Template) {
        self.template = template
    }

    private static var purpose: String { "Збір на пікап для 160-ї ОМБр" }
    private static var goal: String { "250 000 грн." }

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
                        template(Self.purpose, Self.goal) { AnyView(photo) }
                            .frame(width: format.size.width, height: format.size.height)
                    }
                }

                labelled("square · без цілі") {
                    template(Self.purpose, nil) { AnyView(photo) }
                        .frame(width: 300, height: 300)
                }

                labelled("square · довга назва") {
                    template("Збір на евакуаційний транспорт та тепловізори для 160-ї окремої механізованої бригади", Self.goal) { AnyView(photo) }
                        .frame(width: 300, height: 300)
                }
            }
            .padding()
        }
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
