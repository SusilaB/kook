import Foundation

/// Copy for the welcome disclaimer screen — unit-testable without ViewInspector.
enum DisclaimerPresentation {
    static let medicalHeading = "Medical disclaimer"
    static let medicalBody =
        "Kook is not medical advice. Nutrition thresholds are draft values pending registered dietitian review. If you have allergies, diabetes, or another medical condition, consult a clinician before changing your diet."
    static let continueTitle = "I understand — continue"
    static let screenAccessibilityID = "disclaimer.screen"
    static let medicalBodyAccessibilityID = "disclaimer.medical.body"
    static let continueAccessibilityID = "disclaimer.continue"
}
