import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

// Historical import/cleanup records remain intact. Match their source hashes
// against the lossless conversion ledger before accepting a new encoding.
final _optimizedImages = (jsonDecode(
        File('tools/release_image_optimization.json')
            .readAsStringSync())['images'] as List)
    .cast<Map>();

Map? _imageRecord(String path) {
  for (final row in _optimizedImages) {
    if (row['original'] == path || row['optimized'] == path) return row;
  }
  return null;
}

String optimizedImagePath(String path) =>
    _imageRecord(path)?['optimized'] as String? ?? path;

String originalImagePath(String path) =>
    _imageRecord(path)?['original'] as String? ?? path;

String optimizedImageHash(String path, Object? historicalHash) {
  final hash = historicalHash as String;
  final record = _imageRecord(path);
  if (record == null) return hash;
  expect(record['originalSHA256'], hash.toUpperCase(),
      reason:
          'Optimization must start from the approved original asset: $path');
  expect(record['pixelsIdentical'], true);
  expect(record['flutterRGBA_SHA256'], isNotNull);
  final current = record['optimizedSHA256'] as String;
  return hash == hash.toLowerCase()
      ? current.toLowerCase()
      : current.toUpperCase();
}
