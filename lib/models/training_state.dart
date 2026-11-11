import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:greyskull_lp/themes/theme.dart';
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

class FrequencySet {
  FrequencySet({
    required this.pushUps,
    required this.chinUps,
    required this.usedNegatives,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final int pushUps;
  final int chinUps;
  final bool usedNegatives;
  final DateTime timestamp;

  Map<String, dynamic> toJsonMap() => {
        'pushUps': pushUps,
        'chinUps': chinUps,
        'usedNegatives': usedNegatives,
        'timestamp': timestamp.toIso8601String(),
      };

  factory FrequencySet.fromJsonMap(Map<String, dynamic> map) {
    return FrequencySet(
      pushUps: map['pushUps'] as int? ?? 0,
      chinUps: map['chinUps'] as int? ?? 0,
      usedNegatives: map['usedNegatives'] as bool? ?? false,
      timestamp: DateTime.tryParse(map['timestamp'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class HistoryEntry {
  HistoryEntry({
    String? id,
    required this.timestamp,
    required this.title,
    required this.details,
    required this.category,
    this.method,
    this.pushUps,
    this.chinUps,
    this.weightVolume,
    this.proteinGrams,
    this.calories,
    this.methodMetadata,
  }) : id = id ??
            '${timestamp.microsecondsSinceEpoch}_${category.name}_${method?.name ?? 'none'}';

  final String id;
  final DateTime timestamp;
  final String title;
  final String details;
  final HistoryCategory category;
  final DailyMethod? method;
  final int? pushUps;
  final int? chinUps;
  final double? weightVolume;
  final int? proteinGrams;
  final int? calories;
  final Map<String, dynamic>? methodMetadata;

  HistoryEntry copyWith({
    String? title,
    String? details,
    DailyMethod? method,
    int? pushUps,
    int? chinUps,
    double? weightVolume,
    int? proteinGrams,
    int? calories,
    Map<String, dynamic>? methodMetadata,
  }) {
    return HistoryEntry(
      id: id,
      timestamp: timestamp,
      title: title ?? this.title,
      details: details ?? this.details,
      category: category,
      method: method ?? this.method,
      pushUps: pushUps ?? this.pushUps,
      chinUps: chinUps ?? this.chinUps,
      weightVolume: weightVolume ?? this.weightVolume,
      proteinGrams: proteinGrams ?? this.proteinGrams,
      calories: calories ?? this.calories,
      methodMetadata: methodMetadata ?? this.methodMetadata,
    );
  }

  Map<String, dynamic> toJsonMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'title': title,
      'details': details,
      'category': category.name,
      'method': method?.name,
      'pushUps': pushUps,
      'chinUps': chinUps,
      'weightVolume': weightVolume,
      'proteinGrams': proteinGrams,
      'calories': calories,
      'methodMetadata': methodMetadata,
    };
  }

  factory HistoryEntry.fromJsonMap(Map<String, dynamic> map) {
    DailyMethod? parsedMethod;
    final methodStr = map['method'] as String?;
    if (methodStr != null) {
      for (final m in DailyMethod.values) {
        if (m.name == methodStr) {
          parsedMethod = m;
          break;
        }
      }
    }

    final ts =
        DateTime.tryParse(map['timestamp'] as String? ?? '') ?? DateTime.now();
    final catName = map['category'] as String? ?? '';
    final category = HistoryCategory.values.firstWhere(
      (value) => value.name == catName,
      orElse: () => HistoryCategory.daily,
    );

    return HistoryEntry(
      id: map['id'] as String? ??
          '${ts.microsecondsSinceEpoch}_${category.name}',
      timestamp: ts,
      title: map['title'] as String? ?? 'Session',
      details: map['details'] as String? ?? '',
      category: category,
      method: parsedMethod,
      pushUps: map['pushUps'] as int?,
      chinUps: map['chinUps'] as int?,
      weightVolume: (map['weightVolume'] as num?)?.toDouble(),
      proteinGrams: map['proteinGrams'] as int?,
      calories: map['calories'] as int?,
      methodMetadata: (map['methodMetadata'] as Map<dynamic, dynamic>?)?.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
    );
  }
}

class TrainingState extends ChangeNotifier {
  static const String _prefsKey = 'greyskull_training_state_v1';

  GreyskullSkin _activeSkin = GreyskullSkin.ironAndBone;
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

  // In-progress Frequency Method state
  final List<FrequencySet> _todayFrequencySets = [];
  DateTime _frequencyTrackingDate = _normalizedDay(DateTime.now());

  // In-progress Ladder Method state (persisted across tab/method switching)
  String _activeLadderExercise = 'Chin-ups';
  bool _activeLadderUsedNegatives = false;
  final List<List<int>> _activeCompletedLadders = [];
  final List<int> _activeCurrentLadderRungs = [];

  // In-progress Total Work Method state (persisted across tab/method switching)
  String _activeTotalWorkExercise = 'Push-ups';
  bool _activeTotalWorkUsedNegatives = false;
  String _activeTotalWorkModel = 'daily'; // 'daily' or 'weekly'
  int _activeTotalWorkTargetReps = 70;
  final List<int> _activeTotalWorkSets = [];

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

  GreyskullSkin get activeSkin => _activeSkin;
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

  // Frequency getters
  List<FrequencySet> get todayFrequencySets =>
      List<FrequencySet>.unmodifiable(_todayFrequencySets);
  int get todayFrequencyPushUps =>
      _todayFrequencySets.fold(0, (sum, set) => sum + set.pushUps);
  int get todayFrequencyChinUps =>
      _todayFrequencySets.fold(0, (sum, set) => sum + set.chinUps);

  // Ladder getters
  String get activeLadderExercise => _activeLadderExercise;
  bool get activeLadderUsedNegatives => _activeLadderUsedNegatives;
  List<List<int>> get activeCompletedLadders => List.unmodifiable(
      _activeCompletedLadders.map((l) => List<int>.unmodifiable(l)));
  List<int> get activeCurrentLadderRungs =>
      List.unmodifiable(_activeCurrentLadderRungs);
  int get activeLadderNextRung => _activeCurrentLadderRungs.isEmpty
      ? 1
      : _activeCurrentLadderRungs.last + 1;
  int get activeLadderTotalReps {
    final fromCompleted = _activeCompletedLadders.fold<int>(
        0, (sum, l) => sum + l.fold<int>(0, (s, r) => s + r));
    final fromCurrent = _activeCurrentLadderRungs.fold<int>(0, (s, r) => s + r);
    return fromCompleted + fromCurrent;
  }

  int get activeLadderPeakRung {
    var peak = 0;
    for (final l in _activeCompletedLadders) {
      for (final r in l) {
        if (r > peak) peak = r;
      }
    }
    for (final r in _activeCurrentLadderRungs) {
      if (r > peak) peak = r;
    }
    return peak;
  }

  // Total Work getters
  String get activeTotalWorkExercise => _activeTotalWorkExercise;
  bool get activeTotalWorkUsedNegatives => _activeTotalWorkUsedNegatives;
  String get activeTotalWorkModel => _activeTotalWorkModel;
  int get activeTotalWorkTargetReps => _activeTotalWorkTargetReps;
  List<int> get activeTotalWorkSets => List.unmodifiable(_activeTotalWorkSets);
  int get activeTotalWorkCompletedReps =>
      _activeTotalWorkSets.fold(0, (s, r) => s + r);
  int get activeTotalWorkRemainingReps =>
      (_activeTotalWorkTargetReps - activeTotalWorkCompletedReps)
          .clamp(0, _activeTotalWorkTargetReps);

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
    if (_frequencyTrackingDate != today) {
      _frequencyTrackingDate = today;
      _todayFrequencySets.clear();
    }
  }

  void _notifyAndPersist() {
    notifyListeners();
    unawaited(_saveToDisk());
  }

  Map<String, dynamic> _buildPayload() {
    return <String, dynamic>{
      'schemaVersion': 2,
      'activeSkin': _activeSkin.name,
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
      'frequencyTrackingDate': _frequencyTrackingDate.toIso8601String(),
      'todayFrequencySets':
          _todayFrequencySets.map((s) => s.toJsonMap()).toList(),
      // Ladder in-progress state
      'activeLadderExercise': _activeLadderExercise,
      'activeLadderUsedNegatives': _activeLadderUsedNegatives,
      'activeCompletedLadders': _activeCompletedLadders,
      'activeCurrentLadderRungs': _activeCurrentLadderRungs,
      // Total Work in-progress state
      'activeTotalWorkExercise': _activeTotalWorkExercise,
      'activeTotalWorkUsedNegatives': _activeTotalWorkUsedNegatives,
      'activeTotalWorkModel': _activeTotalWorkModel,
      'activeTotalWorkTargetReps': _activeTotalWorkTargetReps,
      'activeTotalWorkSets': _activeTotalWorkSets,
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
    _activeSkin = GreyskullSkin.values.firstWhere(
      (value) => value.name == (map['activeSkin'] as String? ?? ''),
      orElse: () => GreyskullSkin.ironAndBone,
    );
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
    _frequencyTrackingDate =
        DateTime.tryParse(map['frequencyTrackingDate'] as String? ?? '') ??
            _normalizedDay(DateTime.now());

    _todayFrequencySets
      ..clear()
      ..addAll(
        (map['todayFrequencySets'] as List<dynamic>? ?? <dynamic>[])
            .whereType<Map>()
            .map((item) =>
                item.map((key, value) => MapEntry(key.toString(), value)))
            .map(FrequencySet.fromJsonMap),
      );

    // Restore Ladder in-progress state
    _activeLadderExercise =
        map['activeLadderExercise'] as String? ?? 'Chin-ups';
    _activeLadderUsedNegatives =
        map['activeLadderUsedNegatives'] as bool? ?? false;
    _activeCompletedLadders
      ..clear()
      ..addAll(
        (map['activeCompletedLadders'] as List<dynamic>? ?? <dynamic>[])
            .whereType<List<dynamic>>()
            .map((sub) => sub.whereType<int>().toList()),
      );
    _activeCurrentLadderRungs
      ..clear()
      ..addAll(
        (map['activeCurrentLadderRungs'] as List<dynamic>? ?? <dynamic>[])
            .whereType<int>(),
      );

    // Restore Total Work in-progress state
    _activeTotalWorkExercise =
        map['activeTotalWorkExercise'] as String? ?? 'Push-ups';
    _activeTotalWorkUsedNegatives =
        map['activeTotalWorkUsedNegatives'] as bool? ?? false;
    _activeTotalWorkModel = map['activeTotalWorkModel'] as String? ?? 'daily';
    _activeTotalWorkTargetReps =
        (map['activeTotalWorkTargetReps'] as int? ?? 70).clamp(1, 2000);
    _activeTotalWorkSets
      ..clear()
      ..addAll(
        (map['activeTotalWorkSets'] as List<dynamic>? ?? <dynamic>[])
            .whereType<int>(),
      );

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

  void setActiveSkin(GreyskullSkin skin) {
    if (_activeSkin == skin) {
      return;
    }
    _activeSkin = skin;
    _notifyAndPersist();
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

  // --- Frequency Method Mutators ---
  void addFrequencySet({
    required int pushUps,
    required int chinUps,
    required bool usedNegatives,
  }) {
    _rollMacroDayIfNeeded();
    _todayFrequencySets.add(
      FrequencySet(
        pushUps: pushUps,
        chinUps: chinUps,
        usedNegatives: usedNegatives,
      ),
    );
    _notifyAndPersist();
  }

  void removeFrequencySet(int index) {
    if (index >= 0 && index < _todayFrequencySets.length) {
      _todayFrequencySets.removeAt(index);
      _notifyAndPersist();
    }
  }

  void clearTodayFrequencySets() {
    _todayFrequencySets.clear();
    _notifyAndPersist();
  }

  // --- Ladder Method Mutators (In-Progress Session survives navigation) ---
  void setLadderExercise(String exercise) {
    if (_activeLadderExercise != exercise) {
      _activeLadderExercise = exercise;
      _notifyAndPersist();
    }
  }

  void setLadderUsedNegatives(bool value) {
    if (_activeLadderUsedNegatives != value) {
      _activeLadderUsedNegatives = value;
      _notifyAndPersist();
    }
  }

  void recordLadderRung() {
    _activeCurrentLadderRungs.add(activeLadderNextRung);
    _notifyAndPersist();
  }

  void undoLadderRung() {
    if (_activeCurrentLadderRungs.isNotEmpty) {
      _activeCurrentLadderRungs.removeLast();
      _notifyAndPersist();
    }
  }

  void finishCurrentLadder() {
    if (_activeCurrentLadderRungs.isNotEmpty) {
      _activeCompletedLadders.add(List<int>.from(_activeCurrentLadderRungs));
      _activeCurrentLadderRungs.clear();
      _notifyAndPersist();
    }
  }

  void removeCompletedLadder(int index) {
    if (index >= 0 && index < _activeCompletedLadders.length) {
      _activeCompletedLadders.removeAt(index);
      _notifyAndPersist();
    }
  }

  void resetActiveLadderSession() {
    _activeCompletedLadders.clear();
    _activeCurrentLadderRungs.clear();
    _notifyAndPersist();
  }

  // --- Total Work Method Mutators (In-Progress Session survives navigation) ---
  void setTotalWorkExercise(String exercise) {
    if (_activeTotalWorkExercise != exercise) {
      _activeTotalWorkExercise = exercise;
      _notifyAndPersist();
    }
  }

  void setTotalWorkUsedNegatives(bool value) {
    if (_activeTotalWorkUsedNegatives != value) {
      _activeTotalWorkUsedNegatives = value;
      _notifyAndPersist();
    }
  }

  void setTotalWorkModel(String model) {
    if (_activeTotalWorkModel != model) {
      _activeTotalWorkModel = model;
      _notifyAndPersist();
    }
  }

  void setTotalWorkTargetReps(int reps) {
    final clamped = reps.clamp(1, 2000);
    if (_activeTotalWorkTargetReps != clamped) {
      _activeTotalWorkTargetReps = clamped;
      _notifyAndPersist();
    }
  }

  void addTotalWorkSet(int reps) {
    if (reps > 0) {
      _activeTotalWorkSets.add(reps);
      _notifyAndPersist();
    }
  }

  void removeTotalWorkSet(int index) {
    if (index >= 0 && index < _activeTotalWorkSets.length) {
      _activeTotalWorkSets.removeAt(index);
      _notifyAndPersist();
    }
  }

  void resetActiveTotalWorkSession() {
    _activeTotalWorkSets.clear();
    _notifyAndPersist();
  }

  // --- History Mutation ---
  void deleteHistoryEntry(String id) {
    final initialLen = _history.length;
    _history.removeWhere((entry) => entry.id == id);
    if (_history.length != initialLen) {
      _notifyAndPersist();
    }
  }

  void updateHistoryEntry(HistoryEntry updated) {
    final index = _history.indexWhere((e) => e.id == updated.id);
    if (index != -1) {
      _history[index] = updated;
      _notifyAndPersist();
    }
  }

  void logDailyMethodSession({
    required DailyMethod method,
    required int pushUps,
    required int chinUps,
    required bool usedNegatives,
    required String optionalExerciseSummary,
    String? title,
    String? customDetails,
    Map<String, dynamic>? metadata,
  }) {
    final methodName = methodLabel(method);
    final fallbackDetails =
        'Push-ups: $pushUps, Chin-ups: $chinUps${usedNegatives ? ' (negatives used)' : ''}\nOptional: $optionalExerciseSummary';

    _history.add(
      HistoryEntry(
        timestamp: DateTime.now(),
        title: title ?? '$methodName Session',
        category: HistoryCategory.daily,
        method: method,
        pushUps: pushUps,
        chinUps: chinUps,
        details: customDetails ?? fallbackDetails,
        methodMetadata: metadata,
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
