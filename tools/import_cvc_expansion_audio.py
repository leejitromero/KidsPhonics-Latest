"""Validate the supplied 33 word/praise pairs, then import unchanged MP3s.

Run from the project root after placing the two supplied ZIPs in
build/cvc_expansion_audio. Pass --apply to copy validated files into assets.
Requires the existing FFmpeg binary in build/audio_tools/imageio_ffmpeg/binaries.
Spoken content is not independently transcribed by this technical validation.
"""

import argparse
import array
import hashlib
import json
import math
from pathlib import Path
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[1]
WORDS = """mat rat can jam pet wet get let set bin tin fin win big hit fit kid
hot dot hop pop nod got not lot bun tub jug gum pup cub mud fun""".split()


def digest(data):
    return hashlib.sha256(data).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apply', action='store_true')
    args = parser.parse_args()
    staging = ROOT / 'build/cvc_expansion_audio'
    target_dir = ROOT / 'assets/audio/cvc_lesson'
    ffmpeg = next((ROOT / 'build/audio_tools/imageio_ffmpeg/binaries').glob(
        'ffmpeg*.exe'))
    originals = {p.name: digest(p.read_bytes()) for p in target_dir.glob('*.mp3')
                 if p.stem.split('-', 1)[-1] not in WORDS}
    assert len(originals) == 34, 'Expected 17 original pairs to preserve'
    rows, payloads, archives = [], {}, []
    for kind in ('word', 'praise'):
        source = staging / f'new_{kind}_cvc.zip'
        archives.append({'file': source.name, 'sha256': digest(source.read_bytes())})
        with zipfile.ZipFile(source) as archive:
            files = [e for e in archive.infolist() if not e.is_dir()]
            expected = {f'new_{kind}_cvc/{kind}_{w}.mp3' for w in WORDS}
            assert len(files) == len(expected) == 33
            assert {e.filename for e in files} == expected, 'Unexpected/missing files'
            for word in WORDS:
                name = f'new_{kind}_cvc/{kind}_{word}.mp3'
                data = archive.read(name)  # Also validates ZIP CRC.
                result = subprocess.run([
                    str(ffmpeg), '-hide_banner', '-nostdin', '-v', 'error',
                    '-xerror', '-err_detect', 'explode', '-i', 'pipe:0',
                    '-map', '0:a:0', '-ar', '22050', '-ac', '1',
                    '-f', 'f32le', 'pipe:1',
                ], input=data, capture_output=True, check=True)
                assert not result.stderr.strip(), result.stderr.decode(errors='replace')
                samples = array.array('f', result.stdout)
                assert samples and all(math.isfinite(v) for v in samples)
                duration = len(samples) / 22050
                peak = max(map(abs, samples))
                rms = math.sqrt(sum(v * v for v in samples) / len(samples))
                assert .2 < duration < 20, f'Invalid duration: {name}'
                assert peak > .01 and rms > .001, f'Silent/very quiet audio: {name}'
                active = [i for i, v in enumerate(samples) if abs(v) > peak * .02]
                target = target_dir / f'{kind}-{word}.mp3'
                if target.exists():
                    assert target.read_bytes() == data, f'Refusing overwrite: {target}'
                payloads[target] = data
                rows.append({
                    'word': word, 'kind': kind, 'source': name,
                    'target': target.relative_to(ROOT).as_posix(),
                    'bytes': len(data), 'sha256': digest(data),
                    'durationSeconds': round(duration, 3),
                    'peakDbfs': round(20 * math.log10(peak), 2),
                    'rmsDbfs': round(20 * math.log10(rms), 2),
                    'nearFullScalePercent': round(
                        100 * sum(abs(v) >= .999 for v in samples) / len(samples), 5),
                    'leadingSilenceSeconds': round(active[0] / 22050, 3),
                    'trailingSilenceSeconds': round(
                        (len(samples) - 1 - active[-1]) / 22050, 3),
                })
    assert len({r['sha256'] for r in rows}) == 66, 'Duplicate recording bytes'
    report = {
        'archives': archives, 'validatedCount': len(rows),
        'imported': args.apply, 'bytesAdded': sum(map(len, payloads.values())),
        'originalCountPreserved': len(originals), 'originalHashes': originals,
        'validation': 'Exact filenames and 33 pairs; ZIP CRC; full strict FFmpeg '
                      'decode; finite, non-silent PCM; duration, peak and RMS; '
                      'unique file hashes. Imported MP3 bytes are unchanged. '
                      'Spoken content has not been independently transcribed.',
        'recordings': rows,
    }
    if args.apply:
        for target, data in payloads.items():
            target.write_bytes(data)
            assert digest(target.read_bytes()) == digest(data)
        assert all(digest((target_dir / name).read_bytes()) == value
                   for name, value in originals.items())
    output = ROOT / ('tools/cvc_expansion_audio_import.json' if args.apply else
                     'build/cvc_expansion_audio/validation.json')
    output.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({
        'validated': len(rows), 'imported': args.apply,
        'bytesAdded': report['bytesAdded'],
        'originalFilesPreserved': len(originals),
        'durationRangeSeconds': [min(r['durationSeconds'] for r in rows),
                                 max(r['durationSeconds'] for r in rows)],
        'peakRangeDbfs': [min(r['peakDbfs'] for r in rows),
                          max(r['peakDbfs'] for r in rows)],
        'nearFullScaleSamples': any(r['nearFullScalePercent'] for r in rows),
        'report': str(output),
    }, indent=2))


if __name__ == '__main__':
    main()
