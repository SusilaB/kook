import SwiftUI

struct RootView: View {
    @EnvironmentObject private var prefs: PreferencesStore
    @EnvironmentObject private var app: AppModel

    var body: some View {
        Group {
            if !prefs.preferences.acceptedDisclaimer {
                DisclaimerView()
            } else if !prefs.preferences.completedQuestionnaire {
                QuestionnaireView()
            } else {
                MainTabView()
                    .onAppear {
                        if app.plan == nil {
                            app.regenerate(using: prefs.preferences)
                        }
                    }
            }
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            PlanSummaryView()
                .tabItem { Label("Plan", systemImage: "fork.knife") }
            ShoppingListView()
                .tabItem { Label("Shop", systemImage: "cart") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}
