import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsphonics/controllers/game_narration_controller.dart';
import 'package:kidsphonics/services/phonics_audio_service.dart';

void main() {
  test('entry, resume and reset do not play generated game speech', () async {
    final played = <String>[];
    final controller = GameNarrationController(
        play: (phrase) async {
          played.add(phrase);
          return true;
        },
        stop: () async {});
    addTearDown(controller.dispose);
    controller.updateEnvironment(enabled: true, active: true);
    controller.resetRound();
    controller.updateEnvironment(enabled: true, active: false);
    controller.updateEnvironment(enabled: true, active: true);
    expect(played, isEmpty);
    for (var i = 0; i < 6; i++) {
      expect(PhonicsAudioService.assetForPhrase('game-praise-$i'), isNull);
    }
    expect(PhonicsAudioService.assetForPhrase('game-intro-flappy-letters'),
        isNull);
  });

  test('every selected phoneme and cleared letter uses its supplied recording',
      () async {
    final played = <String>[];
    final controller = GameNarrationController(
        play: (phrase) async {
          played.add(phrase);
          return true;
        },
        stop: () async {});
    addTearDown(controller.dispose);
    controller.updateEnvironment(enabled: true, active: true);
    for (var c = 65; c <= 90; c++) {
      final letter = String.fromCharCode(c);
      await controller.letterSound(letter);
      await controller.letterName(letter);
      expect(played.sublist(played.length - 2),
          ['lesson-sound-$letter', 'lesson-letter-$letter']);
      for (final phrase in played.skip(played.length - 2)) {
        final asset = PhonicsAudioService.assetForPhrase(phrase);
        expect(asset, isNotNull, reason: phrase);
        expect(File('assets/$asset').existsSync(), isTrue, reason: phrase);
      }
    }
    expect(controller.speaking, isFalse);
    expect(controller.feedback, isNull);
  });

  for (final mute in [true, false]) {
    test(
        'pending letter audio cancels on ${mute ? 'mute' : 'pause'} without replay',
        () async {
      final pending = Completer<bool>();
      final played = <String>[];
      var stopped = 0;
      final controller = GameNarrationController(play: (phrase) {
        played.add(phrase);
        return pending.future;
      }, stop: () async {
        stopped++;
      });
      addTearDown(controller.dispose);
      controller.updateEnvironment(enabled: true, active: true);
      final sound = controller.letterSound('A');
      controller.updateEnvironment(enabled: !mute, active: mute);
      pending.complete(true);
      await sound;
      await controller.letterName('B');
      expect(stopped, 1);
      expect(played, ['lesson-sound-A']);
      expect(controller.feedback, isNull);
      controller.updateEnvironment(enabled: true, active: true);
      expect(played, hasLength(1));
    });
  }

  test('unavailable letter audio does not break the game', () async {
    final controller = GameNarrationController(
        play: (_) async => throw StateError('Audio unavailable'),
        stop: () async {});
    addTearDown(controller.dispose);
    controller.updateEnvironment(enabled: true, active: true);
    await controller.letterSound('A');
    expect(controller.speaking, isFalse);
    expect(controller.audioUnavailable, isTrue);
  });
}
