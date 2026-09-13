import SwiftUI

/// Усе, що плакат знає про гроші збору.
///
/// Раніше шаблон отримував саму лише відформатовану ціль. Тепер він отримує
/// увесь грошовий стан, бо кожен шаблон малює і поступ, і завершення власною
/// мовою — а не спільним віджетом, накладеним поверх чужої композиції.
struct CampaignPosterFunding: Equatable, Sendable {
    /// Відформатована ціль збору, якщо її задано.
    let goal: String?

    /// Відформатована зібрана сума. Є лише тоді, коли банку підключено
    /// й дані вже прийшли.
    let collected: String?

    /// Частка цілі від нуля до одиниці. Є лише тоді, коли відомі й ціль,
    /// і зібране, тож смужка поступу з'являється разом із нею.
    let fraction: Double?

    /// Збір завершено: ціль узято, банку закрито, або так вирішив автор.
    let isFinished: Bool

    /// Плакат без жодних сум — так виглядає чернетка, у якій ще нічого не
    /// заповнили.
    static let none = Self(goal: nil, collected: nil, fraction: nil, isFinished: false)

    init(goal: String?, collected: String?, fraction: Double?, isFinished: Bool) {
        self.goal = goal
        self.collected = collected
        self.fraction = fraction
        self.isFinished = isFinished
    }

    init(campaign: Campaign) {
        self.init(
            goal: campaign.target?.formattedAmount.appendingCurrency,
            collected: campaign.collected?.formattedAmount.appendingCurrency,
            fraction: campaign.fundedFraction,
            isFinished: campaign.isFinished
        )
    }

    /// Підпис, який шаблон ставить над завершеним збором.
    static let finishedLabel = "Зібрано!"

    /// Смужку поступу видно лише в незавершеному зборі: у завершеному її місце
    /// займає власний фінальний підпис шаблону.
    var showsProgress: Bool {
        !isFinished && fraction != nil
    }
}

/// Частини плаката, які показують гроші, але яких не можна торкнутись у
/// редакторі: зібране й поступ приходять із банки, а не з полів автора. Тому
/// вони не належать до `CampaignPosterElement` — лишається сам ідентифікатор,
/// щоб тести знали, куди дивитись.
enum CampaignPosterFundingElement: String {
    case collected
    case progress
    case finished

    var accessibilityIdentifier: String {
        "poster-funding-\(rawValue)"
    }
}

extension View {
    func campaignPosterFundingElement(
        _ element: CampaignPosterFundingElement
    ) -> some View {
        accessibilityIdentifier(element.accessibilityIdentifier)
    }
}

/// Смужка поступу в стилі, який задає шаблон.
///
/// Геометрія тут спільна — доріжка, заповнення, форма кінців. Кольори й
/// товщину кожен шаблон передає свої, бо смужка має належати плакату, а не
/// виглядати на ньому чужою.
struct PosterProgressBar<BarShape: Shape>: View {
    let fraction: Double
    let shape: BarShape
    let height: CGFloat
    let track: Color
    let fill: Color

    init(
        fraction: Double,
        shape: BarShape = Capsule(),
        height: CGFloat,
        track: Color,
        fill: Color
    ) {
        self.fraction = fraction
        self.shape = shape
        self.height = height
        self.track = track
        self.fill = fill
    }

    var body: some View {
        GeometryReader { geometry in
            shape
                .fill(track)
                .overlay(alignment: .leading) {
                    shape
                        .fill(self.fill)
                        .frame(
                            width: geometry.size.width * min(max(fraction, 0), 1)
                        )
                }
        }
        .frame(height: height)
        .campaignPosterFundingElement(.progress)
    }
}
