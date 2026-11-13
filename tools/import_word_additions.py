"""Validate the supplied 20 CVC pairs and 28 Blending image/audio sets.

Reads the extracted folders in build/word_additions. All media are validated
before --apply adds files to assets; existing assets may not be overwritten.
MP3 bytes stay unchanged. Images become contained, lossless WebP, preserving
visible pixels and alpha after scaling. Speech is not independently transcribed.
"""
import argparse
import array
import hashlib
import json
import math
from pathlib import Path
import struct
import subprocess

ROOT = Path(__file__).resolve().parents[1]
STAGE = ROOT / 'build/word_additions'
FFMPEG = STAGE / 'tools/ffmpeg.exe'
CVC = 'dad pad nap tap den peg vet fed lid zip dip sip cot fog rod job hug cut rub tug'.split()
BLENDING = {
    5: 'stick dress glass crate skate chick bench swing'.split(),
    6: 'bottle button candle carrot flower hammer ladder spider magnet ribbon'.split(),
    7: 'blanket chicken dolphin giraffe hamster penguin balloon pumpkin trumpet tractor'.split(),
}
ALIASES = {
    ('stick', 'image'): 'strick.png',
    ('button', 'word'): 'word_buton.mp3',
    ('hamster', 'praise'): 'praise_hamester.mp3',
    ('tractor', 'image'): 'tracktor.png',
    ('trumpet', 'word'): 'word_tumpet.mp3',
}


def digest(data):
    return hashlib.sha256(data).hexdigest()


def decode(arguments, data):
    result = subprocess.run([
        str(FFMPEG), '-hide_banner', '-nostdin', '-v', 'error',
        '-xerror', '-err_detect', 'explode', *arguments,
    ], input=data, capture_output=True, check=True)
    if result.stderr.strip():
        raise ValueError(result.stderr.decode(errors='replace'))
    return result.stdout


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apply', action='store_true')
    args = parser.parse_args()
    assert FFMPEG.is_file(), 'Project FFmpeg decoder required'
    inputs = []
    seen = set()
    for lesson, groups in [('cvc', {3: CVC}), ('blending', BLENDING)]:
        folder = STAGE / ('cvc additions' if lesson == 'cvc' else 'blending addtions')
        supplied = {p for p in folder.rglob('*') if p.is_file()}
        expected_count = 40 if lesson == 'cvc' else 84
        assert len(supplied) == expected_count, (lesson, len(supplied))
        matched = set()
        for letters, words in groups.items():
            for word in words:
                for kind in (['word', 'praise'] if lesson == 'cvc' else ['word', 'praise', 'image']):
                    filename = (f'{word}.png' if kind == 'image' else f'{kind}_{word}.mp3')
                    filename = ALIASES.get((word, kind), filename)
                    if lesson == 'cvc' and word == 'dip' and kind == 'praise':
                        filename = 'praise-dip.mp3'
                    matches = [p for p in supplied if p.name.lower() == filename]
                    assert len(matches) == 1, (lesson, word, kind, matches)
                    source = matches[0]
                    assert source not in matched
                    matched.add(source)
                    target = (ROOT / f'assets/images/cvc_blending/{word}.webp' if kind == 'image'
                              else ROOT / f'assets/audio/{lesson}_lesson/{kind}-{word}.mp3')
                    assert (lesson, word, kind) not in seen
                    seen.add((lesson, word, kind))
                    inputs.append((lesson, word, kind, source, target))
        assert matched == supplied, f'Unexpected files in {lesson}'
    assert len(inputs) == 124
    originals = {p.relative_to(ROOT).as_posix(): digest(p.read_bytes())
                 for folder in ['assets/audio/cvc_lesson', 'assets/audio/blending_lesson',
                                'assets/images/cvc_blending']
                 for p in (ROOT / folder).iterdir() if p.is_file()}
    rows, outputs = [], {}
    for number, (lesson, word, kind, source, target) in enumerate(inputs, 1):
        data = source.read_bytes()
        row = {'lesson': lesson, 'word': word, 'kind': kind,
               'source': source.relative_to(ROOT).as_posix(),
               'sourceSha256': digest(data), 'sourceBytes': len(data),
               'target': target.relative_to(ROOT).as_posix()}
        if kind == 'image':
            assert data[:8] == b'\x89PNG\r\n\x1a\n', source
            width, height = struct.unpack('>II', data[16:24])
            assert 1 < width <= 8192 and 1 < height <= 8192
            raw = decode(['-i', 'pipe:0', '-frames:v', '1', '-f', 'rawvideo', '-pix_fmt', 'rgba', 'pipe:1'], data)
            assert len(raw) == width * height * 4
            row.update({'sourceWidth': width, 'sourceHeight': height,
                        'sourceTransparentPixels': raw[3::4].count(0)})
            scale = 'scale=w=min(768\\,iw):h=min(1024\\,ih):force_original_aspect_ratio=decrease:flags=lanczos'
            output = decode(['-i', 'pipe:0', '-frames:v', '1', '-vf', scale,
                             '-c:v', 'libwebp', '-lossless', '1', '-compression_level', '6',
                             '-f', 'webp', 'pipe:1'], data)
            expected = decode(['-i', 'pipe:0', '-frames:v', '1', '-vf', scale,
                               '-f', 'rawvideo', '-pix_fmt', 'rgba', 'pipe:1'], data)
            actual = decode(['-i', 'pipe:0', '-frames:v', '1', '-f', 'rawvideo', '-pix_fmt', 'rgba', 'pipe:1'], output)
            assert len(actual) == len(expected)
            assert actual[3::4] == expected[3::4]
            assert all(actual[i:i+3] == expected[i:i+3]
                       for i in range(0, len(expected), 4) if expected[i+3])
            row['transparentPixels'] = actual[3::4].count(0)
            thumbnails = STAGE / 'previews'
            thumbnails.mkdir(exist_ok=True)
            index = sum(r['kind'] == 'image' for r in rows)
            preview = decode(['-i', 'pipe:0', '-frames:v', '1', '-vf',
                              "scale=144:144:force_original_aspect_ratio=decrease,pad=160:190:(ow-iw)/2:8:color=white,"
                              "drawtext=fontfile='C\\:/Windows/Fonts/arial.ttf':"
                              f"text='{word.upper()}':fontsize=16:fontcolor=black:x=(w-tw)/2:y=h-28",
                              '-f', 'image2pipe', '-c:v', 'png', 'pipe:1'], output)
            (thumbnails / f'{index:02}.png').write_bytes(preview)
        else:
            output = data
            pcm = decode(['-i', 'pipe:0', '-map', '0:a:0', '-ar', '22050', '-ac', '1',
                          '-f', 'f32le', 'pipe:1'], data)
            samples = array.array('f', pcm)
            assert samples and all(math.isfinite(value) for value in samples)
            duration = len(samples) / 22050
            peak = max(map(abs, samples))
            rms = math.sqrt(sum(value * value for value in samples) / len(samples))
            assert .2 < duration < 20 and peak > .01 and rms > .001, source
            row.update({'durationSeconds': round(duration, 3),
                        'peakDbfs': round(20 * math.log10(peak), 2),
                        'rmsDbfs': round(20 * math.log10(rms), 2),
                        'nearFullScalePercent': round(100 * sum(abs(v) >= .999 for v in samples) / len(samples), 5)})
        if target.exists():
            assert target.read_bytes() == output, f'Refusing overwrite: {target}'
        outputs[target] = output
        row.update({'sha256': digest(output), 'bytes': len(output)})
        rows.append(row)
        if number % 20 == 0 or number == len(inputs):
            print(f'Validated {number}/{len(inputs)} media files', flush=True)
    assert len({r['sourceSha256'] for r in rows if r['kind'] != 'image'}) == 96
    assert all(not r['nearFullScalePercent'] for r in rows if r['kind'] != 'image'), 'Clipped audio needs review'
    mosaic = STAGE / 'contact_sheet.png'
    result = subprocess.run([str(FFMPEG), '-hide_banner', '-nostdin', '-v', 'error', '-y',
                             '-framerate', '1', '-i', str(STAGE / 'previews/%02d.png'),
                             '-vf', 'tile=7x4', '-frames:v', '1', str(mosaic)], capture_output=True, check=True)
    assert not result.stderr.strip()
    if args.apply:
        for target, output in outputs.items():
            target.write_bytes(output)
            assert digest(target.read_bytes()) == digest(output)
    assert all(digest((ROOT / name).read_bytes()) == expected for name, expected in originals.items())
    report = {'applied': args.apply, 'validatedCount': len(rows),
              'cvcWords': CVC, 'blendingWords': BLENDING,
              'originalHashes': originals, 'assets': rows,
              'bytesAdded': sum(map(len, outputs.values())),
              'sourceImageBytes': sum(r['sourceBytes'] for r in rows if r['kind'] == 'image'),
              'bundledImageBytes': sum(r['bytes'] for r in rows if r['kind'] == 'image'),
              'validation': 'Exact 20 CVC pairs and 28 Blending image/word/praise sets; strict full '
                            'FFmpeg decode; finite non-silent PCM, no full-scale clipping; unique '
                            'audio hashes; unchanged MP3s; lossless visible image pixels/alpha '
                            'after contained scaling; all existing assets preserved. Speech not '
                            'independently transcribed.'}
    report_path = ROOT / ('tools/word_additions_import.json' if args.apply else 'build/word_additions/validation.json')
    report_path.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({key: report[key] for key in ['applied', 'validatedCount', 'bytesAdded',
                                                'sourceImageBytes', 'bundledImageBytes']}, indent=2))


if __name__ == '__main__':
    main()
