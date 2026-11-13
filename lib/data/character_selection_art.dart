abstract final class CharacterSelectionArt {
  static const banner = 'assets/images/character_selection/banner.webp';
  static const boy = 'assets/images/character_selection/boy.webp';
  static const girl = 'assets/images/character_selection/girl.webp';
  static const assets = [banner, boy, girl];
  static String portrait(String character) => character == 'girl' ? girl : boy;
}
