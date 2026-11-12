import 'dart:convert';

import 'package:greyskull_lp/models/food_search_result.dart';
import 'package:http/http.dart' as http;

/// Food lookups for the Diet page.
///
/// Open Food Facts is the keyless default. Building with
/// `--dart-define=USDA_API_KEY=...` enables the USDA FoodData Central fallback
/// for US/branded coverage without ever asking users for a key (issue #48).
class FoodSearchService {
  const FoodSearchService();

  /// Empty in the public build, so the app stays keyless by default.
  static const String buildTimeUsdaKey = String.fromEnvironment('USDA_API_KEY');

  /// Open Food Facts rejects requests without a descriptive User-Agent.
  static const String userAgent =
      'GreyskullLP/1.0 (+https://github.com/suncoast-servers/GreyskullLP)';

  /// USDA is only queried when a build-time key exists and Open Food Facts
  /// returned too few matches.
  static bool shouldQueryUsda({
    required int openFoodFactsCount,
    required String apiKey,
  }) =>
      apiKey.trim().isNotEmpty && openFoodFactsCount < 8;

  Future<List<FoodSearchResult>> searchFoods(
    String query, {
    String? usdaApiKeyOverride,
  }) async {
    if (query.trim().isEmpty) {
      return <FoodSearchResult>[];
    }

    final apiKey = (usdaApiKeyOverride ?? buildTimeUsdaKey).trim();
    final offResults = await _searchOpenFoodFacts(query);
    if (!shouldQueryUsda(
      openFoodFactsCount: offResults.length,
      apiKey: apiKey,
    )) {
      return offResults;
    }

    final usdaResults = await _searchUsda(query, apiKey);
    final merged = <FoodSearchResult>[...offResults];
    for (final item in usdaResults) {
      final exists = merged.any(
        (existing) => existing.name.toLowerCase() == item.name.toLowerCase(),
      );
      if (!exists) {
        merged.add(item);
      }
      if (merged.length >= 16) {
        break;
      }
    }
    return merged;
  }

  Future<List<FoodSearchResult>> _searchOpenFoodFacts(String query) async {
    final uri =
        Uri.https('world.openfoodfacts.org', '/cgi/search.pl', <String, String>{
      'search_terms': query,
      'search_simple': '1',
      'action': 'process',
      'json': '1',
      'page_size': '12',
    });

    final response = await _get(uri);
    if (response == null) {
      return <FoodSearchResult>[];
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final products = body['products'] as List<dynamic>? ?? <dynamic>[];
    final output = <FoodSearchResult>[];

    for (final dynamic raw in products) {
      if (raw is! Map) {
        continue;
      }
      final map = raw.map((key, value) => MapEntry(key.toString(), value));
      final name = (map['product_name'] as String? ?? '').trim();
      if (name.isEmpty) {
        continue;
      }

      final nutrimentsRaw = map['nutriments'];
      if (nutrimentsRaw is! Map) {
        continue;
      }
      final nutriments =
          nutrimentsRaw.map((key, value) => MapEntry(key.toString(), value));

      final calories = _asInt(
        nutriments['energy-kcal_100g'] ?? nutriments['energy-kcal_serving'],
      );
      final protein = _asInt(
        nutriments['proteins_100g'] ?? nutriments['proteins_serving'],
      );
      if (calories <= 0 && protein <= 0) {
        continue;
      }

      output.add(
        FoodSearchResult(
          name: name,
          calories: calories,
          proteinGrams: protein,
          source: 'Open Food Facts',
          servingDescription: 'Approx per 100g',
        ),
      );
      if (output.length >= 12) {
        break;
      }
    }
    return output;
  }

  /// GET with the required User-Agent and a short timeout; returns null on any
  /// transport/HTTP failure so the UI can fall back to "no results".
  Future<http.Response?> _get(Uri uri) async {
    try {
      final response = await http.get(uri, headers: {
        'User-Agent': userAgent
      }).timeout(const Duration(seconds: 12));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      return response;
    } catch (_) {
      return null;
    }
  }

  Future<List<FoodSearchResult>> _searchUsda(
      String query, String apiKey) async {
    final uri =
        Uri.https('api.nal.usda.gov', '/fdc/v1/foods/search', <String, String>{
      'api_key': apiKey,
      'query': query,
      'pageSize': '10',
    });

    final response = await _get(uri);
    if (response == null) {
      return <FoodSearchResult>[];
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final foods = body['foods'] as List<dynamic>? ?? <dynamic>[];
    final output = <FoodSearchResult>[];

    for (final dynamic raw in foods) {
      if (raw is! Map) {
        continue;
      }
      final map = raw.map((key, value) => MapEntry(key.toString(), value));
      final name = (map['description'] as String? ?? '').trim();
      if (name.isEmpty) {
        continue;
      }
      final nutrients = map['foodNutrients'] as List<dynamic>? ?? <dynamic>[];
      int calories = 0;
      int protein = 0;
      for (final dynamic nutrientRaw in nutrients) {
        if (nutrientRaw is! Map) {
          continue;
        }
        final nutrient =
            nutrientRaw.map((key, value) => MapEntry(key.toString(), value));
        final nutrientNumber = nutrient['nutrientNumber']?.toString() ?? '';
        if (nutrientNumber == '1008') {
          calories = _asInt(nutrient['value']);
        } else if (nutrientNumber == '1003') {
          protein = _asInt(nutrient['value']);
        }
      }
      if (calories <= 0 && protein <= 0) {
        continue;
      }
      output.add(
        FoodSearchResult(
          name: name,
          calories: calories,
          proteinGrams: protein,
          source: 'USDA FoodData Central',
          servingDescription: 'Approx per 100g',
        ),
      );
    }
    return output;
  }

  int _asInt(dynamic value) {
    if (value == null) {
      return 0;
    }
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.round();
    }
    return double.tryParse(value.toString())?.round() ?? 0;
  }
}
