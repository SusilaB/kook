import Foundation

enum MajorAllergen: String, Codable, CaseIterable, Identifiable, Hashable {
    case milk, eggs, fish, shellfish, treeNuts = "tree_nuts", peanuts, wheat, soy, sesame

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .milk: return "Milk"
        case .eggs: return "Eggs"
        case .fish: return "Fish"
        case .shellfish: return "Shellfish"
        case .treeNuts: return "Tree nuts"
        case .peanuts: return "Peanuts"
        case .wheat: return "Wheat"
        case .soy: return "Soy"
        case .sesame: return "Sesame"
        }
    }
}

enum Cuisine: String, Codable, CaseIterable, Identifiable, Hashable {
    case american, indian, mediterranean, mexican, chinese

    var id: String { rawValue }

    var displayName: String { rawValue.capitalized }
}

enum MealTime: String, Codable, CaseIterable, Identifiable, Hashable {
    case breakfast, lunch, dinner, snack, fullDay = "full_day"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fullDay: return "Full day"
        default: return rawValue.capitalized
        }
    }
}

enum SugarMode: String, Codable, CaseIterable, Identifiable, Hashable {
    case none = "none"
    case noAddedSugar = "no_added_sugar"
    case diabeticFriendly = "diabetic_friendly"
    case lowCarb = "low_carb"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none: return "No sugar restriction"
        case .noAddedSugar: return "No added sugar"
        case .diabeticFriendly: return "Diabetic-friendly"
        case .lowCarb: return "Low-carb"
        }
    }
}

enum DietPreference: String, Codable, CaseIterable, Identifiable, Hashable {
    case vegetarian
    case nonVegetarian = "non_vegetarian"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .vegetarian: return "Vegetarian"
        case .nonVegetarian: return "Non-vegetarian"
        }
    }
}

struct Ingredient: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let quantity: Double
    let unit: String
    let allergens: [MajorAllergen]
    let tags: [String]
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id, name, quantity, unit, allergens, tags, notes
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        quantity = try c.decode(Double.self, forKey: .quantity)
        unit = try c.decode(String.self, forKey: .unit)
        allergens = try c.decodeIfPresent([MajorAllergen].self, forKey: .allergens) ?? []
        tags = try c.decodeIfPresent([String].self, forKey: .tags) ?? []
        notes = try c.decodeIfPresent(String.self, forKey: .notes)
    }

    init(
        id: String,
        name: String,
        quantity: Double,
        unit: String,
        allergens: [MajorAllergen] = [],
        tags: [String] = [],
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.allergens = allergens
        self.tags = tags
        self.notes = notes
    }

    func scaled(by factor: Double) -> Ingredient {
        Ingredient(
            id: id,
            name: name,
            quantity: quantity * factor,
            unit: unit,
            allergens: allergens,
            tags: tags,
            notes: notes
        )
    }

    var isNonVegetarian: Bool {
        let banned: Set<String> = [
            "meat", "poultry", "fish", "shellfish", "egg", "eggs",
            "gelatin", "lard", "animal_broth", "animal-broth", "broth_animal"
        ]
        if tags.contains(where: { banned.contains($0.lowercased()) }) { return true }
        let nameLower = name.lowercased()
        let keywords = ["chicken", "beef", "pork", "turkey", "lamb", "fish", "shrimp",
                        "crab", "lobster", "gelatin", "lard", "egg", "bone broth", "animal broth"]
        return keywords.contains { nameLower.contains($0) }
    }
}

struct Recipe: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let cuisine: Cuisine
    let mealTimes: [MealTime]
    let servings: Int
    let vegetarian: Bool
    let allergens: [MajorAllergen]
    let sugarTags: [SugarMode]
    let addedSugarGramsPerServing: Double
    let netCarbsGramsPerServing: Double
    let totalSugarGramsPerServing: Double
    let seasonalIngredients: [String]
    let ingredients: [Ingredient]
    let steps: [String]
    let crossContactNotes: String

    enum CodingKeys: String, CodingKey {
        case id, name, cuisine
        case mealTimes = "meal_times"
        case servings, vegetarian, allergens
        case sugarTags = "sugar_tags"
        case addedSugarGramsPerServing = "added_sugar_grams_per_serving"
        case netCarbsGramsPerServing = "net_carbs_grams_per_serving"
        case totalSugarGramsPerServing = "total_sugar_grams_per_serving"
        case seasonalIngredients = "seasonal_ingredients"
        case ingredients, steps
        case crossContactNotes = "cross_contact_notes"
    }
}

struct RecipeCatalog: Codable {
    let version: Int
    let recipes: [Recipe]
}

struct UserPreferences: Codable, Equatable {
    var acceptedDisclaimer: Bool
    var completedQuestionnaire: Bool
    var cuisine: Cuisine?
    var diet: DietPreference
    var sugarMode: SugarMode
    var allergens: [MajorAllergen]
    var householdSize: Int
    var mealTime: MealTime
    var preferOrganic: Bool

    static let `default` = UserPreferences(
        acceptedDisclaimer: false,
        completedQuestionnaire: false,
        cuisine: nil,
        diet: .nonVegetarian,
        sugarMode: .none,
        allergens: [],
        householdSize: 2,
        mealTime: .fullDay,
        preferOrganic: true
    )
}

struct PlannedMeal: Identifiable, Hashable {
    let id: String
    let mealTime: MealTime
    let recipe: Recipe
    let scaleFactor: Double

    var scaledIngredients: [Ingredient] {
        recipe.ingredients
            .filter { $0.quantity > 0 }
            .map { $0.scaled(by: scaleFactor) }
    }
}

struct MealPlan: Identifiable {
    let id: UUID
    let meals: [PlannedMeal]
    let generatedAt: Date
    let preferences: UserPreferences
}

enum HealthVerdictKind: String, Codable {
    case healthy
    case unhealthy
}

struct HealthVerdict: Identifiable, Hashable {
    let id: String
    let kind: HealthVerdictKind
    let reason: String
    let sources: [String]
}

struct PricedOffer: Hashable {
    let amount: Double?
    let store: String?
    let unit: String?
    let url: String?
    let fetchedAt: Date
    let unavailable: Bool

    static func unavailable(fetchedAt: Date) -> PricedOffer {
        PricedOffer(amount: nil, store: nil, unit: nil, url: nil, fetchedAt: fetchedAt, unavailable: true)
    }
}

struct IngredientPrice: Identifiable, Hashable {
    let id: String
    let ingredientId: String
    let conventional: PricedOffer
    let organic: PricedOffer

    var organicPremiumPercent: Double? {
        guard let c = conventional.amount, let o = organic.amount, c > 0 else { return nil }
        return ((o - c) / c) * 100.0
    }

    var exceedsOrganicPremiumThreshold: Bool {
        guard let p = organicPremiumPercent else { return false }
        return p > 25.0
    }
}

struct ShoppingListItem: Identifiable, Hashable {
    let id: String
    let ingredient: Ingredient
    let price: IngredientPrice?
}
