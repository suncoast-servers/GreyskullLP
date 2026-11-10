import 'package:flutter/material.dart';
import 'package:greyskull_lp/models/food_search_result.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/services/food_search_service.dart';

class DietPage extends StatefulWidget {
  const DietPage({super.key});

  @override
  State<DietPage> createState() => _DietPageState();
}

class _DietPageState extends State<DietPage> {
  final FoodSearchService _foodSearchService = FoodSearchService();
  final TextEditingController _proteinController = TextEditingController();
  final TextEditingController _calorieController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<FoodSearchResult> _results = <FoodSearchResult>[];

  @override
  void dispose() {
    _proteinController.dispose();
    _calorieController.dispose();
    _noteController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchFoods() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      return;
    }

    setState(() {
      _isSearching = true;
    });
    try {
      final items = await _foodSearchService.searchFoods(
        query,
        usdaApiKey: trainingState.usdaApiKey,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _results = items;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _addEntry() {
    final protein = int.tryParse(_proteinController.text.trim()) ?? 0;
    final calories = int.tryParse(_calorieController.text.trim()) ?? 0;
    if (protein <= 0 && calories <= 0) {
      return;
    }

    trainingState.logDietIntake(
      proteinGrams: protein,
      calories: calories,
      note: _noteController.text.trim(),
    );
    _proteinController.clear();
    _calorieController.clear();
    _noteController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Diet entry saved to history')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: trainingState,
      builder: (context, _) {
        final calorieProgress = trainingState.dailyCalorieTarget == 0
            ? 0.0
            : (trainingState.dailyCaloriesConsumed /
                    trainingState.dailyCalorieTarget)
                .clamp(0.0, 1.0);
        final proteinProgress = trainingState.dailyProteinTarget == 0
            ? 0.0
            : (trainingState.dailyProteinConsumed /
                    trainingState.dailyProteinTarget)
                .clamp(0.0, 1.0);
        final calorieDelta = trainingState.dailyCaloriesConsumed -
            trainingState.dailyCalorieTarget;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Diet Tracker',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Today: ${trainingState.macroTrackingDate.year}-${trainingState.macroTrackingDate.month.toString().padLeft(2, '0')}-${trainingState.macroTrackingDate.day.toString().padLeft(2, '0')}',
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mode: ${TrainingState.nutritionModeLabel(trainingState.nutritionMode)}',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Protein: ${trainingState.dailyProteinConsumed}g / ${trainingState.dailyProteinTarget}g',
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(value: proteinProgress),
                    const SizedBox(height: 10),
                    Text(
                      'Calories: ${trainingState.dailyCaloriesConsumed} / ${trainingState.dailyCalorieTarget} kcal',
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(value: calorieProgress),
                    const SizedBox(height: 10),
                    Text(
                      trainingState.nutritionMode == NutritionMode.cutting
                          ? (calorieDelta <= 0
                              ? 'You are ${-calorieDelta} kcal under target (good for cutting).'
                              : 'You are $calorieDelta kcal over target.')
                          : (calorieDelta >= 0
                              ? 'You are $calorieDelta kcal over target (good for bulking).'
                              : 'You are ${-calorieDelta} kcal under bulking target.'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Search Free Food Databases',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Search foods',
                    ),
                    onSubmitted: (_) => _searchFoods(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _isSearching ? null : _searchFoods,
                  child: _isSearching
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Find'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Uses Open Food Facts first, then USDA fallback when configured in Settings.',
            ),
            const SizedBox(height: 8),
            ..._results.take(8).map(
                  (item) => Card(
                    child: ListTile(
                      title: Text(item.name),
                      subtitle: Text(
                        '${item.source} - ${item.calories} kcal, ${item.proteinGrams}g protein (${item.servingDescription})',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          trainingState.logDietIntake(
                            proteinGrams: item.proteinGrams,
                            calories: item.calories,
                            note: '${item.name} (${item.source})',
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Added ${item.name}')),
                          );
                        },
                      ),
                    ),
                  ),
                ),
            const SizedBox(height: 12),
            TextField(
              controller: _proteinController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Protein (grams)',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _calorieController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Calories',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Meal note (optional)',
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _addEntry,
              icon: const Icon(Icons.add),
              label: const Text('Add Entry'),
            ),
            OutlinedButton.icon(
              onPressed: trainingState.resetTodaysMacros,
              icon: const Icon(Icons.refresh),
              label: const Text('Reset Today'),
            ),
            const Divider(height: 32),
            const Text(
              'Future Integration Idea',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'You can integrate a free open-food database later and keep this local tracker as an offline fallback.',
            ),
          ],
        );
      },
    );
  }
}
