import Foundation

/// Copy for the plan summary screen — unit-testable without ViewInspector.
enum PlanSummaryPresentation {
    static let navigationTitle = "Today’s plan"
    static let editPreferencesTitle = "Edit preferences"
    static let refreshTitle = "Refresh"
    static let noPlanTitle = "No plan yet"
    static let noPlanDescription = "Generate a plan from Settings or re-run the questionnaire."
    static let noMatchesTitle = "No matching recipes"
    static let noMatchesDescription =
        "No seed recipes match this cuisine, meal time, diet, and allergen filters. Change preferences and try again."
    static let editPreferencesAccessibilityID = "plan.editPreferences"
    static let refreshAccessibilityID = "plan.refresh"
    static let noMatchesAccessibilityID = "plan.noMatches"
    static let screenAccessibilityID = "plan.screen"

    static func householdScaleLine(people: Int) -> String {
        "Scaled for \(people) · US / USD prototype"
    }
}
