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
                        Text("Medical disclaimer")
                            .font(.headline)
                        Text("Kook is not medical advice. Nutrition thresholds are draft values pending registered dietitian review. If you have allergies, diabetes, or another medical condition, consult a clinician before changing your diet.")
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
                Button("I understand — continue") {
                    prefs.acceptDisclaimer()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.ultraThinMaterial)
            }
            .navigationTitle("Welcome")
        }
    }
}
