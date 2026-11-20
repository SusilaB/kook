import SwiftUI

struct DisclaimerView: View {
    @EnvironmentObject private var prefs: PreferencesStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Kook")
                        .font(.largeTitle.bold())
                    Text("Allergy-safe healthy cooking — US prototype")
                        .font(.title3)
                        .foregroundStyle(.secondary)

                    Group {
                        Text(DisclaimerPresentation.medicalHeading)
                            .font(.headline)
                            .accessibilityIdentifier("disclaimer.medical.heading")
                        Text(DisclaimerPresentation.medicalBody)
                            .accessibilityIdentifier(DisclaimerPresentation.medicalBodyAccessibilityID)
                        Text("Region & data")
                            .font(.headline)
                        Text("This prototype is US-only and prices are shown in USD. Preferences stay on this device — no accounts or cloud sync. Prices are stub fixtures (not live scrapes) and are timestamped; missing prices show as unavailable.")
                        Text("Allergens")
                            .font(.headline)
                        Text("Only the major 9 US allergens are supported: milk, eggs, fish, shellfish, tree nuts, peanuts, wheat, soy, and sesame. Free-text allergies are out of scope for v1.")
                    }
                    .font(.body)
                }
                .padding()
            }
            .safeAreaInset(edge: .bottom) {
                Button(DisclaimerPresentation.continueTitle) {
                    prefs.acceptDisclaimer()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.ultraThinMaterial)
                .accessibilityIdentifier(DisclaimerPresentation.continueAccessibilityID)
            }
            .navigationTitle("Welcome")
            .accessibilityIdentifier(DisclaimerPresentation.screenAccessibilityID)
        }
    }
}
