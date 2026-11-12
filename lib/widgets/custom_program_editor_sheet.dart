import 'package:flutter/material.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/themes/theme.dart';

/// Modal bottom sheet to create and edit custom barbell programs from zero
/// without requiring official book presets.
class CustomProgramEditorSheet extends StatefulWidget {
  const CustomProgramEditorSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => const CustomProgramEditorSheet(),
    );
  }

  @override
  State<CustomProgramEditorSheet> createState() =>
      _CustomProgramEditorSheetState();
}

class _CustomProgramEditorSheetState extends State<CustomProgramEditorSheet> {
  late TextEditingController _nameController;
  late TextEditingController _subtitleController;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: trainingState.customTemplateName);
    _subtitleController =
        TextEditingController(text: trainingState.customTemplateSubtitle);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }

  void _showDuplicatePresetDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Duplicate from Book Preset'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select an official book template to copy into your custom program. '
              'All workout days, core lifts, and plug-in accessories will be cloned '
              'so you can customize them freely.',
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
                  setState(() {
                    _nameController.text = trainingState.customTemplateName;
                    _subtitleController.text =
                        trainingState.customTemplateSubtitle;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Cloned from ${details.name} into Custom Program'),
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

  void _confirmResetToFactory() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset to Factory Defaults?'),
        content: const Text(
          'This will restore the standard Day A / Day B starting template and remove '
          'all custom workout days and core lift adjustments.\n\n'
          'Are you sure you want to revert to factory?',
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
              setState(() {
                _nameController.text = trainingState.customTemplateName;
                _subtitleController.text = trainingState.customTemplateSubtitle;
              });
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

  void _showAddWorkoutDayDialog() {
    final nextNum = trainingState.customTemplateWorkouts.length + 1;
    final codeCtrl = TextEditingController(text: 'Day $nextNum');
    final titleCtrl = TextEditingController(text: 'Workout Day $nextNum');
    final subtitleCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Workout Day'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: codeCtrl,
              decoration: const InputDecoration(
                labelText: 'Day Code (e.g., Day C, Day 3)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Day Title (e.g., Workout C)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: subtitleCtrl,
              decoration: const InputDecoration(
                labelText: 'Subtitle / Focus (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              trainingState.addCustomWorkoutDay(
                code: codeCtrl.text,
                title: titleCtrl.text,
                subtitle: subtitleCtrl.text,
              );
              Navigator.of(ctx).pop();
            },
            child: const Text('Add Day'),
          ),
        ],
      ),
    );
  }

  void _showAddCoreLiftDialog(int dayIndex) {
    const defaultOptions = [
      'Overhead Press',
      'Bench Press',
      'Incline Bench Press',
      'Squat',
      'Front Squat',
      'Deadlift',
      'Power Clean',
      'Barbell Row',
    ];

    String selectedLift = 'Bench Press';
    final customNameCtrl = TextEditingController();
    bool isCustomName = false;
    int sets = 3;
    int reps = 5;
    bool isAmrap = true;
    bool isUpperBody = true;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final liftName = isCustomName ? customNameCtrl.text : selectedLift;
          final prescription = sets == 1
              ? (isAmrap ? '1 x $reps+' : '1 x $reps')
              : (isAmrap
                  ? '${sets - 1} x $reps, 1 x $reps+ (AMRAP)'
                  : '$sets x $reps');

          return AlertDialog(
            title: const Text('Add Core Barbell Lift'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Movement:',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      ...defaultOptions.map((opt) {
                        final isSel = !isCustomName && selectedLift == opt;
                        return ChoiceChip(
                          label:
                              Text(opt, style: const TextStyle(fontSize: 12)),
                          selected: isSel,
                          onSelected: (val) {
                            if (val) {
                              setDialogState(() {
                                isCustomName = false;
                                selectedLift = opt;
                                isUpperBody = [
                                  'Overhead Press',
                                  'Bench Press',
                                  'Incline Bench Press',
                                  'Barbell Row'
                                ].contains(opt);
                                if (opt == 'Deadlift') {
                                  sets = 1;
                                } else if (sets == 1) {
                                  sets = 3;
                                }
                              });
                            }
                          },
                        );
                      }),
                      ChoiceChip(
                        label: const Text('Other / Custom',
                            style: TextStyle(fontSize: 12)),
                        selected: isCustomName,
                        onSelected: (val) {
                          if (val) {
                            setDialogState(() => isCustomName = true);
                          }
                        },
                      ),
                    ],
                  ),
                  if (isCustomName) ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: customNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Custom Lift Name',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: sets,
                          decoration: const InputDecoration(
                            labelText: 'Sets',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                          ),
                          items: [1, 2, 3, 4, 5]
                              .map((s) => DropdownMenuItem(
                                  value: s, child: Text('$s sets')))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() => sets = val);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: reps,
                          decoration: const InputDecoration(
                            labelText: 'Base Reps',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                          ),
                          items: [3, 5, 6, 8, 10, 12]
                              .map((r) => DropdownMenuItem(
                                  value: r, child: Text('$r reps')))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() => reps = val);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Last Set AMRAP (5+ reps)',
                        style: TextStyle(fontSize: 14)),
                    subtitle: Text(
                        'GSLP standard: push final set to near failure',
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.mutedText(context))),
                    value: isAmrap,
                    onChanged: (val) => setDialogState(() => isAmrap = val),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Upper Body Lift',
                        style: TextStyle(fontSize: 14)),
                    subtitle: Text(
                        'Greyskull rule: Upper body lifts are always performed before lower body lifts',
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.mutedText(context))),
                    value: isUpperBody,
                    onChanged: (val) => setDialogState(() => isUpperBody = val),
                  ),
                  const SizedBox(height: 8),
                  Text('Prescription: $prescription',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.resistanceAccent(context))),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: liftName.trim().isEmpty
                    ? null
                    : () {
                        trainingState.addCoreLiftToCustomWorkout(
                          dayIndex,
                          TemplateLift(
                            name: liftName.trim(),
                            prescription: prescription,
                            sets: sets,
                            defaultReps: reps,
                            isAmrap: isAmrap,
                            isUpperBody: isUpperBody,
                          ),
                        );
                        Navigator.of(ctx).pop();
                      },
                child: const Text('Add Lift'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: trainingState,
      builder: (context, _) {
        final days = trainingState.customTemplateWorkouts;

        return DraggableScrollableSheet(
          initialChildSize: 0.88,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (ctx, scrollController) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: ListView(
                controller: scrollController,
                children: [
                  // Header bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Customize Barbell Program',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Build from zero without book presets',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.mutedText(context)),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const Divider(height: 20),

                  // Program metadata card
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Program Identity',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Program Name',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                            ),
                            onChanged: (val) =>
                                trainingState.setCustomTemplateName(val),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _subtitleController,
                            decoration: const InputDecoration(
                              labelText: 'Program Subtitle / Description',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                            ),
                            onChanged: (val) =>
                                trainingState.setCustomTemplateSubtitle(val),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Quick actions: Duplicate from Preset & Revert to Factory
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showDuplicatePresetDialog,
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text('Duplicate Preset',
                              style: TextStyle(fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _confirmResetToFactory,
                          icon: const Icon(Icons.restore,
                              size: 16, color: Colors.red),
                          label: const Text('Revert to Factory',
                              style:
                                  TextStyle(fontSize: 13, color: Colors.red)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Greyskull Golden Rule reminder
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .secondary
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Theme.of(context).colorScheme.secondary),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline,
                            size: 18,
                            color: Theme.of(context).colorScheme.secondary),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Greyskull Rule: Compound upper body lifts (Press, Bench) are always performed before lower body lifts (Squat, Deadlift).',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Workout days header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Workout Days (${days.length})',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        onPressed: _showAddWorkoutDayDialog,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Day'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Workout days list
                  ...days.asMap().entries.map((entry) {
                    final dayIndex = entry.key;
                    final day = entry.value;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .primaryContainer,
                                      child: Text(day.code,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      day.title,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15),
                                    ),
                                  ],
                                ),
                                if (days.length > 1)
                                  IconButton(
                                    icon: Icon(Icons.delete_outline,
                                        size: 20,
                                        color: AppTheme.mutedText(context)),
                                    onPressed: () => trainingState
                                        .removeCustomWorkoutDay(dayIndex),
                                  ),
                              ],
                            ),
                            if (day.subtitle.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(day.subtitle,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.mutedText(context))),
                            ],
                            const SizedBox(height: 10),
                            const Text('Core Lifts:',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 4),
                            if (day.coreLifts.isEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Text('No core lifts configured yet.',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                        color: AppTheme.mutedText(context))),
                              ),
                            ...day.coreLifts.asMap().entries.map((liftEntry) {
                              final liftIndex = liftEntry.key;
                              final lift = liftEntry.value;

                              return Card(
                                elevation: 0.5,
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withValues(alpha: 0.35),
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: ListTile(
                                  dense: true,
                                  leading: Icon(
                                    lift.isUpperBody
                                        ? Icons.arrow_upward
                                        : Icons.arrow_downward,
                                    size: 18,
                                    color: lift.isUpperBody
                                        ? AppTheme.resistanceAccent(context)
                                        : AppTheme.calisthenicsAccent(context),
                                  ),
                                  title: Text(lift.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14)),
                                  subtitle: Text(
                                    '${lift.prescription} • ${lift.isUpperBody ? "Upper Body" : "Lower Body"}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (liftIndex > 0)
                                        IconButton(
                                          icon: const Icon(Icons.arrow_upward,
                                              size: 16),
                                          onPressed: () => trainingState
                                              .reorderCoreLiftsInCustomWorkout(
                                                  dayIndex,
                                                  liftIndex,
                                                  liftIndex - 1),
                                        ),
                                      if (liftIndex < day.coreLifts.length - 1)
                                        IconButton(
                                          icon: const Icon(Icons.arrow_downward,
                                              size: 16),
                                          onPressed: () => trainingState
                                              .reorderCoreLiftsInCustomWorkout(
                                                  dayIndex,
                                                  liftIndex,
                                                  liftIndex + 2),
                                        ),
                                      IconButton(
                                        icon: Icon(Icons.delete_outline,
                                            size: 18,
                                            color: AppTheme.mutedText(context)),
                                        onPressed: () => trainingState
                                            .removeCoreLiftFromCustomWorkout(
                                                dayIndex, liftIndex),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: () =>
                                    _showAddCoreLiftDialog(dayIndex),
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Add Core Lift',
                                    style: TextStyle(fontSize: 13)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Done'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
