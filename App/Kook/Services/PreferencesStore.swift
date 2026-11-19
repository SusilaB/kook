import Foundation
import Combine

@MainActor
final class PreferencesStore: ObservableObject {
    @Published var preferences: UserPreferences {
        didSet { persist() }
    }

    private let key = "kook.userPreferences.v1"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode(UserPreferences.self, from: data) {
            self.preferences = decoded
        } else {
            self.preferences = .default
        }
    }

    func acceptDisclaimer() {
        preferences.acceptedDisclaimer = true
    }

    func skipQuestionnaireAndUseDefaults() {
        var next = preferences
        next.completedQuestionnaire = true
        next.cuisine = nil
        next.diet = .nonVegetarian
        next.sugarMode = .none
        next.allergens = []
        next.householdSize = 2
        next.mealTime = .fullDay
        preferences = next
    }

    func saveQuestionnaire(_ value: UserPreferences) {
        var next = value
        next.acceptedDisclaimer = true
        next.completedQuestionnaire = true
        preferences = next
    }

    func resetOnboarding() {
        preferences = .default
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(preferences) {
            defaults.set(data, forKey: key)
        }
    }
}
