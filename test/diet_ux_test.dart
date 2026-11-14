import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greyskull_lp/models/food_search_result.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/pages/diet_page.dart';
import 'package:greyskull_lp/services/food_search_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeSearch extends FoodSearchService {
  @override
  Future<List<FoodSearchResult>> searchFoods(
    String query, {
    String? usdaApiKeyOverride,
  }) async =>
      [
        FoodSearchResult(
          name: 'Skyr (${query.trim()})',
          calories: 120,
          proteinGrams: 20,
          source: 'Open Food Facts',
          servingDescription: 'per 100g',
        ),
      ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    for (final entry in trainingState.history.toList()) {
      trainingState.deleteHistoryEntry(entry.id);
    }
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: DietPage(searchService: _FakeSearch()))),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('selecting a food acknowledges, closes search and lists it',
      (tester) async {
    await pump(tester);

    final field = find.widgetWithText(TextField, 'Search foods');
    await tester.enterText(field, 'skyr');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Log Skyr (skyr)'));
    await tester.pumpAndSettle();

    // Acknowledged inline, search UI closed, field cleared.
    expect(find.textContaining('Logged Skyr (skyr) to today'), findsOneWidget);
    expect(find.text('Skyr (skyr)'), findsNothing);
    final textField = tester.widget<TextField>(field);
    expect(textField.controller?.text, isEmpty);

    // Logged foods live at the bottom of the page.
    expect(find.text('Logged today'), findsOneWidget);
    expect(
        trainingState.history
            .where((e) => e.category == HistoryCategory.diet)
            .length,
        1);
    await tester.scrollUntilVisible(
      find.text('Logged today'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('20g protein'), findsOneWidget);
  });

  testWidgets('search field shows a clear X when it has text', (tester) async {
    await pump(tester);

    expect(find.byTooltip('Clear search'), findsNothing);
    final field = find.widgetWithText(TextField, 'Search foods');
    await tester.enterText(field, 'milk');
    await tester.pump();

    expect(find.byTooltip('Clear search'), findsOneWidget);
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();

    expect(tester.widget<TextField>(field).controller?.text, isEmpty);
    expect(find.byTooltip('Clear search'), findsNothing);
  });
}
