import Foundation

/// Future live scraping must go through a server-side proxy — never from the phone.
protocol PriceProvider {
    func price(for ingredientId: String) -> IngredientPrice?
    var fetchedAt: Date { get }
}

struct FixturePriceFile: Codable {
    let version: Int
    let currency: String
    let fetchedAt: String
    let items: [FixtureItem]

    enum CodingKeys: String, CodingKey {
        case version, currency, items
        case fetchedAt = "fetched_at"
    }

    struct FixtureItem: Codable {
        let ingredientId: String
        let conventional: Offer?
        let organic: Offer?

        enum CodingKeys: String, CodingKey {
            case ingredientId = "ingredient_id"
            case conventional, organic
        }
    }

    struct Offer: Codable {
        let amount: Double
        let store: String
        let unit: String
        let url: String
    }
}

final class StubPriceProvider: PriceProvider {
    private let map: [String: IngredientPrice]
    let fetchedAt: Date

    init(file: FixturePriceFile? = BundleJSON.load("price_fixtures", as: FixturePriceFile.self)) {
        let formatter = ISO8601DateFormatter()
        let fetched = file.flatMap { formatter.date(from: $0.fetchedAt) } ?? Date(timeIntervalSince1970: 0)
        self.fetchedAt = fetched

        var built: [String: IngredientPrice] = [:]
        for item in file?.items ?? [] {
            let conventional: PricedOffer
            if let c = item.conventional {
                conventional = PricedOffer(amount: c.amount, store: c.store, unit: c.unit, url: c.url, fetchedAt: fetched, unavailable: false)
            } else {
                conventional = .unavailable(fetchedAt: fetched)
            }
            let organic: PricedOffer
            if let o = item.organic {
                organic = PricedOffer(amount: o.amount, store: o.store, unit: o.unit, url: o.url, fetchedAt: fetched, unavailable: false)
            } else {
                organic = .unavailable(fetchedAt: fetched)
            }
            built[item.ingredientId] = IngredientPrice(
                id: item.ingredientId,
                ingredientId: item.ingredientId,
                conventional: conventional,
                organic: organic
            )
        }
        self.map = built
    }

    func price(for ingredientId: String) -> IngredientPrice? {
        map[ingredientId]
    }
}
