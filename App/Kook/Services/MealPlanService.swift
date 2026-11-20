import Foundation

final class MealPlanService {
    private let catalog: RecipeCatalog
    private let validator: RecipeValidator
    private let seasonality: SeasonalityService

    init(
        catalog: RecipeCatalog? = BundleJSON.load("recipes", as: RecipeCatalog.self),
        validator: RecipeValidator = RecipeValidator(),
        seasonality: SeasonalityService = SeasonalityService()
    ) {
        self.catalog = catalog ?? RecipeCatalog(version: 1, recipes: [])
        self.validator = validator
        self.seasonality = seasonality
    }

    var allRecipes: [Recipe] { catalog.recipes }

    func buildPlan(preferences: UserPreferences) -> MealPlan {
        let safe = validator.filter(catalog.recipes, against: preferences)
        // Cuisine is a hard constraint when the user picked one — never soft-rank a mismatch in.
        let pool: [Recipe]
        if let cuisine = preferences.cuisine {
            pool = safe.filter { $0.cuisine == cuisine }
        } else {
            pool = safe
        }

        let targets: [MealTime]
        if preferences.mealTime == .fullDay {
            targets = [.breakfast, .lunch, .dinner]
        } else {
            targets = [preferences.mealTime]
        }

        var meals: [PlannedMeal] = []
        var used = Set<String>()

        for mealTime in targets {
            let candidates = ranked(
                pool.filter { $0.mealTimes.contains(mealTime) },
                preferences: preferences
            )
            .filter { !used.contains($0.id) }

            // No silent fallback to a different meal slot or cuisine.
            guard let recipe = candidates.first else { continue }

            used.insert(recipe.id)
            let scale = Double(preferences.householdSize) / Double(max(recipe.servings, 1))
            meals.append(PlannedMeal(
                id: "\(mealTime.rawValue)-\(recipe.id)",
                mealTime: mealTime,
                recipe: recipe,
                scaleFactor: scale
            ))
        }

        return MealPlan(id: UUID(), meals: meals, generatedAt: Date(), preferences: preferences)
    }

    private func ranked(_ recipes: [Recipe], preferences: UserPreferences) -> [Recipe] {
        recipes.sorted { a, b in
            score(a, preferences: preferences) > score(b, preferences: preferences)
        }
    }

    private func score(_ recipe: Recipe, preferences: UserPreferences) -> Int {
        var s = 0
        if let cuisine = preferences.cuisine, recipe.cuisine == cuisine { s += 10 }
        s += seasonality.seasonalBoost(for: recipe) * 2
        if preferences.diet == .vegetarian && recipe.vegetarian { s += 3 }
        if preferences.sugarMode != .none, recipe.sugarTags.contains(preferences.sugarMode) { s += 4 }
        return s
    }
}
