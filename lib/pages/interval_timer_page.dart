import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/themes/theme.dart';

/// Interval / METCON timer (issue #75).
///
/// Clean-room implementation: platform sounds and haptics only, no third-party
/// audio or artwork.
class IntervalTimerPage extends StatefulWidget {
  const IntervalTimerPage({super.key});

  @override
  State<IntervalTimerPage> createState() => _IntervalTimerPageState();
}

enum _Phase { idle, prep, work, rest, done }

class _IntervalTimerPageState extends State<IntervalTimerPage> {
  int _workSeconds = 40;
  int _restSeconds = 20;
  int _rounds = 8;
  int _prepSeconds = 5;

  _Phase _phase = _Phase.idle;
  int _remaining = 0;
  int _round = 0;
  bool _paused = false;
  Timer? _ticker;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _start() {
    _ticker?.cancel();
    setState(() {
      _phase = _Phase.prep;
      _remaining = _prepSeconds;
      _round = 1;
      _paused = false;
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _stop() {
    _ticker?.cancel();
    setState(() {
      _phase = _Phase.idle;
      _remaining = 0;
      _round = 0;
      _paused = false;
    });
  }

  void _togglePause() {
    if (_phase == _Phase.idle || _phase == _Phase.done) return;
    setState(() => _paused = !_paused);
  }

  void _tick() {
    if (_paused) return;
    if (!mounted) return;

    setState(() {
      _remaining -= 1;
      if (_remaining <= 0) {
        _advancePhase();
      } else if (_phase == _Phase.work && _remaining <= 3) {
        _cue();
      }
    });
  }

  void _advancePhase() {
    switch (_phase) {
      case _Phase.prep:
        _phase = _Phase.work;
        _remaining = _workSeconds;
        break;
      case _Phase.work:
        if (_round >= _rounds) {
          _finish();
          return;
        }
        _phase = _Phase.rest;
        _remaining = _restSeconds;
        break;
      case _Phase.rest:
        _round += 1;
        _phase = _Phase.work;
        _remaining = _workSeconds;
        break;
      case _Phase.idle:
      case _Phase.done:
        return;
    }
    _cue();
  }

  void _finish() {
    _ticker?.cancel();
    _phase = _Phase.done;
    _remaining = 0;
    _cue();
  }

  void _cue() {
    if (!trainingState.restTimerSoundEnabled) return;
    SystemSound.play(SystemSoundType.alert);
    HapticFeedback.heavyImpact();
  }

  String get _clock {
    final minutes = _remaining ~/ 60;
    final seconds = _remaining % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String get _phaseLabel => switch (_phase) {
        _Phase.idle => 'Ready',
        _Phase.prep => 'Get ready',
        _Phase.work => 'Work',
        _Phase.rest => 'Rest',
        _Phase.done => 'Complete',
      };

  Color _phaseColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return switch (_phase) {
      _Phase.work => AppTheme.calisthenicsAccent(context),
      _Phase.rest => AppTheme.positiveAccent(context),
      _Phase.done => scheme.secondary,
      _ => scheme.onSurfaceVariant,
    };
  }

  Widget _presetRow(
    String label,
    int value,
    List<int> options,
    ValueChanged<int> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          DropdownButton<int>(
            value: value,
            items: options
                .map(
                    (v) => DropdownMenuItem<int>(value: v, child: Text('$v s')))
                .toList(),
            onChanged: _phase == _Phase.idle
                ? (v) {
                    if (v != null) onChanged(v);
                  }
                : null,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final running = _phase != _Phase.idle && _phase != _Phase.done;
    final progress = switch (_phase) {
      _Phase.work => _workSeconds == 0 ? 0.0 : _remaining / _workSeconds,
      _Phase.rest => _restSeconds == 0 ? 0.0 : _remaining / _restSeconds,
      _Phase.prep => _prepSeconds == 0 ? 0.0 : _remaining / _prepSeconds,
      _ => 0.0,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Interval Timer')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    _phaseLabel,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _phaseColor(context),
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _phase == _Phase.idle
                        ? '$_workSeconds / $_restSeconds'
                        : _clock,
                    style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: _phase == _Phase.idle
                          ? scheme.onSurface
                          : _phaseColor(context),
                    ),
                  ),
                  Text(
                    _phase == _Phase.idle
                        ? 'work / rest'
                        : 'Round $_round of $_rounds',
                    style:
                        TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: scheme.onSurface.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation(_phaseColor(context)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!running)
                        ElevatedButton.icon(
                          onPressed: _start,
                          icon: const Icon(Icons.play_arrow),
                          label:
                              Text(_phase == _Phase.done ? 'Restart' : 'Start'),
                        )
                      else ...[
                        OutlinedButton.icon(
                          onPressed: _togglePause,
                          icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
                          label: Text(_paused ? 'Resume' : 'Pause'),
                        ),
                        const SizedBox(width: 12),
                        TextButton.icon(
                          onPressed: _stop,
                          icon: const Icon(Icons.stop),
                          label: const Text('Stop'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Presets',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  _presetRow('Work', _workSeconds, const [20, 30, 40, 45, 60],
                      (v) {
                    setState(() => _workSeconds = v);
                  }),
                  _presetRow('Rest', _restSeconds, const [10, 15, 20, 30, 60],
                      (v) {
                    setState(() => _restSeconds = v);
                  }),
                  _presetRow('Rounds', _rounds, const [4, 6, 8, 10, 12], (v) {
                    setState(() => _rounds = v);
                  }),
                  _presetRow('Prep', _prepSeconds, const [3, 5, 10], (v) {
                    setState(() => _prepSeconds = v);
                  }),
                  const SizedBox(height: 4),
                  Text(
                    'Cues follow Settings → Workout Timing (sound & vibration).',
                    style:
                        TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
