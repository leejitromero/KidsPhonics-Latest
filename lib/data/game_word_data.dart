import '../models/difficulty.dart';

class GameWord {
  const GameWord(
      this.difficulty, this.letter, this.slug, this.word, this.frames);
  final Difficulty difficulty;
  final String letter, slug, word;
  final List<String> frames;
  String get audioKey => word;
  String get audioAsset => 'audio/game_words/$slug.mp3';
}

const gameWords = <GameWord>[
  GameWord(Difficulty.easy, 'A', 'axe', 'Axe', [
    'assets/images/game_words/axe-0.png',
    'assets/images/game_words/axe-0.png'
  ]),
  GameWord(Difficulty.easy, 'B', 'bag', 'Bag', [
    'assets/images/game_words/bag-0.png',
    'assets/images/game_words/bag-1.png'
  ]),
  GameWord(Difficulty.easy, 'C', 'cow', 'Cow', [
    'assets/images/game_words/cow-0.png',
    'assets/images/game_words/cow-1.png'
  ]),
  GameWord(Difficulty.easy, 'D', 'dog', 'Dog', [
    'assets/images/game_words/dog-0.png',
    'assets/images/game_words/dog-1.png'
  ]),
  GameWord(Difficulty.easy, 'E', 'ear', 'Ear', [
    'assets/images/game_words/ear-0.png',
    'assets/images/game_words/ear-1.png'
  ]),
  GameWord(Difficulty.easy, 'F', 'fan', 'Fan', [
    'assets/images/game_words/fan-0.png',
    'assets/images/game_words/fan-1.png'
  ]),
  GameWord(Difficulty.easy, 'G', 'goat', 'Goat', [
    'assets/images/game_words/goat-0.png',
    'assets/images/game_words/goat-1.png'
  ]),
  GameWord(Difficulty.easy, 'H', 'hand', 'Hand', [
    'assets/images/game_words/hand-0.png',
    'assets/images/game_words/hand-1.png'
  ]),
  GameWord(Difficulty.easy, 'I', 'ice', 'Ice', [
    'assets/images/game_words/ice-0.png',
    'assets/images/game_words/ice-1.png'
  ]),
  GameWord(Difficulty.easy, 'J', 'jar', 'Jar', [
    'assets/images/game_words/jar-0.png',
    'assets/images/game_words/jar-1.png'
  ]),
  GameWord(Difficulty.easy, 'K', 'key', 'Key', [
    'assets/images/game_words/key-0.png',
    'assets/images/game_words/key-1.png'
  ]),
  GameWord(Difficulty.easy, 'L', 'lips', 'Lips', [
    'assets/images/game_words/lips-0.png',
    'assets/images/game_words/lips-1.png'
  ]),
  GameWord(Difficulty.easy, 'M', 'moon', 'Moon', [
    'assets/images/game_words/moon-0.png',
    'assets/images/game_words/moon-1.png'
  ]),
  GameWord(Difficulty.easy, 'N', 'net', 'Net', [
    'assets/images/game_words/net-0.png',
    'assets/images/game_words/net-1.png'
  ]),
  GameWord(Difficulty.easy, 'O', 'onion', 'Onion', [
    'assets/images/game_words/onion-0.png',
    'assets/images/game_words/onion-1.png'
  ]),
  GameWord(Difficulty.easy, 'P', 'pen', 'Pen', [
    'assets/images/game_words/pen-0.png',
    'assets/images/game_words/pen-1.png'
  ]),
  GameWord(Difficulty.easy, 'Q', 'quill', 'Quill', [
    'assets/images/game_words/quill-0.png',
    'assets/images/game_words/quill-1.png'
  ]),
  GameWord(Difficulty.easy, 'R', 'rose', 'Rose', [
    'assets/images/game_words/rose-0.png',
    'assets/images/game_words/rose-1.png'
  ]),
  GameWord(Difficulty.easy, 'S', 'star', 'Star', [
    'assets/images/game_words/star-0.png',
    'assets/images/game_words/star-1.png'
  ]),
  GameWord(Difficulty.easy, 'T', 'tub', 'Tub', [
    'assets/images/game_words/tub-0.png',
    'assets/images/game_words/tub-1.png'
  ]),
  GameWord(Difficulty.easy, 'U', 'umbrella', 'Umbrella', [
    'assets/images/game_words/umbrella-0.png',
    'assets/images/game_words/umbrella-1.png'
  ]),
  GameWord(Difficulty.easy, 'V', 'vase', 'Vase', [
    'assets/images/game_words/vase-0.png',
    'assets/images/game_words/vase-1.png'
  ]),
  GameWord(Difficulty.easy, 'W', 'web', 'Web', [
    'assets/images/game_words/web-0.png',
    'assets/images/game_words/web-1.png'
  ]),
  GameWord(Difficulty.easy, 'Y', 'yarn', 'Yarn', [
    'assets/images/game_words/yarn-0.png',
    'assets/images/game_words/yarn-1.png'
  ]),
  GameWord(Difficulty.medium, 'A', 'apple', 'Apple', [
    'assets/images/game_words/apple-0.png',
    'assets/images/game_words/apple-1.png'
  ]),
  GameWord(Difficulty.medium, 'B', 'book', 'Book', [
    'assets/images/game_words/book-0.png',
    'assets/images/game_words/book-1.png'
  ]),
  GameWord(Difficulty.medium, 'C', 'corn', 'Corn', [
    'assets/images/game_words/corn-0.png',
    'assets/images/game_words/corn-1.png'
  ]),
  GameWord(Difficulty.medium, 'D', 'door', 'Door', [
    'assets/images/game_words/door-0.png',
    'assets/images/game_words/door-1.png'
  ]),
  GameWord(Difficulty.medium, 'E', 'elephant', 'Elephant', [
    'assets/images/game_words/elephant-0.png',
    'assets/images/game_words/elephant-1.png'
  ]),
  GameWord(Difficulty.medium, 'F', 'frog', 'Frog', [
    'assets/images/game_words/frog-0.png',
    'assets/images/game_words/frog-1.png'
  ]),
  GameWord(Difficulty.medium, 'G', 'grapes', 'Grapes', [
    'assets/images/game_words/grapes-0.png',
    'assets/images/game_words/grapes-1.png'
  ]),
  GameWord(Difficulty.medium, 'H', 'heart', 'Heart', [
    'assets/images/game_words/heart-0.png',
    'assets/images/game_words/heart-1.png'
  ]),
  GameWord(Difficulty.medium, 'I', 'ice_cream', 'Ice Cream', [
    'assets/images/game_words/ice_cream-0.png',
    'assets/images/game_words/ice_cream-1.png'
  ]),
  GameWord(Difficulty.medium, 'J', 'jacket', 'Jacket', [
    'assets/images/game_words/jacket-0.png',
    'assets/images/game_words/jacket-1.png'
  ]),
  GameWord(Difficulty.medium, 'K', 'king', 'King', [
    'assets/images/game_words/king-0.png',
    'assets/images/game_words/king-1.png'
  ]),
  GameWord(Difficulty.medium, 'L', 'lamb', 'Lamb', [
    'assets/images/game_words/lamb-0.png',
    'assets/images/game_words/lamb-1.png'
  ]),
  GameWord(Difficulty.medium, 'M', 'mango', 'Mango', [
    'assets/images/game_words/mango-0.png',
    'assets/images/game_words/mango-1.png'
  ]),
  GameWord(Difficulty.medium, 'N', 'nest', 'Nest', [
    'assets/images/game_words/nest-0.png',
    'assets/images/game_words/nest-1.png'
  ]),
  GameWord(Difficulty.medium, 'O', 'orange', 'Orange', [
    'assets/images/game_words/orange-0.png',
    'assets/images/game_words/orange-0.png'
  ]),
  GameWord(Difficulty.medium, 'P', 'plate', 'Plate', [
    'assets/images/game_words/plate-0.png',
    'assets/images/game_words/plate-1.png'
  ]),
  GameWord(Difficulty.medium, 'Q', 'queen', 'Queen', [
    'assets/images/game_words/queen-0.png',
    'assets/images/game_words/queen-1.png'
  ]),
  GameWord(Difficulty.medium, 'R', 'rabbit', 'Rabbit', [
    'assets/images/game_words/rabbit-0.png',
    'assets/images/game_words/rabbit-1.png'
  ]),
  GameWord(Difficulty.medium, 'S', 'sheep', 'Sheep', [
    'assets/images/game_words/sheep-0.png',
    'assets/images/game_words/sheep-1.png'
  ]),
  GameWord(Difficulty.medium, 'T', 'tiger', 'Tiger', [
    'assets/images/game_words/tiger-0.png',
    'assets/images/game_words/tiger-1.png'
  ]),
  GameWord(Difficulty.medium, 'U', 'uniform', 'Uniform', [
    'assets/images/game_words/uniform-0.png',
    'assets/images/game_words/uniform-1.png'
  ]),
  GameWord(Difficulty.medium, 'V', 'violin', 'Violin', [
    'assets/images/game_words/violin-0.png',
    'assets/images/game_words/violin-1.png'
  ]),
  GameWord(Difficulty.medium, 'W', 'wolf', 'Wolf', [
    'assets/images/game_words/wolf-0.png',
    'assets/images/game_words/wolf-1.png'
  ]),
  GameWord(Difficulty.hard, 'A', 'airplane', 'Airplane', [
    'assets/images/game_words/airplane-0.png',
    'assets/images/game_words/airplane-1.png'
  ]),
  GameWord(Difficulty.hard, 'B', 'bottle', 'Bottle', [
    'assets/images/game_words/bottle-0.png',
    'assets/images/game_words/bottle-1.png'
  ]),
  GameWord(Difficulty.hard, 'C', 'chicken', 'Chicken', [
    'assets/images/game_words/chicken-0.png',
    'assets/images/game_words/chicken-1.png'
  ]),
  GameWord(Difficulty.hard, 'D', 'donkey', 'Donkey', [
    'assets/images/game_words/donkey-0.png',
    'assets/images/game_words/donkey-1.png'
  ]),
  GameWord(Difficulty.hard, 'E', 'eggplant', 'Eggplant', [
    'assets/images/game_words/eggplant-0.png',
    'assets/images/game_words/eggplant-1.png'
  ]),
  GameWord(Difficulty.hard, 'F', 'fairy', 'Fairy', [
    'assets/images/game_words/fairy-0.png',
    'assets/images/game_words/fairy-1.png'
  ]),
  GameWord(Difficulty.hard, 'G', 'gorilla', 'Gorilla', [
    'assets/images/game_words/gorilla-0.png',
    'assets/images/game_words/gorilla-1.png'
  ]),
  GameWord(Difficulty.hard, 'H', 'house', 'House', [
    'assets/images/game_words/house-0.png',
    'assets/images/game_words/house-1.png'
  ]),
  GameWord(Difficulty.hard, 'I', 'island', 'Island', [
    'assets/images/game_words/island-0.png',
    'assets/images/game_words/island-1.png'
  ]),
  GameWord(Difficulty.hard, 'J', 'jellyfish', 'Jellyfish', [
    'assets/images/game_words/jellyfish-0.png',
    'assets/images/game_words/jellyfish-1.png'
  ]),
  GameWord(Difficulty.hard, 'K', 'kangaroo', 'Kangaroo', [
    'assets/images/game_words/kangaroo-0.png',
    'assets/images/game_words/kangaroo-1.png'
  ]),
  GameWord(Difficulty.hard, 'L', 'lollipop', 'Lollipop', [
    'assets/images/game_words/lollipop-0.png',
    'assets/images/game_words/lollipop-1.png'
  ]),
  GameWord(Difficulty.hard, 'M', 'monkey', 'Monkey', [
    'assets/images/game_words/monkey-0.png',
    'assets/images/game_words/monkey-0.png'
  ]),
  GameWord(Difficulty.hard, 'N', 'notebook', 'Notebook', [
    'assets/images/game_words/notebook-0.png',
    'assets/images/game_words/notebook-1.png'
  ]),
  GameWord(Difficulty.hard, 'O', 'octopus', 'Octopus', [
    'assets/images/game_words/octopus-0.png',
    'assets/images/game_words/octopus-0.png'
  ]),
  GameWord(Difficulty.hard, 'P', 'potato', 'Potato', [
    'assets/images/game_words/potato-0.png',
    'assets/images/game_words/potato-1.png'
  ]),
  GameWord(Difficulty.hard, 'Q', 'quack', 'Quack', [
    'assets/images/game_words/quack-0.png',
    'assets/images/game_words/quack-1.png'
  ]),
  GameWord(Difficulty.hard, 'R', 'rooster', 'Rooster', [
    'assets/images/game_words/rooster-0.png',
    'assets/images/game_words/rooster-1.png'
  ]),
  GameWord(Difficulty.hard, 'S', 'spoon', 'Spoon', [
    'assets/images/game_words/spoon-0.png',
    'assets/images/game_words/spoon-1.png'
  ]),
  GameWord(Difficulty.hard, 'T', 'train', 'Train', [
    'assets/images/game_words/train-0.png',
    'assets/images/game_words/train-1.png'
  ]),
  GameWord(Difficulty.hard, 'U', 'unicorn', 'Unicorn', [
    'assets/images/game_words/unicorn-0.png',
    'assets/images/game_words/unicorn-1.png'
  ]),
  GameWord(Difficulty.hard, 'V', 'vacuum', 'Vacuum', [
    'assets/images/game_words/vacuum-0.png',
    'assets/images/game_words/vacuum-1.png'
  ]),
  GameWord(Difficulty.hard, 'W', 'whale', 'Whale', [
    'assets/images/game_words/whale-0.png',
    'assets/images/game_words/whale-1.png'
  ]),
  GameWord(Difficulty.hard, 'Y', 'yogurt', 'Yogurt', [
    'assets/images/game_words/yogurt-0.png',
    'assets/images/game_words/yogurt-1.png'
  ]),
];
List<GameWord> gameWordsFor(Difficulty d) =>
    gameWords.where((w) => w.difficulty == d).toList();
GameWord? gameWordFor(String word) {
  for (final item in gameWords) {
    if (item.word.toLowerCase() == word.toLowerCase()) return item;
  }
  return null;
}
