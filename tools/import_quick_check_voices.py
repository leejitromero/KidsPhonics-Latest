"""Import and balance the supplied Quick Check recordings (no generated speech)."""
import argparse
import array
import hashlib
import json
import math
from pathlib import Path
import zipfile
from import_home_voices import ROOT, RATE, measure, encode, run

FILES = {key: key + '.mp3' for key in [
    'intro', 'match', 'sound', 'spelling', 'hunt', 'saved', 'mastered', 'practice']}
FILES.update({'picture-beginning': 'picture-beggining.mp3',
              'picture-middle': 'picture-middle.mp3', 'picture-end': 'picture-ending.mp3'})


def build(zip_path):
    stage = ROOT / 'build/quick_check_voice_import/originals'
    output = ROOT / 'assets/audio/quick_check'
    stage.mkdir(parents=True, exist_ok=True)
    output.mkdir(parents=True, exist_ok=True)
    report = {}
    with zipfile.ZipFile(zip_path) as source:
        for key, name in FILES.items():
            entries = [entry for entry in source.infolist()
                       if not entry.is_dir() and Path(entry.filename).name == name]
            if len(entries) != 1:
                raise ValueError(f'Expected one supplied file: {name}')
            data = source.read(entries[0])
            original = stage / name
            original.write_bytes(data)
            before = measure(original)
            destination = output / (key + '.mp3')
            gain = -14 - before['activeRmsDbfs']
            for _ in range(6):
                encode([original], f'[0:a]volume={gain:.6f}dB,'
                       'alimiter=limit=0.794328:level=false:latency=true[out]', destination)
                after = measure(destination)
                error = -14 - after['activeRmsDbfs']
                if abs(error) <= .6:
                    break
                gain += error
            if abs(error) > .6 or abs(before['seconds'] - after['seconds']) > .002:
                raise ValueError(f'Failed balance/duration check: {key}')
            pcm = array.array('f', run(['-i', str(destination), '-ar', str(RATE * 4),
                                       '-ac', '1', '-f', 'f32le', 'pipe:1']))
            peak = 20 * math.log10(max(abs(sample) for sample in pcm))
            if peak > -.5:
                raise ValueError(f'Insufficient peak headroom: {key}')
            report[key] = {'source': entries[0].filename,
                           'sourceSHA256': hashlib.sha256(data).hexdigest(),
                           'asset': destination.relative_to(ROOT).as_posix(),
                           'assetSHA256': hashlib.sha256(destination.read_bytes()).hexdigest(),
                           'before': before, 'after': after,
                           'oversampledPeakDbfs': peak}
    (ROOT / 'tools/quick_check_voice_import_report.json').write_text(
        json.dumps(report, indent=2) + '\n', encoding='utf-8')
    print(f'Imported {len(report)} recordings, timing preserved, levels balanced, no clipping.')
    print(f'Total bundled size: {sum(p.stat().st_size for p in output.glob("*.mp3"))} bytes')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('zip_path', type=Path)
    build(parser.parse_args().zip_path)
