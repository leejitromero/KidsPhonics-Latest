"""Validate/import the user's 50 Blending image/word/praise sets.

Input: build/blending_expansion/new_words_bleding_img.zip.
MP3 bytes are preserved. PNGs are converted to lossless WebP, contained within
768x1024 without cropping/upscaling. Original PNGs remain in build for review.
Run without --apply to validate; --apply publishes only after all sets pass.
Spoken content is not independently transcribed by this technical check.
"""
import argparse
import array
import hashlib
import json
import math
from pathlib import Path
import struct
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[1]
GROUPS = {
    4: 'frog crab drum flag plum sled trap plug clam slug hand twig nest tent lamp belt mask desk vest milk'.split(),
    5: 'block clock brick truck plant clamp stamp crust stump flask skunk snail snake spoon brush shell shark train grape plane'.split(),
    6: 'rabbit kitten parrot turtle monkey donkey basket bucket pencil helmet'.split(),
}


def digest(data):
    return hashlib.sha256(data).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apply', action='store_true')
    args = parser.parse_args()
    stage = ROOT / 'build/blending_expansion'
    source = stage / 'new_words_bleding_img.zip'
    ffmpeg = next((ROOT / 'build/audio_tools/imageio_ffmpeg/binaries').glob('ffmpeg*.exe'))
    image_dir = ROOT / 'assets/images/cvc_blending'
    audio_dir = ROOT / 'assets/audio/blending_lesson'
    new_names = {w for words in GROUPS.values() for w in words}
    originals = {p.relative_to(ROOT).as_posix(): digest(p.read_bytes())
                 for folder in (image_dir, audio_dir) for p in folder.iterdir()
                 if p.is_file() and p.stem.split('-', 1)[-1] not in new_names}

    def run(arguments, data=None):
        result = subprocess.run([str(ffmpeg), '-hide_banner', '-nostdin', '-v', 'error',
                                 '-xerror', '-err_detect', 'explode', *arguments],
                                input=data, capture_output=True, check=True)
        if result.stderr.strip():
            raise ValueError(result.stderr.decode(errors='replace'))
        return result.stdout

    rows, outputs, seen = [], {}, set()
    with zipfile.ZipFile(source) as archive:
        files = {e.filename: e for e in archive.infolist() if not e.is_dir()}
        assert len(files) == 150
        for count, words in GROUPS.items():
            prefix = f'new_words_bleding_img/{count}_letters_blending/'
            img_folder = {4: '4letters_img', 5: '5letters_img_blending', 6: '6words_img_blending'}[count]
            for word in words:
                for kind in ('word', 'praise', 'image'):
                    name = (f'{prefix}{img_folder}/{word}.png' if kind == 'image' else
                            f'{prefix}{count}letters_audio_{kind}/' +
                            ('clock.mp3' if word == 'clock' and kind == 'word' else f'{kind}_{word}.mp3'))
                    assert name in files, f'Missing: {name}'
                    seen.add(name)
                    data = archive.read(name)
                    row = {'word': word, 'kind': kind, 'source': name,
                           'sourceSha256': digest(data), 'sourceBytes': len(data)}
                    if kind == 'image':
                        assert data[:8] == b'\x89PNG\r\n\x1a\n'
                        width, height = struct.unpack('>II', data[16:24])
                        assert 1 < width <= 8192 and 1 < height <= 8192
                        raw = run(['-i', 'pipe:0', '-frames:v', '1', '-f', 'rawvideo', '-pix_fmt', 'rgba', 'pipe:1'], data)
                        assert len(raw) == width * height * 4
                        alpha = raw[3::4]
                        row.update({'sourceWidth': width, 'sourceHeight': height,
                                    'sourceTransparentPixels': alpha.count(0)})
                        original_png = stage / 'original_images' / f'{word}.png'
                        original_png.parent.mkdir(parents=True, exist_ok=True)
                        original_png.write_bytes(data)
                        target = image_dir / f'{word}.webp'
                        scale = 'scale=w=min(768\\,iw):h=min(1024\\,ih):force_original_aspect_ratio=decrease:flags=lanczos'
                        output = run(['-i', 'pipe:0', '-frames:v', '1', '-vf', scale,
                                      '-c:v', 'libwebp', '-lossless', '1', '-compression_level', '6',
                                      '-f', 'webp', 'pipe:1'], data)
                        # Compare decoded pixels with the contained PNG rendition.
                        expected = run(['-i', 'pipe:0', '-frames:v', '1', '-vf', scale,
                                        '-f', 'rawvideo', '-pix_fmt', 'rgba', 'pipe:1'], data)
                        decoded = run(['-i', 'pipe:0', '-frames:v', '1', '-f', 'rawvideo', '-pix_fmt', 'rgba', 'pipe:1'], output)
                        # Invisible RGB may be discarded by WebP; alpha and visible RGB must match.
                        assert decoded[3::4] == expected[3::4]
                        assert all(decoded[i:i+3] == expected[i:i+3]
                                   for i in range(0, len(expected), 4) if expected[i+3])
                        row['transparentPixels'] = decoded[3::4].count(0)
                    else:
                        target = audio_dir / f'{kind}-{word}.mp3'
                        output = data
                        raw = run(['-i', 'pipe:0', '-map', '0:a:0', '-ar', '22050', '-ac', '1', '-f', 'f32le', 'pipe:1'], data)
                        samples = array.array('f', raw)
                        assert samples and all(math.isfinite(v) for v in samples)
                        duration = len(samples) / 22050
                        peak = max(map(abs, samples))
                        rms = math.sqrt(sum(v*v for v in samples) / len(samples))
                        assert .2 < duration < 20 and peak > .01 and rms > .001
                        row.update({'durationSeconds': round(duration, 3),
                                    'peakDbfs': round(20 * math.log10(peak), 2),
                                    'rmsDbfs': round(20 * math.log10(rms), 2),
                                    'nearFullScalePercent': round(100 * sum(abs(v) >= .999 for v in samples) / len(samples), 5)})
                    if target.exists():
                        assert target.read_bytes() == output, f'Refusing overwrite: {target}'
                    outputs[target] = output
                    row.update({'target': target.relative_to(ROOT).as_posix(),
                                'sha256': digest(output), 'bytes': len(output)})
                    rows.append(row)
        assert seen == set(files), 'Unexpected archive entries'
    assert len({r['sourceSha256'] for r in rows if r['kind'] != 'image'}) == 100
    if args.apply:
        for target, data in outputs.items():
            target.write_bytes(data)
            assert digest(target.read_bytes()) == digest(data)
        assert all(digest((ROOT / path).read_bytes()) == value for path, value in originals.items())
    report = {'sourceArchive': source.name, 'archiveSha256': digest(source.read_bytes()),
              'applied': args.apply, 'validatedCount': len(rows),
              'bytesAdded': sum(map(len, outputs.values())),
              'sourceImageBytes': sum(r['sourceBytes'] for r in rows if r['kind'] == 'image'),
              'bundledImageBytes': sum(r['bytes'] for r in rows if r['kind'] == 'image'),
              'originalHashes': originals,
              'validation': 'Exact 50 sets; ZIP CRC; strict full audio/image decode; non-silent finite PCM; '
                            'unique audio hashes; lossless visible image pixels and alpha after contained scaling; '
                            'unchanged MP3 bytes and original assets. Spoken content not independently transcribed.',
              'assets': rows}
    path = ROOT / ('tools/blending_expansion_import.json' if args.apply else 'build/blending_expansion/validation.json')
    path.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({key: report[key] for key in ('applied', 'validatedCount', 'bytesAdded', 'sourceImageBytes', 'bundledImageBytes')}, indent=2))


if __name__ == '__main__':
    main()
