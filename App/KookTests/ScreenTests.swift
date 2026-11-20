import XCTest
import SwiftUI
import UIKit
@testable import Kook

// MARK: - Disclaimer (hosted SwiftUI)

@MainActor
final class DisclaimerViewTests: XCTestCase {
    func testMedicalDisclaimerAndContinueCopy() {
        XCTAssertEqual(DisclaimerPresentation.medicalHeading, "Medical disclaimer")
        XCTAssertTrue(
            DisclaimerPresentation.medicalBody.localizedCaseInsensitiveContains("not medical advice"),
            "Disclaimer must state Kook is not medical advice"
        )
        XCTAssertTrue(
            DisclaimerPresentation.medicalBody.localizedCaseInsensitiveContains("dietitian")
                || DisclaimerPresentation.medicalBody.localizedCaseInsensitiveContains("clinician"),
            "Disclaimer should point users to professional guidance"
        )
        XCTAssertFalse(DisclaimerPresentation.continueTitle.isEmpty)
        XCTAssertTrue(DisclaimerPresentation.continueTitle.localizedCaseInsensitiveContains("continue"))
    }

    func testHostsDisclaimerScreenWithoutCrash() {
        let suite = "kook.tests.disclaimer.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        let prefs = PreferencesStore(defaults: defaults)

        let host = UIHostingController(
            rootView: DisclaimerView()
                .environmentObject(prefs)
        )
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.loadViewIfNeeded()
        host.view.layoutIfNeeded()

        XCTAssertNotNil(host.view)
        XCTAssertGreaterThan(host.view.bounds.width, 0)
        XCTAssertFalse(prefs.preferences.acceptedDisclaimer)

        // Accessibility identifiers are attached for XCUITest; UIView traversal is unreliable for SwiftUI Text.
        XCTAssertEqual(DisclaimerPresentation.medicalBodyAccessibilityID, "disclaimer.medical.body")
        XCTAssertEqual(DisclaimerPresentation.continueAccessibilityID, "disclaimer.continue")
    }

    func testAcceptDisclaimerMarksPreference() {
        let suite = "kook.tests.disclaimer.accept.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        let prefs = PreferencesStore(defaults: defaults)
        XCTAssertFalse(prefs.preferences.acceptedDisclaimer)
        prefs.acceptDisclaimer()
        XCTAssertTrue(prefs.preferences.acceptedDisclaimer)
    }
}

// MARK: - Questionnaire → MealPlan wiring

@MainActor
final class QuestionnaireMealPlanTests: XCTestCase {
    func testSkipDefaultsWireFullDayPlan() {
        let suite = "kook.tests.questionnaire.skip.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        let prefs = PreferencesStore(defaults: defaults)
        prefs.acceptDisclaimer()
        prefs.skipQuestionnaireAndUseDefaults()

        XCTAssertTrue(prefs.preferences.completedQuestionnaire)
        XCTAssertEqual(prefs.preferences.mealTime, .fullDay)
        XCTAssertEqual(prefs.preferences.householdSize, 2)
        XCTAssertNil(prefs.preferences.cuisine)

        let plan = MealPlanService().buildPlan(preferences: prefs.preferences)
        let times = Set(plan.meals.map(\.mealTime))
        XCTAssertEqual(times, Set([.breakfast, .lunch, .dinner]))
        XCTAssertEqual(plan.meals.count, 3)
    }

    func testFullDayPreferenceBuildsThreeMeals() {
        var prefs = UserPreferences.default
        prefs.acceptedDisclaimer = true
        prefs.completedQuestionnaire = true
        prefs.mealTime = .fullDay
        let plan = MealPlanService().buildPlan(preferences: prefs)
        XCTAssertEqual(plan.meals.map(\.mealTime), [.breakfast, .lunch, .dinner])
    }

    func testSingleMealTimeBuildsOneSlot() {
        var prefs = UserPreferences.default
        prefs.acceptedDisclaimer = true
        prefs.completedQuestionnaire = true
        prefs.mealTime = .dinner
        let plan = MealPlanService().buildPlan(preferences: prefs)
        XCTAssertEqual(plan.meals.count, 1)
        XCTAssertEqual(plan.meals.first?.mealTime, .dinner)
    }

    func testAppModelRegenerateAfterSkip() {
        let suite = "kook.tests.appmodel.skip.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        let prefs = PreferencesStore(defaults: defaults)
        let app = AppModel()
        prefs.acceptDisclaimer()
        prefs.skipQuestionnaireAndUseDefaults()
        app.regenerate(using: prefs.preferences)
        XCTAssertEqual(app.plan?.meals.count, 3)
    }

    func testIndianVegetarianLunchReturnsChanaNotBreakfast() {
        var prefs = UserPreferences.default
        prefs.acceptedDisclaimer = true
        prefs.completedQuestionnaire = true
        prefs.cuisine = .indian
        prefs.diet = .vegetarian
        prefs.mealTime = .lunch
        prefs.householdSize = 4
        let plan = MealPlanService().buildPlan(preferences: prefs)
        XCTAssertEqual(plan.meals.count, 1)
        guard let meal = plan.meals.first else {
            return XCTFail("Expected one Indian vegetarian lunch meal")
        }
        XCTAssertEqual(meal.mealTime, .lunch)
        XCTAssertEqual(meal.recipe.cuisine, .indian)
        XCTAssertTrue(meal.recipe.vegetarian)
        XCTAssertEqual(meal.recipe.id, "indian-chana-masala")
        XCTAssertFalse(meal.recipe.name.localizedCaseInsensitiveContains("berry"))
        XCTAssertTrue(meal.recipe.mealTimes.contains(.lunch))
    }

    func testCuisineAndMealTimeMismatchYieldsEmptyPlan() {
        var prefs = UserPreferences.default
        prefs.acceptedDisclaimer = true
        prefs.completedQuestionnaire = true
        prefs.cuisine = .indian
        prefs.diet = .vegetarian
        prefs.mealTime = .breakfast
        let plan = MealPlanService().buildPlan(preferences: prefs)
        XCTAssertTrue(plan.meals.isEmpty, "No Indian breakfast seed — must not substitute American oats")
    }

    func testMilkAllergyExcludesBerryBowlEvenWhenVegetarian() {
        var prefs = UserPreferences.default
        prefs.acceptedDisclaimer = true
        prefs.completedQuestionnaire = true
        prefs.diet = .vegetarian
        prefs.allergens = [.milk]
        prefs.mealTime = .breakfast
        prefs.cuisine = .american
        let plan = MealPlanService().buildPlan(preferences: prefs)
        XCTAssertFalse(plan.meals.contains { $0.recipe.id == "american-oat-berry-bowl" })
        XCTAssertTrue(plan.meals.isEmpty, "Only American breakfast seed has milk — empty is honest")
    }
}

// MARK: - Plan summary nav / empty-state presentation

@MainActor
final class PlanSummaryPresentationTests: XCTestCase {
    func testEditPreferencesAndNoMatchesCopy() {
        XCTAssertEqual(PlanSummaryPresentation.editPreferencesTitle, "Edit preferences")
        XCTAssertFalse(PlanSummaryPresentation.noMatchesTitle.isEmpty)
        XCTAssertTrue(
            PlanSummaryPresentation.noMatchesDescription.localizedCaseInsensitiveContains("match")
        )
        XCTAssertEqual(PlanSummaryPresentation.editPreferencesAccessibilityID, "plan.editPreferences")
        XCTAssertEqual(PlanSummaryPresentation.noMatchesAccessibilityID, "plan.noMatches")
    }

    func testBeginEditingQuestionnaireReopensMoodCheckIn() {
        let suite = "kook.tests.plan.edit.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        let prefs = PreferencesStore(defaults: defaults)
        prefs.acceptDisclaimer()
        var draft = UserPreferences.default
        draft.acceptedDisclaimer = true
        draft.cuisine = .indian
        draft.diet = .vegetarian
        draft.mealTime = .lunch
        draft.householdSize = 4
        prefs.saveQuestionnaire(draft)

        XCTAssertTrue(prefs.preferences.completedQuestionnaire)
        XCTAssertFalse(prefs.isEditingQuestionnaire)

        prefs.beginEditingQuestionnaire()
        XCTAssertTrue(prefs.isEditingQuestionnaire)
        XCTAssertFalse(prefs.preferences.completedQuestionnaire)
        XCTAssertEqual(prefs.preferences.cuisine, .indian)
        XCTAssertEqual(prefs.preferences.diet, .vegetarian)
        XCTAssertEqual(prefs.preferences.mealTime, .lunch)

        prefs.cancelQuestionnaireEdit()
        XCTAssertFalse(prefs.isEditingQuestionnaire)
        XCTAssertTrue(prefs.preferences.completedQuestionnaire)
        XCTAssertEqual(prefs.preferences.cuisine, .indian)
    }
}

// MARK: - Shopping list presentation

final class ShoppingListPresentationTests: XCTestCase {
    func testMissingPriceShowsUnavailableCopy() {
        XCTAssertEqual(ShoppingListPresentation.priceUnavailable, "Price unavailable")
        let offer = PricedOffer.unavailable(fetchedAt: Date())
        XCTAssertEqual(
            ShoppingListPresentation.offerLine(label: "Organic", offer: offer),
            "Organic: price unavailable"
        )
    }

    func testOrganicPremiumWarningWhenOverThreshold() {
        let provider = StubPriceProvider()
        guard let chicken = provider.price(for: "chicken_breast") else {
            return XCTFail("fixture missing chicken_breast")
        }
        XCTAssertTrue(chicken.exceedsOrganicPremiumThreshold)
        guard let premium = chicken.organicPremiumPercent else {
            return XCTFail("expected premium percent")
        }
        let line = ShoppingListPresentation.organicPremiumLine(percent: premium)
        XCTAssertTrue(line.contains("Organic premium:"))
        let note = ShoppingListPresentation.organicPremiumValueNote(exceedsThreshold: true)
        XCTAssertNotNil(note)
        XCTAssertTrue(note!.contains("25%"))
        XCTAssertNil(ShoppingListPresentation.organicPremiumValueNote(exceedsThreshold: false))
    }

    func testShoppingListServicePropagatesUnavailablePrices() {
        let plan = MealPlanService().buildPlan(preferences: {
            var p = UserPreferences.default
            p.acceptedDisclaimer = true
            p.completedQuestionnaire = true
            p.mealTime = .fullDay
            return p
        }())
        let items = ShoppingListService().buildList(from: plan)
        XCTAssertFalse(items.isEmpty)

        // Ingredients with no fixture entry surface as nil price → "Price unavailable" in the UI.
        let unknown = ShoppingListItem(
            id: "mystery_spice",
            ingredient: Ingredient(id: "mystery_spice", name: "Mystery spice", quantity: 1, unit: "tsp"),
            price: StubPriceProvider().price(for: "mystery_spice")
        )
        XCTAssertNil(unknown.price)
        XCTAssertEqual(ShoppingListPresentation.priceUnavailable, "Price unavailable")

        if let cabbage = items.first(where: { $0.id == "cabbage" }) ?? items.first(where: {
            $0.price?.organic.unavailable == true
        }) {
            if let price = cabbage.price {
                XCTAssertTrue(
                    price.organic.unavailable || price.organic.amount == nil
                        || ShoppingListPresentation.offerLine(label: "Organic", offer: price.organic)
                            .contains("unavailable")
                )
            }
        }
    }
}

// MARK: - Ingredient swap sources (screen data path)

final class IngredientCustomizeDataPathTests: XCTestCase {
    func testVerdictSourcesAreCitedForSwapUI() {
        let service = IngredientSwapService()
        let original = Ingredient(id: "brown_rice", name: "Brown rice", quantity: 1, unit: "cup")
        let verdict = service.evaluate(from: original, to: "white_rice", replacementName: "White rice")
        XCTAssertFalse(verdict.sources.isEmpty, "Customize screen must show at least one source")
        XCTAssertFalse(verdict.reason.isEmpty)
        XCTAssertEqual(verdict.kind, .unhealthy)
    }
}

