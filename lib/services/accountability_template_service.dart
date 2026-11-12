import 'package:greyskull_lp/models/training_state.dart';

class AccountabilityTemplateService {
  static String formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  static String generateWeightSessionPost({
    required String coreLiftSummary,
    required String optionalExerciseSummary,
    required double volume,
    String notes = '',
    String userDisplayName = '',
    DateTime? date,
  }) {
    final d = date ?? DateTime.now();
    final buffer = StringBuffer();
    buffer.writeln('[b]Greyskull LP - Workout Accountability Log[/b]');
    buffer.writeln('📅 Date: ${formatDate(d)}');
    buffer.writeln('🏋️ Session Type: Barbell Strength Training');
    if (userDisplayName.trim().isNotEmpty) {
      buffer.writeln('👤 Lifter: ${userDisplayName.trim()}');
    }
    buffer.writeln();
    buffer.writeln('[b]Core Lifts:[/b]');
    buffer.writeln(coreLiftSummary.trim());
    buffer.writeln();
    if (optionalExerciseSummary.trim().isNotEmpty &&
        optionalExerciseSummary.trim() != 'None selected') {
      buffer.writeln('[b]Accessory Work:[/b]');
      buffer.writeln(optionalExerciseSummary.trim());
      buffer.writeln();
    }
    if (volume > 0) {
      buffer
          .writeln('📊 Total Session Volume: ${volume.toStringAsFixed(1)} lbs');
    }
    if (notes.trim().isNotEmpty) {
      buffer.writeln();
      buffer.writeln('📝 Notes:');
      buffer.writeln(notes.trim());
    }
    buffer.writeln();
    buffer.writeln('- Logged with the Official Greyskull LP App');
    buffer.writeln('https://store.greyskullnation.com/');
    return buffer.toString().trim();
  }

  static String generateDailyMethodPost({
    required DailyMethod method,
    required int pushUps,
    required int chinUps,
    required bool usedNegatives,
    required String optionalExerciseSummary,
    String userDisplayName = '',
    DateTime? date,
  }) {
    final d = date ?? DateTime.now();
    final methodName = TrainingState.methodLabel(method);
    final buffer = StringBuffer();
    buffer.writeln('[b]Greyskull LP - Daily Calisthenics Accountability[/b]');
    buffer.writeln('📅 Date: ${formatDate(d)}');
    buffer.writeln('💪 Method: $methodName');
    if (userDisplayName.trim().isNotEmpty) {
      buffer.writeln('👤 Lifter: ${userDisplayName.trim()}');
    }
    buffer.writeln();
    buffer.writeln('[b]Reps Completed:[/b]');
    buffer.writeln('• Push-ups: $pushUps reps');
    buffer.writeln(
        '• Chin-ups: $chinUps reps${usedNegatives ? ' (negatives used)' : ''}');
    if (optionalExerciseSummary.trim().isNotEmpty &&
        optionalExerciseSummary.trim() != 'None selected') {
      buffer.writeln('• Optional: $optionalExerciseSummary');
    }
    buffer.writeln();
    buffer.writeln('- Logged with the Official Greyskull LP App');
    buffer.writeln('https://store.greyskullnation.com/');
    return buffer.toString().trim();
  }

  static String generateDailySummaryPost({
    required DateTime date,
    required List<HistoryEntry> history,
    required int pushUpTarget,
    required int chinUpTarget,
    required int proteinConsumed,
    required int calorieConsumed,
    String userDisplayName = '',
  }) {
    final dayNormalized = DateTime(date.year, date.month, date.day);
    final todaysEntries = history.where((e) {
      final eDay =
          DateTime(e.timestamp.year, e.timestamp.month, e.timestamp.day);
      return eDay == dayNormalized;
    }).toList();

    final buffer = StringBuffer();
    buffer.writeln('[b]Greyskull LP - End-of-Day Accountability Summary[/b]');
    buffer.writeln('📅 Date: ${formatDate(date)}');
    if (userDisplayName.trim().isNotEmpty) {
      buffer.writeln('👤 Lifter: ${userDisplayName.trim()}');
    }
    buffer.writeln();

    // Lifts
    final weightEntries = todaysEntries
        .where((e) => e.category == HistoryCategory.weight)
        .toList();
    buffer.writeln('[b]🏋️ Strength Work:[/b]');
    if (weightEntries.isEmpty) {
      buffer.writeln('• Rest / Active Recovery Day');
    } else {
      for (final e in weightEntries) {
        buffer.writeln('• ${e.title}:');
        buffer.writeln(e.details);
      }
    }
    buffer.writeln();

    // Calisthenics
    final dailyEntries = todaysEntries
        .where((e) => e.category == HistoryCategory.daily)
        .toList();
    int pushUpsTotal = 0;
    int chinUpsTotal = 0;
    for (final e in dailyEntries) {
      pushUpsTotal += e.pushUps ?? 0;
      chinUpsTotal += e.chinUps ?? 0;
    }
    buffer.writeln('[b]💪 Daily Calisthenics Totals:[/b]');
    buffer.writeln('• Push-ups: $pushUpsTotal / $pushUpTarget reps target');
    buffer.writeln('• Chin-ups: $chinUpsTotal / $chinUpTarget reps target');
    buffer.writeln();

    // Nutrition
    if (proteinConsumed > 0 || calorieConsumed > 0) {
      buffer.writeln('[b]🥗 Daily Nutrition:[/b]');
      buffer.writeln('• Protein: ${proteinConsumed}g');
      buffer.writeln('• Calories: $calorieConsumed kcal');
      buffer.writeln();
    }

    buffer.writeln('- Logged with the Official Greyskull LP App');
    buffer.writeln('https://store.greyskullnation.com/');
    return buffer.toString().trim();
  }
}
