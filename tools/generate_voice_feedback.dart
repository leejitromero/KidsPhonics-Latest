// Historical generator, retained for provenance only. See tools/README.md.
// Not part of the current validation or asset-replacement workflow.
// generate_voice_feedback.dart
// Generates voice feedback MP3s for Kidsphonics.
// Run: dart run tools/generate_voice_feedback.dart

import 'dart:io';
import 'package:http/http.dart' as http;

const _base = 'assets/audio/phonics/voice_feedback';

Uri _ttsUrl(String text, {bool slow = false}) {
  return Uri.https('translate.google.com', '/translate_tts', {
    'ie': 'UTF-8',
    'q': text,
    'tl': 'en',
    'ttsspeed': slow ? '0.5' : '0.9',
    'client': 'tw-ob',
  });
}

int _generated = 0;
late http.Client _client;

Future<void> make(String filename, String text, {bool slow = false}) async {
  final file = File('$_base/$filename');
  if (file.existsSync() && file.lengthSync() > 0) {
    stdout.writeln('  skip  $filename');
    return;
  }
  try {
    final res = await _client.get(_ttsUrl(text, slow: slow), headers: {
      'User-Agent': 'Mozilla/5.0',
      'Referer': 'https://translate.google.com/',
    });
    if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
      file.writeAsBytesSync(res.bodyBytes);
      stdout.writeln('  ✓  $filename  (${res.bodyBytes.length ~/ 1024} KB)');
      _generated++;
    } else {
      stdout.writeln('  ✗  $filename  HTTP ${res.statusCode}');
    }
    await Future.delayed(const Duration(milliseconds: 300));
  } catch (e) {
    stdout.writeln('  ✗  $filename  $e');
  }
}

Future<void> main() async {
  _client = http.Client();
  Directory(_base).createSync(recursive: true);
  stdout.writeln('\n🎙️ Generating Voice Feedback Audio\n');

  // ── PRAISE — varied so it doesn't feel repetitive ──────────────────────
  stdout.writeln('── Praise ──');
  await make('praise_1.mp3', 'Amazing! You got it right!');
  await make('praise_2.mp3', 'Fantastic! Keep it up!');
  await make('praise_3.mp3', 'You are so smart! Great job!');
  await make('praise_4.mp3', 'Wonderful! That is correct!');
  await make('praise_5.mp3', 'Yes! You did it! Awesome!');
  await make('praise_6.mp3', 'Super! You are a star!');
  await make('praise_7.mp3', 'Excellent work! Keep going!');
  await make('praise_8.mp3', 'Woohoo! That is right!');

  // ── WRONG — encouraging, not discouraging ──────────────────────────────
  stdout.writeln('\n── Wrong / Try Again ──');
  await make('wrong_1.mp3', 'Oops! Not quite. Try again!');
  await make('wrong_2.mp3', 'Good try! Listen carefully and try again!');
  await make('wrong_3.mp3', 'Almost! You can do it! Try one more time!');
  await make('wrong_4.mp3', 'That is okay! Let us try again!');
  await make('wrong_5.mp3', 'Keep trying! You are doing great!');

  // ── WIN / COMPLETION ───────────────────────────────────────────────────
  stdout.writeln('\n── Win / Completion ──');
  await make('win_perfect.mp3', 'Perfect score! You are incredible!');
  await make('win_great.mp3', 'Great job! You finished the game!');
  await make('win_good.mp3', 'Good work! Practice makes perfect!');
  await make('win_sound_match.mp3', 'You matched all the sounds! Amazing!');
  await make('win_memory.mp3', 'All pairs found! Your memory is great!');
  await make('win_quiz.mp3', 'Quiz complete! You are a phonics star!');
  await make('win_word_builder.mp3', 'All words spelled! You are brilliant!');
  await make('win_alphabet.mp3', 'Alphabet Master! You know all the letters!');
  await make('win_rhyming.mp3', 'Rhyming champion! You found all the rhymes!');
  await make('win_voice.mp3', 'Great pronunciation! You said it perfectly!');

  // ── GAME INTRO / MOTIVATIONAL ─────────────────────────────────────────
  stdout.writeln('\n── Game Intros ──');
  await make(
      'intro_sound_match.mp3', 'Let us play Sound Match! Listen carefully!',
      slow: false);
  await make('intro_memory.mp3', 'Memory Flip time! Find the matching pairs!',
      slow: false);
  await make('intro_quiz.mp3', 'Phonics Quiz! Name the sound you hear!',
      slow: false);
  await make(
      'intro_word_builder.mp3', 'Word Builder! Spell the missing letter!',
      slow: false);
  await make('intro_alphabet.mp3', 'Alphabet Order! Put the letters in order!',
      slow: false);
  await make('intro_rhyming.mp3', 'Rhyming Words! Find the word that rhymes!',
      slow: false);
  await make('intro_voice.mp3', 'Say It Right! Speak the word clearly!',
      slow: false);

  // ── MILESTONE / ACHIEVEMENT ───────────────────────────────────────────
  stdout.writeln('\n── Milestones ──');
  await make('level_up.mp3', 'Level up! You are getting better and better!');
  await make(
      'achievement_first.mp3', 'You learned your first letter! Great start!');
  await make('achievement_5.mp3', 'Five letters learned! You are on fire!');
  await make('achievement_13.mp3', 'Halfway there! Thirteen letters learned!');
  await make(
      'achievement_26.mp3', 'Alphabet Master! All twenty six letters learned!');
  await make(
      'achievement_xp.mp3', 'One hundred XP earned! You are an XP hunter!');
  await make(
      'achievement_streak.mp3', 'Three day streak! Keep coming back to learn!');

  // ── SPECIFIC WRONG ANSWER EXPLANATIONS ────────────────────────────────
  stdout.writeln('\n── Wrong Answer Explanations ──');
  // Sound Match
  await make('wrong_sound_match.mp3',
      'Listen again! The word starts with a different sound!',
      slow: true);
  // Phonics Quiz
  await make(
      'wrong_quiz.mp3', 'Not quite! Think about the first sound of the word!',
      slow: true);
  // Word Builder
  await make('wrong_word.mp3', 'Try again! Think about what letter is missing!',
      slow: true);
  // Memory Flip
  await make(
      'wrong_memory.mp3', 'Not a match! Try to remember where the letters are!',
      slow: true);
  // Alphabet Order
  await make('wrong_alphabet.mp3',
      'Not the right order! Think about which letter comes next!',
      slow: true);
  // Rhyming
  await make('wrong_rhyming.mp3',
      'That does not rhyme! Listen for the same ending sound!',
      slow: true);

  _client.close();
  stdout.writeln('\n══════════════════════════════');
  stdout.writeln('✅  Generated: $_generated files');
  stdout.writeln('══════════════════════════════\n');
}
