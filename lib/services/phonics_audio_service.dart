import '../data/game_word_data.dart';
import 'local_audio_focus.dart';
import '../data/lesson_example_data.dart';
import 'background_music_service.dart';
// Local recordings only. No TTS fallback. Retired mappings are documented in
// AUDIO_REPLACEMENT_AUDIT.md; current lesson replacements are in LESSON_ASSETS.md.

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

class PhonicsAudioService {
  static PhonicsAudioService _instance = PhonicsAudioService._internal();
  factory PhonicsAudioService() => _instance._disposed
      ? _instance = PhonicsAudioService._internal()
      : _instance;
  PhonicsAudioService._internal();

  // Main player for game speech feedback
  final AudioPlayer _player = AudioPlayer();

  // ── phrase → filename map ─────────────────────────────────────────────
  // Keys are the exact strings passed to speak() in letter_data.dart and
  // game screens.  Values are paths under assets/audio/phonics/.
  static const Map<String, String> _phraseMap = {
    'Big': 'rhyming_words/word_big.mp3',
    'Mat': 'rhyming_words/word_mat.mp3',
    'Mug': 'rhyming_words/word_mug.mp3',
    'Log': 'rhyming_words/word_log.mp3',
    'Car': 'rhyming_words/word_car.mp3',
    'Lake': 'rhyming_words/word_lake.mp3',
    'Mouse': 'rhyming_words/word_mouse.mp3',
    'Box': 'rhyming_words/word_box.mp3',
    'Ape': 'word_builder/word_ape.mp3',
    'Balloon': 'rhyming_words/word_balloon.mp3',
    'Ball': 'rhyming_words/word_ball.mp3',
    'Banana': 'say_it_right/word_banana.mp3',
    'Bat': 'rhyming_words/word_bat.mp3',
    'Bee': 'say_it_right/word_bee.mp3',
    'Bug': 'rhyming_words/word_bug.mp3',
    'Cake': 'rhyming_words/word_cake.mp3',
    'Cat': 'say_it_right/word_cat.mp3',
    'Cub': 'say_it_right/word_cub.mp3',
    'Egg': 'say_it_right/word_egg.mp3',
    'Fin': 'word_builder/word_fin.mp3',
    'Fish': 'say_it_right/word_fish.mp3',
    'Fox': 'rhyming_words/word_fox.mp3',
    'Hat': 'rhyming_words/word_hat.mp3',
    'Hog': 'say_it_right/word_hog.mp3',
    'Juice': 'say_it_right/word_juice.mp3',
    'Kite': 'say_it_right/word_kite.mp3',
    'Lion': 'say_it_right/word_lion.mp3',
    'Lip': 'word_builder/word_lip.mp3',
    'Mop': 'word_builder/word_mop.mp3',
    'Nut': 'say_it_right/word_nut.mp3',
    'Oak': 'say_it_right/word_oak.mp3',
    'Pig': 'say_it_right/word_pig.mp3',
    'Rain': 'say_it_right/word_rain.mp3',
    'Rainbow': 'say_it_right/word_rainbow.mp3',
    'Rat': 'word_builder/word_rat.mp3',
    'Snake': 'rhyming_words/word_snake.mp3',
    'Sun': 'say_it_right/word_sun.mp3',
    'Tree': 'rhyming_words/word_tree.mp3',
    'Turtle': 'say_it_right/word_turtle.mp3',
    'Zebra': 'say_it_right/word_zebra.mp3',
  };

  static String? assetForPhrase(String phrase) {
    if (RegExp(r'^[A-Z]$').hasMatch(phrase)) {
      return 'audio/phonics/lesson_audio/letters/letter-${phrase.toLowerCase()}.mp3';
    }
    final supplied = gameWordFor(phrase.trim());
    if (supplied != null) return supplied.audioAsset;
    final lesson =
        RegExp(r'^lesson-(letter|word|sound)-([A-Z])$').firstMatch(phrase);
    if (lesson != null) {
      final type = lesson.group(1)!;
      final letter = lesson.group(2)!.toLowerCase();
      if (type == 'word') {
        final replacement = gameWordFor(lessonExamples
            .firstWhere((e) => e.letter == letter.toUpperCase())
            .word);
        if (replacement != null) return replacement.audioAsset;
      }
      final name = type == 'word'
          ? lessonExamples
              .firstWhere((e) => e.letter == letter.toUpperCase())
              .slug
          : letter;
      return 'audio/phonics/lesson_audio/${type}s/$type-$name.mp3';
    }
    final filename = _phraseMap[phrase.trim()];
    return filename == null ? null : 'audio/phonics/$filename';
  }

  bool _disposed = false;
  int _request = 0;
  Completer<bool>? _completion;
  Future<void> stop() async {
    _request++;
    final completion = _completion;
    _completion = null;
    if (completion != null && !completion.isCompleted) {
      completion.complete(false);
    }
    try {
      if (!_disposed) await _player.stop();
    } catch (_) {}
  }

  /// One instructional channel, with latest-request-wins cancellation.
  /// Returns true only on real completion; never falls back to TTS.
  Future<bool> playInstruction(String phrase) async {
    if (_disposed) return false;
    final focus = LocalAudioFocus.claim();
    final request = _request + 1;
    await stop();
    if (_disposed || request != _request) return false;
    final asset = assetForPhrase(phrase);
    if (asset == null) return false;
    final completed = Completer<bool>();
    _completion = completed;
    final subscription = _player.onPlayerComplete.listen((_) {
      if (request == _request && !completed.isCompleted) {
        completed.complete(true);
      }
    }, onError: (Object _) {
      if (!completed.isCompleted) completed.complete(false);
    });
    try {
      await rootBundle.load('assets/$asset');
      if (request != _request ||
          !LocalAudioFocus.isCurrent(focus) ||
          completed.isCompleted) {
        return false;
      }
      await BackgroundMusicService.instance.playForeground(
          _player, AssetSource(asset),
          isCurrent: () =>
              !_disposed &&
              request == _request &&
              LocalAudioFocus.isCurrent(focus));
      if (_disposed || request != _request) return false;
      return await completed.future
          .timeout(const Duration(seconds: 30), onTimeout: () => false);
    } catch (_) {
      return false;
    } finally {
      await subscription.cancel();
      if (request == _request) await stop();
    }
  }

  Future<void> tryPlay(String phrase) async {
    await playInstruction(phrase);
  }

  Future<void> tryPlayHint(String phrase) async {
    await playInstruction(phrase);
  }

  void dispose() {
    if (_disposed) return;
    stop();
    _disposed = true;
    BackgroundMusicService.instance.forget(_player);
    _player.dispose();
  }
}
