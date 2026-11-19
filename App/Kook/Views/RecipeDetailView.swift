import SwiftUI

struct RecipeDetailView: View {
    @EnvironmentObject private var app: AppModel
    let meal: PlannedMeal

    var body: some View {
        List {
            Section("About") {
                LabeledContent("Cuisine", value: meal.recipe.cuisine.displayName)
                LabeledContent("Base servings", value: "\(meal.recipe.servings)")
                LabeledContent("Scale", value: String(format: "%.2f×", meal.scaleFactor))
                if meal.recipe.vegetarian {
                    Text("Vegetarian (dairy & honey OK)")
                }
                let seasonal = app.seasonality.seasonalBadges(for: meal.recipe)
                if !seasonal.isEmpty {
                    Text("Seasonal now: \(seasonal.joined(separator: ", "))")
                } else {
                    Text("No seasonal badge (unknown or out of season)")
                        .foregroundStyle(.secondary)
                }
                if !meal.recipe.crossContactNotes.isEmpty {
                    Text(meal.recipe.crossContactNotes)
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }
            }

            Section("Ingredients (scaled)") {
                ForEach(meal.scaledIngredients) { ingredient in
                    NavigationLink {
                        IngredientCustomizeView(ingredient: ingredient)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(ingredient.name)
                            Text(quantityLabel(ingredient))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Steps") {
                ForEach(Array(meal.recipe.steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top) {
                        Text("\(index + 1).")
                            .bold()
                        Text(step)
                    }
                }
            }
        }
        .navigationTitle(meal.recipe.name)
    }

    private func quantityLabel(_ ingredient: Ingredient) -> String {
        let q: String
        if ingredient.quantity == floor(ingredient.quantity) {
            q = String(Int(ingredient.quantity))
        } else {
            q = String(format: "%.2f", ingredient.quantity)
        }
        return "\(q) \(ingredient.unit)"
    }
}
