import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:greyskull_lp/models/accountability_post.dart';
import 'package:greyskull_lp/services/accountability_template_service.dart';
import 'package:greyskull_lp/themes/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DailyMethod {
  frequency,
  ladder,
  totalWork,
}

enum BarbellTemplate {
  ogBase,
  villain,
  gladiator,
  twoDaySplit,
  fourDaySplit,
  custom,
}

class TemplateLift {
  final String name;
  final String prescription;
  final int sets;
  final int defaultReps;
  final bool isAmrap;
  final bool isUpperBody;

  const TemplateLift({
    required this.name,
    required this.prescription,
    this.sets = 3,
    this.defaultReps = 5,
    this.isAmrap = true,
    this.isUpperBody = false,
  });

  TemplateLift copyWith({
    String? name,
    String? prescription,
    int? sets,
    int? defaultReps,
    bool? isAmrap,
    bool? isUpperBody,
  }) =>
      TemplateLift(
        name: name ?? this.name,
        prescription: prescription ?? this.prescription,
        sets: sets ?? this.sets,
        defaultReps: defaultReps ?? this.defaultReps,
        isAmrap: isAmrap ?? this.isAmrap,
        isUpperBody: isUpperBody ?? this.isUpperBody,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'prescription': prescription,
        'sets': sets,
        'defaultReps': defaultReps,
        'isAmrap': isAmrap,
        'isUpperBody': isUpperBody,
      };

  factory TemplateLift.fromJson(Map<String, dynamic> json) => TemplateLift(
        name: json['name'] as String? ?? 'Lift',
        prescription: json['prescription'] as String? ?? '3 x 5+',
        sets: json['sets'] as int? ?? 3,
        defaultReps: json['defaultReps'] as int? ?? 5,
        isAmrap: json['isAmrap'] as bool? ?? true,
        isUpperBody: json['isUpperBody'] as bool? ?? false,
      );
}

class TemplateWorkoutDay {
  final String code;
  final String title;
  final String subtitle;
  final List<TemplateLift> coreLifts;
  final List<String> defaultAccessories;

  const TemplateWorkoutDay({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.coreLifts,
    this.defaultAccessories = const [],
  });

  TemplateWorkoutDay copyWith({
    String? code,
    String? title,
    String? subtitle,
    List<TemplateLift>? coreLifts,
    List<String>? defaultAccessories,
  }) =>
      TemplateWorkoutDay(
        code: code ?? this.code,
        title: title ?? this.title,
        subtitle: subtitle ?? this.subtitle,
        coreLifts: coreLifts ?? this.coreLifts,
        defaultAccessories: defaultAccessories ?? this.defaultAccessories,
      );

  Map<String, dynamic> toJson() => {
        'code': code,
        'title': title,
        'subtitle': subtitle,
        'coreLifts': coreLifts.map((l) => l.toJson()).toList(),
        'defaultAccessories': defaultAccessories,
      };

  factory TemplateWorkoutDay.fromJson(Map<String, dynamic> json) =>
      TemplateWorkoutDay(
        code: json['code'] as String? ?? 'A',
        title: json['title'] as String? ?? 'Workout A',
        subtitle: json['subtitle'] as String? ?? '',
        coreLifts: (json['coreLifts'] as List<dynamic>?)
                ?.map((e) =>
                    TemplateLift.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            const [],
        defaultAccessories: (json['defaultAccessories'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );
}

class BarbellTemplateDetails {
  final BarbellTemplate template;
  final String name;
  final String subtitle;
  final String bookReference;
  final String scheduleDescription;
  final List<TemplateWorkoutDay> workouts;

  const BarbellTemplateDetails({
    required this.template,
    required this.name,
    required this.subtitle,
    required this.bookReference,
    required this.scheduleDescription,
    required this.workouts,
  });
}

enum ProgramLevel {
  foundation(
    levelNumber: 1,
    displayName: 'Foundation (Starter Path)',
    shortLabel: 'Level 1: Foundation',
    badge: 'Starter',
    subtitle: 'Base Barbell Progression + Frequency Method',
    description:
        'Johnny Pain’s recommended starter path: master the core barbell lifts (Press, Squat, Bench, Deadlift) and accumulate clean daily push-ups & chin-ups with zero accessory distraction.',
  ),
  villain(
    levelNumber: 2,
    displayName: 'Villain (Arms & Neck Plug-ins)',
    shortLabel: 'Level 2: Villain',
    badge: 'Intermediate',
    subtitle: 'Base Program + Plug-in Accessories + Ladder Method',
    description:
        'Adds Johnny Pain’s iconic arms & neck plug-ins (curls, neck harness, weighted chins) and unlocks the Ladder Method for ascending calisthenics work.',
  ),
  gladiator(
    levelNumber: 3,
    displayName: 'Gladiator (Advanced Hypertrophy & Splits)',
    shortLabel: 'Level 3: Gladiator',
    badge: 'Advanced',
    subtitle: 'All Barbell Splits + Total Work Method + Full Customization',
    description:
        'Unlocks high-volume hypertrophy splits (Gladiator, Two-Day, Four-Day LCI), density Total Work calisthenics, and unrestricted custom accessory programming.',
  );

  final int levelNumber;
  final String displayName;
  final String shortLabel;
  final String badge;
  final String subtitle;
  final String description;

  const ProgramLevel({
    required this.levelNumber,
    required this.displayName,
    required this.shortLabel,
    required this.badge,
    required this.subtitle,
    required this.description,
  });
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

class MethodTransitionMilestone {
  final String title;
  final String description;
  final DateTime timestamp;
  final String methodCategory;

  const MethodTransitionMilestone({
    required this.title,
    required this.description,
    required this.timestamp,
    required this.methodCategory,
  });
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
  ProgramLevel _programLevel = ProgramLevel.foundation;
  bool _hasCompletedOnboarding = false;
  bool _socialSharePromptEnabled = true;
  String _socialShareHashtag = '#GreyskullLP #JohnnyPain';
  BarbellTemplate _activeBarbellTemplate = BarbellTemplate.ogBase;
  int _activeBarbellRotationIndex = 0;
  final Map<String, List<String>> _customAccessoriesByWorkout = {};
  final Map<String, List<String>> _customCalisthenicsAccessoriesByMethod = {};
  String _customTemplateName = 'Custom Program (Build from Zero)';
  String _customTemplateSubtitle = 'User-designed linear progression template';
  final List<TemplateWorkoutDay> _customTemplateWorkouts = [];

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

  static const String defaultForumUrl = 'https://forum.greyskullnation.com/';
  static const String defaultForumLoginUrl =
      'https://www.greyskullnation.com/wp-login.php';

  bool _forumSignedIn = false;
  String _forumDisplayName = '';
  String _forumUrl = defaultForumUrl;
  String _forumLoginUrl = defaultForumLoginUrl;
  String _storeUrl = 'https://store.greyskullnation.com/';

  AccountabilityPostMode _accountabilityMode = AccountabilityPostMode.off;
  final List<AccountabilityDraft> _accountabilityDrafts = [];
  AccountabilityDraft? _latestAccountabilityDraft;

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

  static const List<String> officialBookAccessories = [
    'Bicep Curls (2 x 10–12)',
    'Neck Harness Extensions (4 x 25+)',
    'Weighted Chin-ups (2 x 6–8)',
    'Weighted Dips (2 x 6–8)',
    'Yates / Barbell Rows (2 x 6–8)',
    'Power Cleans (3–5 x 3)',
    'Direct Abdominal Work (3–5 sets)',
    'Direct Calf Exercises (2–3 sets)',
    'Barbell / Dumbbell Shrugs (2 x 10–12)',
    'Face Pulls (2 x 15–20)',
    'Forearm Wrist Curls (2 sets)',
    'Dumbbell Pullovers (2 sets)',
  ];

  static const List<BarbellTemplate> officialBookTemplates = [
    BarbellTemplate.ogBase,
    BarbellTemplate.villain,
    BarbellTemplate.gladiator,
    BarbellTemplate.twoDaySplit,
    BarbellTemplate.fourDaySplit,
  ];

  static const BarbellTemplateDetails defaultCustomTemplateDetails =
      BarbellTemplateDetails(
    template: BarbellTemplate.custom,
    name: 'Custom Program (Build from Zero)',
    subtitle: 'User-designed linear progression template',
    bookReference: 'User Customized (GSLP Principles)',
    scheduleDescription: 'Customizable rotation and workout days',
    workouts: [
      TemplateWorkoutDay(
        code: 'A',
        title: 'Workout A',
        subtitle: 'Custom Day 1',
        coreLifts: [
          TemplateLift(
            name: 'Bench Press',
            prescription: '2 x 5, 1 x 5+',
            sets: 3,
            defaultReps: 5,
            isAmrap: true,
            isUpperBody: true,
          ),
          TemplateLift(
            name: 'Squat',
            prescription: '2 x 5, 1 x 5+',
            sets: 3,
            defaultReps: 5,
            isAmrap: true,
            isUpperBody: false,
          ),
        ],
        defaultAccessories: [],
      ),
      TemplateWorkoutDay(
        code: 'B',
        title: 'Workout B',
        subtitle: 'Custom Day 2',
        coreLifts: [
          TemplateLift(
            name: 'Overhead Press',
            prescription: '2 x 5, 1 x 5+',
            sets: 3,
            defaultReps: 5,
            isAmrap: true,
            isUpperBody: true,
          ),
          TemplateLift(
            name: 'Deadlift',
            prescription: '1 x 5+',
            sets: 1,
            defaultReps: 5,
            isAmrap: true,
            isUpperBody: false,
          ),
        ],
        defaultAccessories: [],
      ),
    ],
  );

  static const List<String> weightOptionalExerciseOptions =
      officialBookAccessories;

  static const Map<BarbellTemplate, BarbellTemplateDetails>
      templateDefinitions = {
    BarbellTemplate.custom: defaultCustomTemplateDetails,
    BarbellTemplate.ogBase: BarbellTemplateDetails(
      template: BarbellTemplate.ogBase,
      name: '"OG" Base Program',
      subtitle: 'The foundational 3-day A/B Greyskull linear progression',
      bookReference: '3rd Edition, Chapter 3, pp. 47–48',
      scheduleDescription:
          '3 days/week (Mon/Wed/Fri): Week 1: A/B/A, Week 2: B/A/B',
      workouts: [
        TemplateWorkoutDay(
          code: 'A',
          title: 'Workout A (Press & Squat)',
          subtitle: 'Upper body pressing first, followed by squat',
          coreLifts: [
            TemplateLift(
                name: 'Overhead Press',
                prescription: '2 x 5, 1 x 5+ (AMRAP)',
                isUpperBody: true),
            TemplateLift(
                name: 'Squat',
                prescription: '2 x 5, 1 x 5+ (AMRAP)',
                isUpperBody: false),
          ],
          defaultAccessories: [],
        ),
        TemplateWorkoutDay(
          code: 'B',
          title: 'Workout B (Bench & Deadlift)',
          subtitle: 'Upper body bench first, followed by deadlift',
          coreLifts: [
            TemplateLift(
                name: 'Bench Press',
                prescription: '2 x 5, 1 x 5+ (AMRAP)',
                isUpperBody: true),
            TemplateLift(
                name: 'Deadlift',
                prescription: '1 x 5+ (AMRAP)',
                sets: 1,
                isUpperBody: false),
          ],
          defaultAccessories: [],
        ),
      ],
    ),
    BarbellTemplate.villain: BarbellTemplateDetails(
      template: BarbellTemplate.villain,
      name: '"Villain" Arms & Neck Plugin',
      subtitle: 'The most popular GSLP variant with Arms & Neck plug-ins',
      bookReference: '3rd Edition, Chapter 4, pp. 56–61',
      scheduleDescription: '3 days/week alternating Workout A and Workout B',
      workouts: [
        TemplateWorkoutDay(
          code: 'A',
          title: 'Workout A (Press, Squat, Chins, Neck)',
          subtitle: 'Press + Chins + Squat + Neck Harness',
          coreLifts: [
            TemplateLift(
                name: 'Overhead Press',
                prescription: '2 x 5, 1 x 5+ (AMRAP)',
                isUpperBody: true),
            TemplateLift(
                name: 'Squat',
                prescription: '2 x 5, 1 x 5+ (AMRAP)',
                isUpperBody: false),
          ],
          defaultAccessories: [
            'Weighted Chin-ups (2 x 6–8)',
            'Neck Harness Extensions (4 x 25+)',
          ],
        ),
        TemplateWorkoutDay(
          code: 'B',
          title: 'Workout B (Bench, Deadlift, Curls, Neck)',
          subtitle: 'Bench + Curls + Deadlift + Neck Harness',
          coreLifts: [
            TemplateLift(
                name: 'Bench Press',
                prescription: '2 x 5, 1 x 5+ (AMRAP)',
                isUpperBody: true),
            TemplateLift(
                name: 'Deadlift',
                prescription: '1 x 5+ (AMRAP)',
                sets: 1,
                isUpperBody: false),
          ],
          defaultAccessories: [
            'Bicep Curls (2 x 10–12)',
            'Neck Harness Extensions (4 x 25+)',
          ],
        ),
      ],
    ),
    BarbellTemplate.gladiator: BarbellTemplateDetails(
      template: BarbellTemplate.gladiator,
      name: 'Greyskull Gladiator (Hypertrophy)',
      subtitle:
          '"Linebacker" mass-gain focus with rotating pressing variants and dips',
      bookReference: '3rd Edition, Chapter 6, pp. 106–109',
      scheduleDescription: '3 days/week rotating A, B, and C',
      workouts: [
        TemplateWorkoutDay(
          code: 'A',
          title: 'Workout A (Press, Squat, Chins)',
          subtitle: 'Press + Weighted Chins + Squat + Neck',
          coreLifts: [
            TemplateLift(
                name: 'Overhead Press',
                prescription: '2 x 5, 1 x 5+ (AMRAP)',
                isUpperBody: true),
            TemplateLift(
                name: 'Squat',
                prescription: '2 x 5, 1 x 5+ (AMRAP)',
                isUpperBody: false),
          ],
          defaultAccessories: [
            'Weighted Chin-ups (2 x 6–8)',
            'Neck Harness Extensions (4 x 25+)',
          ],
        ),
        TemplateWorkoutDay(
          code: 'B',
          title: 'Workout B (Bench, Deadlift, Curls, Rows)',
          subtitle: 'Bench + EZ-Bar Curls + Yates Row + Deadlift + Neck',
          coreLifts: [
            TemplateLift(
                name: 'Bench Press',
                prescription: '2 x 5, 1 x 5+ (AMRAP)',
                isUpperBody: true),
            TemplateLift(
                name: 'Deadlift',
                prescription: '1 x 5+ (AMRAP)',
                sets: 1,
                isUpperBody: false),
          ],
          defaultAccessories: [
            'Bicep Curls (2 x 10–12)',
            'Yates / Barbell Rows (2 x 6–8)',
            'Neck Harness Extensions (4 x 25+)',
          ],
        ),
        TemplateWorkoutDay(
          code: 'C',
          title: 'Workout C (Incline Bench, Front Squat, Dips)',
          subtitle: 'Incline Bench + Weighted Dips + Front Squat + Neck',
          coreLifts: [
            TemplateLift(
                name: 'Incline Bench Press',
                prescription: '2 x 5, 1 x 5+ (AMRAP)',
                isUpperBody: true),
            TemplateLift(
                name: 'Front Squat',
                prescription: '2 x 5, 1 x 5+ (AMRAP)',
                isUpperBody: false),
          ],
          defaultAccessories: [
            'Weighted Dips (2 x 6–8)',
            'Neck Harness Extensions (4 x 25+)',
          ],
        ),
      ],
    ),
    BarbellTemplate.twoDaySplit: BarbellTemplateDetails(
      template: BarbellTemplate.twoDaySplit,
      name: 'Two-Day Split (Dan / Mike)',
      subtitle:
          'For busy professionals, travel, and recovery-constrained trainees',
      bookReference: '3rd Edition, Chapter 3, pp. 49–53',
      scheduleDescription:
          '2 days/week (e.g., Tue/Fri) or flexible A/B cadence',
      workouts: [
        TemplateWorkoutDay(
          code: 'A',
          title: 'Workout A (Bench & Deadlift)',
          subtitle: 'Bench Press + Deadlift + Curls',
          coreLifts: [
            TemplateLift(
                name: 'Bench Press',
                prescription: '2 x 5, 1 x 5+ (AMRAP)',
                isUpperBody: true),
            TemplateLift(
                name: 'Deadlift',
                prescription: '1 x 5+ (AMRAP)',
                sets: 1,
                isUpperBody: false),
          ],
          defaultAccessories: [
            'Bicep Curls (2 x 10–12)',
          ],
        ),
        TemplateWorkoutDay(
          code: 'B',
          title: 'Workout B (Press & Squat)',
          subtitle: 'Overhead Press + Squat + Chins',
          coreLifts: [
            TemplateLift(
                name: 'Overhead Press',
                prescription: '2 x 5, 1 x 5+ (AMRAP)',
                isUpperBody: true),
            TemplateLift(
                name: 'Squat',
                prescription: '2 x 5, 1 x 5+ (AMRAP)',
                isUpperBody: false),
          ],
          defaultAccessories: [
            'Weighted Chin-ups (2 x 6–8)',
          ],
        ),
      ],
    ),
    BarbellTemplate.fourDaySplit: BarbellTemplateDetails(
      template: BarbellTemplate.fourDaySplit,
      name: 'Four-Day Single-Lift Split (LCI)',
      subtitle:
          'One primary compound lift per day for quick, high-intensity sessions',
      bookReference: '3rd Edition, Chapter 3, pp. 54–55',
      scheduleDescription: '4 days/week (e.g., Mon/Tue/Thu/Fri)',
      workouts: [
        TemplateWorkoutDay(
          code: 'Day 1',
          title: 'Day 1: Bench Press',
          subtitle: 'Bench Press + Curls',
          coreLifts: [
            TemplateLift(
                name: 'Bench Press',
                prescription: '2 x 5, 1 x 5+ (AMRAP)',
                isUpperBody: true),
          ],
          defaultAccessories: ['Bicep Curls (2 x 10–12)'],
        ),
        TemplateWorkoutDay(
          code: 'Day 2',
          title: 'Day 2: Deadlift',
          subtitle: 'Deadlift + Abdominal Work',
          coreLifts: [
            TemplateLift(
                name: 'Deadlift',
                prescription: '1 x 5+ (AMRAP)',
                sets: 1,
                isUpperBody: false),
          ],
          defaultAccessories: ['Direct Abdominal Work (3–5 sets)'],
        ),
        TemplateWorkoutDay(
          code: 'Day 3',
          title: 'Day 3: Overhead Press',
          subtitle: 'Overhead Press + Weighted Dips',
          coreLifts: [
            TemplateLift(
                name: 'Overhead Press',
                prescription: '2 x 5, 1 x 5+ (AMRAP)',
                isUpperBody: true),
          ],
          defaultAccessories: ['Weighted Dips (2 x 6–8)'],
        ),
        TemplateWorkoutDay(
          code: 'Day 4',
          title: 'Day 4: Squat',
          subtitle: 'Squat + Calf Work',
          coreLifts: [
            TemplateLift(
                name: 'Squat',
                prescription: '2 x 5, 1 x 5+ (AMRAP)',
                isUpperBody: false),
          ],
          defaultAccessories: ['Direct Calf Exercises (2–3 sets)'],
        ),
      ],
    ),
  };

  static const List<String> dailyOptionalExerciseOptions = [
    'Dips',
    'Band Pull-Aparts',
    'Plank',
    'Hollow Body Hold',
    'Face Pulls',
    'Conditioning Finisher (placeholder)',
  ];

  static const Map<DailyMethod, List<String>>
      defaultCalisthenicsAccessoriesByMethod = {
    DailyMethod.frequency: [
      'Dips',
      'Hanging Knee Raises',
      'Bodyweight Squats',
    ],
    DailyMethod.ladder: [
      'Dips',
      'Inverted Rows',
      'Push-up Variations',
    ],
    DailyMethod.totalWork: [
      'Dips',
      'Planks',
      'Walking Lunges',
    ],
  };

  static const List<String> officialCalisthenicsAccessories = [
    'Dips',
    'Hanging Knee Raises',
    'Inverted Rows',
    'Bodyweight Squats',
    'Planks',
    'Walking Lunges',
    'Sit-ups',
    'Burpees',
    'Diamond Push-ups',
    'Band Pull-Aparts',
    'Hollow Body Hold',
  ];

  GreyskullSkin get activeSkin => _activeSkin;
  ProgramLevel get programLevel => _programLevel;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  bool get isLadderMethodUnlocked => _programLevel.levelNumber >= 2;
  bool get isTotalWorkMethodUnlocked => _programLevel.levelNumber >= 3;
  bool get isAccessoriesUnlocked => _programLevel.levelNumber >= 2;
  bool get isAdvancedSplitsUnlocked => _programLevel.levelNumber >= 3;

  bool get socialSharePromptEnabled => _socialSharePromptEnabled;
  String get socialShareHashtag => _socialShareHashtag;

  BarbellTemplate get activeBarbellTemplate => _activeBarbellTemplate;
  int get activeBarbellRotationIndex => _activeBarbellRotationIndex;

  String get customTemplateName => _customTemplateName;
  String get customTemplateSubtitle => _customTemplateSubtitle;

  List<TemplateWorkoutDay> get customTemplateWorkouts {
    if (_customTemplateWorkouts.isEmpty) {
      return List<TemplateWorkoutDay>.unmodifiable(
          defaultCustomTemplateDetails.workouts);
    }
    return List<TemplateWorkoutDay>.unmodifiable(_customTemplateWorkouts);
  }

  bool get isCustomTemplateActive =>
      _activeBarbellTemplate == BarbellTemplate.custom;

  bool get isCustomTemplateModified =>
      _customTemplateWorkouts.isNotEmpty ||
      _customTemplateName != defaultCustomTemplateDetails.name ||
      _customTemplateSubtitle != defaultCustomTemplateDetails.subtitle;

  BarbellTemplateDetails get activeBarbellTemplateDetails =>
      getTemplateDetails(_activeBarbellTemplate);

  BarbellTemplateDetails getTemplateDetails(BarbellTemplate template) {
    if (template == BarbellTemplate.custom) {
      final workouts = _customTemplateWorkouts.isNotEmpty
          ? _customTemplateWorkouts
          : defaultCustomTemplateDetails.workouts;
      return BarbellTemplateDetails(
        template: BarbellTemplate.custom,
        name: _customTemplateName,
        subtitle: _customTemplateSubtitle,
        bookReference: 'User Customized (GSLP Principles)',
        scheduleDescription:
            '${workouts.length} workout day${workouts.length == 1 ? '' : 's'} in rotation',
        workouts: workouts,
      );
    }
    return templateDefinitions[template]!;
  }

  TemplateWorkoutDay get currentTemplateWorkout {
    final workouts = activeBarbellTemplateDetails.workouts;
    if (workouts.isEmpty) {
      return templateDefinitions[BarbellTemplate.ogBase]!.workouts.first;
    }
    final index = _activeBarbellRotationIndex % workouts.length;
    return workouts[index];
  }

  List<String> getAccessoriesForWorkout(
      BarbellTemplate template, String workoutCode) {
    final key = '${template.name}_$workoutCode';
    if (_customAccessoriesByWorkout.containsKey(key)) {
      return List<String>.unmodifiable(_customAccessoriesByWorkout[key]!);
    }
    final workouts = getTemplateDetails(template).workouts;
    final match = workouts.where((w) => w.code == workoutCode);
    if (match.isNotEmpty) {
      return List<String>.unmodifiable(match.first.defaultAccessories);
    }
    return const [];
  }

  List<String> get currentWorkoutAccessories => getAccessoriesForWorkout(
      _activeBarbellTemplate, currentTemplateWorkout.code);

  bool isCurrentWorkoutCustomized() {
    final key = '${_activeBarbellTemplate.name}_${currentTemplateWorkout.code}';
    return _customAccessoriesByWorkout.containsKey(key);
  }

  List<String> getCalisthenicsAccessories(DailyMethod method) {
    final key = method.name;
    if (_customCalisthenicsAccessoriesByMethod.containsKey(key)) {
      return List<String>.unmodifiable(
          _customCalisthenicsAccessoriesByMethod[key]!);
    }
    final defaults = defaultCalisthenicsAccessoriesByMethod[method];
    if (defaults != null) {
      return List<String>.unmodifiable(defaults);
    }
    return const ['Dips'];
  }

  bool isCalisthenicsMethodCustomized(DailyMethod method) {
    return _customCalisthenicsAccessoriesByMethod.containsKey(method.name);
  }

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
  AccountabilityPostMode get accountabilityMode => _accountabilityMode;
  List<AccountabilityDraft> get accountabilityDrafts =>
      List<AccountabilityDraft>.unmodifiable(_accountabilityDrafts.reversed);
  AccountabilityDraft? get latestAccountabilityDraft =>
      _latestAccountabilityDraft;

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
      'programLevel': _programLevel.name,
      'hasCompletedOnboarding': _hasCompletedOnboarding,
      'socialSharePromptEnabled': _socialSharePromptEnabled,
      'socialShareHashtag': _socialShareHashtag,
      'activeBarbellTemplate': _activeBarbellTemplate.name,
      'activeBarbellRotationIndex': _activeBarbellRotationIndex,
      'customTemplateName': _customTemplateName,
      'customTemplateSubtitle': _customTemplateSubtitle,
      'customTemplateWorkouts':
          _customTemplateWorkouts.map((w) => w.toJson()).toList(),
      'customAccessoriesByWorkout': _customAccessoriesByWorkout.map(
        (key, list) => MapEntry(key, List<dynamic>.from(list)),
      ),
      'customCalisthenicsAccessoriesByMethod':
          _customCalisthenicsAccessoriesByMethod.map(
        (key, list) => MapEntry(key, List<dynamic>.from(list)),
      ),
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
      'accountabilityMode': _accountabilityMode.name,
      'accountabilityDrafts':
          _accountabilityDrafts.map((d) => d.toJsonMap()).toList(),
      'selectedWeightOptionalExercises':
          _selectedWeightOptionalExercises.toList(),
      'selectedDailyOptionalExercises':
          _selectedDailyOptionalExercises.toList(),
      'history': _history.map((entry) => entry.toJsonMap()).toList(),
    };
  }

  void _applyMap(Map<String, dynamic> map) {
    _programLevel = ProgramLevel.values.firstWhere(
      (value) => value.name == (map['programLevel'] as String? ?? ''),
      orElse: () => ProgramLevel.foundation,
    );
    _hasCompletedOnboarding = map['hasCompletedOnboarding'] as bool? ?? false;

    _socialSharePromptEnabled =
        map['socialSharePromptEnabled'] as bool? ?? true;
    _socialShareHashtag =
        map['socialShareHashtag'] as String? ?? '#GreyskullLP #JohnnyPain';

    _customTemplateName = map['customTemplateName'] as String? ??
        defaultCustomTemplateDetails.name;
    _customTemplateSubtitle = map['customTemplateSubtitle'] as String? ??
        defaultCustomTemplateDetails.subtitle;
    _customTemplateWorkouts.clear();
    if (map['customTemplateWorkouts'] is List) {
      for (final item in map['customTemplateWorkouts'] as List) {
        if (item is Map) {
          _customTemplateWorkouts.add(
              TemplateWorkoutDay.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    _activeBarbellTemplate = BarbellTemplate.values.firstWhere(
      (value) => value.name == (map['activeBarbellTemplate'] as String? ?? ''),
      orElse: () => BarbellTemplate.ogBase,
    );
    final workoutsCount = activeBarbellTemplateDetails.workouts.length;
    _activeBarbellRotationIndex =
        (map['activeBarbellRotationIndex'] as int? ?? 0)
            .clamp(0, workoutsCount > 0 ? workoutsCount - 1 : 0);
    _customAccessoriesByWorkout.clear();
    if (map['customAccessoriesByWorkout'] is Map) {
      final rawMap = map['customAccessoriesByWorkout'] as Map;
      for (final entry in rawMap.entries) {
        if (entry.value is List) {
          _customAccessoriesByWorkout[entry.key.toString()] =
              (entry.value as List).whereType<String>().toList();
        }
      }
    }

    _customCalisthenicsAccessoriesByMethod.clear();
    if (map['customCalisthenicsAccessoriesByMethod'] is Map) {
      final rawMap = map['customCalisthenicsAccessoriesByMethod'] as Map;
      for (final entry in rawMap.entries) {
        if (entry.value is List) {
          _customCalisthenicsAccessoriesByMethod[entry.key.toString()] =
              (entry.value as List).whereType<String>().toList();
        }
      }
    }

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
    final savedForumUrl = map['forumUrl'] as String? ?? _forumUrl;
    if (savedForumUrl == 'https://greyskullnation.com/forum' ||
        savedForumUrl == 'https://www.greyskullnation.com/forum') {
      _forumUrl = defaultForumUrl;
    } else {
      _forumUrl = savedForumUrl;
    }
    _forumLoginUrl = map['forumLoginUrl'] as String? ?? _forumLoginUrl;
    _storeUrl = map['storeUrl'] as String? ?? _storeUrl;

    _accountabilityMode = AccountabilityPostMode.values.firstWhere(
      (m) => m.name == map['accountabilityMode'],
      orElse: () => AccountabilityPostMode.off,
    );
    _accountabilityDrafts
      ..clear()
      ..addAll(
        (map['accountabilityDrafts'] as List<dynamic>? ?? <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map(AccountabilityDraft.fromJsonMap),
      );

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

  void setProgramLevel(ProgramLevel level) {
    if (_programLevel == level) {
      return;
    }
    _programLevel = level;
    _notifyAndPersist();
  }

  void completeOnboarding({ProgramLevel? selectedLevel}) {
    _hasCompletedOnboarding = true;
    if (selectedLevel != null) {
      _programLevel = selectedLevel;
    }
    _notifyAndPersist();
  }

  void resetOnboarding() {
    _hasCompletedOnboarding = false;
    _programLevel = ProgramLevel.foundation;
    _notifyAndPersist();
  }

  void setSocialSharePromptEnabled(bool enabled) {
    if (_socialSharePromptEnabled == enabled) {
      return;
    }
    _socialSharePromptEnabled = enabled;
    _notifyAndPersist();
  }

  void setSocialShareHashtag(String value) {
    final trimmed = value.trim();
    if (_socialShareHashtag == trimmed) {
      return;
    }
    _socialShareHashtag =
        trimmed.isEmpty ? '#GreyskullLP #JohnnyPain' : trimmed;
    _notifyAndPersist();
  }

  void setBarbellTemplate(BarbellTemplate template) {
    if (_activeBarbellTemplate == template) {
      return;
    }
    _activeBarbellTemplate = template;
    final maxIndex = (templateDefinitions[template]?.workouts.length ?? 1) - 1;
    if (_activeBarbellRotationIndex > maxIndex) {
      _activeBarbellRotationIndex = 0;
    }
    _notifyAndPersist();
  }

  void setBarbellRotationIndex(int index) {
    final workoutsCount = activeBarbellTemplateDetails.workouts.length;
    if (workoutsCount == 0) return;
    final clamped = index.clamp(0, workoutsCount - 1);
    if (_activeBarbellRotationIndex == clamped) return;
    _activeBarbellRotationIndex = clamped;
    _notifyAndPersist();
  }

  void advanceBarbellRotation() {
    final workoutsCount = activeBarbellTemplateDetails.workouts.length;
    if (workoutsCount > 0) {
      _activeBarbellRotationIndex =
          (_activeBarbellRotationIndex + 1) % workoutsCount;
      _notifyAndPersist();
    }
  }

  void addAccessoryToCurrentWorkout(String accessory) {
    final trimmed = accessory.trim();
    if (trimmed.isEmpty) return;
    final key = '${_activeBarbellTemplate.name}_${currentTemplateWorkout.code}';
    final currentList = List<String>.from(currentWorkoutAccessories);
    if (!currentList.contains(trimmed)) {
      currentList.add(trimmed);
      _customAccessoriesByWorkout[key] = currentList;
      _notifyAndPersist();
    }
  }

  void removeAccessoryFromCurrentWorkout(int index) {
    final currentList = List<String>.from(currentWorkoutAccessories);
    if (index >= 0 && index < currentList.length) {
      currentList.removeAt(index);
      final key =
          '${_activeBarbellTemplate.name}_${currentTemplateWorkout.code}';
      _customAccessoriesByWorkout[key] = currentList;
      _notifyAndPersist();
    }
  }

  void reorderAccessoriesInCurrentWorkout(int oldIndex, int newIndex) {
    final currentList = List<String>.from(currentWorkoutAccessories);
    if (oldIndex < 0 || oldIndex >= currentList.length) return;
    if (newIndex < 0 || newIndex > currentList.length) return;
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = currentList.removeAt(oldIndex);
    currentList.insert(newIndex, item);
    final key = '${_activeBarbellTemplate.name}_${currentTemplateWorkout.code}';
    _customAccessoriesByWorkout[key] = currentList;
    _notifyAndPersist();
  }

  void resetCurrentWorkoutAccessoriesToDefault() {
    final key = '${_activeBarbellTemplate.name}_${currentTemplateWorkout.code}';
    if (_customAccessoriesByWorkout.containsKey(key)) {
      _customAccessoriesByWorkout.remove(key);
      _notifyAndPersist();
    }
  }

  void addCalisthenicsAccessory(DailyMethod method, String accessory) {
    final trimmed = accessory.trim();
    if (trimmed.isEmpty) return;
    final currentList = List<String>.from(getCalisthenicsAccessories(method));
    if (!currentList.contains(trimmed)) {
      currentList.add(trimmed);
      _customCalisthenicsAccessoriesByMethod[method.name] = currentList;
      _notifyAndPersist();
    }
  }

  void removeCalisthenicsAccessory(DailyMethod method, int index) {
    final currentList = List<String>.from(getCalisthenicsAccessories(method));
    if (index >= 0 && index < currentList.length) {
      currentList.removeAt(index);
      _customCalisthenicsAccessoriesByMethod[method.name] = currentList;
      _notifyAndPersist();
    }
  }

  void reorderCalisthenicsAccessories(
      DailyMethod method, int oldIndex, int newIndex) {
    final currentList = List<String>.from(getCalisthenicsAccessories(method));
    if (oldIndex < 0 || oldIndex >= currentList.length) return;
    if (newIndex < 0 || newIndex >= currentList.length) return;
    final item = currentList.removeAt(oldIndex);
    currentList.insert(newIndex, item);
    _customCalisthenicsAccessoriesByMethod[method.name] = currentList;
    _notifyAndPersist();
  }

  void resetCalisthenicsAccessoriesToDefault(DailyMethod method) {
    if (_customCalisthenicsAccessoriesByMethod.containsKey(method.name)) {
      _customCalisthenicsAccessoriesByMethod.remove(method.name);
      _notifyAndPersist();
    }
  }

  void setCustomTemplateName(String name) {
    final trimmed = name.trim();
    if (trimmed.isNotEmpty && trimmed != _customTemplateName) {
      _customTemplateName = trimmed;
      _notifyAndPersist();
    }
  }

  void setCustomTemplateSubtitle(String subtitle) {
    final trimmed = subtitle.trim();
    if (trimmed != _customTemplateSubtitle) {
      _customTemplateSubtitle = trimmed;
      _notifyAndPersist();
    }
  }

  void duplicateTemplateFromPreset(BarbellTemplate sourceTemplate) {
    final source = templateDefinitions[sourceTemplate];
    if (source == null) return;

    _customTemplateWorkouts.clear();
    for (final day in source.workouts) {
      _customTemplateWorkouts.add(
        TemplateWorkoutDay(
          code: day.code,
          title: day.title,
          subtitle: day.subtitle,
          coreLifts: day.coreLifts
              .map((lift) => TemplateLift(
                    name: lift.name,
                    prescription: lift.prescription,
                    sets: lift.sets,
                    defaultReps: lift.defaultReps,
                    isAmrap: lift.isAmrap,
                    isUpperBody: lift.isUpperBody,
                  ))
              .toList(),
          defaultAccessories: List<String>.from(day.defaultAccessories),
        ),
      );
    }
    _customTemplateName = 'Custom (${source.name})';
    _customTemplateSubtitle = 'Duplicated from ${source.name}';
    _activeBarbellRotationIndex = 0;
    _notifyAndPersist();
  }

  void resetCustomTemplateToDefault() {
    _customTemplateWorkouts.clear();
    _customTemplateName = defaultCustomTemplateDetails.name;
    _customTemplateSubtitle = defaultCustomTemplateDetails.subtitle;
    _activeBarbellRotationIndex = 0;
    _notifyAndPersist();
  }

  void addCustomWorkoutDay({
    required String code,
    required String title,
    String subtitle = '',
    List<TemplateLift>? coreLifts,
    List<String>? defaultAccessories,
  }) {
    if (_customTemplateWorkouts.isEmpty) {
      _customTemplateWorkouts.addAll(defaultCustomTemplateDetails.workouts);
    }
    final nextNum = _customTemplateWorkouts.length + 1;
    _customTemplateWorkouts.add(
      TemplateWorkoutDay(
        code: code.trim().isEmpty ? 'Day $nextNum' : code.trim(),
        title: title.trim().isEmpty ? 'Workout Day $nextNum' : title.trim(),
        subtitle: subtitle.trim(),
        coreLifts: coreLifts ?? const [],
        defaultAccessories: defaultAccessories ?? const [],
      ),
    );
    _notifyAndPersist();
  }

  void removeCustomWorkoutDay(int index) {
    if (_customTemplateWorkouts.isEmpty) {
      _customTemplateWorkouts.addAll(defaultCustomTemplateDetails.workouts);
    }
    if (index >= 0 && index < _customTemplateWorkouts.length) {
      _customTemplateWorkouts.removeAt(index);
      if (_customTemplateWorkouts.isEmpty) {
        _customTemplateWorkouts
            .add(defaultCustomTemplateDetails.workouts.first);
      }
      final maxIndex = _customTemplateWorkouts.length - 1;
      if (_activeBarbellRotationIndex > maxIndex) {
        _activeBarbellRotationIndex = 0;
      }
      _notifyAndPersist();
    }
  }

  void updateCustomWorkoutDay(int index, TemplateWorkoutDay updatedDay) {
    if (_customTemplateWorkouts.isEmpty) {
      _customTemplateWorkouts.addAll(defaultCustomTemplateDetails.workouts);
    }
    if (index >= 0 && index < _customTemplateWorkouts.length) {
      _customTemplateWorkouts[index] = updatedDay;
      _notifyAndPersist();
    }
  }

  void addCoreLiftToCustomWorkout(int dayIndex, TemplateLift lift) {
    if (_customTemplateWorkouts.isEmpty) {
      _customTemplateWorkouts.addAll(defaultCustomTemplateDetails.workouts);
    }
    if (dayIndex >= 0 && dayIndex < _customTemplateWorkouts.length) {
      final day = _customTemplateWorkouts[dayIndex];
      final newLifts = List<TemplateLift>.from(day.coreLifts)..add(lift);
      _customTemplateWorkouts[dayIndex] = day.copyWith(coreLifts: newLifts);
      _notifyAndPersist();
    }
  }

  void removeCoreLiftFromCustomWorkout(int dayIndex, int liftIndex) {
    if (_customTemplateWorkouts.isEmpty) {
      _customTemplateWorkouts.addAll(defaultCustomTemplateDetails.workouts);
    }
    if (dayIndex >= 0 && dayIndex < _customTemplateWorkouts.length) {
      final day = _customTemplateWorkouts[dayIndex];
      if (liftIndex >= 0 && liftIndex < day.coreLifts.length) {
        final newLifts = List<TemplateLift>.from(day.coreLifts)
          ..removeAt(liftIndex);
        _customTemplateWorkouts[dayIndex] = day.copyWith(coreLifts: newLifts);
        _notifyAndPersist();
      }
    }
  }

  void reorderCoreLiftsInCustomWorkout(
      int dayIndex, int oldIndex, int newIndex) {
    if (_customTemplateWorkouts.isEmpty) {
      _customTemplateWorkouts.addAll(defaultCustomTemplateDetails.workouts);
    }
    if (dayIndex >= 0 && dayIndex < _customTemplateWorkouts.length) {
      final day = _customTemplateWorkouts[dayIndex];
      final newLifts = List<TemplateLift>.from(day.coreLifts);
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      if (oldIndex >= 0 &&
          oldIndex < newLifts.length &&
          newIndex >= 0 &&
          newIndex <= newLifts.length) {
        final item = newLifts.removeAt(oldIndex);
        newLifts.insert(newIndex, item);
        _customTemplateWorkouts[dayIndex] = day.copyWith(coreLifts: newLifts);
        _notifyAndPersist();
      }
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

  void resetForumUrlsToDefault() {
    _forumUrl = defaultForumUrl;
    _forumLoginUrl = defaultForumLoginUrl;
    _notifyAndPersist();
  }

  static const String defaultStoreUrl = 'https://store.greyskullnation.com/';

  void setStoreUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == _storeUrl) {
      return;
    }
    _storeUrl = trimmed;
    _notifyAndPersist();
  }

  void resetStoreUrlToDefault() {
    _storeUrl = defaultStoreUrl;
    _notifyAndPersist();
  }

  void setAccountabilityMode(AccountabilityPostMode mode) {
    _accountabilityMode = mode;
    _notifyAndPersist();
  }

  AccountabilityDraft queueWeightSessionDraft({
    required String coreLiftSummary,
    required String optionalExerciseSummary,
    required double volume,
    String notes = '',
  }) {
    final postContent = AccountabilityTemplateService.generateWeightSessionPost(
      coreLiftSummary: coreLiftSummary,
      optionalExerciseSummary: optionalExerciseSummary,
      volume: volume,
      notes: notes,
      userDisplayName: _forumDisplayName,
    );
    final draft = AccountabilityDraft(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      title: 'Weight Program Session',
      content: postContent,
      category: 'weight',
    );
    _accountabilityDrafts.add(draft);
    _latestAccountabilityDraft = draft;
    return draft;
  }

  AccountabilityDraft queueDailyMethodDraft({
    required DailyMethod method,
    required int pushUps,
    required int chinUps,
    required bool usedNegatives,
    required String optionalExerciseSummary,
  }) {
    final postContent = AccountabilityTemplateService.generateDailyMethodPost(
      method: method,
      pushUps: pushUps,
      chinUps: chinUps,
      usedNegatives: usedNegatives,
      optionalExerciseSummary: optionalExerciseSummary,
      userDisplayName: _forumDisplayName,
    );
    final draft = AccountabilityDraft(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      title: '${methodLabel(method)} Session',
      content: postContent,
      category: 'daily',
    );
    _accountabilityDrafts.add(draft);
    _latestAccountabilityDraft = draft;
    return draft;
  }

  AccountabilityDraft queueDailySummaryDraft([DateTime? date]) {
    final targetDate = date ?? DateTime.now();
    final postContent = AccountabilityTemplateService.generateDailySummaryPost(
      date: targetDate,
      history: _history,
      pushUpTarget: _dailyPushUpTarget,
      chinUpTarget: _dailyChinUpTarget,
      proteinConsumed: _dailyProteinConsumed,
      calorieConsumed: _dailyCaloriesConsumed,
      userDisplayName: _forumDisplayName,
    );
    final draft = AccountabilityDraft(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      title: 'End-of-Day Summary',
      content: postContent,
      category: 'summary',
    );
    _accountabilityDrafts.add(draft);
    _latestAccountabilityDraft = draft;
    _notifyAndPersist();
    return draft;
  }

  void removeAccountabilityDraft(String id) {
    _accountabilityDrafts.removeWhere((d) => d.id == id);
    if (_latestAccountabilityDraft?.id == id) {
      _latestAccountabilityDraft = null;
    }
    _notifyAndPersist();
  }

  void clearAccountabilityDrafts() {
    _accountabilityDrafts.clear();
    _latestAccountabilityDraft = null;
    _notifyAndPersist();
  }

  void markAccountabilityDraftPosted(String id) {
    final index = _accountabilityDrafts.indexWhere((d) => d.id == id);
    if (index != -1) {
      _accountabilityDrafts[index] =
          _accountabilityDrafts[index].copyWith(isPosted: true);
      _notifyAndPersist();
    }
  }

  AccountabilityDraft? logWeightSession({
    required String coreLiftSummary,
    required String optionalExerciseSummary,
    required double volume,
    String templateName = '',
    String workoutName = '',
    String notes = '',
  }) {
    // TODO(ForumSync): Sync food/workout summaries to forum for accountability posts.
    final effectiveTitle = (templateName.isNotEmpty && workoutName.isNotEmpty)
        ? '$templateName - $workoutName'
        : 'Weight Program Session';
    final detailsBuffer = StringBuffer()
      ..writeln('Core Lifts: $coreLiftSummary')
      ..writeln('Accessories: $optionalExerciseSummary')
      ..writeln('Total Volume: ${volume.toStringAsFixed(1)} lbs');
    if (notes.trim().isNotEmpty) {
      detailsBuffer.writeln('Notes: ${notes.trim()}');
    }

    _history.add(
      HistoryEntry(
        timestamp: DateTime.now(),
        title: effectiveTitle,
        details: detailsBuffer.toString().trim(),
        category: HistoryCategory.weight,
        weightVolume: volume,
      ),
    );

    AccountabilityDraft? draft;
    if (_accountabilityMode != AccountabilityPostMode.off) {
      draft = queueWeightSessionDraft(
        coreLiftSummary: coreLiftSummary,
        optionalExerciseSummary: optionalExerciseSummary,
        volume: volume,
        notes: notes,
      );
    }

    _notifyAndPersist();
    return draft;
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

  AccountabilityDraft? logDailyMethodSession({
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

    AccountabilityDraft? draft;
    if (_accountabilityMode != AccountabilityPostMode.off) {
      draft = queueDailyMethodDraft(
        method: method,
        pushUps: pushUps,
        chinUps: chinUps,
        usedNegatives: usedNegatives,
        optionalExerciseSummary: optionalExerciseSummary,
      );
    }

    _notifyAndPersist();
    return draft;
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

  int calculateCurrentStreakDays() {
    if (_history.isEmpty) return 0;
    final workoutDates = _history
        .where((e) =>
            e.category == HistoryCategory.weight ||
            e.category == HistoryCategory.daily)
        .map((e) =>
            DateTime(e.timestamp.year, e.timestamp.month, e.timestamp.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    if (workoutDates.isEmpty) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (workoutDates.first != today && workoutDates.first != yesterday) {
      return 0;
    }

    int streak = 1;
    DateTime checkDate = workoutDates.first;

    for (int i = 1; i < workoutDates.length; i++) {
      final expectedPrev = checkDate.subtract(const Duration(days: 1));
      if (workoutDates[i] == expectedPrev) {
        streak++;
        checkDate = expectedPrev;
      } else {
        break;
      }
    }
    return streak;
  }

  List<MethodTransitionMilestone> getMethodTransitions() {
    final milestones = <MethodTransitionMilestone>[];
    final chronological = List<HistoryEntry>.from(_history)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    bool hasWeight = false;
    bool hasFrequency = false;
    bool hasLadder = false;
    bool hasTotalWork = false;
    double cumulativeVolume = 0;
    int cumulativePushUps = 0;
    bool hit5kVolume = false;
    bool hit25kVolume = false;
    bool hit100PushUps = false;
    bool hit500PushUps = false;

    for (final entry in chronological) {
      if (entry.category == HistoryCategory.weight) {
        if (!hasWeight) {
          hasWeight = true;
          milestones.add(
            MethodTransitionMilestone(
              title: 'Started Barbell Program',
              description:
                  'Logged first Greyskull LP heavy resistance session.',
              timestamp: entry.timestamp,
              methodCategory: 'Resistance',
            ),
          );
        }
        cumulativeVolume += (entry.weightVolume ?? 0);
        if (!hit5kVolume && cumulativeVolume >= 5000) {
          hit5kVolume = true;
          milestones.add(
            MethodTransitionMilestone(
              title: '5,000 lbs Volume Milestone',
              description: 'Surpassed 5,000 lbs of total resistance work.',
              timestamp: entry.timestamp,
              methodCategory: 'Resistance',
            ),
          );
        }
        if (!hit25kVolume && cumulativeVolume >= 25000) {
          hit25kVolume = true;
          milestones.add(
            MethodTransitionMilestone(
              title: '25,000 lbs Volume Milestone',
              description: 'Surpassed 25,000 lbs of total resistance work.',
              timestamp: entry.timestamp,
              methodCategory: 'Resistance',
            ),
          );
        }
      } else if (entry.category == HistoryCategory.daily) {
        final title = entry.title.toLowerCase();
        if (title.contains('frequency') && !hasFrequency) {
          hasFrequency = true;
          milestones.add(
            MethodTransitionMilestone(
              title: 'Adopted Frequency Method',
              description:
                  'Began daily sub-maximal bodyweight volume practice.',
              timestamp: entry.timestamp,
              methodCategory: 'Frequency',
            ),
          );
        } else if (title.contains('ladder') && !hasLadder) {
          hasLadder = true;
          milestones.add(
            MethodTransitionMilestone(
              title: 'Graduated to Ladder Method',
              description:
                  'Progressed calisthenics work to ascending ladder rungs.',
              timestamp: entry.timestamp,
              methodCategory: 'Ladder',
            ),
          );
        } else if (title.contains('total work') && !hasTotalWork) {
          hasTotalWork = true;
          milestones.add(
            MethodTransitionMilestone(
              title: 'Advanced to Total Work Method',
              description:
                  'Took on time-constrained density calisthenics sessions.',
              timestamp: entry.timestamp,
              methodCategory: 'Total Work',
            ),
          );
        }

        cumulativePushUps += (entry.pushUps ?? 0);
        if (!hit100PushUps && cumulativePushUps >= 100) {
          hit100PushUps = true;
          milestones.add(
            MethodTransitionMilestone(
              title: '100 Push-ups Club',
              description: 'Accumulated over 100 bodyweight push-ups.',
              timestamp: entry.timestamp,
              methodCategory: 'Calisthenics',
            ),
          );
        }
        if (!hit500PushUps && cumulativePushUps >= 500) {
          hit500PushUps = true;
          milestones.add(
            MethodTransitionMilestone(
              title: '500 Push-ups Elite',
              description: 'Accumulated over 500 bodyweight push-ups.',
              timestamp: entry.timestamp,
              methodCategory: 'Calisthenics',
            ),
          );
        }
      }
    }

    return milestones.reversed.toList();
  }

  Map<DateTime, double> getDailyVolumeByDay({int days = 7}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final result = <DateTime, double>{};

    for (int i = days - 1; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      result[date] = 0.0;
    }

    for (final entry in _history) {
      if (entry.category == HistoryCategory.weight &&
          entry.weightVolume != null) {
        final day = DateTime(
            entry.timestamp.year, entry.timestamp.month, entry.timestamp.day);
        if (result.containsKey(day)) {
          result[day] = (result[day] ?? 0.0) + entry.weightVolume!;
        }
      }
    }
    return result;
  }

  Map<DateTime, int> getDailyCalisthenicsByDay({int days = 7}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final result = <DateTime, int>{};

    for (int i = days - 1; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      result[date] = 0;
    }

    for (final entry in _history) {
      if (entry.category == HistoryCategory.daily) {
        final day = DateTime(
            entry.timestamp.year, entry.timestamp.month, entry.timestamp.day);
        if (result.containsKey(day)) {
          result[day] =
              (result[day] ?? 0) + (entry.pushUps ?? 0) + (entry.chinUps ?? 0);
        }
      }
    }
    return result;
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

  static String barbellTemplateLabel(BarbellTemplate template) {
    return templateDefinitions[template]?.name ?? template.name;
  }
}

final TrainingState trainingState = TrainingState();
