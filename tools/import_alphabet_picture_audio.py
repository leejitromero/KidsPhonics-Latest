"""Import the user's A-Z sentence recordings, preserving their original bytes."""
import hashlib
import json
import re
import zipfile
from pathlib import Path

root = Path(__file__).resolve().parents[1]
source = root / 'build/A_Z_sounds_received.zip'
destination = root / 'assets/audio/alphabet_pictures'
digest = lambda data: hashlib.sha256(data).hexdigest().upper()


def mp3_frames(data):
    offset = 0
    if data[:3] == b'ID3':
        size = 0
        for value in data[6:10]:
            assert value < 128, 'Invalid ID3 size'
            size = (size << 7) | value
        offset = size + 10 + (10 if data[5] & 16 else 0)
    frames = 0
    seconds = 0
    rates = set()
    while offset < len(data):
        if len(data) - offset == 128 and data[offset:offset+3] == b'TAG':
            offset += 128
            break
        assert len(data) - offset >= 4, 'Truncated MPEG header'
        header = int.from_bytes(data[offset:offset+4], 'big')
        assert header >> 21 == 0x7ff, f'Invalid MPEG sync at byte {offset}'
        version, layer = (header >> 19) & 3, (header >> 17) & 3
        rate, sample = (header >> 12) & 15, (header >> 10) & 3
        assert version != 1 and layer == 1 and 0 < rate < 15 and sample < 3
        bitrate = ([0,32,40,48,56,64,80,96,112,128,160,192,224,256,320]
            if version == 3 else [0,8,16,24,32,40,48,56,64,80,96,112,128,144,160])[rate]
        sample_rate = [44100,48000,32000][sample] // {3:1,2:2,0:4}[version]
        length = (144000 if version == 3 else 72000) * bitrate // sample_rate
        length += (header >> 9) & 1
        assert offset + length <= len(data), 'Truncated MPEG frame'
        offset += length
        frames += 1
        seconds += (1152 if version == 3 else 576) / sample_rate
        rates.add(sample_rate)
    assert frames > 0 and offset == len(data)
    return dict(mpegFrames=frames, frameDurationSeconds=round(seconds, 3),
        sampleRatesHz=sorted(rates))


items = []
with zipfile.ZipFile(source) as archive:
    assert archive.testzip() is None, 'ZIP checksum failure'
    for entry in archive.infolist():
        if entry.is_dir():
            continue
        path = Path(entry.filename)
        assert len(path.parts) == 2 and path.parts[0] == 'A_Z_sounds'
        assert re.fullmatch(r'[A-Za-z]\.mp3', path.name), path.name
        letter = path.stem.upper()
        data = archive.read(entry)
        output = destination / path.name
        if output.exists():
            assert output.read_bytes() == data, f'Existing recording differs: {output}'
        items.append((output, data, dict(letter=letter, original=entry.filename,
            path=output.relative_to(root).as_posix(), sha256=digest(data),
            bytes=len(data), **mp3_frames(data))))
assert len(items) == 26
assert {item[2]['letter'] for item in items} == set('ABCDEFGHIJKLMNOPQRSTUVWXYZ')
assert len({item[2]['sha256'] for item in items}) == 26
destination.mkdir(parents=True, exist_ok=True)
for output, data, _ in items:
    output.write_bytes(data)
report = dict(source=r'C:/Users/leeji/Downloads/A_Z_sounds.zip',
    sourceSHA256=digest(source.read_bytes()), recordings=26, audioUnmodified=True,
    mpegFramesValidated=True, files=[item[2] for item in items])
(root / 'tools/alphabet_picture_audio_import.json').write_text(json.dumps(report, indent=2)+'\n')
print('Imported all 26 original A-Z MP3s; all MPEG frames and ZIP checksums valid.')
for _, _, item in items:
    print(item['letter'], item['frameDurationSeconds'], item['path'])
