import SwiftUI

struct QuestionnaireView: View {
    @EnvironmentObject private var prefs: PreferencesStore
    @EnvironmentObject private var app: AppModel

    @State private var draft: UserPreferences = .default

    var body: some View {
        NavigationStack {
            Form {
                Section("Cuisine mood") {
                    Picker("Cuisine", selection: Binding(
                        get: { draft.cuisine ?? .american },
                        set: { draft.cuisine = $0 }
                    )) {
                        ForEach(Cuisine.allCases) { c in
                            Text(c.displayName).tag(c)
                        }
                    }
                }

                Section("Diet") {
                    Picker("Preference", selection: $draft.diet) {
                        ForEach(DietPreference.allCases) { d in
                            Text(d.displayName).tag(d)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Sugar mode") {
                    Picker("Mode", selection: $draft.sugarMode) {
                        ForEach(SugarMode.allCases) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                }

                Section("Major-9 allergens to exclude") {
                    ForEach(MajorAllergen.allCases) { allergen in
                        Toggle(allergen.displayName, isOn: Binding(
                            get: { draft.allergens.contains(allergen) },
                            set: { on in
                                if on {
                                    draft.allergens.append(allergen)
                                } else {
                                    draft.allergens.removeAll { $0 == allergen }
                                }
                            }
                        ))
                    }
                }

                Section("Household") {
                    Stepper("People: \(draft.householdSize)", value: $draft.householdSize, in: 1...12)
                    Picker("Meal time", selection: $draft.mealTime) {
                        ForEach(MealTime.allCases) { m in
                            Text(m.displayName).tag(m)
                        }
                    }
                }
            }
            .navigationTitle("Mood check-in")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") {
                        prefs.skipQuestionnaireAndUseDefaults()
                        app.regenerate(using: prefs.preferences)
                    }
                    .accessibilityIdentifier("questionnaire.skip")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Build plan") {
                        draft.acceptedDisclaimer = true
                        prefs.saveQuestionnaire(draft)
                        app.regenerate(using: prefs.preferences)
                    }
                    .accessibilityIdentifier("questionnaire.build")
                }
            }
            .onAppear {
                draft = prefs.preferences
                draft.acceptedDisclaimer = true
                if draft.cuisine == nil { draft.cuisine = .american }
            }
            .accessibilityIdentifier("questionnaire.screen")
        }
    }
}
