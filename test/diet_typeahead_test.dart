import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greyskull_lp/models/food_search_result.dart';
import 'package:greyskull_lp/pages/diet_page.dart';
import 'package:greyskull_lp/services/food_search_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeSearch extends FoodSearchService {
  _FakeSearch();

  int calls = 0;

  @override
  Future<List<FoodSearchResult>> searchFoods(
    String query, {
    String? usdaApiKeyOverride,
  }) async {
    calls += 1;
    return [
      FoodSearchResult(
        name: 'Greek Yogurt (${query.trim()})',
        calories: 100,
        proteinGrams: 10,
        source: 'Open Food Facts',
        servingDescription: 'per 100g',
      ),
    ];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('typeahead searches after three characters without a Find button',
      (tester) async {
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fake = _FakeSearch();
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: DietPage(searchService: fake))),
    );
    await tester.pumpAndSettle();

    // No separate search button any more.
    expect(find.widgetWithText(FilledButton, 'Find'), findsNothing);

    final field = find.widgetWithText(TextField, 'Search foods');
    await tester.enterText(field, 'gy');
    await tester.pump(const Duration(milliseconds: 600));
    expect(fake.calls, 0, reason: 'under three characters should not search');

    await tester.enterText(field, 'greek yogurt');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(fake.calls, greaterThanOrEqualTo(1));
    expect(find.textContaining('Greek Yogurt'), findsOneWidget);
  });
}
