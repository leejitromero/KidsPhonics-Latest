// Historical generator, retained for provenance only. See tools/README.md.
// Not part of the current validation or asset-replacement workflow.
// Historical network-based SVG conversion utility. See tools/README.md.
import 'dart:io';

// We'll write a minimal BMP/PPM and convert, but easiest:
// We download the rendered PNG from a public SVG render service.

import 'package:http/http.dart' as http;

Future<void> main() async {
  stdout.writeln('🎨 Generating app icon PNG...');

  // Read SVG
  final svg = File('assets/images/app_icon.svg').readAsStringSync();
  final encoded = Uri.encodeComponent(svg);

  // Historical online renderer attempt: use Kroki.io — open source diagram renderer, supports SVG passthrough
  stdout.writeln('  Trying kroki.io...');
  try {
    final res = await http
        .post(
          Uri.parse('https://kroki.io/svgbob/png'),
          headers: {'Content-Type': 'text/plain'},
          body: svg,
        )
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 200 && res.bodyBytes.length > 500) {
      _save(res.bodyBytes);
      return;
    }
  } catch (_) {}

  // Use Browserless screenshot of an HTML page embedding the SVG
  stdout.writeln('  Trying cloudinary...');
  try {
    // Encode SVG as data URI and fetch rendered version
    final dataUri = 'data:image/svg+xml;charset=utf-8,$encoded';
    final res = await http
        .get(
          Uri.parse(
              'https://res.cloudinary.com/demo/image/fetch/w_1024,h_1024/$dataUri'),
        )
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 200 && res.bodyBytes.length > 1000) {
      _save(res.bodyBytes);
      return;
    }
  } catch (_) {}

  // Final fallback — use html2canvas via a public render API
  stdout.writeln('  Trying htmlcsstoimage...');
  try {
    final html =
        '''<!DOCTYPE html><html><body style="margin:0;padding:0;width:1024px;height:1024px;">
${svg.replaceAll('width="100%"', 'width="1024"').replaceAll('height="100%"', 'height="1024"')}
</body></html>''';
    final res = await http
        .post(
          Uri.parse('https://hcti.io/v1/image'),
          headers: {'Content-Type': 'application/json'},
          body:
              '{"html":"${html.replaceAll('"', '\\"').replaceAll('\n', '')}","css":"","google_fonts":""}',
        )
        .timeout(const Duration(seconds: 20));
    if (res.statusCode == 200) {
      stdout.writeln('  Got URL, downloading...');
    }
  } catch (_) {}

  stdout.writeln('\n❌ All online methods failed due to network restrictions.');
  stdout.writeln('\n✅ EASY MANUAL METHOD (2 minutes):');
  stdout.writeln('   1. Go to: https://svgtopng.com');
  stdout.writeln('   2. Upload this file: assets/images/app_icon.svg');
  stdout.writeln('   3. Set size to 1024×1024');
  stdout.writeln('   4. Download and save as: assets/images/app_icon.png');
  stdout.writeln('   5. Run: dart run flutter_launcher_icons');
  stdout.writeln('\n   OR open the SVG file in a browser (Chrome/Edge),');
  stdout.writeln('   right-click the image → "Save image as" → app_icon.png');
  stdout.writeln('   Save to: assets/images/app_icon.png');
}

void _save(List<int> bytes) {
  File('assets/images/app_icon.png').writeAsBytesSync(bytes);
  stdout.writeln(
      '✅ Saved: assets/images/app_icon.png (${bytes.length ~/ 1024} KB)');
  stdout.writeln('   Now run: dart run flutter_launcher_icons');
}
