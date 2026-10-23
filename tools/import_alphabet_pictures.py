"""Import the user's complete A-Z PNG collection without changing the artwork."""
import hashlib
import json
import re
import struct
import zipfile
from pathlib import Path

root = Path(__file__).resolve().parents[1]
source = Path(r'C:/Users/leeji/KidsPhonicsProject/IMAGES A-Z.zip')
destination = root / 'assets/images/lesson_frames'
digest = lambda data: hashlib.sha256(data).hexdigest().upper()
images = []
with zipfile.ZipFile(source) as archive:
    assert archive.testzip() is None, 'ZIP checksum failure'
    for entry in archive.infolist():
        if entry.is_dir():
            continue
        path = Path(entry.filename)
        assert len(path.parts) == 2 and path.parts[0] == 'IMAGES A-Z', entry.filename
        match = re.fullmatch(r'([a-z]+)_([A-Z])([12]?)\.png', path.name)
        assert match, f'Unexpected entry: {entry.filename}'
        word, letter, variant = match.groups()
        assert word[0].upper() == letter, path.name
        data = archive.read(entry)
        assert data.startswith(b'\x89PNG\r\n\x1a\n'), path.name
        width, height = struct.unpack('>II', data[16:24])
        output = destination / path.name
        if output.exists():
            assert output.read_bytes() == data, f'Existing file differs: {output}'
        images.append((output, data, dict(letter=letter, word=word,
            variant=variant or 'base', path=output.relative_to(root).as_posix(),
            sha256=digest(data), bytes=len(data), width=width, height=height,
            pngColorType=data[25])))
assert len(images) == 78
assert len({item[0].name for item in images}) == 78
for letter in 'ABCDEFGHIJKLMNOPQRSTUVWXYZ':
    assert {item[2]['variant'] for item in images if item[2]['letter'] == letter} == {'base', '1', '2'}, letter
destination.mkdir(parents=True, exist_ok=True)
for path, data, _ in images:
    path.write_bytes(data)
report = dict(source=str(source), sourceSHA256=digest(source.read_bytes()),
    letters=26, images=78, artworkUnmodified=True,
    files=[item[2] for item in images])
(root / 'tools/alphabet_picture_import.json').write_text(json.dumps(report, indent=2) + '\n')
print('Imported 78 original PNGs: complete A-Z, 3 images per letter.')
