const sceneAssets = 'assets/images/update_scene';

class HomeDialogue {
  const HomeDialogue(this.phrase, this.text, {this.games = false});
  final String phrase, text;
  final bool games;
}

const homeIntroduction = <HomeDialogue>[
  HomeDialogue('home-lessons-intro-1',
      'Hi, friend! Welcome to KidsPhonics! I’m Lala, your Lessons guide!'),
  HomeDialogue('home-lessons-intro-2',
      'I’ll help you learn letters, their sounds, and how to read words. We’ll learn together, one step at a time!'),
  HomeDialogue('home-lessons-intro-3',
      'Tap the Lessons sign to visit me. Listen carefully to the sounds, then try the activities!'),
  HomeDialogue('home-lessons-intro-4',
      'You can replay a sound whenever you need. The Practice This Letter button helps you practice your next letter!'),
  HomeDialogue(
      'home-lessons-intro-5', 'Ready to meet my friend Lulu? Tap Next!'),
  HomeDialogue('home-games-intro-1', 'Hi, friend! I’m Lulu, your Games guide!',
      games: true),
  HomeDialogue('home-games-intro-2',
      'We’ll practice letters, sounds, and words through fun games. Learning can be an adventure!',
      games: true),
  HomeDialogue('home-games-intro-3',
      'Tap the Games sign to visit me. Choose a game, pick a difficulty, and follow the instructions!',
      games: true),
  HomeDialogue('home-games-intro-4',
      'Keep trying! You can see your stars and learning journey in Progress.',
      games: true),
  HomeDialogue('home-games-intro-5',
      'Ready for your adventure? Tap Get Started to choose your character!',
      games: true),
];

const profileIntroduction = <HomeDialogue>[
  HomeDialogue('home-profile-setup-1',
      'Choose the boy or girl character you like. This character will represent you on your learning adventure!',
      games: true),
  HomeDialogue('home-profile-setup-2',
      'Type your name in the box. When you’re ready, tap Let’s go!',
      games: true),
];

List<String> mascotTalkingFrames(bool games) => [
      for (var i = 1; i <= 5; i++)
        '$sceneAssets/${games ? 'games_talking_$i' : 'lesson_mascot_talking$i'}.png',
    ];

List<String> studentWalkingFrames(String character, {required bool left}) => [
      for (var i = left ? 7 : 2; i <= (left ? 10 : 5); i++)
        '$sceneAssets/${character}_$i.png',
    ];

const welcomeLessonText =
    'Hi, friend! Welcome to KidsPhonics! I’m Lala, your Lessons guide! '
    'I’ll help you learn letters, their sounds, and how to read words. '
    'We’ll learn together, one step at a time! Tap Lessons to visit me. '
    'Now, tap Next to meet Lulu, your Games guide!';
const welcomeGamesText = 'Hi, friend! I’m Lulu, your Games guide! '
    'We’ll practice letters, sounds, and words through fun games. '
    'Tap Games whenever you’re ready to play! '
    'You can see your stars and learning journey in Progress. '
    'Tap Done to choose your character!';
const lessonsGuideText =
    'Choose a lesson. Listen carefully to the sounds, then try the activities! '
    'You can replay a sound whenever you need. Tap Progress to see how much you’ve learned!';
const gamesGuideText =
    'Choose a game, pick a difficulty, and follow the instructions. Let’s play and learn! '
    'Keep trying! Your progress and stars are saved in your profile. You can check them in Progress!';
