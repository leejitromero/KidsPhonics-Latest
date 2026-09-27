// Historical generator, retained for provenance only. See tools/README.md.
// Not part of the current validation or asset-replacement workflow.
// generate_icon.dart
// Converts app_icon.svg → app_icon.png (1024×1024) using an online SVG renderer.
// Run: dart run tools/generate_icon.dart
import 'dart:io';
import 'package:http/http.dart' as http;

Future<void> main() async {
  final svgFile = File('assets/images/app_icon.svg');
  if (!svgFile.existsSync()) {
    stdout.writeln('❌ SVG not found at assets/images/app_icon.svg');
    exit(1);
  }

  final svgContent = svgFile.readAsStringSync();

  stdout.writeln('🎨 Converting SVG → PNG via API...');

  // Use svg2png API (free, no key)
  final uri = Uri.parse('https://svg2png.com/api/');
  final response = await http.post(
    uri,
    headers: {'Content-Type': 'application/x-www-form-urlencoded'},
    body: {
      'svg': svgContent,
      'width': '1024',
      'height': '1024',
    },
  );

  if (response.statusCode == 200 && response.bodyBytes.length > 1000) {
    final out = File('assets/images/app_icon.png');
    out.writeAsBytesSync(response.bodyBytes);
    stdout.writeln(
        '✅ Saved: assets/images/app_icon.png (${response.bodyBytes.length ~/ 1024} KB)');
  } else {
    stdout.writeln(
        '❌ API failed (${response.statusCode}). Using fallback method...');
    // Fallback: instruct user
    stdout.writeln('\n📌 Manual fallback:');
    stdout.writeln('   1. Open https://svgtopng.com/');
    stdout.writeln('   2. Upload: assets/images/app_icon.svg');
    stdout
        .writeln('   3. Download as PNG, save to: assets/images/app_icon.png');
    stdout.writeln('   4. Run: flutter pub run flutter_launcher_icons\n');
  }
}
