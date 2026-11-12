import 'package:audioplayers/audioplayers.dart';
import 'package:greyskull_lp/models/training_state.dart';

/// Original workout cue sounds (issue #75).
///
/// The tones in `assets/sounds/` were generated for this project; nothing is
/// copied from any third-party app. Playback always respects the
/// Workout Timing sound toggle.
class TimerCueService {
  TimerCueService._();

  static final TimerCueService instance = TimerCueService._();

  static const String restEnd = 'sounds/rest_end.wav';
  static const String countdownTick = 'sounds/countdown_tick.wav';
  static const String workStart = 'sounds/work_start.wav';
  static const String restStart = 'sounds/rest_start.wav';

  /// Set to false in tests or when the user disables cues.
  static bool muted = false;

  final AudioPlayer _player = AudioPlayer();

  Future<void> play(String asset) async {
    if (muted || !trainingState.restTimerSoundEnabled) return;
    try {
      await _player.stop();
      await _player.play(AssetSource(asset));
    } catch (_) {
      // Audio is best-effort; never break a workout because a cue failed.
    }
  }

  Future<void> restFinished() => play(restEnd);

  Future<void> countdownTickCue() => play(countdownTick);

  Future<void> phaseChanged({required bool working}) =>
      play(working ? workStart : restStart);
}
