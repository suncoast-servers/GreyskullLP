import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greyskull_lp/services/timer_cue_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bell cue asset is bundled and non-empty (#86)', () async {
    final data = await rootBundle.load('assets/${TimerCueService.bell}');
    expect(data.lengthInBytes, greaterThan(1000));
  });

  test('every cue asset resolves', () async {
    for (final asset in [
      TimerCueService.bell,
      TimerCueService.countdownTick,
      TimerCueService.workStart,
      TimerCueService.restStart,
    ]) {
      final data = await rootBundle.load('assets/$asset');
      expect(data.lengthInBytes, greaterThan(500), reason: asset);
    }
  });
}
