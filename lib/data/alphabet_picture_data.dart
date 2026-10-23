class AlphabetPicture {
  const AlphabetPicture(this.letter, this.word);
  final String letter, word;
  String get sentence => '$letter is for $word.';
  String get phrase => 'alphabet-picture-$letter';
  List<String> get frames => [
        for (final suffix in ['', '1', '2'])
          'assets/images/lesson_frames/${word}_$letter$suffix.png'
      ];
}

const alphabetPictures = [
  AlphabetPicture('A', 'ant'),
  AlphabetPicture('B', 'ball'),
  AlphabetPicture('C', 'cat'),
  AlphabetPicture('D', 'drum'),
  AlphabetPicture('E', 'egg'),
  AlphabetPicture('F', 'fish'),
  AlphabetPicture('G', 'giraffe'),
  AlphabetPicture('H', 'hat'),
  AlphabetPicture('I', 'igloo'),
  AlphabetPicture('J', 'juice'),
  AlphabetPicture('K', 'kite'),
  AlphabetPicture('L', 'lion'),
  AlphabetPicture('M', 'monkey'),
  AlphabetPicture('N', 'nest'),
  AlphabetPicture('O', 'orange'),
  AlphabetPicture('P', 'penguin'),
  AlphabetPicture('Q', 'queen'),
  AlphabetPicture('R', 'rabbit'),
  AlphabetPicture('S', 'sun'),
  AlphabetPicture('T', 'turtle'),
  AlphabetPicture('U', 'umbrella'),
  AlphabetPicture('V', 'van'),
  AlphabetPicture('W', 'whale'),
  AlphabetPicture('X', 'xylophone'),
  AlphabetPicture('Y', 'yoyo'),
  AlphabetPicture('Z', 'zebra'),
];

// Original A_Z_sounds.zip recordings. Preserve the supplied lowercase k.mp3.
const alphabetPictureRecordings = <String, String>{
  'A': 'audio/alphabet_pictures/A.mp3',
  'B': 'audio/alphabet_pictures/B.mp3',
  'C': 'audio/alphabet_pictures/C.mp3',
  'D': 'audio/alphabet_pictures/D.mp3',
  'E': 'audio/alphabet_pictures/E.mp3',
  'F': 'audio/alphabet_pictures/F.mp3',
  'G': 'audio/alphabet_pictures/G.mp3',
  'H': 'audio/alphabet_pictures/H.mp3',
  'I': 'audio/alphabet_pictures/I.mp3',
  'J': 'audio/alphabet_pictures/J.mp3',
  'K': 'audio/alphabet_pictures/k.mp3',
  'L': 'audio/alphabet_pictures/L.mp3',
  'M': 'audio/alphabet_pictures/M.mp3',
  'N': 'audio/alphabet_pictures/N.mp3',
  'O': 'audio/alphabet_pictures/O.mp3',
  'P': 'audio/alphabet_pictures/P.mp3',
  'Q': 'audio/alphabet_pictures/Q.mp3',
  'R': 'audio/alphabet_pictures/R.mp3',
  'S': 'audio/alphabet_pictures/S.mp3',
  'T': 'audio/alphabet_pictures/T.mp3',
  'U': 'audio/alphabet_pictures/U.mp3',
  'V': 'audio/alphabet_pictures/V.mp3',
  'W': 'audio/alphabet_pictures/W.mp3',
  'X': 'audio/alphabet_pictures/X.mp3',
  'Y': 'audio/alphabet_pictures/Y.mp3',
  'Z': 'audio/alphabet_pictures/Z.mp3',
};

String? alphabetPictureAudioAsset(String phrase) {
  final match = RegExp(r'^alphabet-picture-([A-Z])$').firstMatch(phrase);
  return match == null ? null : alphabetPictureRecordings[match.group(1)];
}
