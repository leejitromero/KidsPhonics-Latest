"""Stage lossless PNG encodings; retain the complete pre-change ZIP backup.

No resize, palette reduction, audio transcoding, or animation timing changes.
Run without arguments to stage; --apply requires a completed verified stage.
"""
import argparse
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
from pathlib import Path
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'build/image_codec_tools'))
from PIL import Image

STAGE = ROOT / 'build/release_image_optimization'
REPORT = ROOT / 'tools/release_image_optimization.json'


def digest(data):
    return hashlib.sha256(data).hexdigest().upper()


def candidates():
    return sorted(p for p in (ROOT / 'assets/images').rglob('*.png')
                  if 'lesson_frames' not in p.parts
                  and p.name not in {'app_icon.png', 'app_mascot.png'})


def encode(source):
    relative = source.relative_to(ROOT).as_posix()
    destination = STAGE / Path(relative).with_suffix('.webp')
    destination.parent.mkdir(parents=True, exist_ok=True)
    if source.with_suffix('.webp').exists():
        raise RuntimeError(f'Existing asset collision: {source}')
    original = source.read_bytes()
    with Image.open(source) as image:
        if getattr(image, 'n_frames', 1) != 1:
            raise RuntimeError(f'Animated PNG requires separate review: {relative}')
        rgba = image.convert('RGBA')
        options = {'lossless': True, 'exact': True, 'method': 6}
        for key in ['icc_profile', 'exif']:
            if image.info.get(key):
                options[key] = image.info[key]
        rgba.save(destination, format='WEBP', **options)
        with Image.open(destination) as converted:
            if converted.size != image.size or converted.convert('RGBA').tobytes() != rgba.tobytes():
                raise RuntimeError(f'Pixel mismatch: {relative}')
            if converted.info.get('icc_profile') != image.info.get('icc_profile'):
                raise RuntimeError(f'Color profile changed: {relative}')
        return {
            'original': relative,
            'optimized': Path(relative).with_suffix('.webp').as_posix(),
            'originalBytes': len(original),
            'optimizedBytes': destination.stat().st_size,
            'originalSHA256': digest(original),
            'optimizedSHA256': digest(destination.read_bytes()),
            'rgbaSHA256': digest(rgba.tobytes()),
            'width': image.width, 'height': image.height,
            'sourceMetadataKeys': sorted(image.info.keys()),
            'pixelsIdentical': True, 'colorProfileIdentical': True,
        }


def stage():
    paths = candidates()
    records = []
    with ThreadPoolExecutor(max_workers=4) as pool:
        for row in pool.map(encode, paths):
            records.append(row)
            if len(records) % 10 == 0 or len(records) == len(paths):
                print(f'Pixel-verified {len(records)}/{len(paths)}', flush=True)
    before = sum(row['originalBytes'] for row in records)
    after = sum(row['optimizedBytes'] for row in records)
    if not records or after >= before:
        raise RuntimeError('No verified aggregate saving; originals untouched.')
    backup = json.loads((ROOT / 'build/size_optimization_backup.json').read_text())
    result = {'codec': 'lossless WebP', 'applied': False,
              'backup': backup, 'count': len(records),
              'originalBytes': before, 'optimizedBytes': after,
              'savedBytes': before - after, 'allPixelsIdentical': True,
              'protected': ['assets/images/lesson_frames/', 'assets/images/app_icon.png'],
              'images': records}
    STAGE.mkdir(parents=True, exist_ok=True)
    (STAGE / 'manifest.json').write_text(json.dumps(result, indent=2), encoding='utf-8')
    print(f'Verified image bytes: {before} -> {after}; saved {before-after}', flush=True)


def apply():
    result = json.loads((STAGE / 'manifest.json').read_text(encoding='utf-8'))
    verification = json.loads((STAGE / 'flutter_verification.json').read_text())
    flutter = {row['original']: row for row in verification['images']}
    if (verification.get('allFlutterCompatible') is not True
            or verification['count'] != result['count']
            or set(flutter) != {row['original'] for row in result['images']}):
        raise RuntimeError('Complete Flutter canvas/color/alpha verification is required')
    with zipfile.ZipFile(result['backup']['archive']) as backup:
        for row in result['images']:
            if digest(backup.read(row['original'])) != row['originalSHA256']:
                raise RuntimeError(f'Backup does not preserve the approved original: {row["original"]}')
            checked = flutter[row['original']]
            if (checked['optimized'] != row['optimized'] or checked['maxDelta'] > 1
                    or checked['opaqueDifferences'] != 0 or checked['alphaDifferences'] != 0):
                raise RuntimeError('Unapproved Flutter decoder difference')
            row.update({
                'flutterRGBA_SHA256': checked['flutterRGBA_SHA256'],
                'flutterPixelsIdentical': checked['pixelsIdentical'],
                'flutterPremultipliedMaxDelta': checked['maxDelta'],
                'flutterOpaqueDifferences': checked['opaqueDifferences'],
                'flutterAlphaDifferences': checked['alphaDifferences'],
            })
    result['flutterVerification'] = {key: value for key, value in verification.items() if key != 'images'}
    # Validate the entire input set before creating or retiring any active asset.
    for row in result['images']:
        source = (ROOT / row['original']).resolve()
        target = (ROOT / row['optimized']).resolve()
        if not source.is_relative_to(ROOT / 'assets/images') or not target.is_relative_to(ROOT / 'assets/images'):
            raise RuntimeError('Asset escapes the intended workspace directory')
        if digest(source.read_bytes()) != row['originalSHA256']:
            raise RuntimeError(f'Source changed since staging: {source}')
        if target.exists():
            raise RuntimeError(f'Target already exists: {target}')
        if digest((STAGE / row['optimized']).read_bytes()) != row['optimizedSHA256']:
            raise RuntimeError(f'Staged output changed: {target}')
    print(f'Checked all replacement paths inside {ROOT / "assets/images"}', flush=True)
    for row in result['images']:
        (ROOT / row['optimized']).write_bytes((STAGE / row['optimized']).read_bytes())
    # The complete original assets are preserved in the verified backup ZIP.
    for row in result['images']:
        (ROOT / row['original']).unlink()
    result['applied'] = True
    REPORT.write_text(json.dumps(result, indent=2), encoding='utf-8')
    print(f'Applied {result["count"]} pixel-identical encodings; source backup retained.', flush=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--apply', action='store_true')
    arguments = parser.parse_args()
    apply() if arguments.apply else stage()
