abstract final class CharacterSelectionArt {
  static const banner = 'assets/images/character_selection/banner.png';
  static const boy = 'assets/images/character_selection/boy.png';
  static const girl = 'assets/images/character_selection/girl.png';
  static const assets = [banner, boy, girl];
  static String portrait(String character) => character == 'girl' ? girl : boy;
}
