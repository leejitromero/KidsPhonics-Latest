class JourneyQuestion {
  const JourneyQuestion(
      this.prompt, this.choices, this.answer, this.explanation,
      {this.audio});
  final String prompt, answer, explanation;
  final List<String> choices;
  final String? audio;
}

class JourneyLesson {
  const JourneyLesson(this.id, this.title, this.description,
      [this.questions = const []]);
  final String id, title, description;
  final List<JourneyQuestion> questions;
}

class JourneyLevel {
  const JourneyLevel(this.title, this.description, this.lessons);
  final String title, description;
  final List<JourneyLesson> lessons;
}

const lessonJourney = [
  JourneyLevel('Meet the Letters', 'Learn letters and their sounds.', [
    JourneyLesson('letters', 'Letter Sounds A–Z',
        'Start with m, a, s, t, p, i, n. Explore more at your pace.'),
    JourneyLesson(
        'match', 'Match Letters and Sounds', 'Listen, then choose a letter.', [
      JourneyQuestion('Listen to the sound. Which letter?', ['s', 'm', 't'],
          'm', 'm represents the /m/ sound.',
          audio: 'lesson-sound-M'),
      JourneyQuestion('Listen to the sound. Which letter?', ['a', 's', 'p'],
          's', 's represents the /s/ sound.',
          audio: 'lesson-sound-S'),
      JourneyQuestion('Listen to the sound. Which letter?', ['t', 'm', 'a'],
          'a', 'a represents the short /a/ sound.',
          audio: 'lesson-sound-A'),
    ]),
    JourneyLesson('tricky', 'Letter Mix-Up Practice',
        'Practice letters you find tricky.'),
  ]),
  JourneyLevel(
      'Meet the Sounds', 'Hear sounds at the start, middle, and end.', [
    JourneyLesson('vowels', 'Short Vowel Sounds', 'Explore a, e, i, o, u.'),
    JourneyLesson(
        'beginning', 'Beginning Sounds', 'Listen for the first sound.', [
      JourneyQuestion('What is the first sound in cat?', ['m', 'c', 't'], 'c',
          'cat starts with /k/, written c.',
          audio: 'Cat'),
      JourneyQuestion('What is the first sound in sun?', ['s', 'n', 'u'], 's',
          'sun starts with /s/.',
          audio: 'Sun'),
      JourneyQuestion('What is the first sound in mat?', ['t', 'a', 'm'], 'm',
          'mat starts with /m/.',
          audio: 'Mat'),
    ]),
    JourneyLesson('ending', 'Ending Sounds', 'Listen for the last sound.', [
      JourneyQuestion('What is the last sound in cat?', ['c', 't', 'a'], 't',
          'cat ends with /t/.',
          audio: 'Cat'),
      JourneyQuestion('What is the last sound in sun?', ['s', 'u', 'n'], 'n',
          'sun ends with /n/.',
          audio: 'Sun'),
      JourneyQuestion('What is the last sound in mat?', ['t', 'm', 'a'], 't',
          'mat ends with /t/.',
          audio: 'Mat'),
    ]),
    JourneyLesson(
        'middle', 'Middle Sounds', 'Listen for the vowel in the middle.', [
      JourneyQuestion('What is the middle sound in cat?', ['i', 'a', 'o'], 'a',
          'c–a–t: the middle sound is short a.',
          audio: 'Cat'),
      JourneyQuestion('What is the middle sound in pig?', ['i', 'e', 'u'], 'i',
          'p–i–g: the middle sound is short i.',
          audio: 'Pig'),
      JourneyQuestion('What is the middle sound in sun?', ['a', 'o', 'u'], 'u',
          's–u–n: the middle sound is short u.',
          audio: 'Sun'),
    ]),
  ]),
  JourneyLevel('Build Words', 'Blend to read. Segment to spell.', [
    JourneyLesson(
        'blend', 'Blend Sounds', 'Say each sound, then slide them together.', [
      JourneyQuestion('Blend /m/ /a/ /t/.', ['sat', 'mat', 'map'], 'mat',
          '/m/ /a/ /t/ together make mat.'),
      JourneyQuestion('Blend /s/ /a/ /t/.', ['sat', 'sit', 'mat'], 'sat',
          '/s/ /a/ /t/ together make sat.'),
      JourneyQuestion('Blend /p/ /i/ /n/.', ['pan', 'pit', 'pin'], 'pin',
          '/p/ /i/ /n/ together make pin.'),
    ]),
    JourneyLesson(
        'cvc', 'Read CVC Words', 'Read a consonant, vowel, and consonant.', [
      JourneyQuestion('Which word matches c–a–t?', ['cut', 'cat', 'cot'], 'cat',
          'Blend c–a–t to read cat.'),
      JourneyQuestion('Which word matches p–i–g?', ['pig', 'peg', 'pug'], 'pig',
          'Blend p–i–g to read pig.'),
      JourneyQuestion('Which word matches s–u–n?', ['sat', 'sip', 'sun'], 'sun',
          'Blend s–u–n to read sun.'),
    ]),
    JourneyLesson('segment', 'Segment and Spell',
        'Split a spoken word into its sounds.', [
      JourneyQuestion('Which sounds spell mat?', ['m–i–t', 'm–a–t', 's–a–t'],
          'm–a–t', 'mat has three sounds: /m/ /a/ /t/.',
          audio: 'Mat'),
      JourneyQuestion('Which sounds spell pig?', ['p–i–g', 'p–e–g', 'b–i–g'],
          'p–i–g', 'pig has three sounds: /p/ /i/ /g/.',
          audio: 'Pig'),
      JourneyQuestion('Which sounds spell sun?', ['s–a–n', 's–u–m', 's–u–n'],
          's–u–n', 'sun has three sounds: /s/ /u/ /n/.',
          audio: 'Sun'),
    ]),
  ]),
  JourneyLevel('Discover Words', 'Explore patterns and useful words.', [
    JourneyLesson(
        'families', 'Word Families', 'Read words with the same ending.', [
      JourneyQuestion('Which word belongs with cat and mat?',
          ['pig', 'hat', 'sun'], 'hat', 'cat, mat, and hat share –at.'),
      JourneyQuestion('Which word belongs with pin and fin?',
          ['tin', 'tap', 'top'], 'tin', 'pin, fin, and tin share –in.'),
      JourneyQuestion('Which word belongs with hop and mop?',
          ['map', 'hip', 'top'], 'top', 'hop, mop, and top share –op.'),
    ]),
    JourneyLesson('common', 'Common Words',
        'Sound out regular parts; learn unusual parts.', [
      JourneyQuestion(
          'Read: can. Which sounds spell it?',
          ['c–a–t', 'c–a–n', 'c–o–n'],
          'c–a–n',
          'can is regular: blend /k/ /a/ /n/.'),
      JourneyQuestion(
          'In “the”, which letters work together?',
          ['th', 'he', 'te'],
          'th',
          'th makes one sound. The vowel in the is unusual; it often sounds like /uh/.'),
      JourneyQuestion(
          'In “is”, which letter sounds like /z/?',
          ['i', 's', 'Both'],
          's',
          'i has its short sound; s sounds like /z/ in is.'),
    ]),
    JourneyLesson('mixed', 'Mixed Word Practice',
        'Use the sounds and patterns you know.', [
      JourneyQuestion('Choose the word with short a.', ['pig', 'cat', 'sun'],
          'cat', 'cat has short a in the middle.'),
      JourneyQuestion('Choose the word in the –in family.',
          ['pin', 'pan', 'pot'], 'pin', 'pin ends with –in.'),
      JourneyQuestion('Blend /m/ /o/ /p/.', ['map', 'mat', 'mop'], 'mop',
          'Blend the sounds to read mop.'),
    ]),
  ]),
  JourneyLevel('Start Reading', 'Read, then think about the meaning.', [
    JourneyLesson(
        'phrases', 'Read Short Phrases', 'Read a few words together.', [
      JourneyQuestion('Read: a big pig. Which animal?', ['cat', 'pig', 'dog'],
          'pig', 'The phrase tells us about a pig.'),
      JourneyQuestion('Read: the red hat. What is red?', ['hat', 'mat', 'sun'],
          'hat', 'The hat is red.'),
      JourneyQuestion(
          'Read: a cat on the mat. Where is the cat?',
          ['in a hut', 'on a log', 'on the mat'],
          'on the mat',
          'The words tell us where the cat is.'),
    ]),
    JourneyLesson('sentences', 'Simple Sentences',
        'Read a sentence and answer a question.', [
      JourneyQuestion(
          'The cat is big. What is big?',
          ['The pig', 'The cat', 'The sun'],
          'The cat',
          'The sentence tells us the cat is big.'),
      JourneyQuestion('A pig can dig. What can the pig do?',
          ['dig', 'sit', 'hop'], 'dig', 'The pig can dig.'),
      JourneyQuestion(
          'The dog is on the mat. Where is the dog?',
          ['on a log', 'in a pen', 'on the mat'],
          'on the mat',
          'The dog is on the mat.'),
    ]),
    JourneyLesson(
        'stories', 'Mini Stories', 'Read a tiny story and find its meaning.', [
      JourneyQuestion(
          'The cat is on the mat. The cat can nap.\nWho can nap?',
          ['The dog', 'The cat', 'The pig'],
          'The cat',
          'The story says the cat can nap.'),
      JourneyQuestion(
          'A pig is in a pen. The pig can dig.\nWhere is the pig?',
          ['in a pen', 'on a mat', 'in a hut'],
          'in a pen',
          'The first sentence tells us where the pig is.'),
      JourneyQuestion(
          'The dog can hop. The dog can sit.\nWhat can the dog do?',
          ['dig and nap', 'run and dig', 'hop and sit'],
          'hop and sit',
          'Both sentences tell us what the dog can do.'),
    ]),
  ]),
];
