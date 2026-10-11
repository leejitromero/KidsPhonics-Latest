"""Build one synchronized cheer and four balanced menu clips from supplied MP3s.

Originals stay in build/, outside Flutter assets. Requires imageio-ffmpeg in
build/audio_tools. Re-run against originals to avoid cumulative encoding loss.
"""
import array
import hashlib
import json
import math
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'build/audio_tools'))
import imageio_ffmpeg

FFMPEG = imageio_ffmpeg.get_ffmpeg_exe()
SOURCE = ROOT / 'build/home_voice_import/originals'
OUTPUT = ROOT / 'assets/audio/home'
RATE = 44100


def run(args):
    return subprocess.run([FFMPEG, '-hide_banner', '-nostdin', '-loglevel',
                           'error', *args], check=True, capture_output=True).stdout


def measure(path):
    pcm = array.array('f', run(['-i', str(path), '-ar', str(RATE), '-ac', '1',
                               '-f', 'f32le', 'pipe:1']))
    peak = max(abs(x) for x in pcm)
    if peak == 0:
        raise ValueError(f'Silent input: {path}')
    blocks = [(i, sum(x*x for x in pcm[i:i+882]) / len(pcm[i:i+882]))
              for i in range(0, len(pcm), 882)]
    active = [(i, e) for i, e in blocks if math.sqrt(e) > peak * .02]
    return {'seconds': len(pcm) / RATE, 'onsetSeconds': active[0][0] / RATE,
            'activeRmsDbfs': 10 * math.log10(sum(e for _, e in active) / len(active)),
            'peakDbfs': 20 * math.log10(peak)}


def encode(inputs, graph, destination):
    args = ['-y']
    for source in inputs:
        args += ['-i', str(source)]
    run(args + ['-filter_complex', graph, '-map', '[out]', '-map_metadata', '-1',
                '-ar', str(RATE), '-ac', '1', '-c:a', 'libmp3lame', '-b:a', '128k',
                str(destination)])


def build():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    intro = [SOURCE / f'intro{suffix}.mp3' for suffix in ['', '1', '2', '3']]
    stats = [measure(path) for path in intro]
    filters = []
    for i, stat in enumerate(stats):
        # Align spoken onsets, retaining 10ms of room before the first syllable.
        start = max(0, stat['onsetSeconds'] - .01)
        gain = -18 - stat['activeRmsDbfs']
        filters.append(f'[{i}:a]atrim=start={start:.4f},asetpts=PTS-STARTPTS,'
                       f'volume={gain:.5f}dB[v{i}]')
    base = ';'.join(filters) + ';[v0][v1][v2][v3]amix=inputs=4:duration=longest:normalize=0[mix]'
    mixed = OUTPUT / 'kidsphonics_intro.mp3'
    gain = 0.0
    for _ in range(4):
        encode(intro, base + f';[mix]volume={gain:.5f}dB,'
               'alimiter=limit=0.794328:level=false:latency=true[out]', mixed)
        measured = measure(mixed)
        error = -14 - measured['activeRmsDbfs']
        if abs(error) < .6:
            break
        gain += error
    report = {'introInputs': [dict(filename=p.name, sha256=hashlib.sha256(p.read_bytes()).hexdigest(),
                                  **s) for p, s in zip(intro, stats)],
              'introMix': measure(mixed), 'menu': {}}
    for name, original in [('lessons', 'lesson.mp3'), ('games', 'games_voice.mp3'),
                           ('progress', 'progress_voice.mp3'), ('parents', 'parents_voice.mp3')]:
        source = SOURCE / original
        before = measure(source)
        target = OUTPUT / f'{name}_voice.mp3'
        encode([source], f'[0:a]volume={-14-before["activeRmsDbfs"]:.5f}dB,'
               'alimiter=limit=0.794328:level=false:latency=true[out]', target)
        after = measure(target)
        if abs(before['seconds'] - after['seconds']) > .002:
            raise ValueError(f'Duration changed: {name}')
        report['menu'][name] = {'before': before, 'after': after}
    for path in OUTPUT.glob('*.mp3'):
        # Oversampling catches MP3 peaks between the original samples.
        pcm = array.array('f', run(['-i', str(path), '-ar', str(RATE * 4),
                                   '-ac', '1', '-f', 'f32le', 'pipe:1']))
        peak = 20 * math.log10(max(abs(x) for x in pcm))
        if peak > -.5:
            raise ValueError(f'Insufficient headroom: {path}: {peak}')
    (ROOT / 'tools/home_voice_import_report.json').write_text(
        json.dumps(report, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    build()
