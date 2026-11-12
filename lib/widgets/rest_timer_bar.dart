import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:greyskull_lp/models/training_state.dart';

/// Rest countdown shown between sets (#75).
///
/// Clean-room implementation: system alert sound + haptics only, no bundled
/// third-party audio or artwork.
class RestTimerBar extends StatefulWidget {
  const RestTimerBar({
    super.key,
    required this.seconds,
    required this.soundEnabled,
    this.onDismissed,
  });

  final int seconds;
  final bool soundEnabled;
  final VoidCallback? onDismissed;

  @override
  State<RestTimerBar> createState() => _RestTimerBarState();
}

class _RestTimerBarState extends State<RestTimerBar> {
  Timer? _ticker;
  late int _remaining;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _remaining = widget.seconds;
    _start();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _start() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _remaining -= 1;
        if (_remaining <= 0) {
          _remaining = 0;
          _finished = true;
          _ticker?.cancel();
        }
      });
      if (_finished) _fireCue();
    });
  }

  void _fireCue() {
    if (!widget.soundEnabled) return;
    // Platform sounds/haptics only; nothing is bundled with the app.
    SystemSound.play(SystemSoundType.alert);
    HapticFeedback.heavyImpact();
  }

  void _adjust(int delta) {
    setState(() {
      _remaining = (_remaining + delta).clamp(0, 900);
      _finished = _remaining == 0;
    });
    if (_finished) _fireCue();
  }

  void _skip() {
    _ticker?.cancel();
    widget.onDismissed?.call();
  }

  String get _label {
    final minutes = _remaining ~/ 60;
    final seconds = _remaining % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = widget.seconds == 0 ? 0.0 : _remaining / widget.seconds;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: scheme.primary.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_finished ? Icons.notifications_active : Icons.timer,
                    size: 20,
                    color:
                        _finished ? scheme.secondary : scheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  _finished ? 'Rest complete — next set' : 'Rest',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const Spacer(),
                Text(
                  _label,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: _finished ? scheme.secondary : scheme.onSurface,
                  ),
                ),
                IconButton(
                  tooltip: 'Skip rest',
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: _skip,
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: scheme.onSurface.withValues(alpha: 0.12),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                TextButton(
                  onPressed: () => _adjust(-15),
                  child: const Text('-15 s'),
                ),
                TextButton(
                  onPressed: () => _adjust(15),
                  child: const Text('+15 s'),
                ),
                const Spacer(),
                Text(
                  TrainingState.restTimerPresets.contains(widget.seconds)
                      ? 'Default ${widget.seconds}s'
                      : '${widget.seconds}s rest',
                  style:
                      TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
