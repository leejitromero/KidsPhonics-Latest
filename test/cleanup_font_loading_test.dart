import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidsphonics/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('application theme and discovered Medium/SemiBold fonts load offline',
      () async {
    final previous = GoogleFonts.config.allowRuntimeFetching;
    addTearDown(() => GoogleFonts.config.allowRuntimeFetching = previous);
    GoogleFonts.config.allowRuntimeFetching = false;
    final theme = AppTheme.theme;
    expect(theme.textTheme.bodyMedium, isNotNull);
    GoogleFonts.nunito(fontWeight: FontWeight.w500);
    GoogleFonts.nunito(fontWeight: FontWeight.w600);
    await GoogleFonts.pendingFonts();
  });
}
