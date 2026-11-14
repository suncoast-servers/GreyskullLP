import 'dart:async';

import 'package:flutter/material.dart';
import 'package:greyskull_lp/models/food_search_result.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/themes/theme.dart';
import 'package:greyskull_lp/services/food_search_service.dart';
import 'package:greyskull_lp/widgets/body_measurements_card.dart';

class DietPage extends StatefulWidget {
  const DietPage({super.key, this.searchService});

  /// Injectable for tests; production uses the Open Food Facts client.
  final FoodSearchService? searchService;

  @override
  State<DietPage> createState() => _DietPageState();
}

class _DietPageState extends State<DietPage> {
  late final FoodSearchService _foodSearchService =
      widget.searchService ?? FoodSearchService();
  final TextEditingController _proteinController = TextEditingController();
  final TextEditingController _calorieController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<FoodSearchResult> _results = <FoodSearchResult>[];
  Timer? _searchDebounce;
  String _query = '';
  String? _lastLoggedFood;

  @override
  void dispose() {
    _proteinController.dispose();
    _calorieController.dispose();
    _noteController.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    FocusScope.of(context).unfocus();
    setState(() {
      _query = '';
      _results = <FoodSearchResult>[];
      _lastLoggedFood = null;
      _isSearching = false;
    });
  }

  void _onQueryChanged(String value) {
    final query = value.trim();
    _searchDebounce?.cancel();
    setState(() {
      _query = query;
      _lastLoggedFood = null;
    });
    if (query.length < 3) {
      setState(() => _results = <FoodSearchResult>[]);
      return;
    }
    // Typeahead: search as the user types, debounced to protect the API.
    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      _searchFoods();
    });
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

  List<Widget> _loggedTodaySection(BuildContext context) {
    final now = DateTime.now();
    final todayEntries = trainingState.history
        .where((e) =>
            e.category == HistoryCategory.diet &&
            e.timestamp.year == now.year &&
            e.timestamp.month == now.month &&
            e.timestamp.day == now.day)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final visible = todayEntries.take(10).toList();

    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Logged today',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            '${todayEntries.length} ${todayEntries.length == 1 ? 'entry' : 'entries'}',
            style: TextStyle(fontSize: 12, color: AppTheme.mutedText(context)),
          ),
        ],
      ),
      const SizedBox(height: 6),
      if (visible.isEmpty)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              'Nothing logged yet today. Search above or add an entry.',
              style:
                  TextStyle(fontSize: 12, color: AppTheme.mutedText(context)),
            ),
          ),
        )
      else
        ...visible.map((entry) {
          final note = entry.details
              .split('\n')
              .where((line) => line.startsWith('Note: '))
              .map((line) => line.substring(6).trim())
              .firstWhere((line) => line.isNotEmpty, orElse: () => '');
          final time = '${entry.timestamp.hour.toString().padLeft(2, '0')}:'
              '${entry.timestamp.minute.toString().padLeft(2, '0')}';
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 3),
            child: ListTile(
              dense: true,
              leading: Icon(Icons.restaurant_outlined,
                  size: 20, color: Theme.of(context).colorScheme.secondary),
              title: Text(note.isEmpty ? 'Diet intake' : note,
                  style: const TextStyle(fontSize: 13.5)),
              subtitle: Text(
                '${entry.proteinGrams ?? 0}g protein · '
                '${entry.calories ?? 0} kcal · $time',
                style: const TextStyle(fontSize: 11.5),
              ),
            ),
          );
        }),
    ];
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
                    LinearProgressIndicator(
                      value: proteinProgress,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                      backgroundColor:
                          Theme.of(context).colorScheme.onSurface.withValues(
                                alpha: 0.12,
                              ),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Calories: ${trainingState.dailyCaloriesConsumed} / ${trainingState.dailyCalorieTarget} kcal',
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: calorieProgress,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                      backgroundColor:
                          Theme.of(context).colorScheme.onSurface.withValues(
                                alpha: 0.12,
                              ),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.secondary,
                      ),
                    ),
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
            const BodyMeasurementsCard(),
            const SizedBox(height: 16),
            const Text(
              'Search Foods',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _searchController,
              onChanged: _onQueryChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'Search foods',
                suffixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.close),
                            onPressed: _clearSearch,
                          ),
              ),
            ),
            if (_lastLoggedFood != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.check_circle,
                      size: 16, color: Theme.of(context).colorScheme.secondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Logged $_lastLoggedFood to today',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.mutedText(context),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 6),
            if (!_isSearching && _query.length >= 3 && _results.isEmpty)
              Text(
                'No matches for "$_query"',
                style:
                    TextStyle(fontSize: 12, color: AppTheme.mutedText(context)),
              ),
            const SizedBox(height: 8),
            const Text(
              'Search Open Food Facts for calories and protein, then add an item with one tap.',
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
                        tooltip: 'Log ${item.name}',
                        onPressed: () {
                          trainingState.logDietIntake(
                            proteinGrams: item.proteinGrams,
                            calories: item.calories,
                            note: '${item.name} (${item.source})',
                          );
                          _searchDebounce?.cancel();
                          _searchController.clear();
                          FocusScope.of(context).unfocus();
                          setState(() {
                            _query = '';
                            _results = <FoodSearchResult>[];
                            _lastLoggedFood = item.name;
                          });
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
            const SizedBox(height: 20),
            ..._loggedTodaySection(context),
          ],
        );
      },
    );
  }
}
