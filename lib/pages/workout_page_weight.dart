import 'dart:async';

import 'package:flutter/material.dart';
import 'package:greyskull_lp/ui/gs_dialog.dart';
import 'package:greyskull_lp/models/accountability_post.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/services/workout_notification_service.dart';
import 'package:greyskull_lp/program/template_labels.dart';
import 'package:greyskull_lp/services/social_share_service.dart';
import 'package:greyskull_lp/themes/gs_tokens.dart';
import 'package:greyskull_lp/themes/theme.dart';
import 'package:greyskull_lp/ui/gs_icon.dart';
import 'package:greyskull_lp/ui/gs_widgets.dart';
import 'package:greyskull_lp/widgets/accountability_post_sheet.dart';
import 'package:greyskull_lp/widgets/custom_program_editor_sheet.dart';
import 'package:greyskull_lp/widgets/circular_rest_timer.dart';

class WorkoutPageWeight extends StatefulWidget {
  const WorkoutPageWeight({
    super.key,
    this.liveMode = false,
    this.onSessionLogged,
  });

  /// When true the page runs as the focused live session (issue #80):
  /// session clock starts immediately, setup chrome is hidden and leaving
  /// requires confirmation.
  final bool liveMode;

  /// Lets the live shell stop its ongoing notification when the session is
  /// logged (#112).
  final VoidCallback? onSessionLogged;

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

  String _weightLabel(TextEditingController controller) {
    final value = _fieldDouble(controller);
    if (value <= 0) {
      return '—';
    }
    final text = value.truncateToDouble() == value
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
    return '$text lb';
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
            return GsAlertDialog(
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
      builder: (ctx) => GsAlertDialog(
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
      builder: (ctx) => GsAlertDialog(
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

    // The session is finished: no ongoing or rest alerts should linger
    // (issue #112).
    WorkoutNotificationService.instance.cancelAll();
    widget.onSessionLogged?.call();

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

    // Post-log share sheet (#110): the workout is already saved, so the sheet
    // is the last step. Accountability modes already offer their own sheet.
    if (trainingState.accountabilityMode == AccountabilityPostMode.off &&
        trainingState.history.isNotEmpty) {
      SocialShareService.maybePromptAfterLog(
        context,
        trainingState.history.first,
      );
    }
  }

  Set<int> _setsForLift(String liftName) =>
      _completedSetsByLift.putIfAbsent(liftName, () => <int>{});

  Future<void> _editRestSeconds(String liftName) async {
    final current = trainingState.restSecondsForLift(liftName);
    final choice = await showDialog<int>(
      context: context,
      builder: (ctx) => GsSimpleDialog(
        title: Text('Rest for $liftName'),
        children: [
          for (final seconds in const [30, 45, 60, 90, 120, 180, 300])
            GsDialogOption(
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
      TemplateLift lift, int setIndex, int totalSets,
      {bool completeAfterSave = false}) async {
    final current = _repOverrides[lift.name]?[setIndex] ?? lift.defaultReps;
    var value = current;
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => GsAlertDialog(
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
      if (completeAfterSave && !_setsForLift(lift.name).contains(setIndex)) {
        _toggleSet(lift.name, setIndex, totalSets);
      }
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
        final perLiftRest = trainingState.restSecondsForLift(liftName);
        // 0 means "same as the lift's own rest" (issue #107): the hidden 60s
        // default used to override a configured 90s rest on the last set.
        _restSeconds = liftDone && trainingState.restAfterExerciseSeconds > 0
            ? trainingState.restAfterExerciseSeconds
            : perLiftRest;
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

  Widget _buildSessionHeader({
    required TemplateWorkoutDay currentWorkout,
    required BarbellTemplateDetails templateDetails,
    required List<TemplateLift> coreLifts,
    required double totalVolume,
  }) {
    final tokens = context.gs;
    final totalSets = coreLifts.fold<int>(
      0,
      (sum, lift) => sum + (lift.sets <= 0 ? 3 : lift.sets),
    );
    final doneSets = coreLifts.fold<int>(
      0,
      (sum, lift) => sum + _setsForLift(lift.name).length,
    );
    final progress = totalSets == 0 ? 0.0 : doneSets / totalSets;

    return GsCard(
      gradient: LinearGradient(
        colors: <Color>[
          tokens.accent.withValues(alpha: 0.18),
          tokens.surface,
        ],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      ),
      borderColor: tokens.accent.withValues(alpha: 0.30),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'LIVE SESSION',
                      style: TextStyle(
                        fontFamily: GsFont.body,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.8,
                        color: tokens.muted,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      currentWorkout.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: GsFont.display,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                        color: tokens.bone,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${templateDetails.name} · ${currentWorkout.subtitle}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: GsFont.body,
                        fontSize: 10.5,
                        height: 1.4,
                        color: tokens.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GsRing(
                progress: progress,
                size: 58,
                strokeWidth: 5.5,
                child: Text(
                  '${(progress * 100).round()}%',
                  style: TextStyle(
                    fontFamily: GsFont.mono,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: tokens.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              GsTag(
                'Session ${_formatElapsed(Duration(seconds: _sessionSeconds))}',
                tone: GsTagTone.accent,
                svgIcon: 'timer',
              ),
              GsTag('$doneSets SETS'),
              GsTag(
                'VOL ${totalVolume.toStringAsFixed(0)} LBS',
                svgIcon: 'db',
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: trainingState,
      builder: (context, _) {
        final tokens = context.gs;
        final templateDetails = trainingState.activeBarbellTemplateDetails;
        final currentWorkout = trainingState.currentTemplateWorkout;
        final coreLifts = currentWorkout.coreLifts;
        final accessories = trainingState.currentWorkoutAccessories;
        final totalVolume = _calculateTotalVolume(coreLifts);

        // Session summary stays at the top of the list; the rest countdown
        // docks to the bottom so it remains visible while scrolling (#75).
        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(16, 10, 16, 24),
                children: [
                  if (_sessionRunning) ...<Widget>[
                    _buildSessionHeader(
                      currentWorkout: currentWorkout,
                      templateDetails: templateDetails,
                      coreLifts: coreLifts,
                      totalVolume: totalVolume,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (!widget.liveMode &&
                      trainingState.programLevel ==
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
                                // The plan is frozen during a live session
                                // (issue #109); change days in Setup.
                                onSelected: widget.liveMode
                                    ? null
                                    : (_) {
                                        setState(() {
                                          _completedCoreLifts.clear();
                                          _completedAccessories.clear();
                                        });
                                        trainingState
                                            .setBarbellRotationIndex(index);
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

                  // Johnny Pain Rule Banner (setup only; issue #108).
                  if (!widget.liveMode)
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
                    children: <Widget>[
                      Text(
                        'Core Barbell Lifts',
                        style: TextStyle(
                          fontFamily: GsFont.body,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: tokens.bone,
                        ),
                      ),
                      Text(
                        '${_completedCoreLifts.length}/${coreLifts.length} complete',
                        style: TextStyle(
                          fontFamily: GsFont.body,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: tokens.muted,
                        ),
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

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GsCard(
                        borderColor: isCurrent
                            ? tokens.accent
                            : tokens.line.withValues(alpha: 0.8),
                        color: isCurrent
                            ? tokens.accent.withValues(alpha: 0.04)
                            : null,
                        padding: const EdgeInsets.all(13),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Row(
                                        children: <Widget>[
                                          Flexible(
                                            child: Text(
                                              lift.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontFamily: GsFont.body,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: tokens.bone,
                                              ),
                                            ),
                                          ),
                                          if (isCurrent) ...<Widget>[
                                            const SizedBox(width: 6),
                                            const GsTag(
                                              'NEXT',
                                              tone: GsTagTone.accent,
                                            ),
                                          ],
                                          const SizedBox(width: 6),
                                          GsTag(
                                            lift.isUpperBody
                                                ? 'UPPER BODY'
                                                : 'LOWER BODY',
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        lift.prescription,
                                        style: TextStyle(
                                          fontFamily: GsFont.body,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w500,
                                          color: tokens.accent,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            _editRestSeconds(lift.name),
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: const Size(0, 24),
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            GsIcon('timer',
                                                size: 13, color: tokens.accent),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Rest ${trainingState.restSecondsForLift(lift.name)}s',
                                              style:
                                                  const TextStyle(fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isCompleted)
                                  GsIcon(
                                    'check',
                                    size: 18,
                                    color: tokens.accent,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ...List<Widget>.generate(totalSets, (int index) {
                              final isAmrapSet =
                                  lift.isAmrap && index == totalSets - 1;
                              final isDone = doneSets.contains(index);
                              final reps = _repOverrides[lift.name]?[index] ??
                                  lift.defaultReps;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: GsSetRow(
                                  key: ValueKey('set-tap-${lift.name}-$index'),
                                  weightLabel: _weightLabel(weightCtrl),
                                  repsLabel: '$reps',
                                  isDone: isDone,
                                  isAmrap: isAmrapSet,
                                  isLogged: isAmrapSet && isDone,
                                  semanticsLabel: isAmrapSet
                                      ? 'Log AMRAP set reps'
                                      : 'Mark set ${index + 1} done',
                                  onTap: () {
                                    if (isAmrapSet && !isDone) {
                                      _promptRepOverride(
                                        lift,
                                        index,
                                        totalSets,
                                        completeAfterSave: true,
                                      );
                                    } else {
                                      _toggleSet(lift.name, index, totalSets);
                                    }
                                  },
                                  onLongPress: () => _promptRepOverride(
                                      lift, index, totalSets),
                                ),
                              );
                            }),
                            if (!widget.liveMode) ...<Widget>[
                              const SizedBox(height: 2),
                              Text(
                                totalSets == 1
                                    ? 'Tap the circle when the AMRAP set is done'
                                    : lift.isAmrap
                                        ? 'Tap 5, 5, then 5+ (AMRAP) as you finish each set'
                                        : 'Tap each circle as you finish a set',
                                style: TextStyle(
                                  fontFamily: GsFont.body,
                                  fontSize: 11,
                                  color: tokens.muted,
                                ),
                              ),
                            ],
                            if (lift.isAmrap)
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () =>
                                      _toggleAmrapStopwatch(lift.name),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    minimumSize: const Size(0, 30),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      GsIcon(
                                        _amrapRunningLift == lift.name
                                            ? 'pause'
                                            : 'timer',
                                        size: 14,
                                        color: tokens.accent,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        _amrapLabel(lift.name),
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            const SizedBox(height: 6),
                            Row(
                              children: <Widget>[
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
                        children: <Widget>[
                          Text(
                            'Plug-in Accessories',
                            style: TextStyle(
                              fontFamily: GsFont.body,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: tokens.bone,
                            ),
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
                      if (!widget.liveMode)
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
                              if (!widget.liveMode) ...[
                                const SizedBox(height: 6),
                                OutlinedButton.icon(
                                  onPressed: _showAddAccessoryDialog,
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text('Add Official Accessory'),
                                ),
                              ],
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
                          trailing: widget.liveMode
                              ? null
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (index > 0)
                                      IconButton(
                                        icon: const Icon(Icons.arrow_upward,
                                            size: 18),
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
                                          color: Theme.of(context)
                                              .colorScheme
                                              .error),
                                      tooltip: 'Remove',
                                      onPressed: () {
                                        setState(() {
                                          _completedAccessories
                                              .remove(accessory);
                                        });
                                        trainingState
                                            .removeAccessoryFromCurrentWorkout(
                                                index);
                                      },
                                    ),
                                  ],
                                ),
                        ),
                      );
                    }),

                  if (!widget.liveMode &&
                      trainingState.isCurrentWorkoutCustomized())
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
                  GsCard(
                    color: tokens.surface2,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          'Calculated Session Volume:',
                          style: TextStyle(
                            fontFamily: GsFont.body,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                            color: tokens.bone,
                          ),
                        ),
                        Text(
                          '${totalVolume.toStringAsFixed(1)} lbs',
                          style: TextStyle(
                            fontFamily: GsFont.mono,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: tokens.accent,
                          ),
                        ),
                      ],
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
                  GsPrimaryButton(
                    label: 'Log Today\'s Barbell Workout to History',
                    svgIcon: 'check',
                    onPressed: () => _logSession(currentWorkout, coreLifts),
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
            if (_restTimerActive)
              GsStickyDock(
                child: CircularRestTimer(
                  key: ValueKey('rest-$_restTimerToken'),
                  seconds: _restSeconds,
                  soundEnabled: trainingState.restTimerSoundEnabled,
                  countUp: trainingState.restTimerCountUp,
                  size: trainingState.restTimerSize,
                  coachingText: widget.liveMode ? null : _restCoaching,
                  onDismissed: () => setState(() => _restTimerActive = false),
                ),
              ),
          ],
        );
      },
    );
  }
}
