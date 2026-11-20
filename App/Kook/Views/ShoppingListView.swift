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
                Text(ShoppingListPresentation.priceUnavailable)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("shopping.price.unavailable")
            }
        }
        .padding(.vertical, 4)
        .accessibilityIdentifier("shopping.row.\(item.id)")
    }

    @ViewBuilder
    private func priceBlock(_ price: IngredientPrice) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(ShoppingListPresentation.offerLine(label: "Conventional", offer: price.conventional))
                .font(.subheadline)
                .foregroundStyle(
                    price.conventional.unavailable || price.conventional.amount == nil ? .secondary : .primary
                )
            Text(ShoppingListPresentation.offerLine(label: "Organic", offer: price.organic))
                .font(.subheadline)
                .foregroundStyle(
                    price.organic.unavailable || price.organic.amount == nil ? .secondary : .primary
                )
            if let premium = price.organicPremiumPercent {
                Text(ShoppingListPresentation.organicPremiumLine(percent: premium))
                    .font(.caption)
                    .foregroundStyle(price.exceedsOrganicPremiumThreshold ? .orange : .secondary)
                    .accessibilityIdentifier("shopping.organic.premium")
                if let note = ShoppingListPresentation.organicPremiumValueNote(
                    exceedsThreshold: price.exceedsOrganicPremiumThreshold
                ) {
                    Text(note)
                        .font(.caption2)
                        .foregroundStyle(.orange)
                        .accessibilityIdentifier("shopping.organic.premium.warning")
                }
            }
            if let hint = ShoppingListPresentation.buyHint(preferOrganic: preferOrganic, price: price) {
                Text(hint)
                    .font(.caption)
            }
        }
    }

    private func qty(_ ingredient: Ingredient) -> String {
        String(format: "%.2f %@", ingredient.quantity, ingredient.unit)
    }
}
