import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/services/lift_progress_service.dart';
import 'package:greyskull_lp/themes/app_icons.dart';
import 'package:greyskull_lp/themes/theme.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

enum _StatsRange {
  week(7, '7d'),
  month(30, '30d'),
  quarter(90, '90d'),
  all(3650, 'All');

  final int days;
  final String label;
  const _StatsRange(this.days, this.label);
}

enum _StatsCategory {
  overview('Overview', Icons.dashboard_outlined),
  resistance('Resistance', AppIcons.barbell),
  calisthenics('Calisthenics', Icons.accessibility_new),
  nutrition('Nutrition', Icons.restaurant);

  final String label;
  final IconData icon;
  const _StatsCategory(this.label, this.icon);
}

class _StatsPageState extends State<StatsPage> {
  _StatsRange _range = _StatsRange.week;
  _StatsCategory _category = _StatsCategory.overview;

  bool _isInRange(DateTime date) {
    if (_range == _StatsRange.all) return true;
    final cutoff = DateTime.now().subtract(Duration(days: _range.days));
    return date.isAfter(cutoff);
  }

  void _showMetricDefinitions() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Metric Definitions & Rules',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              _buildMetricHelp(
                title: 'Resistance Volume (lbs)',
                description:
                    'Total weight moved during working sets. Calculated as Weight (lbs) x Reps x Sets for each completed core barbell lift.',
              ),
              const SizedBox(height: 12),
              _buildMetricHelp(
                title: 'Calisthenics Volume (Reps)',
                description:
                    'Total bodyweight repetitions accumulated. Spans all active methods: Frequency (sub-maximal sets), Ladder (ascending rungs), and Total Work (density sessions).',
              ),
              const SizedBox(height: 12),
              _buildMetricHelp(
                title: 'Method Transitions',
                description:
                    'Milestones celebrating when a trainee progresses between Johnny Pain\'s calisthenics protocols or adopts heavy linear barbell progression.',
              ),
              const SizedBox(height: 12),
              _buildMetricHelp(
                title: 'Consistency Streak',
                description:
                    'Consecutive active days with at least one recorded workout session (resistance or calisthenics).',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricHelp(
      {required String title, required String description}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface,
              height: 1.3),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: trainingState,
      builder: (context, _) {
        final rangedEntries = trainingState.history
            .where((entry) => _isInRange(entry.timestamp))
            .toList();
        final weightEntries = rangedEntries
            .where((entry) => entry.category == HistoryCategory.weight)
            .toList();
        final dailyEntries = rangedEntries
            .where((entry) => entry.category == HistoryCategory.daily)
            .toList();
        final dietEntries = rangedEntries
            .where((entry) => entry.category == HistoryCategory.diet)
            .toList();

        final totalVolume = weightEntries.fold<double>(
          0,
          (sum, entry) => sum + (entry.weightVolume ?? 0),
        );
        final totalPushUps = dailyEntries.fold<int>(
          0,
          (sum, entry) => sum + (entry.pushUps ?? 0),
        );
        final totalChinUps = dailyEntries.fold<int>(
          0,
          (sum, entry) => sum + (entry.chinUps ?? 0),
        );
        final totalProtein = dietEntries.fold<int>(
          0,
          (sum, entry) => sum + (entry.proteinGrams ?? 0),
        );
        final totalCalories = dietEntries.fold<int>(
          0,
          (sum, entry) => sum + (entry.calories ?? 0),
        );

        final streakDays = trainingState.calculateCurrentStreakDays();
        final methodTransitions = trainingState.getMethodTransitions();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header with info tooltip
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Progress & Analytics',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  tooltip: 'Metric Definitions',
                  onPressed: _showMetricDefinitions,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Range Segmented Button
            SegmentedButton<_StatsRange>(
              segments: _StatsRange.values
                  .map(
                    (range) => ButtonSegment<_StatsRange>(
                      value: range,
                      label: Text(range.label),
                    ),
                  )
                  .toList(),
              selected: {_range},
              onSelectionChanged: (selection) =>
                  setState(() => _range = selection.first),
            ),
            const SizedBox(height: 12),

            // Category Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _StatsCategory.values.map((cat) {
                  final isSelected = _category == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      avatar: Icon(
                        cat.icon,
                        size: 16,
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.primary,
                      ),
                      label: Text(cat.label),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) setState(() => _category = cat);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Render view depending on selected category
            if (_category == _StatsCategory.overview) ...[
              _buildOverviewTab(
                rangedEntries: rangedEntries,
                weightEntries: weightEntries,
                dailyEntries: dailyEntries,
                totalVolume: totalVolume,
                totalPushUps: totalPushUps,
                totalChinUps: totalChinUps,
                streakDays: streakDays,
                methodTransitions: methodTransitions,
              ),
            ] else if (_category == _StatsCategory.resistance) ...[
              _buildResistanceTab(
                  weightEntries: weightEntries, totalVolume: totalVolume),
            ] else if (_category == _StatsCategory.calisthenics) ...[
              _buildCalisthenicsTab(
                dailyEntries: dailyEntries,
                totalPushUps: totalPushUps,
                totalChinUps: totalChinUps,
              ),
            ] else ...[
              _buildNutritionTab(
                dietEntries: dietEntries,
                totalProtein: totalProtein,
                totalCalories: totalCalories,
              ),
            ],
          ],
        );
      },
    );
  }

  // --- OVERVIEW TAB ---
  Widget _buildOverviewTab({
    required List<HistoryEntry> rangedEntries,
    required List<HistoryEntry> weightEntries,
    required List<HistoryEntry> dailyEntries,
    required double totalVolume,
    required int totalPushUps,
    required int totalChinUps,
    required int streakDays,
    required List<MethodTransitionMilestone> methodTransitions,
  }) {
    if (rangedEntries.isEmpty) {
      return _buildEmptyState(
        title: 'No activity in this time range',
        subtitle:
            'Log a weight workout or daily calisthenics session to start tracking your progress analytics.',
        icon: Icons.analytics_outlined,
      );
    }

    // Prepare 7-day or 30-day volume data for the chart
    final chartDays = math.min(_range.days, 14);
    final volumeMap = trainingState.getDailyVolumeByDay(days: chartDays);
    final volumeData = volumeMap.entries.map((e) {
      final label = '${e.key.month}/${e.key.day}';
      return _ChartDataPoint(label: label, value: e.value);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary KPI Grid
        Row(
          children: [
            Expanded(
              child: _MetricKpiCard(
                title: 'Resistance Volume',
                value: totalVolume > 1000
                    ? '${(totalVolume / 1000).toStringAsFixed(1)}k lbs'
                    : '${totalVolume.toStringAsFixed(0)} lbs',
                caption: '${weightEntries.length} weight sessions',
                icon: AppIcons.barbell,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricKpiCard(
                title: 'Calisthenics',
                value: '${totalPushUps + totalChinUps} reps',
                caption: '$totalPushUps push, $totalChinUps chins',
                icon: Icons.accessibility_new,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MetricKpiCard(
                title: 'Active Streak',
                value: streakDays == 1 ? '1 Day' : '$streakDays Days',
                caption: streakDays > 0
                    ? 'Consistency on track!'
                    : 'Log today to start',
                icon: Icons.local_fire_department,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricKpiCard(
                title: 'Total Sessions',
                value: '${rangedEntries.length}',
                caption: 'Across all categories',
                icon: Icons.done_all,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Volume Progression Chart
        _buildLiftProgressionCard(rangedEntries),
        const SizedBox(height: 16),
        _buildBodyTrendCard(),
        const SizedBox(height: 16),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Volume (secondary)',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      'Last $chartDays days',
                      style: TextStyle(
                          fontSize: 11, color: AppTheme.mutedText(context)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 140,
                  child: _TimeSeriesBarChart(
                      data: volumeData,
                      barColor: Theme.of(context).colorScheme.secondary),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Method Transitions Section
        Card(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.25),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.military_tech, size: 20, color: Colors.amber),
                    SizedBox(width: 8),
                    Text(
                      'Method Transitions & Milestones',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Chronological evolution across Greyskull barbell and calisthenics protocols:',
                  style: TextStyle(
                      fontSize: 12, color: AppTheme.mutedText(context)),
                ),
                const SizedBox(height: 10),
                if (methodTransitions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Complete sessions to unlock method transitions and volume badges.',
                      style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: AppTheme.mutedText(context)),
                    ),
                  )
                else
                  ...methodTransitions.take(5).map((m) {
                    final date = m.timestamp;
                    final dateStr = '${date.month}/${date.day}';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              dateStr,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13),
                                ),
                                Text(
                                  m.description,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Recent Activity List
        const Text(
          'Recent Sessions in Range',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 8),
        ...rangedEntries.take(8).map((entry) => _buildSessionTile(entry)),
      ],
    );
  }

  // --- RESISTANCE TAB ---
  /// Per-lift estimated-1RM progression (issue #87).
  Widget _buildLiftProgressionCard(List<HistoryEntry> entries) {
    final series = LiftProgressService.seriesFor(entries);
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lift Progression (est. 1RM)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 2),
            Text(
              'Strength first: each lift tracked from its logged sets.',
              style:
                  TextStyle(fontSize: 11, color: AppTheme.mutedText(context)),
            ),
            const SizedBox(height: 10),
            if (series.isEmpty)
              Text(
                'Log at least two sessions of the same lift to see a trend.',
                style:
                    TextStyle(fontSize: 12, color: AppTheme.mutedText(context)),
              )
            else
              ...series.map((lift) {
                final positive = lift.change >= 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              lift.lift,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                          Text(
                            '${lift.latest.toStringAsFixed(0)} lb',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: scheme.secondary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${positive ? '+' : ''}${lift.change.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: positive
                                  ? AppTheme.positiveAccent(context)
                                  : AppTheme.negativeAccent(context),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 54,
                        child: CustomPaint(
                          size: const Size(double.infinity, 54),
                          painter: _LineChartPainter(
                            values: lift.points
                                .map((p) => p.estimatedOneRm)
                                .toList(),
                            color: scheme.secondary,
                            gridColor: scheme.onSurface.withValues(alpha: 0.12),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  /// Bodyweight / body-fat trend from optional measurements (#57).
  Widget _buildBodyTrendCard() {
    final days = _range == _StatsRange.all ? 3650 : _range.days;
    final entries = trainingState.bodyMeasurementsInRange(days);
    final weights =
        entries.where((m) => m.weightKg != null).toList(growable: false);
    final bodyFats =
        entries.where((m) => m.bodyFatPct != null).toList(growable: false);

    Widget empty() => Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Body Measurements',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 6),
                Text(
                  'No measurements in this range. Log bodyweight or body fat from the Diet tab.',
                  style: TextStyle(
                      fontSize: 12, color: AppTheme.mutedText(context)),
                ),
              ],
            ),
          ),
        );

    if (weights.isEmpty && bodyFats.isEmpty) {
      return empty();
    }

    final useWeight = weights.isNotEmpty;
    final series = useWeight ? weights : bodyFats;
    final unit = useWeight ? 'kg' : '%';
    final first =
        useWeight ? weights.first.weightKg! : bodyFats.first.bodyFatPct!;
    final last = useWeight ? weights.last.weightKg! : bodyFats.last.bodyFatPct!;
    final delta = last - first;
    final deltaText =
        '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)} $unit';

    final chartData = series
        .map((m) => _ChartDataPoint(
              label: '${m.date.month}/${m.date.day}',
              value: useWeight ? m.weightKg! : m.bodyFatPct!,
            ))
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  useWeight ? 'Bodyweight Trend' : 'Body Fat Trend',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  deltaText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: delta <= 0
                        ? AppTheme.positiveAccent(context)
                        : AppTheme.negativeAccent(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Latest: ${last.toStringAsFixed(1)} $unit '
              '(${series.length} entr${series.length == 1 ? 'y' : 'ies'})',
              style:
                  TextStyle(fontSize: 11, color: AppTheme.mutedText(context)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 130,
              child: _TimeSeriesBarChart(
                data: chartData,
                barColor: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResistanceTab({
    required List<HistoryEntry> weightEntries,
    required double totalVolume,
  }) {
    if (weightEntries.isEmpty) {
      return _buildEmptyState(
        title: 'No resistance workouts logged',
        subtitle:
            'Complete a workout on the Weight Program page to view your volume progression and load history.',
        icon: AppIcons.barbell,
      );
    }

    final avgVolume =
        weightEntries.isNotEmpty ? totalVolume / weightEntries.length : 0.0;
    final chartDays = math.min(_range.days, 14);
    final volumeMap = trainingState.getDailyVolumeByDay(days: chartDays);
    final volumeData = volumeMap.entries.map((e) {
      final label = '${e.key.month}/${e.key.day}';
      return _ChartDataPoint(label: label, value: e.value);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricKpiCard(
                title: 'Total Volume',
                value: '${totalVolume.toStringAsFixed(1)} lbs',
                caption: '${weightEntries.length} sessions logged',
                icon: Icons.line_weight,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricKpiCard(
                title: 'Avg. per Workout',
                value: '${avgVolume.toStringAsFixed(1)} lbs',
                caption: 'Mean load per session',
                icon: Icons.functions,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Barbell Volume Progression (Daily)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 150,
                  child: _TimeSeriesBarChart(
                      data: volumeData,
                      barColor: Theme.of(context).colorScheme.secondary),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Resistance Workout Log',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 8),
        ...weightEntries.map((entry) => _buildSessionTile(entry)),
      ],
    );
  }

  // --- CALISTHENICS TAB ---
  Widget _buildCalisthenicsTab({
    required List<HistoryEntry> dailyEntries,
    required int totalPushUps,
    required int totalChinUps,
  }) {
    if (dailyEntries.isEmpty) {
      return _buildEmptyState(
        title: 'No calisthenics sessions logged',
        subtitle:
            'Log push-ups and chin-ups under Frequency, Ladder, or Total Work method to view repetition analytics.',
        icon: Icons.accessibility_new,
      );
    }

    final chartDays = math.min(_range.days, 14);
    final repMap = trainingState.getDailyCalisthenicsByDay(days: chartDays);
    final repData = repMap.entries.map((e) {
      final label = '${e.key.month}/${e.key.day}';
      return _ChartDataPoint(label: label, value: e.value.toDouble());
    }).toList();

    // Method breakdown
    int freqReps = 0;
    int ladderReps = 0;
    int totalWorkReps = 0;

    for (final entry in dailyEntries) {
      final reps = (entry.pushUps ?? 0) + (entry.chinUps ?? 0);
      final title = entry.title.toLowerCase();
      if (title.contains('frequency')) {
        freqReps += reps;
      } else if (title.contains('ladder')) {
        ladderReps += reps;
      } else if (title.contains('total work')) {
        totalWorkReps += reps;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricKpiCard(
                title: 'Total Push-ups',
                value: '$totalPushUps',
                caption: 'Bodyweight volume',
                icon: Icons.horizontal_rule,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricKpiCard(
                title: 'Total Chin-ups',
                value: '$totalChinUps',
                caption: 'Upper body pulling volume',
                icon: Icons.vertical_align_top,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daily Repetition Trend',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 150,
                  child: _TimeSeriesBarChart(
                      data: repData,
                      barColor: Theme.of(context).colorScheme.secondary),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Breakdown card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Repetitions by Method Protocol',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 10),
                _buildMethodDistributionRow('Frequency Method', freqReps,
                    AppTheme.resistanceAccent(context)),
                const SizedBox(height: 6),
                _buildMethodDistributionRow('Ladder Method', ladderReps,
                    AppTheme.calisthenicsAccent(context)),
                const SizedBox(height: 6),
                _buildMethodDistributionRow('Total Work Method', totalWorkReps,
                    AppTheme.positiveAccent(context)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Calisthenics Session Log',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 8),
        ...dailyEntries.map((entry) => _buildSessionTile(entry)),
      ],
    );
  }

  static Widget _buildMethodDistributionRow(
      String name, int reps, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(name, style: const TextStyle(fontSize: 13))),
        Text(
          '$reps reps',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }

  // --- NUTRITION TAB ---
  Widget _buildNutritionTab({
    required List<HistoryEntry> dietEntries,
    required int totalProtein,
    required int totalCalories,
  }) {
    if (dietEntries.isEmpty) {
      return _buildEmptyState(
        title: 'No nutrition logs in range',
        subtitle:
            'Log protein and calories on the Diet page to monitor your nutritional fuel and recovery targets.',
        icon: Icons.restaurant,
      );
    }

    final avgProtein = dietEntries.isNotEmpty
        ? (totalProtein / dietEntries.length).round()
        : 0;
    final avgCalories = dietEntries.isNotEmpty
        ? (totalCalories / dietEntries.length).round()
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricKpiCard(
                title: 'Avg. Protein',
                value: '${avgProtein}g / day',
                caption: 'Target: ${trainingState.dailyProteinTarget}g',
                icon: Icons.egg_alt_outlined,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricKpiCard(
                title: 'Avg. Calories',
                value: '$avgCalories kcal',
                caption: 'Target: ${trainingState.dailyCalorieTarget} kcal',
                icon: Icons.local_fire_department_outlined,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Diet Intake History',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 8),
        ...dietEntries.map((entry) => _buildSessionTile(entry)),
      ],
    );
  }

  // --- REUSABLE EMPTY STATE ---
  Widget _buildEmptyState({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, size: 54, color: AppTheme.mutedText(context)),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.mutedText(context),
                  height: 1.3),
            ),
          ],
        ),
      ),
    );
  }

  // --- REUSABLE SESSION TILE ---
  Widget _buildSessionTile(HistoryEntry entry) {
    final date = entry.timestamp;
    final stamp =
        '${date.month}/${date.day} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(
          entry.category == HistoryCategory.weight
              ? AppIcons.barbell
              : entry.category == HistoryCategory.daily
                  ? Icons.accessibility_new
                  : Icons.restaurant,
          color: Theme.of(context).primaryColor,
        ),
        title: Text(entry.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(
          '$stamp\n${entry.details}',
          style: const TextStyle(fontSize: 12),
        ),
        isThreeLine: true,
      ),
    );
  }
}

// --- DATA POINT & HIGH-PERFORMANCE CUSTOM PAINTER ---
class _ChartDataPoint {
  final String label;
  final double value;

  _ChartDataPoint({required this.label, required this.value});
}

class _TimeSeriesBarChart extends StatelessWidget {
  const _TimeSeriesBarChart({required this.data, required this.barColor});

  final List<_ChartDataPoint> data;
  final Color barColor;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No data to chart'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _BarChartPainter(
            data: data,
            barColor: barColor,
            textColor: Theme.of(context).textTheme.bodySmall?.color ??
                Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        );
      },
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<_ChartDataPoint> data;
  final Color barColor;
  final Color textColor;

  _BarChartPainter({
    required this.data,
    required this.barColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final maxVal = data.fold<double>(0, (prev, p) => math.max(prev, p.value));
    final effectiveMax = maxVal == 0 ? 10.0 : maxVal * 1.15;

    const bottomPadding = 24.0;
    const topPadding = 16.0;
    final chartHeight = size.height - bottomPadding - topPadding;
    final barSlotWidth = size.width / data.length;
    final barWidth = math.min(barSlotWidth * 0.65, 28.0);

    // Draw baseline
    final baselinePaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.3)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height - bottomPadding),
      Offset(size.width, size.height - bottomPadding),
      baselinePaint,
    );

    final barPaint = Paint()
      ..color = barColor
      ..style = PaintingStyle.fill;

    for (int i = 0; i < data.length; i++) {
      final point = data[i];
      final slotCenterX = i * barSlotWidth + barSlotWidth / 2;
      final normalizedHeight = (point.value / effectiveMax) * chartHeight;
      final barTop = (size.height - bottomPadding) - normalizedHeight;

      // Draw bar if value > 0
      if (point.value > 0) {
        final rrect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
              slotCenterX - barWidth / 2, barTop, barWidth, normalizedHeight),
          const Radius.circular(4),
        );
        canvas.drawRRect(rrect, barPaint);

        // Value label above bar
        final valueText = point.value > 1000
            ? '${(point.value / 1000).toStringAsFixed(1)}k'
            : point.value.toStringAsFixed(0);
        final valSpan = TextSpan(
          text: valueText,
          style: TextStyle(
              fontSize: 9, fontWeight: FontWeight.bold, color: barColor),
        );
        final valPainter =
            TextPainter(text: valSpan, textDirection: TextDirection.ltr)
              ..layout();
        valPainter.paint(
          canvas,
          Offset(slotCenterX - valPainter.width / 2,
              barTop - valPainter.height - 2),
        );
      } else {
        // Draw small dot for zero/rest days
        canvas.drawCircle(
          Offset(slotCenterX, size.height - bottomPadding),
          2.0,
          Paint()..color = Colors.grey.withValues(alpha: 0.4),
        );
      }

      // X-axis label (date/day)
      final labelSpan = TextSpan(
        text: point.label,
        style: TextStyle(fontSize: 9, color: textColor),
      );
      final labelPainter =
          TextPainter(text: labelSpan, textDirection: TextDirection.ltr)
            ..layout();
      labelPainter.paint(
        canvas,
        Offset(slotCenterX - labelPainter.width / 2,
            size.height - bottomPadding + 6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.barColor != barColor;
  }
}

// --- KPI CARD ---
class _MetricKpiCard extends StatelessWidget {
  const _MetricKpiCard({
    required this.title,
    required this.value,
    required this.caption,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String caption;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.mutedText(context)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              caption,
              overflow: TextOverflow.ellipsis,
              style:
                  TextStyle(fontSize: 11, color: AppTheme.mutedText(context)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Minimal polyline chart for per-lift progression (#87).
class _LineChartPainter extends CustomPainter {
  const _LineChartPainter({
    required this.values,
    required this.color,
    required this.gridColor,
  });

  final List<double> values;
  final Color color;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final range =
        (maxValue - minValue).abs() < 0.001 ? 1.0 : maxValue - minValue;

    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    canvas.drawLine(
        Offset(0, size.height - 1), Offset(size.width, size.height - 1), grid);

    final path = Path();
    final dot = Paint()..color = color;
    for (var i = 0; i < values.length; i++) {
      final x = size.width * (i / (values.length - 1));
      final normalized = (values[i] - minValue) / range;
      final y = size.height - 6 - normalized * (size.height - 12);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 2.6, dot);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_LineChartPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}
