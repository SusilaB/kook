import Foundation

/// Presentation strings for shopping-list rows — kept free of SwiftUI so XCTest can assert them.
enum ShoppingListPresentation {
    static let priceUnavailable = "Price unavailable"
    static let organicPremiumThresholdPercent: Double = 25

    static func offerLine(label: String, offer: PricedOffer) -> String {
        if offer.unavailable || offer.amount == nil {
            return "\(label): price unavailable"
        }
        if let amount = offer.amount {
            return "\(label): $\(String(format: "%.2f", amount)) · \(offer.store ?? "?") · \(offer.unit ?? "")"
        }
        return "\(label): price unavailable"
    }

    static func organicPremiumLine(percent: Double) -> String {
        String(format: "Organic premium: %.0f%%", percent)
    }

    static func organicPremiumValueNote(exceedsThreshold: Bool) -> String? {
        guard exceedsThreshold else { return nil }
        return "Over 25% premium — conventional may be better value; quality still wins if you choose organic."
    }

    static func buyHint(preferOrganic: Bool, price: IngredientPrice) -> String? {
        if preferOrganic, !price.organic.unavailable, let store = price.organic.store {
            return "Buy (organic): \(store)"
        }
        if let store = price.conventional.store {
            return "Buy (conventional): \(store)"
        }
        return nil
    }
}
