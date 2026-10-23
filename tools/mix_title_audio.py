"""Mix the four supplied title voices from sample zero into one startup cue."""
import array
import hashlib
import json
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'build/audio_tools'))
import imageio_ffmpeg

ffmpeg = imageio_ffmpeg.get_ffmpeg_exe()
inputs = [ROOT / f'tools/title_audio_sources/kidsphonics_intro_{i:02}.mp3'
          for i in range(1, 5)]
sample_rate = 44100
decoded = []
for path in inputs:
    raw = subprocess.run([
        ffmpeg, '-hide_banner', '-nostdin', '-loglevel', 'error',
        '-i', str(path), '-ar', str(sample_rate), '-ac', '1',
        '-f', 'f32le', 'pipe:1'], check=True, capture_output=True).stdout
    samples = array.array('f', raw)
    if not samples or max(map(abs, samples)) == 0:
        raise ValueError(f'Empty or silent title voice: {path.name}')
    decoded.append(samples)

# All voices start at the same sample, at equal gain. Keeping a fixed divisor
# also avoids a volume jump when the shorter recordings finish.
mix = array.array('f', (sum(s[i] if i < len(s) else 0 for s in decoded) / 4
                      for i in range(max(map(len, decoded)))))
peak = max(map(abs, mix))
assert 0 < peak < 1, 'Title chorus must not clip'
output = ROOT / 'assets/audio/home_intro/kidsphonics_title_chorus.mp3'
subprocess.run([
    ffmpeg, '-y', '-hide_banner', '-nostdin', '-loglevel', 'error',
    '-f', 'f32le', '-ar', str(sample_rate), '-ac', '1', '-i', 'pipe:0',
    '-codec:a', 'libmp3lame', '-b:a', '192k', str(output)],
    input=mix.tobytes(), check=True)
report = {
    'inputs': [{'file': p.name, 'sha256': hashlib.sha256(p.read_bytes()).hexdigest(),
                'seconds': round(len(s) / sample_rate, 3),
                'startSample': 0, 'gain': 0.25}
               for p, s in zip(inputs, decoded)],
    'output': str(output.relative_to(ROOT)).replace('\\', '/'),
    'outputSha256': hashlib.sha256(output.read_bytes()).hexdigest(),
    'seconds': round(len(mix) / sample_rate, 3),
    'unencodedPeak': round(peak, 5),
}
(ROOT / 'tools/title_audio_mix_verification.json').write_text(
    json.dumps(report, indent=2) + '\n', encoding='utf-8')
print(json.dumps(report, indent=2))
