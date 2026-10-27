import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'runtime_asset_cleanup_test.dart'
    show currentAssetInventory, evaluatedRuntimeAssets;

void main() {
  test('reviewed cleanup files are absent and no unused media remain', () {
    for (final name in [
      'tools/removed_unused_assets.json',
      'tools/runtime_asset_cleanup.json'
    ]) {
      final data = jsonDecode(File(name).readAsStringSync());
      final removed = data is List ? data : data['removed'] as List;
      for (final item in removed) {
        expect(File(item['path'] as String).existsSync(), isFalse,
            reason: 'Retired file: ${item['path']}');
      }
    }
    expect(currentAssetInventory()['unusedCandidates'], isEmpty,
        reason:
            'Review both literal and dynamic runtime consumers before bundling media.');
  });

  test(
      'all evaluated literal and dynamic runtime media exist and remain declared',
      () {
    final report = currentAssetInventory();
    expect(report['preexistingMissing'], isEmpty);
    final declared = RegExp(r'^\s+- (assets/[^\r\n]+)', multiLine: true)
        .allMatches(File('pubspec.yaml').readAsStringSync())
        .map((m) => m[1]!.trim())
        .toList();
    for (final path in report['required'] as List<String>) {
      expect(File(path).existsSync(), isTrue, reason: path);
      expect(
          declared.any((d) =>
              path == d ||
              (d.endsWith('/') &&
                  path.substring(0, path.lastIndexOf('/') + 1) == d)),
          isTrue,
          reason: '$path must be declared');
    }
    if (const bool.fromEnvironment('AUDIT_ASSETS')) {
      File('tools/asset_usage_audit.json').writeAsStringSync(
          const JsonEncoder.withIndent('  ').convert(report));
    }
  });

  test('audit catches a missing Flappy literal instead of filtering it out',
      () {
    const source = 'lib/widgets/flappy_letters_design.dart';
    const missing = 'assets/images/new_ui/missing-airplane-regression.webp';
    expect(File(missing).existsSync(), isFalse);
    final original = File(source).readAsStringSync();
    expect(original, contains('assets/images/new_ui/airplane.webp'));
    final required = evaluatedRuntimeAssets(sourceOverrides: {
      source: original.replaceAll('assets/images/new_ui/airplane.webp', missing)
    });
    expect(required, contains(missing),
        reason:
            'Simulate the original defect without writing, deleting or renaming an asset');
    expect(required.where((path) => !File(path).existsSync()), [missing]);
  });
}
