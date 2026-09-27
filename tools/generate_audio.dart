// Historical generator, retained for provenance only. See tools/README.md.
// Not part of the current validation or asset-replacement workflow.
// generate_audio.dart
// ─────────────────────────────────────────────────────────────────────────
// Generates ALL phonics MP3 files organized per game/lesson folder.
// Run from project root:
//   dart run tools/generate_audio.dart
//
// Folder structure:
//   assets/audio/phonics/
//     letter_sounds/     ← Letter Sounds A-Z lesson
//     vowel_sounds/      ← Vowel Sounds lesson (A E I O U only)
//     rhyming_words/     ← Rhyming Words lesson
//     alphabet_order/    ← Alphabet Order game
//     sound_match/       ← Sound Match game
//     memory_flip/       ← Memory Flip game
//     phonics_quiz/      ← Phonics Quiz game
//     word_builder/      ← Word Builder game
//     say_it_right/      ← Say It Right game
//     feedback/          ← Shared praise/feedback phrases
// ─────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:http/http.dart' as http;

const _base = 'assets/audio/phonics';

// ── TTS URL ───────────────────────────────────────────────────────────────
Uri _ttsUrl(String text, {bool slow = false}) {
  return Uri.https('translate.google.com', '/translate_tts', {
    'ie': 'UTF-8',
    'q': text,
    'tl': 'en',
    'ttsspeed': slow ? '0.5' : '1',
    'client': 'tw-ob',
  });
}

Future<void> make(String folder, String text, String filename,
    {bool slow = true}) async {
  final dir = Directory('$_base/$folder');
  if (!dir.existsSync()) dir.createSync(recursive: true);
  final file = File('$_base/$folder/$filename');
  if (file.existsSync() && file.lengthSync() > 0) {
    stdout.writeln('  skip  $folder/$filename');
    return;
  }
  try {
    final uri = _ttsUrl(text, slow: slow);
    final response = await _client.get(uri, headers: {
      'User-Agent': 'Mozilla/5.0',
      'Referer': 'https://translate.google.com/',
    });
    if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
      file.writeAsBytesSync(response.bodyBytes);
      stdout.writeln(
          '  ✓  $folder/$filename  (${response.bodyBytes.length ~/ 1024} KB)');
      _generated++;
    } else {
      stdout.writeln('  ✗  $folder/$filename  HTTP ${response.statusCode}');
      _failed++;
    }
    await Future.delayed(const Duration(milliseconds: 280));
  } catch (e) {
    stdout.writeln('  ✗  $folder/$filename  $e');
    _failed++;
  }
}

late http.Client _client;
int _generated = 0, _failed = 0;

Future<void> main() async {
  _client = http.Client();
  stdout.writeln('\n🎵 Generating Kidsphonics audio\n');

  // ══════════════════════════════════════════════════════════════════════════
  // 1. LETTER SOUNDS A-Z
  // ══════════════════════════════════════════════════════════════════════════
  stdout.writeln('\n── Letter Sounds A-Z ──────────────────────────────');
  final letterSounds = [
    ('A', 'Apple', 'A says Ahh! Like Apple!', 'letter_a.mp3'),
    ('B', 'Banana', 'B says Buh! Like Banana!', 'letter_b.mp3'),
    ('C', 'Cat', 'C says Cuh! Like Cat!', 'letter_c.mp3'),
    ('D', 'Dog', 'D says Duh! Like Dog!', 'letter_d.mp3'),
    ('E', 'Egg', 'E says Ehh! Like Egg!', 'letter_e.mp3'),
    ('F', 'Fish', 'F says Fff! Like Fish!', 'letter_f.mp3'),
    ('G', 'Grapes', 'G says Guh! Like Grapes!', 'letter_g.mp3'),
    ('H', 'House', 'H says Hhh! Like House!', 'letter_h.mp3'),
    ('I', 'Ice Cream', 'I says Ihh! Like Ice Cream!', 'letter_i.mp3'),
    ('J', 'Juice', 'J says Juh! Like Juice!', 'letter_j.mp3'),
    ('K', 'Kite', 'K says Kuh! Like Kite!', 'letter_k.mp3'),
    ('L', 'Lion', 'L says Lll! Like Lion!', 'letter_l.mp3'),
    ('M', 'Moon', 'M says Mmm! Like Moon!', 'letter_m.mp3'),
    ('N', 'Nut', 'N says Nnn! Like Nut!', 'letter_n.mp3'),
    ('O', 'Octopus', 'O says Ohh! Like Octopus!', 'letter_o.mp3'),
    ('P', 'Pig', 'P says Puh! Like Pig!', 'letter_p.mp3'),
    ('Q', 'Queen', 'Q says Kww! Like Queen!', 'letter_q.mp3'),
    ('R', 'Rainbow', 'R says Rrr! Like Rainbow!', 'letter_r.mp3'),
    ('S', 'Sun', 'S says Sss! Like Sun!', 'letter_s.mp3'),
    ('T', 'Turtle', 'T says Tuh! Like Turtle!', 'letter_t.mp3'),
    ('U', 'Umbrella', 'U says Uhh! Like Umbrella!', 'letter_u.mp3'),
    ('V', 'Violin', 'V says Vvv! Like Violin!', 'letter_v.mp3'),
    ('W', 'Whale', 'W says Www! Like Whale!', 'letter_w.mp3'),
    ('X', 'Xylophone', 'X says Ksss! Like Xylophone!', 'letter_x.mp3'),
    ('Y', 'Yarn', 'Y says Yyy! Like Yarn!', 'letter_y.mp3'),
    ('Z', 'Zebra', 'Z says Zzz! Like Zebra!', 'letter_z.mp3'),
  ];
  for (final (_, _, phrase, file) in letterSounds) {
    await make('letter_sounds', phrase, file, slow: true);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 2. VOWEL SOUNDS (A E I O U)
  // ══════════════════════════════════════════════════════════════════════════
  stdout.writeln('\n── Vowel Sounds ────────────────────────────────────');
  await make('vowel_sounds', 'A says Ahh! Like Apple!', 'vowel_a.mp3',
      slow: true);
  await make('vowel_sounds', 'E says Ehh! Like Egg!', 'vowel_e.mp3',
      slow: true);
  await make('vowel_sounds', 'I says Ihh! Like Ice Cream!', 'vowel_i.mp3',
      slow: true);
  await make('vowel_sounds', 'O says Ohh! Like Octopus!', 'vowel_o.mp3',
      slow: true);
  await make('vowel_sounds', 'U says Uhh! Like Umbrella!', 'vowel_u.mp3',
      slow: true);
  await make('vowel_sounds', 'A, E, I, O, U. These are the vowels!',
      'vowels_intro.mp3',
      slow: false);
  await make(
      'vowel_sounds',
      'A says Ahh, like Apple! E says Ehh, like Egg! I says Ihh, like Ice Cream! O says Ohh, like Octopus! U says Uhh, like Umbrella!',
      'vowels_all.mp3',
      slow: true);

  // ══════════════════════════════════════════════════════════════════════════
  // 3. ALPHABET ORDER GAME
  // ══════════════════════════════════════════════════════════════════════════
  stdout.writeln('\n── Alphabet Order ──────────────────────────────────');
  // Letter names A-Z
  for (final letter in 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('')) {
    await make('alphabet_order', letter, 'name_${letter.toLowerCase()}.mp3',
        slow: false);
  }
  await make('alphabet_order',
      'A, B, C, D, E, F! Can you put the alphabet in order?', 'intro.mp3',
      slow: false);
  await make(
      'alphabet_order', 'Yes! That is correct! Keep going!', 'correct.mp3',
      slow: false);
  await make(
      'alphabet_order', 'Oops! Try the next letter in order!', 'wrong.mp3',
      slow: false);
  await make(
      'alphabet_order', 'Amazing! You know the whole alphabet!', 'win.mp3',
      slow: false);

  // ══════════════════════════════════════════════════════════════════════════
  // 4. SOUND MATCH GAME
  // ══════════════════════════════════════════════════════════════════════════
  stdout.writeln('\n── Sound Match ─────────────────────────────────────');
  final soundMatchHints = [
    ('Apple! Ahh... Apple!', 'hint_apple.mp3'),
    ('Banana! Buh... Banana!', 'hint_banana.mp3'),
    ('Cat! Cuh... Cat!', 'hint_cat.mp3'),
    ('Dog! Duh... Dog!', 'hint_dog.mp3'),
    ('Egg! Ehh... Egg!', 'hint_egg.mp3'),
    ('Fish! Fff... Fish!', 'hint_fish.mp3'),
    ('Grapes! Guh... Grapes!', 'hint_grapes.mp3'),
    ('House! Hhh... House!', 'hint_house.mp3'),
    ('Kite! Kuh... Kite!', 'hint_kite.mp3'),
    ('Lion! Lll... Lion!', 'hint_lion.mp3'),
    ('Moon! Mmm... Moon!', 'hint_moon.mp3'),
    ('Queen! Kww... Queen!', 'hint_queen.mp3'),
    ('Rainbow! Rrr... Rainbow!', 'hint_rainbow.mp3'),
    ('Sun! Sss... Sun!', 'hint_sun.mp3'),
    ('Umbrella! Uhh... Umbrella!', 'hint_umbrella.mp3'),
    ('Violin! Vvv... Violin!', 'hint_violin.mp3'),
    ('Whale! Www... Whale!', 'hint_whale.mp3'),
    ('Zebra! Zzz... Zebra!', 'hint_zebra.mp3'),
  ];
  for (final (phrase, file) in soundMatchHints) {
    await make('sound_match', phrase, file, slow: true);
  }
  await make('sound_match', 'What letter does it start with?', 'question.mp3',
      slow: false);
  await make('sound_match', 'Tap to hear the word!', 'tap_to_hear.mp3',
      slow: false);
  await make(
      'sound_match', 'Tap the correct starting letter!', 'tap_letter.mp3',
      slow: false);

  // ══════════════════════════════════════════════════════════════════════════
  // 5. MEMORY FLIP GAME
  // ══════════════════════════════════════════════════════════════════════════
  stdout.writeln('\n── Memory Flip ─────────────────────────────────────');
  await make('memory_flip', 'Match the letter to its picture!', 'intro.mp3',
      slow: false);
  await make('memory_flip', 'Find the letter that matches the picture!',
      'instruction.mp3',
      slow: false);
  await make('memory_flip', 'Great match!', 'match.mp3', slow: false);
  await make('memory_flip', 'All pairs found! Amazing job!', 'win.mp3',
      slow: false);
  // Letter names reused for card flips
  for (final letter in 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('')) {
    await make('memory_flip', letter, 'name_${letter.toLowerCase()}.mp3',
        slow: false);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 6. PHONICS QUIZ GAME
  // ══════════════════════════════════════════════════════════════════════════
  stdout.writeln('\n── Phonics Quiz ────────────────────────────────────');
  final quizHints = [
    ('Dog! Duh... Dog! The first sound is D!', 'quiz_dog.mp3'),
    ('Sun! Sss... Sun! The first sound is S!', 'quiz_sun.mp3'),
    ('Apple! Ahh... Apple! The first sound is A!', 'quiz_apple.mp3'),
    ('Fish! Fff... Fish! The first sound is F!', 'quiz_fish.mp3'),
    ('Rainbow! Rrr... Rainbow! The first sound is R!', 'quiz_rainbow.mp3'),
    ('Moon! Mmm... Moon! The first sound is M!', 'quiz_moon.mp3'),
    ('Kite! Kuh... Kite! The first sound is K!', 'quiz_kite.mp3'),
    ('Lion! Lll... Lion! The first sound is L!', 'quiz_lion.mp3'),
    ('Umbrella! Uhh... Umbrella! The first sound is U!', 'quiz_umbrella.mp3'),
    ('Violin! Vvv... Violin! The first sound is V!', 'quiz_violin.mp3'),
    ('Whale! Www... Whale! The first sound is W!', 'quiz_whale.mp3'),
    ('Zebra! Zzz... Zebra! The first sound is Z!', 'quiz_zebra.mp3'),
  ];
  for (final (phrase, file) in quizHints) {
    await make('phonics_quiz', phrase, file, slow: true);
  }
  await make('phonics_quiz', 'What sound does it start with?', 'question.mp3',
      slow: false);
  await make('phonics_quiz', 'Tap to listen!', 'tap_listen.mp3', slow: false);
  await make('phonics_quiz', 'Quiz done! Great work!', 'done.mp3', slow: false);

  // ══════════════════════════════════════════════════════════════════════════
  // 7. WORD BUILDER GAME
  // ══════════════════════════════════════════════════════════════════════════
  stdout.writeln('\n── Word Builder ────────────────────────────────────');
  final wordBuilderPhrases = [
    ('C... blank... T. What is in the middle?', 'hint_cat.mp3'),
    ('D... blank... G. Fill in the middle!', 'hint_dog.mp3'),
    ('S... blank... N. What letter goes here?', 'hint_sun.mp3'),
    ('blank... P... E. What is the first letter?', 'hint_ape.mp3'),
    ('F... I... blank. What is the last letter?', 'hint_fin.mp3'),
    ('R... blank... T. What is the middle?', 'hint_rat.mp3'),
    ('H... blank... T. What is the middle?', 'hint_hut.mp3'),
    ('L... I... blank. The last letter!', 'hint_lip.mp3'),
    ('blank... O... P. What letter starts it?', 'hint_mop.mp3'),
    ('Spell the word!', 'spell_word.mp3'),
    ('Tap the missing letter!', 'tap_missing.mp3'),
  ];
  for (final (phrase, file) in wordBuilderPhrases) {
    await make('word_builder', phrase, file, slow: true);
  }
  // Words used in word builder
  final wbWords = [
    'Cat',
    'Dog',
    'Sun',
    'Ape',
    'Fin',
    'Rat',
    'Hut',
    'Lip',
    'Mop'
  ];
  for (final w in wbWords) {
    await make('word_builder', w, 'word_${w.toLowerCase()}.mp3', slow: true);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 8. SAY IT RIGHT (Voice Recognition)
  // ══════════════════════════════════════════════════════════════════════════
  stdout.writeln('\n── Say It Right ────────────────────────────────────');
  final sayItRightWords = [
    // Easy
    ('Apple', 'A-pple', 'word_apple.mp3'),
    ('Ball', 'B-all', 'word_ball.mp3'),
    ('Cat', 'C-at', 'word_cat.mp3'),
    ('Dog', 'D-og', 'word_dog.mp3'),
    ('Egg', 'E-gg', 'word_egg.mp3'),
    // Medium
    ('Fish', 'F-ish', 'word_fish.mp3'),
    ('Grapes', 'Gr-apes', 'word_grapes.mp3'),
    ('House', 'H-ouse', 'word_house.mp3'),
    ('Ice Cream', 'I-ce Cream', 'word_ice_cream.mp3'),
    ('Juice', 'J-uice', 'word_juice.mp3'),
    ('Kite', 'K-ite', 'word_kite.mp3'),
    // Hard
    ('Lion', 'L-ion', 'word_lion.mp3'),
    ('Moon', 'M-oon', 'word_moon.mp3'),
    ('Rainbow', 'Rain-bow', 'word_rainbow.mp3'),
    ('Umbrella', 'Um-brel-la', 'word_umbrella.mp3'),
    ('Violin', 'Vi-o-lin', 'word_violin.mp3'),
    ('Xylophone', 'Xy-lo-phone', 'word_xylophone.mp3'),
    ('Zebra', 'Ze-bra', 'word_zebra.mp3'),
  ];
  for (final (word, hint, file) in sayItRightWords) {
    await make('say_it_right', word, file, slow: true);
    await make('say_it_right', '$word! $hint', 'hint_$file', slow: true);
  }
  await make('say_it_right', 'Tap the mic and say the word!', 'instruction.mp3',
      slow: false);
  await make('say_it_right', 'Listening... speak now!', 'listening.mp3',
      slow: false);
  await make('say_it_right', 'Great job! You said it correctly!', 'correct.mp3',
      slow: false);
  await make('say_it_right', 'Good try! Listen and try again.', 'try_again.mp3',
      slow: false);
  await make('say_it_right', 'Practice done! You did amazing!', 'done.mp3',
      slow: false);

  // ══════════════════════════════════════════════════════════════════════════
  // 9. RHYMING WORDS LESSON
  // ══════════════════════════════════════════════════════════════════════════
  stdout.writeln('\n── Rhyming Words ───────────────────────────────────');
  final rhymeHints = [
    ('Cat... Bat! Both end in A-T!', 'hint_cat_bat.mp3'),
    ('Bee... Tree! Both end in E-E!', 'hint_bee_tree.mp3'),
    ('Moon... Spoon! Both end in O-O-N!', 'hint_moon_spoon.mp3'),
    ('Pig... Big! Both end in I-G!', 'hint_pig_big.mp3'),
    ('Hat... Mat! Both end in A-T!', 'hint_hat_mat.mp3'),
    ('Bug... Mug! Both end in U-G!', 'hint_bug_mug.mp3'),
    ('Star... Car! Both end in A-R!', 'hint_star_car.mp3'),
    ('Frog... Log! Both end in O-G!', 'hint_frog_log.mp3'),
    ('House... Mouse! Both end in O-U-S-E!', 'hint_house_mouse.mp3'),
    ('Cake... Lake! Both end in A-K-E!', 'hint_cake_lake.mp3'),
    ('Fox... Box! Both end in O-X!', 'hint_fox_box.mp3'),
    ('Moon... Balloon! Both end in O-O-N!', 'hint_moon_balloon.mp3'),
  ];
  for (final (phrase, file) in rhymeHints) {
    await make('rhyming_words', phrase, file, slow: true);
  }
  // Words used in rhyming
  final rhymeWords = [
    'Cat',
    'Bat',
    'Bee',
    'Tree',
    'Moon',
    'Spoon',
    'Pig',
    'Big',
    'Hat',
    'Mat',
    'Bug',
    'Mug',
    'Star',
    'Car',
    'Frog',
    'Log',
    'House',
    'Mouse',
    'Cake',
    'Lake',
    'Fox',
    'Box',
    'Balloon'
  ];
  for (final w in rhymeWords) {
    await make('rhyming_words', w, 'word_${w.toLowerCase()}.mp3', slow: true);
  }
  await make('rhyming_words', 'Which word rhymes with this?', 'question.mp3',
      slow: false);
  await make('rhyming_words', 'Tap the word that rhymes!', 'instruction.mp3',
      slow: false);
  await make('rhyming_words', 'Cat, Bat, Hat! They rhyme!', 'intro.mp3',
      slow: false);
  await make(
      'rhyming_words', 'Rhyming words end with the same sound!', 'explain.mp3',
      slow: false);

  // ══════════════════════════════════════════════════════════════════════════
  // 10. SHARED FEEDBACK / PRAISE
  // ══════════════════════════════════════════════════════════════════════════
  stdout.writeln('\n── Shared Feedback ─────────────────────────────────');
  final feedback = [
    ('Correct!', 'correct.mp3', false),
    ('Great job!', 'great_job.mp3', false),
    ('Wonderful!', 'wonderful.mp3', false),
    ('Amazing!', 'amazing.mp3', false),
    ('Try again!', 'try_again.mp3', false),
    ('Try again! Listen to the hint!', 'try_again_hint.mp3', false),
    ('Hmm, try again! Listen carefully!', 'listen_carefully.mp3', false),
    ('Well done!', 'well_done.mp3', false),
    ('You are doing great!', 'doing_great.mp3', false),
    ('Keep going!', 'keep_going.mp3', false),
    ('All pairs found! Amazing job!', 'all_pairs.mp3', false),
    ('Round complete! You did it!', 'round_complete.mp3', false),
    ('Quiz done! Great work!', 'quiz_done.mp3', false),
    ('All words spelled! Fantastic!', 'all_spelled.mp3', false),
    ('Alphabet Master! You know the alphabet!', 'alphabet_master.mp3', false),
  ];
  for (final (text, file, slow) in feedback) {
    await make('feedback', text, file, slow: slow);
  }

  _client.close();

  // ── Summary ──────────────────────────────────────────────────────────────
  stdout.writeln('\n══════════════════════════════════════════════════');
  // Count files per folder
  final phonicsDir = Directory(_base);
  for (final sub in phonicsDir.listSync().whereType<Directory>()) {
    final count = sub.listSync().whereType<File>().length;
    stdout.writeln(
        '  ${sub.path.split(Platform.pathSeparator).last.padRight(20)} $count files');
  }
  stdout.writeln('──────────────────────────────────────────────────');
  stdout.writeln('✅  Generated : $_generated');
  if (_failed > 0) stdout.writeln('❌  Failed    : $_failed');
  stdout.writeln('══════════════════════════════════════════════════\n');
}
