import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DailyMethod {
  frequency,
  ladder,
  totalWork,
}

enum NutritionMode {
  cutting,
  bulking,
}

enum BackupPreference {
  localOnly,
  manualExport,
  cloudSyncFuture,
}

enum HistoryCategory {
  weight,
  daily,
  diet,
}

class HistoryEntry {
  HistoryEntry({
    required this.timestamp,
    required this.title,
    required this.details,
    required this.category,
    this.pushUps,
    this.chinUps,
    this.weightVolume,
    this.proteinGrams,
    this.calories,
  });

  final DateTime timestamp;
  final String title;
  final String details;
  final HistoryCategory category;
  final int? pushUps;
  final int? chinUps;
  final double? weightVolume;
  final int? proteinGrams;
  final int? calories;

  Map<String, dynamic> toJsonMap() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'title': title,
      'details': details,
      'category': category.name,
      'pushUps': pushUps,
      'chinUps': chinUps,
      'weightVolume': weightVolume,
      'proteinGrams': proteinGrams,
      'calories': calories,
    };
  }

  factory HistoryEntry.fromJsonMap(Map<String, dynamic> map) {
    return HistoryEntry(
      timestamp: DateTime.tryParse(map['timestamp'] as String? ?? '') ??
          DateTime.now(),
      title: map['title'] as String? ?? 'Session',
      details: map['details'] as String? ?? '',
      category: HistoryCategory.values.firstWhere(
        (value) => value.name == (map['category'] as String? ?? ''),
        orElse: () => HistoryCategory.daily,
      ),
      pushUps: map['pushUps'] as int?,
      chinUps: map['chinUps'] as int?,
      weightVolume: (map['weightVolume'] as num?)?.toDouble(),
      proteinGrams: map['proteinGrams'] as int?,
      calories: map['calories'] as int?,
    );
  }
}

class TrainingState extends ChangeNotifier {
  static const String _prefsKey = 'greyskull_training_state_v1';

  DailyMethod _activeDailyMethod = DailyMethod.frequency;
  NutritionMode _nutritionMode = NutritionMode.cutting;
  BackupPreference _backupPreference = BackupPreference.manualExport;
  int _dailyPushUpTarget = 50;
  int _dailyChinUpTarget = 20;
  int _dailyProteinTarget = 180;
  int _dailyCalorieTarget = 2200;
  int _dailyProteinConsumed = 0;
  int _dailyCaloriesConsumed = 0;
  DateTime _macroTrackingDate = _normalizedDay(DateTime.now());
  String _usdaApiKey = '';

  bool _forumSignedIn = false;
  String _forumDisplayName = '';
  String _forumUrl = 'https://www.greyskullnation.com/forum';
  String _forumLoginUrl = 'https://www.greyskullnation.com/wp-login.php';
  String _storeUrl = 'https://store.greyskullnation.com/';

  final Set<String> _selectedWeightOptionalExercises = {
    'Barbell Row',
    'Romanian Deadlift',
  };

  final Set<String> _selectedDailyOptionalExercises = {
    'Dips',
    'Plank',
  };

  final List<HistoryEntry> _history = [];

  static const List<String> weightOptionalExerciseOptions = [
    'Barbell Row',
    'Romanian Deadlift',
    'Deadlift',
    'Split Squat',
    'Farmer Carry',
    'Core Circuit (placeholder)',
  ];

  static const List<String> dailyOptionalExerciseOptions = [
    'Dips',
    'Band Pull-Aparts',
    'Plank',
    'Hollow Body Hold',
    'Face Pulls',
    'Conditioning Finisher (placeholder)',
  ];

  DailyMethod get activeDailyMethod => _activeDailyMethod;
  NutritionMode get nutritionMode => _nutritionMode;
  BackupPreference get backupPreference => _backupPreference;
  int get dailyPushUpTarget => _dailyPushUpTarget;
  int get dailyChinUpTarget => _dailyChinUpTarget;
  int get dailyProteinTarget => _dailyProteinTarget;
  int get dailyCalorieTarget => _dailyCalorieTarget;
  int get dailyProteinConsumed => _dailyProteinConsumed;
  int get dailyCaloriesConsumed => _dailyCaloriesConsumed;
  DateTime get macroTrackingDate => _macroTrackingDate;
  String get usdaApiKey => _usdaApiKey;
  bool get forumSignedIn => _forumSignedIn;
  String get forumDisplayName => _forumDisplayName;
  String get forumUrl => _forumUrl;
  String get forumLoginUrl => _forumLoginUrl;
  String get storeUrl => _storeUrl;

  Set<String> get selectedWeightOptionalExercises =>
      Set<String>.from(_selectedWeightOptionalExercises);

  Set<String> get selectedDailyOptionalExercises =>
      Set<String>.from(_selectedDailyOptionalExercises);

  List<HistoryEntry> get history =>
      List<HistoryEntry>.unmodifiable(_history.reversed);

  Future<void> loadFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) {
      return;
    }

    try {
      final Map<String, dynamic> map = jsonDecode(raw) as Map<String, dynamic>;
      _applyMap(map);
    } catch (_) {
      // Ignore malformed local storage and keep defaults.
    }

    _rollMacroDayIfNeeded();
    notifyListeners();
  }

  static DateTime _normalizedDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  void _rollMacroDayIfNeeded() {
    final today = _normalizedDay(DateTime.now());
    if (_macroTrackingDate != today) {
      _macroTrackingDate = today;
      _dailyProteinConsumed = 0;
      _dailyCaloriesConsumed = 0;
    }
  }

  void _notifyAndPersist() {
    notifyListeners();
    unawaited(_saveToDisk());
  }

  Map<String, dynamic> _buildPayload() {
    return <String, dynamic>{
      'schemaVersion': 1,
      'activeDailyMethod': _activeDailyMethod.name,
      'nutritionMode': _nutritionMode.name,
      'backupPreference': _backupPreference.name,
      'dailyPushUpTarget': _dailyPushUpTarget,
      'dailyChinUpTarget': _dailyChinUpTarget,
      'dailyProteinTarget': _dailyProteinTarget,
      'dailyCalorieTarget': _dailyCalorieTarget,
      'dailyProteinConsumed': _dailyProteinConsumed,
      'dailyCaloriesConsumed': _dailyCaloriesConsumed,
      'macroTrackingDate': _macroTrackingDate.toIso8601String(),
      'usdaApiKey': _usdaApiKey,
      'forumSignedIn': _forumSignedIn,
      'forumDisplayName': _forumDisplayName,
      'forumUrl': _forumUrl,
      'forumLoginUrl': _forumLoginUrl,
      'storeUrl': _storeUrl,
      'selectedWeightOptionalExercises':
          _selectedWeightOptionalExercises.toList(),
      'selectedDailyOptionalExercises':
          _selectedDailyOptionalExercises.toList(),
      'history': _history.map((entry) => entry.toJsonMap()).toList(),
    };
  }

  void _applyMap(Map<String, dynamic> map) {
    _activeDailyMethod = DailyMethod.values.firstWhere(
      (value) => value.name == (map['activeDailyMethod'] as String? ?? ''),
      orElse: () => DailyMethod.frequency,
    );
    _nutritionMode = NutritionMode.values.firstWhere(
      (value) => value.name == (map['nutritionMode'] as String? ?? ''),
      orElse: () => NutritionMode.cutting,
    );
    _backupPreference = BackupPreference.values.firstWhere(
      (value) => value.name == (map['backupPreference'] as String? ?? ''),
      orElse: () => BackupPreference.manualExport,
    );
    _dailyPushUpTarget = (map['dailyPushUpTarget'] as int? ?? 50).clamp(1, 500);
    _dailyChinUpTarget = (map['dailyChinUpTarget'] as int? ?? 20).clamp(1, 250);
    _dailyProteinTarget =
        (map['dailyProteinTarget'] as int? ?? 180).clamp(1, 400);
    _dailyCalorieTarget =
        (map['dailyCalorieTarget'] as int? ?? 2200).clamp(1000, 8000);
    _dailyProteinConsumed =
        (map['dailyProteinConsumed'] as int? ?? 0).clamp(0, 5000);
    _dailyCaloriesConsumed =
        (map['dailyCaloriesConsumed'] as int? ?? 0).clamp(0, 20000);
    _macroTrackingDate =
        DateTime.tryParse(map['macroTrackingDate'] as String? ?? '') ??
            _normalizedDay(DateTime.now());
    _usdaApiKey = map['usdaApiKey'] as String? ?? '';
    _forumSignedIn = map['forumSignedIn'] as bool? ?? false;
    _forumDisplayName = map['forumDisplayName'] as String? ?? '';
    _forumUrl = map['forumUrl'] as String? ?? _forumUrl;
    _forumLoginUrl = map['forumLoginUrl'] as String? ?? _forumLoginUrl;
    _storeUrl = map['storeUrl'] as String? ?? _storeUrl;

    _selectedWeightOptionalExercises
      ..clear()
      ..addAll((map['selectedWeightOptionalExercises'] as List<dynamic>? ??
              <dynamic>[])
          .whereType<String>());
    _selectedDailyOptionalExercises
      ..clear()
      ..addAll((map['selectedDailyOptionalExercises'] as List<dynamic>? ??
              <dynamic>[])
          .whereType<String>());

    _history
      ..clear()
      ..addAll(
        (map['history'] as List<dynamic>? ?? <dynamic>[])
            .whereType<Map>()
            .map((item) =>
                item.map((key, value) => MapEntry(key.toString(), value)))
            .map(HistoryEntry.fromJsonMap),
      );
  }

  Future<void> _saveToDisk() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(_buildPayload()));
  }

  String exportBackupJson() => jsonEncode(_buildPayload());

  Future<bool> importBackupJson(String rawJson) async {
    if (rawJson.trim().isEmpty) {
      return false;
    }
    try {
      final map = jsonDecode(rawJson) as Map<String, dynamic>;
      _applyMap(map);
      _rollMacroDayIfNeeded();
      _notifyAndPersist();
      return true;
    } catch (_) {
      return false;
    }
  }

  void setActiveDailyMethod(DailyMethod method) {
    if (_activeDailyMethod == method) {
      return;
    }
    _activeDailyMethod = method;
    _notifyAndPersist();
  }

  void setDailyPushUpTarget(int value) {
    final adjusted = value.clamp(1, 500);
    if (_dailyPushUpTarget == adjusted) {
      return;
    }
    _dailyPushUpTarget = adjusted;
    _notifyAndPersist();
  }

  void setDailyChinUpTarget(int value) {
    final adjusted = value.clamp(1, 250);
    if (_dailyChinUpTarget == adjusted) {
      return;
    }
    _dailyChinUpTarget = adjusted;
    _notifyAndPersist();
  }

  void setDailyProteinTarget(int value) {
    final adjusted = value.clamp(1, 400);
    if (_dailyProteinTarget == adjusted) {
      return;
    }
    _dailyProteinTarget = adjusted;
    _notifyAndPersist();
  }

  void setDailyCalorieTarget(int value) {
    final adjusted = value.clamp(1000, 8000);
    if (_dailyCalorieTarget == adjusted) {
      return;
    }
    _dailyCalorieTarget = adjusted;
    _notifyAndPersist();
  }

  void setNutritionMode(NutritionMode mode) {
    if (_nutritionMode == mode) {
      return;
    }
    _nutritionMode = mode;
    _notifyAndPersist();
  }

  void setBackupPreference(BackupPreference preference) {
    if (_backupPreference == preference) {
      return;
    }
    _backupPreference = preference;
    _notifyAndPersist();
  }

  void setUsdaApiKey(String value) {
    final trimmed = value.trim();
    if (_usdaApiKey == trimmed) {
      return;
    }
    _usdaApiKey = trimmed;
    _notifyAndPersist();
  }

  void toggleWeightOptionalExercise(String exercise) {
    if (_selectedWeightOptionalExercises.contains(exercise)) {
      _selectedWeightOptionalExercises.remove(exercise);
    } else {
      _selectedWeightOptionalExercises.add(exercise);
    }
    _notifyAndPersist();
  }

  void toggleDailyOptionalExercise(String exercise) {
    if (_selectedDailyOptionalExercises.contains(exercise)) {
      _selectedDailyOptionalExercises.remove(exercise);
    } else {
      _selectedDailyOptionalExercises.add(exercise);
    }
    _notifyAndPersist();
  }

  void setForumSignedIn({
    required bool signedIn,
    String displayName = '',
  }) {
    _forumSignedIn = signedIn;
    _forumDisplayName = signedIn ? displayName.trim() : '';
    _notifyAndPersist();
  }

  void setForumUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == _forumUrl) {
      return;
    }
    _forumUrl = trimmed;
    _notifyAndPersist();
  }

  void setForumLoginUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == _forumLoginUrl) {
      return;
    }
    _forumLoginUrl = trimmed;
    _notifyAndPersist();
  }

  void setStoreUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == _storeUrl) {
      return;
    }
    _storeUrl = trimmed;
    _notifyAndPersist();
  }

  void logWeightSession({
    required String coreLiftSummary,
    required String optionalExerciseSummary,
    required double volume,
    String notes = '',
  }) {
    // TODO(ForumSync): Sync food/workout summaries to forum for accountability posts.
    _history.add(
      HistoryEntry(
        timestamp: DateTime.now(),
        title: 'Weight Program Session',
        category: HistoryCategory.weight,
        weightVolume: volume,
        details:
            '$coreLiftSummary\nOptional: $optionalExerciseSummary${notes.isEmpty ? '' : '\nNotes: $notes'}',
      ),
    );
    _notifyAndPersist();
  }

  void logDailyMethodSession({
    required DailyMethod method,
    required int pushUps,
    required int chinUps,
    required bool usedNegatives,
    required String optionalExerciseSummary,
  }) {
    final methodName = methodLabel(method);
    _history.add(
      HistoryEntry(
        timestamp: DateTime.now(),
        title: '$methodName Session',
        category: HistoryCategory.daily,
        pushUps: pushUps,
        chinUps: chinUps,
        details:
            'Push-ups: $pushUps, Chin-ups: $chinUps${usedNegatives ? ' (negatives used)' : ''}\nOptional: $optionalExerciseSummary',
      ),
    );
    _notifyAndPersist();
  }

  void logDietIntake({
    required int proteinGrams,
    required int calories,
    String note = '',
  }) {
    _rollMacroDayIfNeeded();
    _dailyProteinConsumed += proteinGrams;
    _dailyCaloriesConsumed += calories;
    _history.add(
      HistoryEntry(
        timestamp: DateTime.now(),
        title: 'Diet Intake',
        category: HistoryCategory.diet,
        proteinGrams: proteinGrams,
        calories: calories,
        details:
            'Protein: ${proteinGrams}g, Calories: $calories${note.isEmpty ? '' : '\nNote: $note'}',
      ),
    );
    _notifyAndPersist();
  }

  void resetTodaysMacros() {
    _rollMacroDayIfNeeded();
    _dailyProteinConsumed = 0;
    _dailyCaloriesConsumed = 0;
    _notifyAndPersist();
  }

  static String methodLabel(DailyMethod method) {
    switch (method) {
      case DailyMethod.frequency:
        return 'Frequency Method';
      case DailyMethod.ladder:
        return 'Ladder Method';
      case DailyMethod.totalWork:
        return 'Total Work Method';
    }
  }

  static String nutritionModeLabel(NutritionMode mode) {
    switch (mode) {
      case NutritionMode.cutting:
        return 'Cutting';
      case NutritionMode.bulking:
        return 'Bulking';
    }
  }

  static String backupPreferenceLabel(BackupPreference mode) {
    switch (mode) {
      case BackupPreference.localOnly:
        return 'Local only';
      case BackupPreference.manualExport:
        return 'Manual export';
      case BackupPreference.cloudSyncFuture:
        return 'Cloud sync (future)';
    }
  }
}

final TrainingState trainingState = TrainingState();
