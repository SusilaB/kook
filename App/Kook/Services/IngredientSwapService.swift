import Foundation

struct VerdictRuleFile: Codable {
    let version: Int
    let organicPremiumThresholdPercent: Double
    let rules: [Rule]

    enum CodingKeys: String, CodingKey {
        case version, rules
        case organicPremiumThresholdPercent = "organic_premium_threshold_percent"
    }

    struct Rule: Codable {
        let id: String
        let fromIngredientId: String
        let toIngredientId: String
        let verdict: HealthVerdictKind
        let reason: String
        let sources: [String]

        enum CodingKeys: String, CodingKey {
            case id, verdict, reason, sources
            case fromIngredientId = "from_ingredient_id"
            case toIngredientId = "to_ingredient_id"
        }
    }
}

struct HealthVerdictRules {
    let rules: [VerdictRuleFile.Rule]
    let organicPremiumThresholdPercent: Double

    init(file: VerdictRuleFile? = BundleJSON.load("health_verdict_rules", as: VerdictRuleFile.self)) {
        self.rules = file?.rules ?? []
        self.organicPremiumThresholdPercent = file?.organicPremiumThresholdPercent ?? 25
    }

    func verdict(from: String, to: String) -> HealthVerdict {
        if let exact = rules.first(where: { $0.fromIngredientId == from && $0.toIngredientId == to }) {
            return HealthVerdict(id: exact.id, kind: exact.verdict, reason: exact.reason, sources: exact.sources)
        }
        if let fallback = rules.first(where: { $0.fromIngredientId == "*" && $0.toIngredientId == "*" }) {
            return HealthVerdict(id: fallback.id, kind: fallback.verdict, reason: fallback.reason, sources: fallback.sources)
        }
        return HealthVerdict(
            id: "fallback",
            kind: .unhealthy,
            reason: "No sourced rule matches this swap; prototype defaults to caution.",
            sources: ["Kook HealthVerdictRules table"]
        )
    }
}

final class IngredientSwapService {
    private let rules: HealthVerdictRules

    init(rules: HealthVerdictRules = HealthVerdictRules()) {
        self.rules = rules
    }

    var organicPremiumThresholdPercent: Double { rules.organicPremiumThresholdPercent }

    func evaluate(from original: Ingredient, to replacementId: String, replacementName: String) -> HealthVerdict {
        _ = replacementName
        return rules.verdict(from: original.id, to: replacementId)
    }

    static let commonReplacements: [(id: String, name: String)] = [
        ("brown_rice", "Brown rice"),
        ("white_rice", "White rice"),
        ("tofu", "Firm tofu"),
        ("soda", "Soda"),
        ("lard", "Lard"),
        ("sour_cream", "Sour cream"),
        ("corn_tortilla", "Corn tortilla"),
        ("flour_tortilla", "Flour tortilla"),
        ("chicken_breast", "Chicken breast"),
        ("avocado", "Avocado")
    ]
}
