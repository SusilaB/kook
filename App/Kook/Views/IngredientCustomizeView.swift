import SwiftUI

struct IngredientCustomizeView: View {
    @EnvironmentObject private var app: AppModel
    let ingredient: Ingredient

    @State private var selectedReplacement: String = ""
    @State private var verdict: HealthVerdict?

    private var replacements: [(id: String, name: String)] {
        IngredientSwapService.commonReplacements.filter { $0.id != ingredient.id }
    }

    var body: some View {
        Form {
            Section("Current") {
                Text(ingredient.name)
                if let notes = ingredient.notes, !notes.isEmpty {
                    Text(notes).font(.footnote).foregroundStyle(.secondary)
                }
            }

            Section("Swap with") {
                Picker("Replacement", selection: $selectedReplacement) {
                    Text("Choose…").tag("")
                    ForEach(replacements, id: \.id) { r in
                        Text(r.name).tag(r.id)
                    }
                }
                Button("Get verdict") {
                    guard let match = replacements.first(where: { $0.id == selectedReplacement }) else { return }
                    verdict = app.swapService.evaluate(
                        from: ingredient,
                        to: match.id,
                        replacementName: match.name
                    )
                }
                .disabled(selectedReplacement.isEmpty)
                .accessibilityIdentifier("ingredient.swap.evaluate")
            }

            if let verdict {
                Section("Verdict") {
                    Label(
                        verdict.kind == .healthy ? "Healthy" : "Unhealthy",
                        systemImage: verdict.kind == .healthy ? "checkmark.seal.fill" : "xmark.octagon.fill"
                    )
                    .foregroundStyle(verdict.kind == .healthy ? .green : .red)
                    .accessibilityIdentifier("ingredient.swap.verdict.kind")
                    Text(verdict.reason)
                        .accessibilityIdentifier("ingredient.swap.verdict.reason")
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sources").font(.caption).bold()
                        ForEach(verdict.sources, id: \.self) { source in
                            Text("• \(source)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityIdentifier("ingredient.swap.verdict.sources")
                }
            }
        }
        .navigationTitle("Customize")
        .accessibilityIdentifier("ingredient.customize.screen")
    }
}
