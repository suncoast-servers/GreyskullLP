import 'package:flutter/material.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/themes/theme.dart';

/// Inline accessory logger for the calisthenics methods (issue #84).
///
/// Configuration lives in Settings; this only marks today's accessories as
/// done, using the same visual language on every method page.
class AccessoryChecklist extends StatelessWidget {
  const AccessoryChecklist({
    super.key,
    required this.method,
    required this.completed,
    required this.onChanged,
  });

  final DailyMethod method;
  final Set<String> completed;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    final accessories = trainingState.getCalisthenicsAccessories(method);
    if (accessories.isEmpty) {
      return Text(
        'No accessories configured. Add them in Settings → Calisthenics Accessories.',
        style: TextStyle(fontSize: 12, color: AppTheme.mutedText(context)),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: accessories.map((name) {
        final done = completed.contains(name);
        return FilterChip(
          selected: done,
          showCheckmark: true,
          avatar: Icon(
            done ? Icons.check_circle : Icons.add_circle_outline,
            size: 18,
            color: done
                ? AppTheme.positiveAccent(context)
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          label: Text(name),
          onSelected: (selected) {
            final updated = Set<String>.from(completed);
            if (selected) {
              updated.add(name);
            } else {
              updated.remove(name);
            }
            onChanged(updated);
          },
        );
      }).toList(),
    );
  }
}
