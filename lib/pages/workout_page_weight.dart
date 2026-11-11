import 'package:flutter/material.dart';
import 'package:greyskull_lp/models/training_state.dart';

class WorkoutPageWeight extends StatefulWidget {
  const WorkoutPageWeight({super.key});

  @override
  State<WorkoutPageWeight> createState() => _WorkoutPageWeightState();
}

class _WorkoutPageWeightState extends State<WorkoutPageWeight> {
  final Set<String> _completedCoreLifts = {};
  final Set<String> _completedAccessories = {};
  final Map<String, TextEditingController> _weightControllers = {};
  final Map<String, TextEditingController> _repsControllers = {};
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    for (final controller in _weightControllers.values) {
      controller.dispose();
    }
    for (final controller in _repsControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _getWeightController(String liftName) {
    return _weightControllers.putIfAbsent(
        liftName, () => TextEditingController());
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
                      const Center(
                          child: Text('— OR ENTER CUSTOM ACCESSORY —',
                              style:
                                  TextStyle(fontSize: 11, color: Colors.grey))),
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

  void _logSession(
      TemplateWorkoutDay currentWorkout, List<TemplateLift> coreLifts) {
    final coreLiftSummaries = <String>[];
    for (final lift in coreLifts) {
      final isDone = _completedCoreLifts.contains(lift.name);
      final weight = _fieldDouble(_getWeightController(lift.name));
      final reps = _fieldDouble(_getRepsController(lift.name));
      final status = isDone ? 'Done' : 'Not marked';
      final details = weight > 0 && reps > 0
          ? '${lift.name} ($status, ${weight.toStringAsFixed(1)} lbs x ${reps.toInt()} reps x ${lift.sets} sets)'
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

    trainingState.logWeightSession(
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

    setState(() {
      _completedCoreLifts.clear();
      _completedAccessories.clear();
      _notesController.clear();
      for (final controller in _weightControllers.values) {
        controller.clear();
      }
      for (final controller in _repsControllers.values) {
        controller.clear();
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Workout logged! Advanced rotation to: ${trainingState.currentTemplateWorkout.title}',
        ),
      ),
    );
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

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (trainingState.programLevel == ProgramLevel.foundation) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Level 1 (Foundation): Keep it simple. Johnny Pain advises mastering core lifts first before adding plug-in accessories.',
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Template selection card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Official Greyskull LP Template',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<BarbellTemplate>(
                      key: ValueKey(trainingState.activeBarbellTemplate),
                      initialValue: trainingState.activeBarbellTemplate,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: BarbellTemplate.values.map((template) {
                        final details =
                            TrainingState.templateDefinitions[template]!;
                        return DropdownMenuItem(
                          value: template,
                          child: Text(
                            details.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        );
                      }).toList(),
                      onChanged: (newTemplate) {
                        if (newTemplate != null) {
                          setState(() {
                            _completedCoreLifts.clear();
                            _completedAccessories.clear();
                          });
                          trainingState.setBarbellTemplate(newTemplate);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      templateDetails.subtitle,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Book ref: ${templateDetails.bookReference}',
                      style: const TextStyle(
                          fontSize: 12,
                          color: Colors.indigo,
                          fontStyle: FontStyle.italic),
                    ),
                    Text(
                      'Cadence: ${templateDetails.scheduleDescription}',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),
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
                            color:
                                Theme.of(context).colorScheme.primaryContainer,
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
                      children: List.generate(templateDetails.workouts.length,
                          (index) {
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
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black54),
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
                color: Colors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: Colors.amber.shade700.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      size: 20, color: Colors.amber.shade900),
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_completedCoreLifts.length}/${coreLifts.length} complete',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...coreLifts.map((lift) {
              final isCompleted = _completedCoreLifts.contains(lift.name);
              final weightCtrl = _getWeightController(lift.name);
              final repsCtrl = _getRepsController(lift.name);

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: lift.isUpperBody
                                            ? Colors.blue
                                                .withValues(alpha: 0.15)
                                            : Colors.orange
                                                .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        lift.isUpperBody
                                            ? 'Upper Body'
                                            : 'Lower Body',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: lift.isUpperBody
                                              ? Colors.blue.shade800
                                              : Colors.orange.shade900,
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
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Checkbox(
                            value: isCompleted,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _completedCoreLifts.add(lift.name);
                                } else {
                                  _completedCoreLifts.remove(lift.name);
                                }
                              });
                            },
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
                                labelText:
                                    lift.isAmrap ? 'AMRAP Reps (5+)' : 'Reps',
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
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Book limit: 1–3 per session (${accessories.length} configured)',
                      style: TextStyle(
                        fontSize: 11,
                        color: accessories.length > 3
                            ? Colors.red.shade700
                            : Colors.grey,
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
                        const Text(
                          'No plug-in accessories scheduled for this workout.',
                          style: TextStyle(color: Colors.grey),
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
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
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
                        decoration: isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (index > 0)
                          IconButton(
                            icon: const Icon(Icons.arrow_upward, size: 18),
                            tooltip: 'Move Up',
                            onPressed: () {
                              trainingState.reorderAccessoriesInCurrentWorkout(
                                  index, index - 1);
                            },
                          ),
                        if (index < accessories.length - 1)
                          IconButton(
                            icon: const Icon(Icons.arrow_downward, size: 18),
                            tooltip: 'Move Down',
                            onPressed: () {
                              trainingState.reorderAccessoriesInCurrentWorkout(
                                  index, index + 2);
                            },
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              size: 18, color: Colors.redAccent),
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
                    trainingState.resetCurrentWorkoutAccessoriesToDefault();
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Calculated Session Volume:',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }
}
