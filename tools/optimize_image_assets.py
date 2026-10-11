"""Lossless image encoding with full RGBA verification before replacing assets.

Install Pillow in a local tooling environment. Run --apply to update sources.
Originals and staged output are retained under ignored build/image_optimization.
"""
import argparse
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
import re
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'build/image_codec_tools'))
from PIL import Image

KEEP_PNG = {'assets/images/app_icon.png', 'assets/images/app_mascot.png'}
STAGE = ROOT / 'build/image_optimization'

def encode(source):
    relative = source.relative_to(ROOT).as_posix()
    destination = STAGE / relative.replace('.png', '.webp')
    destination.parent.mkdir(parents=True, exist_ok=True)
    with Image.open(source) as original:
        pixels = original.convert('RGBA')
        options = dict(lossless=True, exact=True, method=6)
        if original.info.get('icc_profile'):
            options['icc_profile'] = original.info['icc_profile']
        pixels.save(destination, format='WEBP', **options)
        with Image.open(destination) as encoded:
            assert encoded.size == pixels.size
            assert encoded.convert('RGBA').tobytes() == pixels.tobytes(), relative
        rgba_hash = hashlib.sha256(pixels.tobytes()).hexdigest()
    return dict(original=relative, optimized=relative.replace('.png', '.webp'),
                originalBytes=source.stat().st_size,
                optimizedBytes=destination.stat().st_size,
                rgbaSHA256=rgba_hash, pixelsIdentical=True)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--apply', action='store_true')
    args = parser.parse_args()
    sources = sorted(p for p in (ROOT / 'assets/images').rglob('*.png')
                     if p.relative_to(ROOT).as_posix() not in KEEP_PNG)
    if not sources:
        raise SystemExit('No PNG candidates; see tools/image_optimization_report.json.')
    records = []
    with ThreadPoolExecutor(max_workers=4) as pool:
        for record in pool.map(encode, sources):
            records.append(record)
            if len(records) % 40 == 0:
                print(f'Verified {len(records)} / {len(sources)} images', flush=True)
    before = sum(r['originalBytes'] for r in records)
    after = sum(r['optimizedBytes'] for r in records)
    assert after < before, 'No aggregate savings; originals remain untouched.'
    report = dict(codec='lossless WebP', count=len(records),
                  originalBytes=before, optimizedBytes=after,
                  savedBytes=before-after, allPixelsIdentical=True, images=records)
    STAGE.mkdir(parents=True, exist_ok=True)
    (STAGE / 'benchmark.json').write_text(json.dumps(report, indent=2))
    print(f'{len(records)} images: {before/1048576:.2f} -> {after/1048576:.2f} MiB', flush=True)
    if not args.apply:
        return
    # All encodes have been checked before any mutation. Preserve originals.
    for r in records:
        original = ROOT / r['original']
        backup = STAGE / 'originals' / r['original']
        backup.parent.mkdir(parents=True, exist_ok=True)
        backup.write_bytes(original.read_bytes())
        (ROOT / r['optimized']).write_bytes((STAGE / r['optimized']).read_bytes())
    # Update literal and interpolated Dart paths. Launcher inputs stay PNG.
    for folder in ['lib', 'test']:
        for source in (ROOT / folder).rglob('*.dart'):
            old = source.read_text(encoding='utf-8')
            new = re.sub(r'''(['"])(assets/images/[^'"\r\n]*?)\1''',
                         lambda m: m[0].replace('.png', '.webp'), old)
            if source.name == 'asset_usage_audit_test.dart':
                new = new.replace("endsWith('.png')", "endsWith('.webp')")
            for kept in KEEP_PNG:
                new = new.replace(kept.replace('.png', '.webp'), kept)
            if old != new:
                source.write_text(new, encoding='utf-8')
    manifest = ROOT / 'tools/game_assets_manifest.json'
    data = manifest.read_text(encoding='utf-8-sig').replace('.png', '.webp')
    manifest.write_text(data, encoding='utf-8')
    for r in records:
        (ROOT / r['original']).unlink()
    (ROOT / 'tools/image_optimization_report.json').write_text(
        json.dumps(report, indent=2), encoding='utf-8')
    print('Applied verified encodings and paths; originals retained in build.', flush=True)

if __name__ == '__main__':
    main()
