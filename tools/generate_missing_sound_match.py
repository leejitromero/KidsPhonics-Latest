# Historical generator, retained for provenance only. See tools/README.md.
# Not part of the current validation or asset-replacement workflow.
"""
generate_missing_sound_match.py
────────────────────────────────
Generates ONLY the missing Sound Match hint MP3 files that don't exist yet.
Saves directly to assets/audio/phonics/sound_match/

Install dependency once:
    pip install gtts

Run from the project root:
    python tools/generate_missing_sound_match.py
"""

from pathlib import Path
from gtts import gTTS

OUTPUT_DIR = Path(__file__).parent.parent / "assets" / "audio" / "phonics" / "sound_match"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)


def make(text: str, filename: str) -> None:
    out = OUTPUT_DIR / filename
    if out.exists():
        print(f"  skip (exists): {filename}")
        return
    try:
        tts = gTTS(text=text, lang="en", tld="com", slow=True)
        tts.save(str(out))
        print(f"  ✓  {filename}")
    except Exception as e:
        print(f"  ✗  {filename} — {e}")


# Missing Medium hints
missing = [
    ("Nut! N sound. Nut!",               "hint_nut.mp3"),
    ("Octopus! O sound. Octopus!",        "hint_octopus.mp3"),
    ("Pig! P sound. Pig!",                "hint_pig.mp3"),
    ("Turtle! T sound. Turtle!",          "hint_turtle.mp3"),
    ("Xylophone! X sound. Xylophone!",    "hint_xylophone.mp3"),
    ("Yarn! Y sound. Yarn!",              "hint_yarn.mp3"),
]

if __name__ == "__main__":
    print(f"\nGenerating missing Sound Match hints → {OUTPUT_DIR}\n")
    for text, fn in missing:
        make(text, fn)
    print("\n✅ Done!\n")

