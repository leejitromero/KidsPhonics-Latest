# Historical generator, retained for provenance only. See tools/README.md.
# Not part of the current validation or asset-replacement workflow.
"""
generate_phonics_audio.py
─────────────────────────
Generates all pre-recorded phonics MP3 files for Kidsphonics using
gTTS (Google Text-to-Speech) — free, no API key required.

Output folder: assets/audio/phonics/

Install dependency once:
    pip install gtts

Run from the project root:
    python tools/generate_phonics_audio.py
"""

from pathlib import Path
from gtts import gTTS

OUTPUT_DIR = Path(__file__).parent.parent / "assets" / "audio" / "phonics"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

# ── gTTS helper ────────────────────────────────────────────────────────────
def make(text: str, filename: str, slow: bool = True) -> None:
    """Generate a slow, clear MP3 for kids."""
    out = OUTPUT_DIR / filename
    if out.exists():
        print(f"  skip (exists): {filename}")
        return
    try:
        tts = gTTS(text=text, lang="en", tld="com", slow=slow)
        tts.save(str(out))
        print(f"  ✓  {filename}")
    except Exception as e:
        print(f"  ✗  {filename} — {e}")


# ── Letter sounds (matches letter_data.dart sound field) ──────────────────
letter_sounds = [
    ("A says Ahh! Like Apple!",       "letter_a.mp3"),
    ("B says Buh! Like Banana!",      "letter_b.mp3"),
    ("C says Cuh! Like Cat!",         "letter_c.mp3"),
    ("D says Duh! Like Dog!",         "letter_d.mp3"),
    ("E says Ehh! Like Egg!",         "letter_e.mp3"),
    ("F says Fff! Like Fish!",        "letter_f.mp3"),
    ("G says Guh! Like Grapes!",      "letter_g.mp3"),
    ("H says Hhh! Like House!",       "letter_h.mp3"),
    ("I says Ihh! Like Ice Cream!",   "letter_i.mp3"),
    ("J says Juh! Like Juice!",       "letter_j.mp3"),
    ("K says Kuh! Like Kite!",        "letter_k.mp3"),
    ("L says Lll! Like Lion!",        "letter_l.mp3"),
    ("M says Mmm! Like Moon!",        "letter_m.mp3"),
    ("N says Nnn! Like Nut!",         "letter_n.mp3"),
    ("O says Ohh! Like Octopus!",     "letter_o.mp3"),
    ("P says Puh! Like Pig!",         "letter_p.mp3"),
    ("Q says Kww! Like Queen!",       "letter_q.mp3"),
    ("R says Rrr! Like Rainbow!",     "letter_r.mp3"),
    ("S says Sss! Like Sun!",         "letter_s.mp3"),
    ("T says Tuh! Like Turtle!",      "letter_t.mp3"),
    ("U says Uhh! Like Umbrella!",    "letter_u.mp3"),
    ("V says Vvv! Like Violin!",      "letter_v.mp3"),
    ("W says Www! Like Whale!",       "letter_w.mp3"),
    ("X says Ksss! Like Xylophone!",  "letter_x.mp3"),
    ("Y says Yyy! Like Yarn!",        "letter_y.mp3"),
    ("Z says Zzz! Like Zebra!",       "letter_z.mp3"),
]

# ── Single letter names (A, B, C … for alphabet order game) ───────────────
letter_names = [
    (letter, f"name_{letter.lower()}.mp3")
    for letter in "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
]

# ── Words ──────────────────────────────────────────────────────────────────
words = [
    ("Apple",     "word_apple.mp3"),
    ("Banana",    "word_banana.mp3"),
    ("Cat",       "word_cat.mp3"),
    ("Dog",       "word_dog.mp3"),
    ("Egg",       "word_egg.mp3"),
    ("Fish",      "word_fish.mp3"),
    ("Grapes",    "word_grapes.mp3"),
    ("House",     "word_house.mp3"),
    ("Ice Cream", "word_ice_cream.mp3"),
    ("Juice",     "word_juice.mp3"),
    ("Kite",      "word_kite.mp3"),
    ("Lion",      "word_lion.mp3"),
    ("Moon",      "word_moon.mp3"),
    ("Nut",       "word_nut.mp3"),
    ("Octopus",   "word_octopus.mp3"),
    ("Pig",       "word_pig.mp3"),
    ("Queen",     "word_queen.mp3"),
    ("Rainbow",   "word_rainbow.mp3"),
    ("Sun",       "word_sun.mp3"),
    ("Turtle",    "word_turtle.mp3"),
    ("Umbrella",  "word_umbrella.mp3"),
    ("Violin",    "word_violin.mp3"),
    ("Whale",     "word_whale.mp3"),
    ("Xylophone", "word_xylophone.mp3"),
    ("Yarn",      "word_yarn.mp3"),
    ("Zebra",     "word_zebra.mp3"),
]

# ── Praise / feedback ─────────────────────────────────────────────────────
praise = [
    ("Correct!",         "praise_correct.mp3",    False),
    ("Great job!",       "praise_great_job.mp3",  False),
    ("Try again!",       "feedback_try_again.mp3",False),
    ("Wonderful!",       "praise_wonderful.mp3",  False),
    ("All pairs found!", "praise_all_pairs.mp3",  False),
]

# ── Sound Match voice hints ────────────────────────────────────────────────
sound_hints = [
    ("Apple! Ahh... Apple!",         "hint_apple.mp3"),
    ("Dog! Duh... Dog!",             "hint_dog.mp3"),
    ("Sun! Sss... Sun!",             "hint_sun.mp3"),
    ("Fish! Fff... Fish!",           "hint_fish.mp3"),
    ("Rainbow! Rrr... Rainbow!",     "hint_rainbow.mp3"),
    ("Banana! Buh... Banana!",       "hint_banana.mp3"),
    ("Moon! Mmm... Moon!",           "hint_moon.mp3"),
    ("Whale! Www... Whale!",         "hint_whale.mp3"),
    ("Zebra! Zzz... Zebra!",         "hint_zebra.mp3"),
    ("Queen! Kww... Queen!",         "hint_queen.mp3"),
    ("Violin! Vvv... Violin!",       "hint_violin.mp3"),
    ("Cat! Cuh... Cat!",             "hint_cat.mp3"),
    ("Egg! Ehh... Egg!",             "hint_egg.mp3"),
    ("Kite! Kuh... Kite!",           "hint_kite.mp3"),
    ("Lion! Lll... Lion!",           "hint_lion.mp3"),
    ("Umbrella! Uhh... Umbrella!",   "hint_umbrella.mp3"),
    ("Grapes! Guh... Grapes!",       "hint_grapes.mp3"),
    ("House! Hhh... House!",         "hint_house.mp3"),
    # ── Missing Medium/Hard hints ──
    ("Nut! Nnn... Nut!",             "hint_nut.mp3"),
    ("Octopus! Ohh... Octopus!",     "hint_octopus.mp3"),
    ("Pig! Puh... Pig!",             "hint_pig.mp3"),
    ("Turtle! Tuh... Turtle!",       "hint_turtle.mp3"),
    ("Xylophone! Ksss... Xylophone!","hint_xylophone.mp3"),
    ("Yarn! Yyy... Yarn!",           "hint_yarn.mp3"),
    ("Umbrella! Uhh... Umbrella!",   "hint_umbrella.mp3"),
    ("Violin! Vvv... Violin!",       "hint_violin.mp3"),
    ("Rainbow! Rrr... Rainbow! The first sound is R!", "quiz_rainbow.mp3"),
    ("Dog! Duh... Dog! The first sound is D!",         "quiz_dog.mp3"),
    ("Sun! Sss... Sun! The first sound is S!",         "quiz_sun.mp3"),
    ("Apple! Ahh... Apple! The first sound is A!",     "quiz_apple.mp3"),
    ("Fish! Fff... Fish! The first sound is F!",       "quiz_fish.mp3"),
]

# ── Run ────────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    print(f"\nGenerating phonics audio → {OUTPUT_DIR}\n")

    print("── Letter sounds ──")
    for text, fn in letter_sounds:
        make(text, fn, slow=True)

    print("\n── Letter names ──")
    for text, fn in letter_names:
        make(text, fn, slow=False)

    print("\n── Words ──")
    for text, fn in words:
        make(text, fn, slow=True)

    print("\n── Praise / feedback ──")
    for text, fn, slow in praise:
        make(text, fn, slow=slow)

    print("\n── Sound hints ──")
    for text, fn in sound_hints:
        make(text, fn, slow=True)

    total = len(list(OUTPUT_DIR.glob("*.mp3")))
    print(f"\n✅ Done! {total} files in {OUTPUT_DIR}\n")

