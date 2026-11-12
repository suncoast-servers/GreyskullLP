# Calorie Data Source (issue #48)

Decision record for the Diet food search: which nutrition API the app uses, and
how keys are handled.

## Requirements

- **No user-facing API keys.** Issue #47 removed the USDA key field from
  Settings; keys may only live in build configuration / owner secrets.
- Free or low-cost at our expected volume (a few searches per user per day).
- Reasonable coverage of packaged foods (barcodes/brand names) **and** generic
  foods, ideally with per-100 g macros so we can scale servings.
- Permissive enough licensing for an open-source app.

## Comparison

| Provider | Key required | Free tier | Coverage | License / notes |
|---|---|---|---|---|
| **Open Food Facts** | No | Unlimited with fair-use rate limits (~100 req/min product, ~10 req/min search) | Crowd-sourced packaged foods, strong EU coverage, barcodes | Database under **ODbL**, API free; quality varies per product |
| **USDA FoodData Central** | Yes (api.data.gov) | 1,000 requests/hour per key | Foundation + SR Legacy + Branded (US-centric, high quality) | **Public domain** data; key cannot be committed |
| Nutritionix | Yes | ~500 requests/day | Excellent branded coverage, natural-language queries | Commercial terms; attribution required |
| Edamam | Yes | ~10k requests/month | Branded + generic, good macro detail | Attribution + plan limits |
| CalorieNinjas | Yes | ~10k requests/month | Simple nutrition lookup | Commercial terms, smaller DB |

## Decision

1. **Open Food Facts is the default and only keyless source.** It keeps the app
   usable out of the box, and the Diet page already consumes it.
2. **USDA FoodData Central is an optional build-time enhancement.** If the build
   is compiled with `--dart-define=USDA_API_KEY=...`, the service queries USDA
   when Open Food Facts returns fewer than 8 matches. Public OSS builds get the
   keyless behaviour automatically.
3. **No keys in git.** The key comes from build config (CI secret or local
   `--dart-define`), never from Settings or a committed file.
4. Nutritionix/Edamam are not selected: a paid or trial key would be required
   for every install and their terms complicate a free, open-source release.

## Implementation

`lib/services/food_search_service.dart`:

```dart
class FoodSearchService {
  const FoodSearchService();

  /// Empty in the public build, so the app stays keyless by default.
  static const String buildTimeUsdaKey = String.fromEnvironment('USDA_API_KEY');

  static bool shouldQueryUsda({
    required int openFoodFactsCount,
    required String apiKey,
  }) =>
      apiKey.trim().isNotEmpty && openFoodFactsCount < 8;
}

// Diet page call site
final items = await const FoodSearchService().searchFoods(query);
```

Manual run with the optional fallback:

```bash
flutter run --dart-define=USDA_API_KEY=your_key_here
```

Sample response handling (already implemented):

```dart
final results = await const FoodSearchService().searchFoods('greek yogurt');
// FoodSearchResult(name, proteinGrams, calories, servingDescription, source)
```

## Follow-ups

- Track Open Food Facts search latency/failures; its search endpoint is slower
  than barcode lookups. A barcode scanner should hit `/api/v2/product/<code>`.
- If branded coverage becomes a blocker for US users, revisit Nutritionix with a
  server-side proxy rather than shipping a key in the client.
