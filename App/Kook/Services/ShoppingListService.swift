import Foundation

final class ShoppingListService {
    private let prices: PriceProvider

    init(prices: PriceProvider = StubPriceProvider()) {
        self.prices = prices
    }

    var priceTimestamp: Date { prices.fetchedAt }

    func buildList(from plan: MealPlan) -> [ShoppingListItem] {
        var merged: [String: Ingredient] = [:]
        for meal in plan.meals {
            for ingredient in meal.scaledIngredients {
                if let existing = merged[ingredient.id] {
                    merged[ingredient.id] = Ingredient(
                        id: existing.id,
                        name: existing.name,
                        quantity: existing.quantity + ingredient.quantity,
                        unit: existing.unit,
                        allergens: existing.allergens,
                        tags: existing.tags,
                        notes: existing.notes
                    )
                } else {
                    merged[ingredient.id] = ingredient
                }
            }
        }

        return merged.values
            .sorted { $0.name < $1.name }
            .map { ingredient in
                let price = prices.price(for: ingredient.id)
                return ShoppingListItem(id: ingredient.id, ingredient: ingredient, price: price)
            }
    }
}
