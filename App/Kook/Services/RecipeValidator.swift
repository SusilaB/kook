import Foundation

struct ValidationIssue: Equatable, Hashable {
    let code: String
    let message: String
}

struct RecipeValidationResult: Equatable {
    let isValid: Bool
    let issues: [ValidationIssue]

    static let ok = RecipeValidationResult(isValid: true, issues: [])
}

/// Deterministic safety gate. A recipe that fails must never be shown for the given preferences.
struct RecipeValidator {
    let thresholds: NutritionThresholds

    init(thresholds: NutritionThresholds = BundleJSON.load("nutrition_thresholds", as: NutritionThresholds.self) ?? .draftFallback) {
        self.thresholds = thresholds
    }

    func validate(_ recipe: Recipe, against preferences: UserPreferences) -> RecipeValidationResult {
        var issues: [ValidationIssue] = []

        // Allergen hard constraint: recipe-level + ingredient-level (quantity > 0)
        let declared = Set(preferences.allergens)
        if !declared.isEmpty {
            let recipeHits = Set(recipe.allergens).intersection(declared)
            for hit in recipeHits {
                issues.append(ValidationIssue(
                    code: "allergen_recipe",
                    message: "Recipe declares allergen \(hit.rawValue)"
                ))
            }
            for ingredient in recipe.ingredients where ingredient.quantity > 0 {
                let hits = Set(ingredient.allergens).intersection(declared)
                for hit in hits {
                    issues.append(ValidationIssue(
                        code: "allergen_ingredient",
                        message: "Ingredient \(ingredient.id) contains allergen \(hit.rawValue)"
                    ))
                }
            }
        }

        // Vegetarian hard constraint
        if preferences.diet == .vegetarian {
            if !recipe.vegetarian {
                issues.append(ValidationIssue(code: "diet_flag", message: "Recipe is marked non-vegetarian"))
            }
            for ingredient in recipe.ingredients where ingredient.quantity > 0 && ingredient.isNonVegetarian {
                issues.append(ValidationIssue(
                    code: "diet_ingredient",
                    message: "Ingredient \(ingredient.id) is non-vegetarian"
                ))
            }
        }

        // Sugar / carb modes
        switch preferences.sugarMode {
        case .none:
            break
        case .noAddedSugar:
            let maxAdded = thresholds.perServing.noAddedSugar.maxAddedSugarGrams ?? 0
            if recipe.addedSugarGramsPerServing > maxAdded {
                issues.append(ValidationIssue(
                    code: "sugar_added",
                    message: "Added sugar \(recipe.addedSugarGramsPerServing)g exceeds \(maxAdded)g"
                ))
            }
        case .diabeticFriendly:
            let t = thresholds.perServing.diabeticFriendly
            if let maxAdded = t.maxAddedSugarGrams, recipe.addedSugarGramsPerServing > maxAdded {
                issues.append(ValidationIssue(code: "sugar_added", message: "Added sugar exceeds diabetic-friendly draft max"))
            }
            if let maxTotal = t.maxTotalSugarGrams, recipe.totalSugarGramsPerServing > maxTotal {
                issues.append(ValidationIssue(code: "sugar_total", message: "Total sugar exceeds diabetic-friendly draft max"))
            }
            if let maxCarbs = t.maxNetCarbsGrams, recipe.netCarbsGramsPerServing > maxCarbs {
                issues.append(ValidationIssue(code: "net_carbs", message: "Net carbs exceed diabetic-friendly draft max"))
            }
        case .lowCarb:
            let t = thresholds.perServing.lowCarb
            if let maxCarbs = t.maxNetCarbsGrams, recipe.netCarbsGramsPerServing > maxCarbs {
                issues.append(ValidationIssue(code: "net_carbs", message: "Net carbs exceed low-carb draft max"))
            }
            if let maxAdded = t.maxAddedSugarGrams, recipe.addedSugarGramsPerServing > maxAdded {
                issues.append(ValidationIssue(code: "sugar_added", message: "Added sugar exceeds low-carb draft max"))
            }
        }

        return RecipeValidationResult(isValid: issues.isEmpty, issues: issues)
    }

    func filter(_ recipes: [Recipe], against preferences: UserPreferences) -> [Recipe] {
        recipes.filter { validate($0, against: preferences).isValid }
    }
}
