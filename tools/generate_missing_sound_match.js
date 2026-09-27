// Historical generator, retained for provenance only. See tools/README.md.
// Not part of the current validation or asset-replacement workflow.
/**
 * generate_missing_sound_match.js
 * ─────────────────────────────────
 * Generates missing Sound Match hint MP3s using the free Google TTS endpoint.
 * No API key required.
 *
 * Run from project root:
 *   node tools/generate_missing_sound_match.js
 */

const https = require('https');
const fs    = require('fs');
const path  = require('path');

const OUTPUT_DIR = path.join(
  __dirname, '..', 'assets', 'audio', 'phonics', 'sound_match'
);

if (!fs.existsSync(OUTPUT_DIR)) fs.mkdirSync(OUTPUT_DIR, { recursive: true });

const missing = [
  { text: 'Nut! N sound. Nut!',             file: 'hint_nut.mp3'       },
  { text: 'Octopus! O sound. Octopus!',     file: 'hint_octopus.mp3'   },
  { text: 'Pig! P sound. Pig!',             file: 'hint_pig.mp3'       },
  { text: 'Turtle! T sound. Turtle!',       file: 'hint_turtle.mp3'    },
  { text: 'Xylophone! X sound. Xylophone!', file: 'hint_xylophone.mp3' },
  { text: 'Yarn! Y sound. Yarn!',           file: 'hint_yarn.mp3'      },
];

function download(text, filename) {
  return new Promise((resolve, reject) => {
    const outPath = path.join(OUTPUT_DIR, filename);

    if (fs.existsSync(outPath)) {
      console.log(`  skip (exists): ${filename}`);
      return resolve();
    }

    const encoded = encodeURIComponent(text);
    // Google Translate TTS — free, no key needed
    const url = `https://translate.google.com/translate_tts?ie=UTF-8&q=${encoded}&tl=en&client=tw-ob`;

    const file = fs.createWriteStream(outPath);
    const req = https.get(url, {
      headers: {
        'User-Agent': 'Mozilla/5.0'
      }
    }, (res) => {
      if (res.statusCode !== 200) {
        file.close();
        fs.unlinkSync(outPath);
        return reject(new Error(`HTTP ${res.statusCode} for ${filename}`));
      }
      res.pipe(file);
      file.on('finish', () => {
        file.close();
        console.log(`  ✓  ${filename}`);
        resolve();
      });
    });

    req.on('error', (err) => {
      file.close();
      if (fs.existsSync(outPath)) fs.unlinkSync(outPath);
      reject(err);
    });
  });
}

async function main() {
  console.log(`\nGenerating missing Sound Match hints → ${OUTPUT_DIR}\n`);
  for (const { text, file } of missing) {
    try {
      await download(text, file);
      // Small delay to avoid rate limiting
      await new Promise(r => setTimeout(r, 500));
    } catch (e) {
      console.error(`  ✗  ${file} — ${e.message}`);
    }
  }
  console.log('\n✅ Done!\n');
}

main();

