import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:greyskull_lp/models/body_measurement.dart';
import 'package:greyskull_lp/models/training_state.dart';

/// Bottom sheet used to add or edit an optional body measurement (#57).
Future<void> showBodyMeasurementSheet(
  BuildContext context, {
  BodyMeasurement? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: _BodyMeasurementForm(existing: existing),
    ),
  );
}

class _BodyMeasurementForm extends StatefulWidget {
  const _BodyMeasurementForm({this.existing});

  final BodyMeasurement? existing;

  @override
  State<_BodyMeasurementForm> createState() => _BodyMeasurementFormState();
}

class _BodyMeasurementFormState extends State<_BodyMeasurementForm> {
  late final TextEditingController _weight;
  late final TextEditingController _bodyFat;
  late final TextEditingController _waist;
  late final TextEditingController _chest;
  late final TextEditingController _arms;
  late final TextEditingController _notes;
  String? _photoBase64;

  @override
  void initState() {
    super.initState();
    final before = widget.existing;
    String value(double? v) => v == null ? '' : v.toString();
    String tape(double? cm) =>
        cm == null ? '' : trainingState.tapeFromCm(cm).toStringAsFixed(1);
    _weight = TextEditingController(text: value(before?.weightKg));
    _bodyFat = TextEditingController(text: value(before?.bodyFatPct));
    _waist = TextEditingController(text: tape(before?.waistCm));
    _chest = TextEditingController(text: tape(before?.chestCm));
    _arms = TextEditingController(text: tape(before?.armsCm));
    _notes = TextEditingController(text: before?.notes ?? '');
    _photoBase64 = before?.photoBase64;
  }

  @override
  void dispose() {
    _weight.dispose();
    _bodyFat.dispose();
    _waist.dispose();
    _chest.dispose();
    _arms.dispose();
    _notes.dispose();
    super.dispose();
  }

  double? _parse(TextEditingController controller) =>
      double.tryParse(controller.text.trim().replaceAll(',', '.'));

  double? _toCm(double? value) =>
      value == null ? null : trainingState.tapeToCm(value);

  Future<void> _pickPhoto() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 640,
        imageQuality: 60,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (bytes.lengthInBytes > 500 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Photo is too large; pick a smaller image.')),
        );
        return;
      }
      if (!mounted) return;
      setState(() => _photoBase64 = base64Encode(bytes));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read that photo.')),
      );
    }
  }

  void _save() {
    final measurement = (widget.existing ?? BodyMeasurement()).copyWith(
      weightKg: _parse(_weight),
      bodyFatPct: _parse(_bodyFat),
      waistCm: _toCm(_parse(_waist)),
      chestCm: _toCm(_parse(_chest)),
      armsCm: _toCm(_parse(_arms)),
      notes: _notes.text.trim(),
      photoBase64: _photoBase64,
    );

    if (!measurement.hasAnyValue) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter at least one measurement before saving.'),
        ),
      );
      return;
    }

    trainingState.upsertBodyMeasurement(measurement);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Measurement saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.existing == null
                  ? 'Log Body Measurement'
                  : 'Edit Body Measurement',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'All fields are optional. Log whatever you track.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('cm')),
                ButtonSegment(value: true, label: Text('in')),
              ],
              selected: {trainingState.tapeMeasurementsInInches},
              onSelectionChanged: (selection) {
                setState(() {
                  trainingState.setTapeMeasurementsInInches(selection.first);
                });
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _numberField(_weight, 'Bodyweight (kg)'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _numberField(_bodyFat, 'Body fat (%)'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _numberField(_waist, _tapeLabel('Waist'))),
                const SizedBox(width: 10),
                Expanded(child: _numberField(_chest, _tapeLabel('Chest'))),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _numberField(_arms, _tapeLabel('Arms'))),
                const SizedBox(width: 10),
                const Expanded(child: SizedBox()),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _notes,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Notes (optional)',
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (_photoBase64 != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        base64Decode(_photoBase64!),
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickPhoto,
                    icon: const Icon(Icons.photo_camera_outlined, size: 18),
                    label: Text(_photoBase64 == null
                        ? 'Add progress photo (optional)'
                        : 'Replace photo'),
                  ),
                ),
                if (_photoBase64 != null)
                  IconButton(
                    tooltip: 'Remove photo',
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() => _photoBase64 = null),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('Save Measurement'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _tapeLabel(String part) =>
      trainingState.tapeMeasurementsInInches ? '$part (in)' : '$part (cm)';

  Widget _numberField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: label,
        isDense: true,
      ),
    );
  }
}
