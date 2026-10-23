import 'package:flutter/material.dart';

/// Home-only category presentation. Destination routes remain in HomeScreen.
enum HomeCategory {
  lessons('Lessons', Icons.auto_stories_rounded, Color(0xFF9250D7),
      Color(0xFFEAC3FF), Color(0xFF502082)),
  games('Games', Icons.sports_esports_rounded, Color(0xFF158BE6),
      Color(0xFFA3EDFF), Color(0xFF13478F)),
  progress('Progress', Icons.emoji_events_rounded, Color(0xFFF4A036),
      Color(0xFFFFECA4), Color(0xFF9A4B17)),
  parents('Parents', Icons.eco_rounded, Color(0xFF50A866), Color(0xFFDFFFAD),
      Color(0xFF215F3D));

  const HomeCategory(
      this.title, this.icon, this.color, this.highlight, this.dark);
  final String title;
  final IconData icon;
  final Color color, highlight, dark;
  String get mascotAsset => 'assets/images/home_village/$name.png';
  bool get hasHouse => this == lessons || this == games;
  String? get houseAsset =>
      hasHouse ? 'assets/images/home_village/${name}_house.png' : null;
  String get voiceKey => name;
}

const homeVillageFrames = [
  'assets/images/home_village/bg_1.png',
  'assets/images/home_village/bg_2.png',
  'assets/images/home_village/bg_3.png',
  'assets/images/home_village/bg_4.png',
];

const homeNavigationArt = <String, String>{
  'home': 'assets/images/navigation_buttons/home_button.png',
  'lessons': 'assets/images/navigation_buttons/lessons_button.png',
  'games': 'assets/images/navigation_buttons/games_button.png',
  'progress': 'assets/images/navigation_buttons/progress_button.png',
  'parents': 'assets/images/navigation_buttons/parent_button.png',
};

/// Geometry of the supplied garden, also used by the background's cover fit.
abstract final class HomeGardenGeometry {
  static const artworkSize = Size(941, 1672);
  static const aspectRatio = 941 / 1672;
  static const foregroundFraction = .73;

  /// Lower garden circle in the original background's coordinate system.
  static Rect lowerPad(HomeCategory category, Size world) {
    final scale =
        world.width / artworkSize.width > world.height / artworkSize.height
            ? world.width / artworkSize.width
            : world.height / artworkSize.height;
    final origin = Offset((world.width - artworkSize.width * scale) / 2,
        (world.height - artworkSize.height * scale) / 2);
    return Rect.fromCenter(
        center: origin +
            Offset(category == HomeCategory.games ? 235 : 706, 1060) * scale,
        width: 300 * scale,
        height: 156 * scale);
  }
}

/// One reusable timeline, also suitable for a later guided introduction.
abstract final class HomeVisitTiming {
  static const duration = Duration(milliseconds: 1800);
  static double door(double t) =>
      const Interval(.08, .55, curve: Curves.easeInOutCubic).transform(t);
  static double mascot(double t) =>
      const Interval(.30, .78, curve: Curves.easeOutCubic).transform(t);
  static double greeting(double t) =>
      const Interval(.68, 1, curve: Curves.easeInOut).transform(t);
}
