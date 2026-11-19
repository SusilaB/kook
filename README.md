# Kook

Allergy-safe healthy cooking and diet-plan **iPhone prototype** (SwiftUI, iOS 17+).

**Owner:** SusilaB · **Region:** US only · **Currency:** USD

## Important limits (prototype)

- **Not medical advice.** Draft sugar/carb thresholds in `data/nutrition_thresholds.json` need registered dietitian review before they are treated as approved.
- **No LLM** meal generation in this phase.
- **No live price scraping.** `StubPriceProvider` serves fixture USD prices (Walmart / Costco / Safeway–shaped). Missing prices show as **price unavailable**, with a fixture timestamp.
- **On-device storage only** (UserDefaults JSON preferences). No accounts or sync.
- **Major-9 allergens only** (milk, eggs, fish, shellfish, tree nuts, peanuts, wheat, soy, sesame). No free-text allergies.
- **Vegetarian** excludes meat, poultry, fish, shellfish, eggs, gelatin, lard, and animal broth. Dairy and honey are OK.
- **Seasonality** badges come from sourced US produce data; unknown produce gets **no badge**. Seasonality only boosts ranking.
- **Organic premium threshold:** 25% (UI callout when organic costs more than that over conventional).

## Open in Xcode (Mac)

1. Clone this repository on a Mac with Xcode 15+ (iOS 17 SDK).
2. Open **`App/Kook.xcodeproj`** (double-click or `open App/Kook.xcodeproj`).
3. Select an **iPhone simulator** (e.g. iPhone 16).
4. Press **Run** (⌘R).

Optional tests:

```bash
xcodebuild test -project App/Kook.xcodeproj -scheme Kook -destination 'platform=iOS Simulator,name=iPhone 16'
```

If you regenerate the project after adding Swift files:

```bash
python3 tools/generate_xcodeproj.py
```

## Validate seed recipes without Xcode

```bash
python3 tools/validate_recipes.py
```

## App flow

1. Medical / US / prototype **disclaimer**
2. Skippable **mood questionnaire** (cuisine, veg/non-veg, sugar mode, major-9 allergens, household size, meal time)
3. **Plan summary** → recipe detail (scaled ingredients, steps, badges)
4. **Shopping list** with organic vs conventional stub prices and buy-where stores
5. **Ingredient customize** → healthy/unhealthy verdict with **cited sources** (rule table, not LLM)

Skip questionnaire → full-day plan from the 4 seed recipes (still filtered by defaults via `RecipeValidator`).

## Layout

| Path | Purpose |
|------|---------|
| `App/Kook.xcodeproj` | Xcode project |
| `App/Kook/` | SwiftUI app sources |
| `App/Kook/Resources/` | Bundled JSON (copy of `data/`) |
| `App/KookTests/` | Validator / price / swap unit tests |
| `data/` | Seed recipes, thresholds, seasonality, price fixtures, verdict rules |
| `tools/validate_recipes.py` | CI twin of `RecipeValidator` |
| `tools/generate_xcodeproj.py` | Regenerates the `.xcodeproj` on Linux/Mac |

## Architecture

- `MealPlanService` + seed `recipes.json` + `RecipeValidator`
- `ShoppingListService` + `PriceProvider` / `StubPriceProvider`
- `IngredientSwapService` + `HealthVerdictRules`
- `PreferencesStore` (on-device)

## Disclaimer

Kook does not diagnose, treat, or manage disease. People with allergies or metabolic conditions should consult a clinician. Prices and availability in this prototype are fixtures, not live market data.
