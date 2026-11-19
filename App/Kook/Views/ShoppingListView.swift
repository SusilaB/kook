import SwiftUI

struct ShoppingListView: View {
    @EnvironmentObject private var prefs: PreferencesStore
    @EnvironmentObject private var app: AppModel

    private var items: [ShoppingListItem] {
        guard let plan = app.plan else { return [] }
        return app.shoppingListService.buildList(from: plan)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    let ts = app.shoppingListService.priceTimestamp
                    Text("Stub prices as of \(ts.formatted(date: .abbreviated, time: .shortened)) · USD")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Toggle("Prefer organic", isOn: $prefs.preferences.preferOrganic)
                    Text("Organic premium threshold: \(Int(app.swapService.organicPremiumThresholdPercent))%. Above that, conventional is highlighted as better value while quality still wins when you choose organic.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if items.isEmpty {
                    ContentUnavailableView("Nothing to shop", systemImage: "cart", description: Text("Generate a meal plan first."))
                } else {
                    ForEach(items) { item in
                        ShoppingRow(item: item, preferOrganic: prefs.preferences.preferOrganic)
                    }
                }
            }
            .navigationTitle("Shopping list")
        }
    }
}

private struct ShoppingRow: View {
    let item: ShoppingListItem
    let preferOrganic: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item.ingredient.name)
                .font(.headline)
            Text(qty(item.ingredient))
                .font(.caption)
                .foregroundStyle(.secondary)

            if let price = item.price {
                priceBlock(price)
            } else {
                Text("Price unavailable")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func priceBlock(_ price: IngredientPrice) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            offerLine(label: "Conventional", offer: price.conventional)
            offerLine(label: "Organic", offer: price.organic)
            if let premium = price.organicPremiumPercent {
                Text(String(format: "Organic premium: %.0f%%", premium))
                    .font(.caption)
                    .foregroundStyle(price.exceedsOrganicPremiumThreshold ? .orange : .secondary)
                if price.exceedsOrganicPremiumThreshold {
                    Text("Over 25% premium — conventional may be better value; quality still wins if you choose organic.")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
            if preferOrganic, !price.organic.unavailable, let store = price.organic.store {
                Text("Buy (organic): \(store)")
                    .font(.caption)
            } else if let store = price.conventional.store {
                Text("Buy (conventional): \(store)")
                    .font(.caption)
            }
        }
    }

    @ViewBuilder
    private func offerLine(label: String, offer: PricedOffer) -> some View {
        if offer.unavailable || offer.amount == nil {
            Text("\(label): price unavailable")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        } else if let amount = offer.amount {
            Text("\(label): $\(String(format: "%.2f", amount)) · \(offer.store ?? "?") · \(offer.unit ?? "")")
                .font(.subheadline)
        }
    }

    private func qty(_ ingredient: Ingredient) -> String {
        String(format: "%.2f %@", ingredient.quantity, ingredient.unit)
    }
}
