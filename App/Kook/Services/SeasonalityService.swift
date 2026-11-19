import Foundation

struct SeasonalProduceTable: Codable {
    let version: Int
    let region: String
    let source: String
    let sourceUrls: [String]?
    let months: [String: [String]]
    let ingredientAliases: [String: String]?

    enum CodingKeys: String, CodingKey {
        case version, region, source
        case sourceUrls = "source_urls"
        case months
        case ingredientAliases = "ingredient_aliases"
    }
}

struct SeasonalityService {
    let table: SeasonalProduceTable?
    let calendar: Calendar

    init(
        table: SeasonalProduceTable? = BundleJSON.load("seasonal_produce_us", as: SeasonalProduceTable.self),
        calendar: Calendar = .current
    ) {
        self.table = table
        self.calendar = calendar
    }

    func isInSeason(_ ingredientKey: String, on date: Date = Date()) -> Bool {
        guard let table else { return false }
        let month = calendar.component(.month, from: date)
        let seasonal = Set(table.months["\(month)"] ?? [])
        let alias = table.ingredientAliases?[ingredientKey] ?? ingredientKey
        // Unknown → no badge (false)
        return seasonal.contains(alias) || seasonal.contains(ingredientKey)
    }

    func seasonalBoost(for recipe: Recipe, on date: Date = Date()) -> Int {
        recipe.seasonalIngredients.reduce(0) { partial, key in
            partial + (isInSeason(key, on: date) ? 1 : 0)
        }
    }

    func seasonalBadges(for recipe: Recipe, on date: Date = Date()) -> [String] {
        recipe.seasonalIngredients.filter { isInSeason($0, on: date) }
    }
}
