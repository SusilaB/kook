import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var prefs: PreferencesStore
    @EnvironmentObject private var app: AppModel

    var body: some View {
        NavigationStack {
            Form {
                Section("Preferences") {
                    Text("Diet: \(prefs.preferences.diet.displayName)")
                    Text("Sugar: \(prefs.preferences.sugarMode.displayName)")
                    Text("Household: \(prefs.preferences.householdSize)")
                    Text("Meal focus: \(prefs.preferences.mealTime.displayName)")
                    if prefs.preferences.allergens.isEmpty {
                        Text("Allergens excluded: none")
                    } else {
                        Text("Allergens excluded: " + prefs.preferences.allergens.map(\.displayName).joined(separator: ", "))
                    }
                }

                Section("Prototype limits") {
                    Text("No LLM meal generation. No live price scraping. On-device storage only. US / USD.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text("Sugar thresholds are draft and need dietitian review.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Button("Redo mood questionnaire") {
                        prefs.beginEditingQuestionnaire()
                    }
                    Button("Reset all onboarding", role: .destructive) {
                        prefs.resetOnboarding()
                        app.plan = nil
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
