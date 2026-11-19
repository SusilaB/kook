import SwiftUI

@main
struct KookApp: App {
    @StateObject private var preferencesStore = PreferencesStore()
    @StateObject private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(preferencesStore)
                .environmentObject(appModel)
        }
    }
}

@MainActor
final class AppModel: ObservableObject {
    let mealPlanService = MealPlanService()
    let shoppingListService = ShoppingListService()
    let swapService = IngredientSwapService()
    let seasonality = SeasonalityService()
    let validator = RecipeValidator()

    @Published var plan: MealPlan?

    func regenerate(using preferences: UserPreferences) {
        plan = mealPlanService.buildPlan(preferences: preferences)
    }
}
