"""Balance existing letter recordings; preserve originals and playback timing.

Install imageio-ffmpeg into build/audio_tools. Run without --apply to stage and
verify all 52 recordings, then --apply to replace assets. Repeated runs always
use the preserved originals, avoiding cumulative MP3 encoding loss.
"""

import argparse
import array
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
import math
from pathlib import Path
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'build/audio_tools'))
import imageio_ffmpeg

FFMPEG = imageio_ffmpeg.get_ffmpeg_exe()
STAGE = ROOT / 'build/letter_audio_balance'
TARGET_DB = -14.0
LIMIT_DB = -2.0
RATE = 44100
CHANNELS = 2


def run(arguments):
    return subprocess.run(
        [FFMPEG, '-hide_banner', '-nostdin', '-loglevel', 'error', *arguments],
        check=True, capture_output=True,
    ).stdout


def measure(path):
    samples = array.array('f', run([
        '-i', str(path), '-ar', str(RATE), '-ac', str(CHANNELS),
        '-f', 'f32le', 'pipe:1',
    ]))
    peak = max(abs(sample) for sample in samples)
    if not peak:
        raise ValueError(f'Silent recording: {path}')
    # Short consonants cannot reliably use a 400 ms gated LUFS measurement.
    # Measure energy over active 20 ms blocks, excluding leading/trailing silence.
    block_size = round(RATE * .02) * CHANNELS
    energies = []
    for start in range(0, len(samples), block_size):
        block = samples[start:start + block_size]
        energy = sum(sample * sample for sample in block) / len(block)
        if math.sqrt(energy) > peak * .02:
            energies.append(energy)
    rms = math.sqrt(sum(energies) / len(energies))
    # Oversampled decoded peaks catch MP3/inter-sample overshoot as well.
    oversampled = array.array('f', run([
        '-i', str(path), '-ar', str(RATE * 4), '-ac', str(CHANNELS),
        '-f', 'f32le', 'pipe:1',
    ]))
    return dict(
        activeRmsDbfs=20 * math.log10(rms),
        peakDbfs=20 * math.log10(peak),
        oversampledPeakDbfs=20 * math.log10(max(abs(x) for x in oversampled)),
        samplesPerChannel=len(samples) // CHANNELS,
        seconds=len(samples) / CHANNELS / RATE,
    )


def balance(asset):
    relative = asset.relative_to(ROOT)
    backup = STAGE / 'originals' / relative
    if not backup.exists():
        backup.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(asset, backup)
    before = measure(backup)
    destination = STAGE / 'normalized' / relative
    destination.parent.mkdir(parents=True, exist_ok=True)
    gain = TARGET_DB - before['activeRmsDbfs']
    for _ in range(6):
        run([
            '-y', '-i', str(backup), '-map', '0:a:0', '-map_metadata', '-1',
            '-af', f'volume={gain:.6f}dB,'
            f'alimiter=limit={10 ** (LIMIT_DB / 20):.8f}:'
            'attack=5:release=50:level=false:latency=true',
            '-ar', str(RATE), '-c:a', 'libmp3lame', '-b:a', '192k',
            str(destination),
        ])
        after = measure(destination)
        error = TARGET_DB - after['activeRmsDbfs']
        if abs(error) <= .6:
            break
        gain += error
    if abs(error) > .6:
        raise ValueError(f'Could not balance {relative}: {after}')
    if after['oversampledPeakDbfs'] > -.5:
        raise ValueError(f'Insufficient peak headroom: {relative}: {after}')
    if abs(before['samplesPerChannel'] - after['samplesPerChannel']) > 1:
        raise ValueError(f'Playback duration changed: {relative}')
    return dict(
        asset=relative.as_posix(), gainDb=round(gain, 3),
        before=before, after=after,
        originalSha256=hashlib.sha256(backup.read_bytes()).hexdigest(),
        normalizedSha256=hashlib.sha256(destination.read_bytes()).hexdigest(),
        originalBytes=backup.stat().st_size,
        normalizedBytes=destination.stat().st_size,
    )


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apply', action='store_true')
    args = parser.parse_args()
    audio_root = ROOT / 'assets/audio/phonics/lesson_audio'
    assets = sorted([*audio_root.glob('letters/*.mp3'),
                     *audio_root.glob('sounds/*.mp3')])
    if len(assets) != 52:
        raise ValueError(f'Expected 26 letter names and 26 sounds; got {len(assets)}')
    with ThreadPoolExecutor(max_workers=4) as pool:
        records = list(pool.map(balance, assets))
    report = dict(
        targetActiveRmsDbfs=TARGET_DB, limiterCeilingDbfs=LIMIT_DB,
        maximumMeasuredOversampledPeakDbfs=max(
            r['after']['oversampledPeakDbfs'] for r in records),
        beforeRangeDbfs=[min(r['before']['activeRmsDbfs'] for r in records),
                         max(r['before']['activeRmsDbfs'] for r in records)],
        afterRangeDbfs=[min(r['after']['activeRmsDbfs'] for r in records),
                        max(r['after']['activeRmsDbfs'] for r in records)],
        durationPreserved=True, applied=args.apply, recordings=records,
    )
    # Validate every output before replacing any app asset.
    if args.apply:
        for record in records:
            shutil.copy2(STAGE / 'normalized' / record['asset'],
                         ROOT / record['asset'])
    (ROOT / 'tools/letter_audio_balance_report.json').write_text(
        json.dumps(report, indent=2), encoding='utf-8')
    print(json.dumps({k: v for k, v in report.items() if k != 'recordings'}, indent=2))


if __name__ == '__main__':
    main()
