import 'package:flutter_test/flutter_test.dart';
import 'package:greyskull_lp/services/food_search_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Food search provider policy (issue #48)', () {
    test('public builds ship without a USDA key', () {
      expect(FoodSearchService.buildTimeUsdaKey, isEmpty);
    });

    test('USDA fallback only runs with a key and thin OFF results', () {
      expect(
        FoodSearchService.shouldQueryUsda(
          openFoodFactsCount: 0,
          apiKey: 'build-time-key',
        ),
        isTrue,
      );
      expect(
        FoodSearchService.shouldQueryUsda(
          openFoodFactsCount: 8,
          apiKey: 'build-time-key',
        ),
        isFalse,
      );
      expect(
        FoodSearchService.shouldQueryUsda(
          openFoodFactsCount: 0,
          apiKey: '   ',
        ),
        isFalse,
      );
    });

    test('blank queries short-circuit without any network call', () async {
      const service = FoodSearchService();
      expect(await service.searchFoods('   '), isEmpty);
      expect(await service.searchFoods(''), isEmpty);
    });
  });
}
