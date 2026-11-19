import Foundation

struct NutritionThresholds: Codable {
    let version: Int
    let status: String
    let disclaimer: String
    let perServing: PerServing

    enum CodingKeys: String, CodingKey {
        case version, status, disclaimer
        case perServing = "per_serving"
    }

    struct PerServing: Codable {
        let noAddedSugar: ModeThreshold
        let diabeticFriendly: ModeThreshold
        let lowCarb: ModeThreshold

        enum CodingKeys: String, CodingKey {
            case noAddedSugar = "no_added_sugar"
            case diabeticFriendly = "diabetic_friendly"
            case lowCarb = "low_carb"
        }
    }

    struct ModeThreshold: Codable {
        let maxAddedSugarGrams: Double?
        let maxTotalSugarGrams: Double?
        let maxNetCarbsGrams: Double?
        let notes: String?
        let sources: [String]?

        enum CodingKeys: String, CodingKey {
            case maxAddedSugarGrams = "max_added_sugar_grams"
            case maxTotalSugarGrams = "max_total_sugar_grams"
            case maxNetCarbsGrams = "max_net_carbs_grams"
            case notes, sources
        }
    }

    static let draftFallback = NutritionThresholds(
        version: 1,
        status: "draft_needs_dietitian_review",
        disclaimer: "Draft thresholds — dietitian review required.",
        perServing: PerServing(
            noAddedSugar: ModeThreshold(maxAddedSugarGrams: 0, maxTotalSugarGrams: nil, maxNetCarbsGrams: nil, notes: nil, sources: nil),
            diabeticFriendly: ModeThreshold(maxAddedSugarGrams: 5, maxTotalSugarGrams: 15, maxNetCarbsGrams: 45, notes: nil, sources: nil),
            lowCarb: ModeThreshold(maxAddedSugarGrams: 5, maxTotalSugarGrams: nil, maxNetCarbsGrams: 30, notes: nil, sources: nil)
        )
    )
}

enum BundleJSON {
    static func load<T: Decodable>(_ name: String, as type: T.Type) -> T? {
        let candidates = [
            Bundle.main.url(forResource: name, withExtension: "json"),
            Bundle.main.url(forResource: name, withExtension: "json", subdirectory: "data"),
            Bundle.main.resourceURL?.appendingPathComponent("data/\(name).json")
        ]
        for url in candidates.compactMap({ $0 }) {
            if let data = try? Data(contentsOf: url),
               let decoded = try? JSONDecoder().decode(T.self, from: data) {
                return decoded
            }
        }
        // Dev / test fallback: walk up from #file toward repo data/
        let fileURL = URL(fileURLWithPath: #filePath)
        var dir = fileURL.deletingLastPathComponent()
        for _ in 0..<8 {
            let candidate = dir.appendingPathComponent("data/\(name).json")
            if let data = try? Data(contentsOf: candidate),
               let decoded = try? JSONDecoder().decode(T.self, from: data) {
                return decoded
            }
            let alt = dir.appendingPathComponent("../data/\(name).json")
            if let data = try? Data(contentsOf: alt),
               let decoded = try? JSONDecoder().decode(T.self, from: data) {
                return decoded
            }
            dir = dir.deletingLastPathComponent()
        }
        return nil
    }
}
