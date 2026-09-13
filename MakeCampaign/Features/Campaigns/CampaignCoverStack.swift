import SwiftUI
import UIKit

/// Де стоїть картка, коли вона на такій-то глибині стоса.
struct CampaignCoverCardPlacement: Equatable {
    let rotationDegrees: Double
    let offset: CGSize
    let scale: CGFloat
    let opacity: Double
    let shadowRadius: CGFloat
    let shadowOpacity: Double
    let shadowOffsetY: CGFloat
}

/// Геометрія стоса обкладинок.
///
/// Стос нічого не додає і не видаляє: усі зразки живуть у ньому завжди, а
/// зміна чільної картки лише пересуває кожну на глибину нижче. Тому анімація
/// — це чиста інтерполяція трансформацій, без переходів появи/зникнення, які
/// в SwiftUI найлегше зламати.
///
/// Кругообіг однієї картки при п'яти зразках:
/// `0` чоло → `4` відлітає вгору і згасає → `3` невидимкою повертається
/// назад → `2` проявляється позаду ліворуч → `1` позаду праворуч → `0` знову
/// чоло.
enum CampaignCoverStackLayout {
    /// Скільки карток стос показує одночасно.
    static let visibleDepth = 3

    /// Найменший каталог: три видимі картки, одна в резерві, одна відлітає.
    static let minimumSampleCount = visibleDepth + 2

    static func depth(of index: Int, frontIndex: Int, count: Int) -> Int {
        guard count > 0 else { return 0 }
        return ((index - frontIndex) % count + count) % count
    }

    static func placement(
        depth: Int,
        count: Int,
        side: CGFloat
    ) -> CampaignCoverCardPlacement {
        if depth == leavingDepth(count: count) {
            return CampaignCoverCardPlacement(
                rotationDegrees: -5,
                offset: CGSize(width: 0, height: -side * 0.42),
                scale: 1.14,
                opacity: 0,
                shadowRadius: 0,
                shadowOpacity: 0,
                shadowOffsetY: 0
            )
        }

        switch depth {
        case 0:
            return CampaignCoverCardPlacement(
                rotationDegrees: 0,
                offset: CGSize(width: 0, height: -side * 0.04),
                scale: 1,
                opacity: 1,
                shadowRadius: side * 0.09,
                shadowOpacity: 0.18,
                shadowOffsetY: side * 0.08
            )
        case 1:
            return CampaignCoverCardPlacement(
                rotationDegrees: 7,
                offset: CGSize(width: side * 0.075, height: side * 0.06),
                scale: 0.94,
                opacity: 1,
                shadowRadius: side * 0.05,
                shadowOpacity: 0.10,
                shadowOffsetY: side * 0.04
            )
        case 2:
            return CampaignCoverCardPlacement(
                rotationDegrees: -8,
                offset: CGSize(width: -side * 0.075, height: side * 0.06),
                scale: 0.94,
                opacity: 1,
                shadowRadius: side * 0.05,
                shadowOpacity: 0.08,
                shadowOffsetY: side * 0.04
            )
        default:
            // Резерв: чекає позаду стоса невидимим, поки не настане черга.
            return CampaignCoverCardPlacement(
                rotationDegrees: -8,
                offset: CGSize(width: -side * 0.075, height: side * 0.06),
                scale: 0.86,
                opacity: 0,
                shadowRadius: 0,
                shadowOpacity: 0,
                shadowOffsetY: 0
            )
        }
    }

    /// Картка, що відлітає, має пройти поверх стоса, а не за ним.
    static func zIndex(depth: Int, count: Int) -> Double {
        depth == leavingDepth(count: count)
            ? Double(count + 1)
            : Double(count - depth)
    }

    /// Каталог, менший за `visibleDepth`, нікуди не відпускає чільну картку:
    /// нема куди — усі глибини видимі.
    private static func leavingDepth(count: Int) -> Int {
        count > visibleDepth ? count - 1 : .max
    }
}

struct CampaignCoverStack: View {
    let samples: [CampaignCoverSample]
    let covers: [CampaignCoverSample.ID: UIImage]
    let frontIndex: Int
    var side: CGFloat = 200

    @Environment(\.rbThemePalette) private var palette

    private var cornerRadius: CGFloat { side * 0.09 }

    var body: some View {
        ZStack {
            ForEach(Array(samples.enumerated()), id: \.element.id) { index, sample in
                let depth = CampaignCoverStackLayout.depth(
                    of: index,
                    frontIndex: frontIndex,
                    count: samples.count
                )
                let placement = CampaignCoverStackLayout.placement(
                    depth: depth,
                    count: samples.count,
                    side: side
                )

                card(for: sample)
                    .frame(width: side, height: side)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: cornerRadius,
                            style: .continuous
                        )
                    )
                    .shadow(
                        color: .black.opacity(placement.shadowOpacity),
                        radius: placement.shadowRadius,
                        x: 0,
                        y: placement.shadowOffsetY
                    )
                    .scaleEffect(placement.scale)
                    .rotationEffect(.degrees(placement.rotationDegrees))
                    .offset(placement.offset)
                    .opacity(placement.opacity)
                    .zIndex(
                        CampaignCoverStackLayout.zIndex(
                            depth: depth,
                            count: samples.count
                        )
                    )
            }
        }
        .frame(width: side * 1.25, height: side * 1.18)
        .accessibilityElement(children: .ignore)
        .accessibilityIdentifier("empty-state-cover-stack")
        .accessibilityLabel("Приклади обкладинок")
        .accessibilityValue(frontSampleLabel)
    }

    @ViewBuilder
    private func card(for sample: CampaignCoverSample) -> some View {
        if let cover = covers[sample.id] {
            Image(uiImage: cover)
                .resizable()
                .interpolation(.high)
                .scaledToFill()
        } else {
            // Поки обкладинки готуються, стос уже стоїть у потрібній формі —
            // щоб поява картинок нічого не зсувала.
            palette.paper
                .overlay {
                    RoundedRectangle(
                        cornerRadius: cornerRadius,
                        style: .continuous
                    )
                    .strokeBorder(palette.border, lineWidth: 1)
                }
        }
    }

    private var frontSampleLabel: String {
        guard !samples.isEmpty else { return "" }
        let index = ((frontIndex % samples.count) + samples.count) % samples.count
        return samples[index].purpose
    }
}
