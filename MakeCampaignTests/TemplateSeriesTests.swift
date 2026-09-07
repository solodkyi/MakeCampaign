import Foundation
import Testing

@testable import MakeCampaign

@Suite("Template series")
struct TemplateSeriesTests {
    @Test("A template saved before the second design set existed decodes as series B")
    func legacyTemplateDecodesAsSeriesB() throws {
        // Build the fixture the way an earlier build would have written it:
        // encode a current template and drop the key that build did not know
        // about. Hand-writing the JSON would bake in assumptions about how the
        // gradient and placement enums encode.
        let current = Template(
            name: "15",
            series: .b,
            gradient: .linearCoralTeal,
            imagePlacement: .trailing
        )
        var fields = try #require(
            JSONSerialization.jsonObject(
                with: try JSONEncoder().encode(current)
            ) as? [String: Any]
        )
        #expect(fields.removeValue(forKey: "series") != nil)

        let legacy = try JSONSerialization.data(withJSONObject: fields)
        let template = try JSONDecoder().decode(Template.self, from: legacy)

        #expect(template.series == .b)
        #expect(template.id == "b_linearCoralTeal_trailing")
    }

    @Test("Series round-trips through a save and reload")
    func seriesSurvivesRoundTrip() throws {
        for series in [Template.Series.a, .b] {
            let template = Template(
                name: "1",
                series: series,
                gradient: .blueLinear,
                imagePlacement: .center
            )

            let data = try JSONEncoder().encode(template)
            let decoded = try JSONDecoder().decode(Template.self, from: data)

            #expect(decoded == template)
            #expect(decoded.series == series)
        }
    }

    @Test("The two series are distinct templates for the same gradient and placement")
    func seriesSeparatesOtherwiseIdenticalEntries() {
        let a = Template(name: "1", series: .a, gradient: .blueLinear, imagePlacement: .center)
        let b = Template(name: "1", series: .b, gradient: .blueLinear, imagePlacement: .center)

        // The ids feed the thumbnail cache key, so a collision here would serve
        // one series' artwork for the other.
        #expect(a.id != b.id)
        #expect(a != b)
    }

    @Test("Every catalogue entry is uniquely identified")
    func catalogueIDsAreUnique() {
        let ids = Template.list.map(\.id)

        #expect(Set(ids).count == ids.count)
    }
}
