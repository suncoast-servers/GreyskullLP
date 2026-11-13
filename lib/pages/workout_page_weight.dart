import 'dart:async';

import 'package:flutter/material.dart';
import 'package:greyskull_lp/models/accountability_post.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/program/template_labels.dart';
import 'package:greyskull_lp/themes/theme.dart';
import 'package:greyskull_lp/services/social_share_service.dart';
import 'package:greyskull_lp/widgets/accountability_post_sheet.dart';
import 'package:greyskull_lp/widgets/custom_program_editor_sheet.dart';
import 'package:greyskull_lp/widgets/circular_rest_timer.dart';

class WorkoutPageWeight extends StatefulWidget {
  const WorkoutPageWeight({super.key, this.liveMode = false});

  /// When true the page runs as the focused live session (issue #80):
  /// session clock starts immediately, setup chrome is hidden and leaving
  /// requires confirmation.
  final bool liveMode;

  @override
  State<WorkoutPageWeight> createState() => _WorkoutPageWeightState();
}

class _WorkoutPageWeightState extends State<WorkoutPageWeight> {
  final Set<String> _completedCoreLifts = {};

  /// Completed set indexes per lift (0-based), so users can tap 5 / 5 / AMRAP
  /// individually instead of a single "done" checkbox.
  final Map<String, Set<int>> _completedSetsByLift = {};

  // Rest countdown (#75)
  bool _restTimerActive = false;
  int _restTimerToken = 0;
  int _restSeconds = 90;
  String _restCoaching = '';

  // Per-set rep overrides from press-and-hold (#80): lift -> set index -> reps.
  final Map<String, Map<int, int>> _repOverrides = {};

  // AMRAP stopwatch (#75)
  final Map<String, int> _amrapSeconds = {};
  String? _amrapRunningLift;
  int _amrapElapsed = 0;
  Timer? _amrapTicker;

  // Whole-session stopwatch (#75): starts with the first completed set.
  int _sessionSeconds = 0;
  bool _sessionRunning = false;
  Timer? _sessionTicker;
  final Set<String> _completedAccessories = {};
  final Map<String, TextEditingController> _weightControllers = {};
  final Map<String, TextEditingController> _repsControllers = {};
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _sessionTicker?.cancel();
    _amrapTicker?.cancel();
    _notesController.dispose();
    for (final controller in _weightControllers.values) {
      controller.dispose();
    }
    for (final controller in _repsControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.liveMode) {
      _sessionRunning = true;
      _sessionSeconds = 0;
      _sessionTicker = Timer.periodic(
        const Duration(seconds: 1),
        (_) => setState(() => _sessionSeconds += 1),
      );
    }
  }

  TextEditingController _getWeightController(String liftName) {
    return _weightControllers.putIfAbsent(liftName, () {
      final suggested = trainingState.nextSessionWeight(liftName);
      return TextEditingController(
        text: suggested == null ? '' : suggested.toStringAsFixed(1),
      );
    });
  }

  TextEditingController _getRepsController(String liftName) {
    return _repsControllers.putIfAbsent(
        liftName, () => TextEditingController());
  }

  double _fieldDouble(TextEditingController controller) {
    return double.tryParse(controller.text.trim()) ?? 0;
  }

  double _calculateTotalVolume(List<TemplateLift> coreLifts) {
    double total = 0;
    for (final lift in coreLifts) {
      final weight = _fieldDouble(_getWeightController(lift.name));
      final reps = _fieldDouble(_getRepsController(lift.name));
      total += weight * reps * lift.sets;
    }
    return total;
  }

  void _showAddAccessoryDialog() {
    final availablePresets = TrainingState.officialBookAccessories
        .where((preset) =>
            !trainingState.currentWorkoutAccessories.contains(preset))
        .toList();

    String? selectedPreset =
        availablePresets.isNotEmpty ? availablePresets.first : null;
    final customController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Plug-in Accessory'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select from Johnny Pain\'s official 3rd Edition plug-ins:',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    if (availablePresets.isNotEmpty) ...[
                      DropdownButtonFormField<String>(
                        initialValue: selectedPreset,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Official Book Plug-in',
                        ),
                        items: availablePresets
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(item,
                                    style: const TextStyle(fontSize: 13)),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          setDialogState(() {
                            selectedPreset = val;
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      Center(
                          child: Text('OR ENTER CUSTOM ACCESSORY',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.mutedText(context)))),
                      const SizedBox(height: 14),
                    ],
                    TextField(
                      controller: customController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Custom Accessory Name',
                        hintText: 'e.g., Hanging Leg Raises (3 x 10)',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final customText = customController.text.trim();
                    final accessoryToAdd =
                        customText.isNotEmpty ? customText : selectedPreset;
                    if (accessoryToAdd != null && accessoryToAdd.isNotEmpty) {
                      trainingState
                          .addAccessoryToCurrentWorkout(accessoryToAdd);
                    }
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Add to Workout'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) => customController.dispose());
  }

  void _showDuplicatePresetDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Duplicate from Book Preset'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Copy all workouts, core lifts, and plug-in accessories from an official book preset into your custom program.',
              style:
                  TextStyle(fontSize: 13, color: AppTheme.mutedText(context)),
            ),
            const SizedBox(height: 12),
            ...TrainingState.officialBookTemplates.map((template) {
              final details = TrainingState.templateDefinitions[template]!;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.fitness_center),
                title: Text(details.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(details.subtitle,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () {
                  Navigator.of(ctx).pop();
                  trainingState.duplicateTemplateFromPreset(template);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('Cloned ${details.name} into Custom Program'),
                    ),
                  );
                },
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _confirmResetToFactory(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset to Factory Defaults?'),
        content: const Text(
          'Revert custom program to factory starting template? All added workout days and custom core lifts will be reset.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.of(ctx).pop();
              trainingState.resetCustomTemplateToDefault();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Custom program reset to factory defaults.')),
              );
            },
            child: const Text('Revert to Factory',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _logSession(
      TemplateWorkoutDay currentWorkout, List<TemplateLift> coreLifts) {
    final coreLiftSummaries = <String>[];
    final bumpedLifts = <String>[];
    for (final lift in coreLifts) {
      final isDone = _completedCoreLifts.contains(lift.name);
      final weight = _fieldDouble(_getWeightController(lift.name));
      final reps = _fieldDouble(_getRepsController(lift.name));
      final status = isDone ? 'Done' : 'Not marked';
      final amrapSeconds = _amrapSeconds[lift.name];
      final amrapNote = amrapSeconds == null ? '' : ', AMRAP ${amrapSeconds}s';
      // AMRAP >= 10 reps -> add weight next session (5 lb upper / 10 lb lower).
      if (weight > 0) {
        final bump =
            lift.isAmrap && reps >= 10 ? (lift.isUpperBody ? 5.0 : 10.0) : 0.0;
        trainingState.setNextSessionWeight(lift.name, weight + bump);
        if (bump > 0) {
          bumpedLifts
              .add('${lift.name} -> ${(weight + bump).toStringAsFixed(1)} lb');
        }
      }
      final overrides = _repOverrides[lift.name];
      final overrideNote = overrides == null || overrides.isEmpty
          ? ''
          : ', set reps ${overrides.entries.map((e) => '${e.key + 1}:${e.value}').join(' ')}';
      final details = weight > 0 && reps > 0
          ? '${lift.name} ($status, ${weight.toStringAsFixed(1)} lbs x ${reps.toInt()} reps x ${lift.sets} sets$amrapNote$overrideNote)'
          : '${lift.name} ($status)';
      coreLiftSummaries.add(details);
    }

    final accessorySummaries = <String>[];
    for (final accessory in trainingState.currentWorkoutAccessories) {
      final isDone = _completedAccessories.contains(accessory);
      accessorySummaries
          .add('$accessory [${isDone ? "Completed" : "Skipped"}]');
    }

    final totalVolume = _calculateTotalVolume(coreLifts);
    final templateDetails = trainingState.activeBarbellTemplateDetails;

    final draft = trainingState.logWeightSession(
      templateName: templateDetails.name,
      workoutName: currentWorkout.title,
      coreLiftSummary: coreLiftSummaries.join('\n'),
      optionalExerciseSummary: accessorySummaries.isEmpty
          ? 'None scheduled'
          : accessorySummaries.join(', '),
      volume: totalVolume,
      notes: _notesController.text.trim(),
    );

    // Advance rotation to next workout in cycle
    trainingState.advanceBarbellRotation();

    _sessionTicker?.cancel();
    _sessionRunning = false;
    _sessionSeconds = 0;
    _amrapTicker?.cancel();
    _amrapRunningLift = null;
    _amrapElapsed = 0;
    setState(() {
      _completedCoreLifts.clear();
      _completedSetsByLift.clear();
      _repOverrides.clear();
      _completedAccessories.clear();
      _notesController.clear();
      for (final controller in _weightControllers.values) {
        controller.clear();
      }
      for (final controller in _repsControllers.values) {
        controller.clear();
      }
    });

    if (!mounted) {
      return;
    }

    // Keep the AMRAP bump visible: one snackbar carries both facts so the
    // progression advice is not replaced by the generic log toast.
    final bumpSuffix =
        bumpedLifts.isEmpty ? '' : '\nNext session: ${bumpedLifts.join(', ')}';
    final loggedMessage = 'Workout logged! Advanced rotation to: '
        '${trainingState.currentTemplateWorkout.title}$bumpSuffix';

    if (trainingState.accountabilityMode ==
            AccountabilityPostMode.onWorkoutComplete &&
        draft != null) {
      AccountabilityPostSheet.show(context, draft: draft);
    } else if (trainingState.accountabilityMode ==
            AccountabilityPostMode.manual &&
        draft != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loggedMessage),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Post to Forum',
            onPressed: () =>
                AccountabilityPostSheet.show(context, draft: draft),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loggedMessage),
          duration: Duration(seconds: bumpedLifts.isEmpty ? 4 : 6),
        ),
      );
    }
  }

  Set<int> _setsForLift(String liftName) =>
      _completedSetsByLift.putIfAbsent(liftName, () => <int>{});

  Future<void> _editRestSeconds(String liftName) async {
    final current = trainingState.restSecondsForLift(liftName);
    final choice = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('Rest for $liftName'),
        children: [
          for (final seconds in const [30, 45, 60, 90, 120, 180, 300])
            SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop(seconds),
              child: Row(
                children: [
                  Icon(
                    seconds == current
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text('$seconds seconds'),
                ],
              ),
            ),
        ],
      ),
    );
    if (choice != null) {
      trainingState.setPerExerciseRestSeconds(liftName, choice);
      setState(() {});
    }
  }

  Future<void> _promptRepOverride(
      TemplateLift lift, int setIndex, int totalSets) async {
    final current = _repOverrides[lift.name]?[setIndex] ?? lift.defaultReps;
    var value = current;
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('${lift.name} set ${setIndex + 1} reps'),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () =>
                    setLocal(() => value = (value - 1).clamp(1, 30)),
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Expanded(
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: () =>
                    setLocal(() => value = (value + 1).clamp(1, 30)),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(value),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _repOverrides.putIfAbsent(lift.name, () => <int, int>{})[setIndex] =
            result;
      });
    }
  }

  void _toggleAmrapStopwatch(String liftName) {
    setState(() {
      if (_amrapRunningLift == liftName) {
        _amrapTicker?.cancel();
        _amrapSeconds[liftName] = _amrapElapsed;
        _amrapRunningLift = null;
        _amrapElapsed = 0;
        return;
      }
      _amrapTicker?.cancel();
      _amrapRunningLift = liftName;
      _amrapElapsed = 0;
      _amrapTicker = Timer.periodic(
        const Duration(seconds: 1),
        (_) => setState(() => _amrapElapsed += 1),
      );
    });
  }

  String _amrapLabel(String liftName) {
    if (_amrapRunningLift == liftName) {
      final value = _amrapElapsed;
      return 'Stop ${value ~/ 60}:${(value % 60).toString().padLeft(2, '0')}';
    }
    final saved = _amrapSeconds[liftName];
    if (saved != null) {
      return 'AMRAP ${saved ~/ 60}:${(saved % 60).toString().padLeft(2, '0')}';
    }
    return 'Time AMRAP';
  }

  String _formatElapsed(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _toggleSet(String liftName, int setIndex, int totalSets) {
    setState(() {
      final sets = _setsForLift(liftName);
      final wasDone = sets.contains(setIndex);
      if (!sets.remove(setIndex)) {
        sets.add(setIndex);
      }
      // Start a rest countdown when a set is completed, not when un-done.
      if (!wasDone && trainingState.restTimerEnabled) {
        final liftDone = sets.length >= totalSets;
        _restSeconds = liftDone
            ? trainingState.restAfterExerciseSeconds
            : trainingState.restSecondsForLift(liftName);
        _restCoaching = liftDone
            ? 'Move to the next lift when this rest ends.'
            : 'Rest, then $liftName set ${sets.length + 1}.';
        _restTimerActive = true;
        _restTimerToken++;
      }
      if (!wasDone && !_sessionRunning) {
        _sessionRunning = true;
        _sessionSeconds = 0;
        _sessionTicker?.cancel();
        _sessionTicker = Timer.periodic(
          const Duration(seconds: 1),
          (_) => setState(() => _sessionSeconds += 1),
        );
      }
      if (sets.length >= totalSets) {
        _completedCoreLifts.add(liftName);
      } else {
        _completedCoreLifts.remove(liftName);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: trainingState,
      builder: (context, _) {
        final templateDetails = trainingState.activeBarbellTemplateDetails;
        final currentWorkout = trainingState.currentTemplateWorkout;
        final coreLifts = currentWorkout.coreLifts;
        final accessories = trainingState.currentWorkoutAccessories;
        final totalVolume = _calculateTotalVolume(coreLifts);

        // The countdown stays pinned above the scroll area so it remains
        // visible while the user works through lifts further down the page.
        return Column(
          children: [
            if (_sessionRunning)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(
                  children: [
                    Icon(Icons.av_timer,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(
                      'Session ${_formatElapsed(Duration(seconds: _sessionSeconds))}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            if (_restTimerActive)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: CircularRestTimer(
                  key: ValueKey('rest-$_restTimerToken'),
                  seconds: _restSeconds,
                  soundEnabled: trainingState.restTimerSoundEnabled,
                  countUp: trainingState.restTimerCountUp,
                  size: trainingState.restTimerSize,
                  coachingText: _restCoaching,
                  onDismissed: () => setState(() => _restTimerActive = false),
                ),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (trainingState.programLevel ==
                      ProgramLevel.foundation) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.resistanceAccent(context)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppTheme.resistanceAccent(context)
                                .withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 16,
                              color: AppTheme.resistanceAccent(context)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Level 1 (Foundation): Keep it simple. Johnny Pain advises mastering core lifts first before adding plug-in accessories.',
                              style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      Theme.of(context).colorScheme.onSurface),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (!widget.liveMode) ...[
                    // Template selection card
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Program',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppTheme.mutedText(context)),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    TemplateLabels.nameFor(
                                        trainingState.activeBarbellTemplate),
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Text(
                                  'Change in Setup',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.mutedText(context)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              TemplateLabels.lineFor(
                                  trainingState.activeBarbellTemplate),
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.mutedText(context)),
                            ),
                            if (trainingState.isCustomTemplateActive) ...[
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  ElevatedButton.icon(
                                    key: const Key('customize_program_btn'),
                                    onPressed: () =>
                                        CustomProgramEditorSheet.show(context),
                                    icon: const Icon(Icons.tune, size: 16),
                                    label: const Text('Customize Program'),
                                  ),
                                  OutlinedButton.icon(
                                    key: const Key('duplicate_preset_btn'),
                                    onPressed: () =>
                                        _showDuplicatePresetDialog(context),
                                    icon: const Icon(Icons.copy, size: 16),
                                    label: const Text('Duplicate Preset'),
                                  ),
                                  if (trainingState.isCustomTemplateModified)
                                    OutlinedButton.icon(
                                      key: const Key('reset_custom_btn'),
                                      onPressed: () =>
                                          _confirmResetToFactory(context),
                                      icon: const Icon(Icons.restore,
                                          size: 16, color: Colors.red),
                                      label: const Text('Revert to Factory',
                                          style: TextStyle(color: Colors.red)),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),

                  // Workout day switcher & rotation indicator
                  Card(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.35),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Workout Rotation',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Active: ${currentWorkout.code}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: List.generate(
                                templateDetails.workouts.length, (index) {
                              final workout = templateDetails.workouts[index];
                              final isSelected = index ==
                                  (trainingState.activeBarbellRotationIndex %
                                      templateDetails.workouts.length);
                              return ChoiceChip(
                                label: Text(workout.code),
                                selected: isSelected,
                                onSelected: (_) {
                                  setState(() {
                                    _completedCoreLifts.clear();
                                    _completedAccessories.clear();
                                  });
                                  trainingState.setBarbellRotationIndex(index);
                                },
                              );
                            }),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            currentWorkout.title,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            currentWorkout.subtitle,
                            style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.mutedText(context)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Johnny Pain Rule Banner
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .secondary
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .secondary
                              .withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline,
                            size: 20,
                            color: Theme.of(context).colorScheme.secondary),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Greyskull Rule: Upper body compound lifts are always completed before lower body lifts. Last set is AMRAP (5+ to failure). Accessories are performed last.',
                            style: TextStyle(fontSize: 12, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Core Barbell Lifts Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Core Barbell Lifts',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${_completedCoreLifts.length}/${coreLifts.length} complete',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.mutedText(context)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...coreLifts.map((lift) {
                    final isCompleted = _completedCoreLifts.contains(lift.name);
                    final weightCtrl = _getWeightController(lift.name);
                    final repsCtrl = _getRepsController(lift.name);
                    final totalSets = lift.sets <= 0 ? 3 : lift.sets;
                    final doneSets = _setsForLift(lift.name);
                    final currentLift = coreLifts
                        .cast<TemplateLift?>()
                        .firstWhere(
                            (l) => !_completedCoreLifts.contains(l!.name),
                            orElse: () => null);
                    final isCurrent =
                        !isCompleted && currentLift?.name == lift.name;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isCurrent
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context)
                                  .colorScheme
                                  .outline
                                  .withValues(alpha: 0.5),
                          width: isCurrent ? 2 : 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              lift.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ),
                                          if (isCurrent) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                    .withValues(alpha: 0.16),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'NEXT',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                ),
                                              ),
                                            ),
                                          ],
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: lift.isUpperBody
                                                  ? AppTheme.resistanceAccent(
                                                          context)
                                                      .withValues(alpha: 0.16)
                                                  : AppTheme.calisthenicsAccent(
                                                          context)
                                                      .withValues(alpha: 0.16),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              lift.isUpperBody
                                                  ? 'Upper Body'
                                                  : 'Lower Body',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: lift.isUpperBody
                                                    ? AppTheme.resistanceAccent(
                                                        context)
                                                    : AppTheme
                                                        .calisthenicsAccent(
                                                            context),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        lift.prescription,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                      ),
                                      TextButton.icon(
                                        onPressed: () =>
                                            _editRestSeconds(lift.name),
                                        icon: const Icon(Icons.alarm, size: 14),
                                        label: Text(
                                          'Rest ${trainingState.restSecondsForLift(lift.name)}s',
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: const Size(0, 24),
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isCompleted)
                                  Icon(Icons.check_circle,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                ...List.generate(totalSets, (index) {
                                  final isAmrapSet =
                                      lift.isAmrap && index == totalSets - 1;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: _SetCircleButton(
                                      key: ValueKey(
                                          'set-tap-${lift.name}-$index'),
                                      label: isAmrapSet
                                          ? '5+'
                                          : '${_repOverrides[lift.name]?[index] ?? lift.defaultReps}',
                                      isAmrap: isAmrapSet,
                                      isDone: doneSets.contains(index),
                                      semanticsLabel: isAmrapSet
                                          ? 'Mark AMRAP set done'
                                          : 'Mark set ${index + 1} done',
                                      onTap: () => _toggleSet(
                                          lift.name, index, totalSets),
                                      onLongPress: () => _promptRepOverride(
                                          lift, index, totalSets),
                                    ),
                                  );
                                }),
                                Expanded(
                                  child: Text(
                                    totalSets == 1
                                        ? 'Tap the circle when the AMRAP set is done'
                                        : lift.isAmrap
                                            ? 'Tap 5, 5, then 5+ (AMRAP) as you finish each set'
                                            : 'Tap each circle as you finish a set',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                if (lift.isAmrap)
                                  TextButton.icon(
                                    onPressed: () =>
                                        _toggleAmrapStopwatch(lift.name),
                                    icon: Icon(
                                      _amrapRunningLift == lift.name
                                          ? Icons.stop_circle_outlined
                                          : Icons.timer_outlined,
                                      size: 16,
                                    ),
                                    label: Text(
                                      _amrapLabel(lift.name),
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: weightCtrl,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    decoration: const InputDecoration(
                                      labelText: 'Working Weight (lbs)',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: repsCtrl,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    decoration: InputDecoration(
                                      labelText: lift.isAmrap
                                          ? 'AMRAP Reps (5+)'
                                          : 'Reps',
                                      border: const OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),

                  // Plug-in Accessories Section (Customizable per book rules)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Plug-in Accessories',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Book limit: 1–3 per session (${accessories.length} configured)',
                            style: TextStyle(
                              fontSize: 11,
                              color: accessories.length > 3
                                  ? Theme.of(context).colorScheme.error
                                  : AppTheme.mutedText(context),
                              fontWeight: accessories.length > 3
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: _showAddAccessoryDialog,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Plug-in'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  if (accessories.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Column(
                            children: [
                              Text(
                                'No plug-in accessories scheduled for this workout.',
                                style: TextStyle(
                                    color: AppTheme.mutedText(context)),
                              ),
                              const SizedBox(height: 6),
                              OutlinedButton.icon(
                                onPressed: _showAddAccessoryDialog,
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Add Official Accessory'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ...List.generate(accessories.length, (index) {
                      final accessory = accessories[index];
                      final isDone = _completedAccessories.contains(accessory);

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 2),
                          leading: Checkbox(
                            value: isDone,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _completedAccessories.add(accessory);
                                } else {
                                  _completedAccessories.remove(accessory);
                                }
                              });
                            },
                          ),
                          title: Text(
                            accessory,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              decoration:
                                  isDone ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (index > 0)
                                IconButton(
                                  icon:
                                      const Icon(Icons.arrow_upward, size: 18),
                                  tooltip: 'Move Up',
                                  onPressed: () {
                                    trainingState
                                        .reorderAccessoriesInCurrentWorkout(
                                            index, index - 1);
                                  },
                                ),
                              if (index < accessories.length - 1)
                                IconButton(
                                  icon: const Icon(Icons.arrow_downward,
                                      size: 18),
                                  tooltip: 'Move Down',
                                  onPressed: () {
                                    trainingState
                                        .reorderAccessoriesInCurrentWorkout(
                                            index, index + 2);
                                  },
                                ),
                              IconButton(
                                icon: Icon(Icons.delete_outline,
                                    size: 18,
                                    color: Theme.of(context).colorScheme.error),
                                tooltip: 'Remove',
                                onPressed: () {
                                  setState(() {
                                    _completedAccessories.remove(accessory);
                                  });
                                  trainingState
                                      .removeAccessoryFromCurrentWorkout(index);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                  if (trainingState.isCurrentWorkoutCustomized())
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () {
                          trainingState
                              .resetCurrentWorkoutAccessoriesToDefault();
                          setState(() {
                            _completedAccessories.clear();
                          });
                        },
                        icon: const Icon(Icons.restore, size: 16),
                        label: const Text('Reset to Book Defaults',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Live Volume Summary
                  Card(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withValues(alpha: 0.3),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Calculated Session Volume:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            '${totalVolume.toStringAsFixed(1)} lbs',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Session notes
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Session Notes',
                      hintText:
                          'e.g., Felt strong on Squat AMRAP (hit 8 reps). Curls felt good.',
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Log Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => _logSession(currentWorkout, coreLifts),
                    icon: const Icon(Icons.save),
                    label: const Text(
                      'Log Today\'s Barbell Workout to History',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      final recent = trainingState.history
                          .where((e) => e.category == HistoryCategory.weight)
                          .toList();
                      if (recent.isNotEmpty) {
                        SocialShareService.showShareModal(
                          context: context,
                          entry: recent.first,
                          defaultHashtag: trainingState.socialShareHashtag,
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('No logged weight workouts to share yet.'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Share Recent Weight Workout'),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Circular tap target used to mark a single set (5 / 5 / 5+ AMRAP) complete.
///
/// Mirrors the simple "tap the ring" flow of the official Greyskull reference
/// apps and keeps the AMRAP set visually distinct.
class _SetCircleButton extends StatelessWidget {
  const _SetCircleButton({
    super.key,
    required this.label,
    required this.isAmrap,
    required this.isDone,
    required this.semanticsLabel,
    required this.onTap,
    this.onLongPress,
  });

  final String label;
  final bool isAmrap;
  final bool isDone;
  final String semanticsLabel;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // AMRAP keeps the Greyskull amber accent so the top set reads differently
    // from the straight sets on every skin.
    const amrapAccent = Color(0xFFFFB300);
    final ringColor = isAmrap ? amrapAccent : scheme.primary;
    final textColor = isDone
        ? (isAmrap ? Colors.black : scheme.onPrimary)
        : (isAmrap ? amrapAccent : scheme.onSurface);

    return Semantics(
      button: true,
      label: semanticsLabel,
      child: InkResponse(
        onTap: onTap,
        onLongPress: onLongPress,
        radius: 26,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone ? ringColor : Colors.transparent,
            border: Border.all(
              color: isDone
                  ? ringColor
                  : ringColor.withValues(alpha: isAmrap ? 1.0 : 0.45),
              width: isAmrap ? 2.5 : 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isAmrap ? 13 : 15,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
