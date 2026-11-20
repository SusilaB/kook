import Foundation
import Combine

@MainActor
final class PreferencesStore: ObservableObject {
    @Published var preferences: UserPreferences {
        didSet { persist() }
    }

    /// True while the user reopened the questionnaire from Plan / Settings to change filters.
    @Published private(set) var isEditingQuestionnaire = false

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

    /// Leave the plan tab and reopen the mood questionnaire with current answers.
    func beginEditingQuestionnaire() {
        isEditingQuestionnaire = true
        var next = preferences
        next.completedQuestionnaire = false
        preferences = next
    }

    /// Discard questionnaire edits and return to the existing plan.
    func cancelQuestionnaireEdit() {
        guard isEditingQuestionnaire else { return }
        isEditingQuestionnaire = false
        var next = preferences
        next.completedQuestionnaire = true
        preferences = next
    }

    func skipQuestionnaireAndUseDefaults() {
        isEditingQuestionnaire = false
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
        isEditingQuestionnaire = false
        var next = value
        next.acceptedDisclaimer = true
        next.completedQuestionnaire = true
        preferences = next
    }

    func resetOnboarding() {
        isEditingQuestionnaire = false
        preferences = .default
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(preferences) {
            defaults.set(data, forKey: key)
        }
    }
}
