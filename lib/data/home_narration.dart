/// Local recordings: each introduction step and character has its own clip.
const homeNarrationAssets = <String, String>{
  'title': 'audio/home_intro/kidsphonics_title_chorus.mp3',
  'lessons-intro-1': 'audio/home_intro/lessons_intro_01.mp3',
  'lessons-intro-2': 'audio/home_intro/lessons_intro_02.mp3',
  'lessons-intro-3': 'audio/home_intro/lessons_intro_03.mp3',
  'lessons-intro-4': 'audio/home_intro/lessons_intro_04.mp3',
  'lessons-intro-5': 'audio/home_intro/lessons_intro_05.mp3',
  'games-intro-1': 'audio/home_intro/games_intro_01.mp3',
  'games-intro-2': 'audio/home_intro/games_intro_02.mp3',
  'games-intro-3': 'audio/home_intro/games_intro_03.mp3',
  'games-intro-4': 'audio/home_intro/games_intro_04.mp3',
  'games-intro-5': 'audio/home_intro/games_intro_05.mp3',
  'profile-setup-1': 'audio/home_intro/profile_setup_01.mp3',
  'profile-setup-2': 'audio/home_intro/profile_setup_02.mp3',
  'boy-learn': 'audio/home_intro/boy_lets_learn.mp3',
  'boy-play': 'audio/home_intro/boy_lets_play.mp3',
  'girl-learn': 'audio/home_intro/girl_lets_learn.mp3',
  'girl-play': 'audio/home_intro/girl_lets_play.mp3',
  'boy-idle': 'audio/home_intro/boy_automatic_voicefeedback.mp3',
  'girl-idle': 'audio/home_intro/girl_automatic_voicefeedback.mp3',
  'girl-idle-1': 'audio/home_intro/girl_automatic_prompt_1.mp3',
  'girl-idle-2': 'audio/home_intro/girl_automatic_prompt_2.mp3',
  'girl-idle-3': 'audio/home_intro/girl_automatic_prompt_3.mp3',
  'boy-idle-4': 'audio/home_intro/boy_automatic_prompt_4.mp3',
  'boy-idle-5': 'audio/home_intro/boy_automatic_prompt_5.mp3',
  'boy-idle-6': 'audio/home_intro/boy_automatic_prompt_6.mp3',
  'intro': 'audio/home/kidsphonics_intro.mp3',
  'lessons': 'audio/home/lessons_voice.mp3',
  'games': 'audio/home/games_voice.mp3',
  'progress': 'audio/home/progress_voice.mp3',
  'parents': 'audio/home/parents_voice.mp3',
};

const girlAutomaticPrompts = [
  (
    phrase: 'home-girl-idle-1',
    text: 'Hi there! Let’s learn and play together!',
  ),
  (
    phrase: 'home-girl-idle-2',
    text: 'Which letter shall we explore today?',
  ),
  (
    phrase: 'home-girl-idle-3',
    text: 'Ready for an adventure? Tap Lessons, and let’s learn!',
  ),
];

const boyAutomaticPrompts = [
  (
    phrase: 'home-boy-idle-4',
    text: 'Let’s listen carefully and practice our letter sounds!',
  ),
  (
    phrase: 'home-boy-idle-5',
    text: 'Want to play? Tap Games, and let’s have some fun!',
  ),
  (
    phrase: 'home-boy-idle-6',
    text: 'Take your time. We can try and learn together!',
  ),
];
