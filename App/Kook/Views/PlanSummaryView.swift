import SwiftUI

struct PlanSummaryView: View {
    @EnvironmentObject private var prefs: PreferencesStore
    @EnvironmentObject private var app: AppModel

    var body: some View {
        NavigationStack {
            List {
                if let plan = app.plan {
                    if plan.meals.isEmpty {
                        ContentUnavailableView(
                            PlanSummaryPresentation.noMatchesTitle,
                            systemImage: "fork.knife.circle",
                            description: Text(PlanSummaryPresentation.noMatchesDescription)
                        )
                        .accessibilityIdentifier(PlanSummaryPresentation.noMatchesAccessibilityID)
                    } else {
                        Section {
                            Text(PlanSummaryPresentation.householdScaleLine(people: prefs.preferences.householdSize))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        ForEach(plan.meals) { meal in
                            NavigationLink(value: meal) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(meal.mealTime.displayName.uppercased())
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(meal.recipe.name)
                                        .font(.headline)
                                    Text(meal.recipe.cuisine.displayName)
                                        .font(.subheadline)
                                    badgeRow(for: meal.recipe)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                } else {
                    ContentUnavailableView(
                        PlanSummaryPresentation.noPlanTitle,
                        systemImage: "fork.knife",
                        description: Text(PlanSummaryPresentation.noPlanDescription)
                    )
                }
            }
            .navigationTitle(PlanSummaryPresentation.navigationTitle)
            .navigationDestination(for: PlannedMeal.self) { meal in
                RecipeDetailView(meal: meal)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(PlanSummaryPresentation.editPreferencesTitle) {
                        prefs.beginEditingQuestionnaire()
                    }
                    .accessibilityIdentifier(PlanSummaryPresentation.editPreferencesAccessibilityID)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(PlanSummaryPresentation.refreshTitle) {
                        app.regenerate(using: prefs.preferences)
                    }
                    .accessibilityIdentifier(PlanSummaryPresentation.refreshAccessibilityID)
                }
            }
            .accessibilityIdentifier(PlanSummaryPresentation.screenAccessibilityID)
        }
    }

    @ViewBuilder
    private func badgeRow(for recipe: Recipe) -> some View {
        let seasonal = app.seasonality.seasonalBadges(for: recipe)
        HStack(spacing: 6) {
            if recipe.vegetarian {
                Label("Veg", systemImage: "leaf")
                    .font(.caption2)
                    .padding(4)
                    .background(Color.green.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            if !seasonal.isEmpty {
                Label("In season", systemImage: "sun.max")
                    .font(.caption2)
                    .padding(4)
                    .background(Color.orange.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            ForEach(recipe.allergens) { a in
                Text(a.displayName)
                    .font(.caption2)
                    .padding(4)
                    .background(Color.red.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
    }
}
