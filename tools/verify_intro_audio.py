"""Decode every supplied intro clip and report timing without changing audio."""
import array
import hashlib
import json
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'build/audio_tools'))
import imageio_ffmpeg

report = []
for path in sorted((ROOT / 'assets/audio/home_intro').glob('*.mp3')):
    decoded = subprocess.run([
        imageio_ffmpeg.get_ffmpeg_exe(), '-hide_banner', '-nostdin',
        '-loglevel', 'error', '-i', str(path), '-ar', '22050', '-ac', '1',
        '-f', 'f32le', 'pipe:1'], check=True, capture_output=True).stdout
    samples = array.array('f', decoded)
    peak = max(map(abs, samples))
    if peak <= 0:
        raise ValueError(f'Silent recording: {path.name}')
    active = [i for i, value in enumerate(samples) if abs(value) > peak * .02]
    report.append({
        'file': path.name, 'seconds': round(len(samples) / 22050, 3),
        'leadingSilenceSeconds': round(active[0] / 22050, 3),
        'trailingSilenceSeconds': round((len(samples) - active[-1]) / 22050, 3),
        'peak': round(peak, 4),
        'sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
    })
assert len(report) == 19, 'Expected 16 intro clips, two Home prompts and title chorus'
output = ROOT / 'tools/intro_audio_verification.json'
output.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
for row in report:
    print(f"{row['file']}: {row['seconds']}s, leading {row['leadingSilenceSeconds']}s, trailing {row['trailingSilenceSeconds']}s")
