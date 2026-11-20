import XCTest
@testable import Kook

final class RecipeValidatorTests: XCTestCase {
    private var recipes: [Recipe]!
    private var validator: RecipeValidator!

    override func setUp() {
        super.setUp()
        let catalog = BundleJSON.load("recipes", as: RecipeCatalog.self)
        XCTAssertNotNil(catalog, "Seed recipes.json must load")
        recipes = catalog?.recipes ?? []
        XCTAssertEqual(recipes.count, 4, "Prototype ships exactly 4 seed recipes")
        validator = RecipeValidator()
    }

    func testZeroAllergenLeaksForEachMajor9() {
        for allergen in MajorAllergen.allCases {
            var prefs = UserPreferences.default
            prefs.allergens = [allergen]
            let shown = validator.filter(recipes, against: prefs)
            for recipe in shown {
                XCTAssertFalse(recipe.allergens.contains(allergen), "Recipe \(recipe.id) leaked recipe-level \(allergen)")
                for ingredient in recipe.ingredients where ingredient.quantity > 0 {
                    XCTAssertFalse(
                        ingredient.allergens.contains(allergen),
                        "Recipe \(recipe.id) leaked ingredient \(ingredient.id) allergen \(allergen)"
                    )
                }
            }
        }
    }

    func testVegetarianFilterExcludesAnimalIngredients() {
        var prefs = UserPreferences.default
        prefs.diet = .vegetarian
        let shown = validator.filter(recipes, against: prefs)
        XCTAssertFalse(shown.contains { $0.id == "mediterranean-lemon-chicken" })
        for recipe in shown {
            XCTAssertTrue(recipe.vegetarian)
            for ingredient in recipe.ingredients where ingredient.quantity > 0 {
                XCTAssertFalse(ingredient.isNonVegetarian, "\(recipe.id) / \(ingredient.id)")
            }
        }
    }

    func testNoAddedSugarFilter() {
        var prefs = UserPreferences.default
        prefs.sugarMode = .noAddedSugar
        let shown = validator.filter(recipes, against: prefs)
        for recipe in shown {
            XCTAssertEqual(recipe.addedSugarGramsPerServing, 0, accuracy: 0.001)
        }
    }

    func testLowCarbFilterRespectsDraftThreshold() {
        var prefs = UserPreferences.default
        prefs.sugarMode = .lowCarb
        let shown = validator.filter(recipes, against: prefs)
        let maxCarbs = validator.thresholds.perServing.lowCarb.maxNetCarbsGrams ?? 30
        for recipe in shown {
            XCTAssertLessThanOrEqual(recipe.netCarbsGramsPerServing, maxCarbs)
        }
        XCTAssertTrue(shown.contains { $0.id == "american-oat-berry-bowl" })
        XCTAssertFalse(shown.contains { $0.id == "indian-chana-masala" })
    }

    func testMilkAllergyHidesYogurtBowl() {
        var prefs = UserPreferences.default
        prefs.allergens = [.milk]
        let shown = validator.filter(recipes, against: prefs)
        XCTAssertFalse(shown.contains { $0.id == "american-oat-berry-bowl" })
    }

    func testSyntheticAllergenLeakIsRejected() throws {
        let json = """
        {"id":"leak","name":"Leak","cuisine":"american","meal_times":["snack"],"servings":1,"vegetarian":true,"allergens":[],"sugar_tags":[],"added_sugar_grams_per_serving":0,"net_carbs_grams_per_serving":10,"total_sugar_grams_per_serving":1,"seasonal_ingredients":[],"ingredients":[{"id":"peanut_butter","name":"Peanut butter","quantity":1,"unit":"tbsp","allergens":["peanuts"],"tags":[]}],"steps":["Spread"],"cross_contact_notes":""}
        """
        let recipe = try JSONDecoder().decode(Recipe.self, from: Data(json.utf8))
        var prefs = UserPreferences.default
        prefs.allergens = [.peanuts]
        let result = validator.validate(recipe, against: prefs)
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.issues.contains { $0.code == "allergen_ingredient" })
    }

    func testMealPlanNeverSurfacesInvalidRecipe() {
        var prefs = UserPreferences.default
        prefs.diet = .vegetarian
        prefs.allergens = [.milk]
        prefs.sugarMode = .noAddedSugar
        prefs.mealTime = .fullDay
        prefs.householdSize = 3
        let plan = MealPlanService().buildPlan(preferences: prefs)
        for meal in plan.meals {
            let result = validator.validate(meal.recipe, against: prefs)
            XCTAssertTrue(result.isValid, "Plan surfaced invalid \(meal.recipe.id): \(result.issues)")
            // Breakfast slot must stay empty when milk allergy excludes the oat bowl —
            // never fill with a lunch/dinner recipe.
            if meal.mealTime == .breakfast {
                XCTFail("Breakfast should be omitted when no safe breakfast seed matches")
            }
            XCTAssertTrue(meal.recipe.mealTimes.contains(meal.mealTime))
        }
        XCTAssertFalse(plan.meals.contains { $0.recipe.id == "american-oat-berry-bowl" })
    }

    func testHardCuisineFilterNeverReturnsOtherCuisine() {
        var prefs = UserPreferences.default
        prefs.cuisine = .indian
        prefs.diet = .vegetarian
        prefs.mealTime = .lunch
        prefs.householdSize = 4
        let plan = MealPlanService().buildPlan(preferences: prefs)
        for meal in plan.meals {
            XCTAssertEqual(meal.recipe.cuisine, .indian)
            XCTAssertTrue(meal.recipe.mealTimes.contains(.lunch))
        }
    }
}

final class IngredientSwapServiceTests: XCTestCase {
    func testCitedVerdictForKnownSwap() {
        let service = IngredientSwapService()
        let original = Ingredient(id: "brown_rice", name: "Brown rice", quantity: 1, unit: "cup")
        let verdict = service.evaluate(from: original, to: "white_rice", replacementName: "White rice")
        XCTAssertEqual(verdict.kind, .unhealthy)
        XCTAssertFalse(verdict.sources.isEmpty)
    }

    func testHealthySwapToTofu() {
        let service = IngredientSwapService()
        let original = Ingredient(id: "chicken_breast", name: "Chicken", quantity: 1, unit: "lb")
        let verdict = service.evaluate(from: original, to: "tofu", replacementName: "Tofu")
        XCTAssertEqual(verdict.kind, .healthy)
        XCTAssertTrue(verdict.sources.contains { $0.contains("http") || $0.contains("USDA") || $0.contains("Dietary") })
    }
}

final class StubPriceProviderTests: XCTestCase {
    func testMissingPriceIsUnavailable() {
        let provider = StubPriceProvider()
        XCTAssertNil(provider.price(for: "definitely_missing_ingredient_xyz"))
        if let cabbage = provider.price(for: "cabbage") {
            XCTAssertTrue(cabbage.organic.unavailable || cabbage.organic.amount == nil)
        }
    }

    func testOrganicPremiumThresholdFlag() {
        let provider = StubPriceProvider()
        // chicken: conventional 3.98, organic 6.99 → ~75% premium
        guard let chicken = provider.price(for: "chicken_breast") else {
            return XCTFail("fixture missing chicken_breast")
        }
        XCTAssertTrue(chicken.exceedsOrganicPremiumThreshold)
    }
}
