import 'package:flutter/material.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/themes/theme.dart';

class CalisthenicsAccessoriesSection extends StatefulWidget {
  final DailyMethod method;
  final Set<String> completedAccessories;
  final ValueChanged<Set<String>> onCompletedChanged;

  /// When false the section only manages the accessory list (add, reorder,
  /// remove) and does not show per-day completion checkboxes.
  final bool showCompletion;

  const CalisthenicsAccessoriesSection({
    super.key,
    required this.method,
    required this.completedAccessories,
    required this.onCompletedChanged,
    this.showCompletion = true,
  });

  @override
  State<CalisthenicsAccessoriesSection> createState() =>
      _CalisthenicsAccessoriesSectionState();
}

class _CalisthenicsAccessoriesSectionState
    extends State<CalisthenicsAccessoriesSection> {
  final TextEditingController _customController = TextEditingController();

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _showAddAccessoryDialog(List<String> currentAccessories) {
    _customController.clear();
    final availablePresets = TrainingState.officialCalisthenicsAccessories
        .where((preset) => !currentAccessories.contains(preset))
        .toList();

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add Optional Calisthenics Accessory'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (availablePresets.isNotEmpty) ...[
                  const Text(
                    'Suggested Accessories:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: availablePresets.map((preset) {
                      return ActionChip(
                        avatar: const Icon(Icons.add, size: 16),
                        label: Text(preset),
                        onPressed: () {
                          trainingState.addCalisthenicsAccessory(
                              widget.method, preset);
                          Navigator.of(ctx).pop();
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                ],
                const Text(
                  'Or enter custom accessory:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _customController,
                  decoration: const InputDecoration(
                    labelText: 'Accessory Name (e.g. Planks)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  textCapitalization: TextCapitalization.words,
                  onSubmitted: (val) {
                    final trimmed = val.trim();
                    if (trimmed.isNotEmpty) {
                      trainingState.addCalisthenicsAccessory(
                          widget.method, trimmed);
                      Navigator.of(ctx).pop();
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final trimmed = _customController.text.trim();
                if (trimmed.isNotEmpty) {
                  trainingState.addCalisthenicsAccessory(
                      widget.method, trimmed);
                  Navigator.of(ctx).pop();
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: trainingState,
      builder: (context, _) {
        final accessories =
            trainingState.getCalisthenicsAccessories(widget.method);
        final isCustomized =
            trainingState.isCalisthenicsMethodCustomized(widget.method);

        return Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Optional Accessories',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${accessories.length} configured for ${TrainingState.methodLabel(widget.method)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.mutedText(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Add Accessory',
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () => _showAddAccessoryDialog(accessories),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (accessories.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: TextButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Add Optional Accessory'),
                        onPressed: () => _showAddAccessoryDialog(accessories),
                      ),
                    ),
                  )
                else
                  ...List.generate(accessories.length, (index) {
                    final item = accessories[index];
                    final isDone = widget.completedAccessories.contains(item);

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: isDone
                          ? Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              .withAlpha(100)
                          : Theme.of(context).cardColor,
                      child: ListTile(
                        dense: true,
                        onTap: widget.showCompletion
                            ? () {
                                final updated = Set<String>.from(
                                    widget.completedAccessories);
                                if (isDone) {
                                  updated.remove(item);
                                } else {
                                  updated.add(item);
                                }
                                widget.onCompletedChanged(updated);
                              }
                            : null,
                        leading: widget.showCompletion
                            ? Checkbox(
                                value: isDone,
                                onChanged: (val) {
                                  final updated = Set<String>.from(
                                      widget.completedAccessories);
                                  if (val == true) {
                                    updated.add(item);
                                  } else {
                                    updated.remove(item);
                                  }
                                  widget.onCompletedChanged(updated);
                                },
                              )
                            : null,
                        title: Text(
                          item,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            decoration:
                                isDone ? TextDecoration.lineThrough : null,
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
                                  trainingState.reorderCalisthenicsAccessories(
                                    widget.method,
                                    index,
                                    index - 1,
                                  );
                                },
                              ),
                            if (index < accessories.length - 1)
                              IconButton(
                                icon:
                                    const Icon(Icons.arrow_downward, size: 18),
                                tooltip: 'Move Down',
                                onPressed: () {
                                  trainingState.reorderCalisthenicsAccessories(
                                    widget.method,
                                    index,
                                    index + 1,
                                  );
                                },
                              ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18),
                              tooltip: 'Remove',
                              onPressed: () {
                                final updated = Set<String>.from(
                                    widget.completedAccessories)
                                  ..remove(item);
                                widget.onCompletedChanged(updated);
                                trainingState.removeCalisthenicsAccessory(
                                    widget.method, index);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                if (isCustomized) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        trainingState.resetCalisthenicsAccessoriesToDefault(
                            widget.method);
                      },
                      child: const Text('Reset to Default Accessories',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
