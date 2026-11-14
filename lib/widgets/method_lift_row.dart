import 'package:flutter/material.dart';
import 'package:greyskull_lp/themes/theme.dart';

/// Shared progress + log rows for the calisthenics methods (issue #111).
///
/// Push-ups, chin-ups and every accessory configured in Settings use the same
/// layout: a progress bar with the day's total, then a counter row with the
/// name, unit, minus, value and plus.
class MethodLiftProgressRow extends StatelessWidget {
  const MethodLiftProgressRow({
    super.key,
    required this.label,
    required this.current,
    required this.target,
    required this.unit,
    this.color,
  });

  final String label;
  final int current;
  final int target;

  /// `reps` or `s` (plank-style holds).
  final String unit;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    final percent = (progress * 100).toInt();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 13),
                ),
              ),
              Text('$current / $target $unit ($percent%)',
                  style: const TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppTheme.subtleFill(context),
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? Theme.of(context).colorScheme.secondary,
            ),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}

class MethodLiftCounterRow extends StatelessWidget {
  const MethodLiftCounterRow({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.onChanged,
    this.step = 1,
    this.max = 100000,
  });

  final String label;
  final int value;
  final String unit;
  final ValueChanged<int> onChanged;
  final int step;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text('$label: $value $unit',
              style: const TextStyle(fontSize: 15)),
        ),
        IconButton(
          tooltip: 'Decrease $label',
          onPressed: () => onChanged((value - step).clamp(0, max)),
          icon: const Icon(Icons.remove_circle_outline),
        ),
        SizedBox(
          width: 42,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          tooltip: 'Increase $label',
          onPressed: () => onChanged((value + step).clamp(0, max)),
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }
}
