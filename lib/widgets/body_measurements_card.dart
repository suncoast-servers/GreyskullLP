import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:greyskull_lp/models/body_measurement.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/widgets/body_measurement_sheet.dart';

/// Compact "Body Measurements" card for the Diet tab (#57).
class BodyMeasurementsCard extends StatelessWidget {
  const BodyMeasurementsCard({super.key});

  String _value(double? value, String unit) =>
      value == null ? '—' : '${value.toStringAsFixed(1)} $unit';

  String _tape(double? cm) {
    if (cm == null) return '—';
    final value = trainingState.tapeFromCm(cm);
    final unit = trainingState.tapeMeasurementsInInches ? 'in' : 'cm';
    return '${value.toStringAsFixed(1)} $unit';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: trainingState,
      builder: (context, _) {
        final entries = trainingState.bodyMeasurements.take(3).toList();
        final latest = trainingState.latestBodyMeasurement;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Body Measurements',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    TextButton.icon(
                      // Always a new entry; editing happens from the row pencil.
                      onPressed: () => showBodyMeasurementSheet(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(latest == null ? 'Log' : 'Add'),
                    ),
                  ],
                ),
                if (latest == null)
                  Text(
                    'Optional: track bodyweight, body fat and tape measurements.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  )
                else ...[
                  Wrap(
                    spacing: 14,
                    runSpacing: 6,
                    children: [
                      _metric('Weight', _value(latest.weightKg, 'kg')),
                      _metric('Body fat', _value(latest.bodyFatPct, '%')),
                      _metric('Waist', _tape(latest.waistCm)),
                      _metric('Chest', _tape(latest.chestCm)),
                      _metric('Arms', _tape(latest.armsCm)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...entries.map(
                    (entry) => _MeasurementRow(entry: entry),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _metric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
        Text(value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _MeasurementRow extends StatelessWidget {
  const _MeasurementRow({required this.entry});

  final BodyMeasurement entry;

  String _summary() {
    final parts = <String>[];
    if (entry.weightKg != null) {
      parts.add('${entry.weightKg!.toStringAsFixed(1)} kg');
    }
    if (entry.bodyFatPct != null) {
      parts.add('${entry.bodyFatPct!.toStringAsFixed(1)}%');
    }
    final unit = trainingState.tapeMeasurementsInInches ? 'in' : 'cm';
    if (entry.waistCm != null) {
      parts.add(
          'waist ${trainingState.tapeFromCm(entry.waistCm!).toStringAsFixed(1)} $unit');
    }
    if (entry.chestCm != null) {
      parts.add(
          'chest ${trainingState.tapeFromCm(entry.chestCm!).toStringAsFixed(1)} $unit');
    }
    if (entry.armsCm != null) {
      parts.add(
          'arms ${trainingState.tapeFromCm(entry.armsCm!).toStringAsFixed(1)} $unit');
    }
    return parts.isEmpty ? entry.notes : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final date =
        '${entry.date.year}-${entry.date.month.toString().padLeft(2, '0')}-${entry.date.day.toString().padLeft(2, '0')}';
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: entry.photoBase64 == null
          ? null
          : ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.memory(
                base64Decode(entry.photoBase64!),
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
      title: Text(date, style: const TextStyle(fontSize: 12)),
      subtitle: Text(_summary(), style: const TextStyle(fontSize: 11)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Edit measurement',
            icon: const Icon(Icons.edit_outlined, size: 18),
            onPressed: () => showBodyMeasurementSheet(context, existing: entry),
          ),
          IconButton(
            tooltip: 'Delete measurement',
            icon: Icon(Icons.delete_outline,
                size: 18, color: Theme.of(context).colorScheme.error),
            onPressed: () => trainingState.deleteBodyMeasurement(entry.id),
          ),
        ],
      ),
    );
  }
}
