import '../models/difficulty.dart';
import 'game_word_data.dart';

List<GameWord> rumbledWordsFor(Difficulty difficulty) =>
    gameWordsFor(difficulty).where((word) => !word.word.contains(' ')).toList();
