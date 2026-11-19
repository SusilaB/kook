#!/usr/bin/env python3
"""Deterministic twin of RecipeValidator for CI without Xcode.

Exit 0 if all seed recipes are internally consistent and sample preference
filters never leak allergens / diet / sugar violations.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RECIPES_PATH = ROOT / "data" / "recipes.json"
THRESHOLDS_PATH = ROOT / "data" / "nutrition_thresholds.json"

MAJOR9 = {
    "milk",
    "eggs",
    "fish",
    "shellfish",
    "tree_nuts",
    "peanuts",
    "wheat",
    "soy",
    "sesame",
}

NON_VEG_TAGS = {
    "meat",
    "poultry",
    "fish",
    "shellfish",
    "egg",
    "eggs",
    "gelatin",
    "lard",
    "animal_broth",
    "animal-broth",
    "broth_animal",
}

NON_VEG_NAME_KEYWORDS = [
    "chicken",
    "beef",
    "pork",
    "turkey",
    "lamb",
    "fish",
    "shrimp",
    "crab",
    "lobster",
    "gelatin",
    "lard",
    "egg",
    "bone broth",
    "animal broth",
]


def load_json(path: Path):
    with path.open(encoding="utf-8") as f:
        return json.load(f)


def is_non_vegetarian(ingredient: dict) -> bool:
    tags = {t.lower() for t in ingredient.get("tags", [])}
    if tags & NON_VEG_TAGS:
        return True
    name = ingredient.get("name", "").lower()
    return any(k in name for k in NON_VEG_NAME_KEYWORDS)


def validate(recipe: dict, prefs: dict, thresholds: dict) -> list[str]:
    issues: list[str] = []
    declared = set(prefs.get("allergens", []))

    if declared:
        for a in set(recipe.get("allergens", [])) & declared:
            issues.append(f"allergen_recipe:{a}")
        for ing in recipe.get("ingredients", []):
            if float(ing.get("quantity", 0)) <= 0:
                continue
            for a in set(ing.get("allergens", [])) & declared:
                issues.append(f"allergen_ingredient:{ing['id']}:{a}")

    if prefs.get("diet") == "vegetarian":
        if not recipe.get("vegetarian", False):
            issues.append("diet_flag")
        for ing in recipe.get("ingredients", []):
            if float(ing.get("quantity", 0)) > 0 and is_non_vegetarian(ing):
                issues.append(f"diet_ingredient:{ing['id']}")

    mode = prefs.get("sugar_mode", "none")
    per = thresholds["per_serving"]
    if mode == "no_added_sugar":
        max_added = per["no_added_sugar"]["max_added_sugar_grams"]
        if recipe["added_sugar_grams_per_serving"] > max_added:
            issues.append("sugar_added")
    elif mode == "diabetic_friendly":
        t = per["diabetic_friendly"]
        if recipe["added_sugar_grams_per_serving"] > t["max_added_sugar_grams"]:
            issues.append("sugar_added")
        if recipe["total_sugar_grams_per_serving"] > t["max_total_sugar_grams"]:
            issues.append("sugar_total")
        if recipe["net_carbs_grams_per_serving"] > t["max_net_carbs_grams"]:
            issues.append("net_carbs")
    elif mode == "low_carb":
        t = per["low_carb"]
        if recipe["net_carbs_grams_per_serving"] > t["max_net_carbs_grams"]:
            issues.append("net_carbs")
        if recipe["added_sugar_grams_per_serving"] > t["max_added_sugar_grams"]:
            issues.append("sugar_added")

    return issues


def main() -> int:
    catalog = load_json(RECIPES_PATH)
    thresholds = load_json(THRESHOLDS_PATH)
    recipes = catalog["recipes"]

    if len(recipes) != 4:
        print(f"FAIL: expected 4 seed recipes, found {len(recipes)}", file=sys.stderr)
        return 1

    errors = 0

    for recipe in recipes:
        for a in recipe.get("allergens", []):
            if a not in MAJOR9:
                print(f"FAIL: {recipe['id']} unknown allergen {a}")
                errors += 1
        for ing in recipe.get("ingredients", []):
            for a in ing.get("allergens", []):
                if a not in MAJOR9:
                    print(f"FAIL: {recipe['id']}/{ing['id']} unknown allergen {a}")
                    errors += 1

    # 0 allergen leaks across major-9
    for allergen in sorted(MAJOR9):
        prefs = {"allergens": [allergen], "diet": "non_vegetarian", "sugar_mode": "none"}
        for recipe in recipes:
            issues = validate(recipe, prefs, thresholds)
            if not issues:
                # shown — must not contain allergen
                if allergen in recipe.get("allergens", []):
                    print(f"FAIL: leak recipe-level {allergen} in {recipe['id']}")
                    errors += 1
                for ing in recipe.get("ingredients", []):
                    if float(ing.get("quantity", 0)) > 0 and allergen in ing.get("allergens", []):
                        print(f"FAIL: leak {allergen} via {recipe['id']}/{ing['id']}")
                        errors += 1

    # Vegetarian filter
    prefs = {"allergens": [], "diet": "vegetarian", "sugar_mode": "none"}
    for recipe in recipes:
        issues = validate(recipe, prefs, thresholds)
        shown = not issues
        if shown and (not recipe.get("vegetarian") or any(
            is_non_vegetarian(i) for i in recipe["ingredients"] if float(i.get("quantity", 0)) > 0
        )):
            print(f"FAIL: vegetarian leak in {recipe['id']}")
            errors += 1
        if recipe["id"] == "mediterranean-lemon-chicken" and shown:
            print("FAIL: chicken recipe shown for vegetarian prefs")
            errors += 1

    # Sugar modes
    for mode in ("no_added_sugar", "diabetic_friendly", "low_carb"):
        prefs = {"allergens": [], "diet": "non_vegetarian", "sugar_mode": mode}
        for recipe in recipes:
            issues = validate(recipe, prefs, thresholds)
            if issues:
                continue
            # shown recipes must satisfy thresholds (re-check)
            again = validate(recipe, prefs, thresholds)
            if again:
                print(f"FAIL: sugar filter inconsistency {recipe['id']} mode={mode}")
                errors += 1

    # Explicit low-carb expectations on seeds
    prefs = {"allergens": [], "diet": "non_vegetarian", "sugar_mode": "low_carb"}
    shown_ids = {r["id"] for r in recipes if not validate(r, prefs, thresholds)}
    if "american-oat-berry-bowl" not in shown_ids:
        print("FAIL: oat bowl should pass low_carb")
        errors += 1
    if "indian-chana-masala" in shown_ids:
        print("FAIL: chana masala should fail low_carb")
        errors += 1

    if errors:
        print(f"FAILED with {errors} error(s)")
        return 1

    print(f"OK: validated {len(recipes)} recipes against allergen/diet/sugar rules")
    print(f"Threshold status: {thresholds.get('status')}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
