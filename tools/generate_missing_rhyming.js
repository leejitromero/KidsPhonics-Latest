// Historical generator, retained for provenance only. See tools/README.md.
// Not part of the current validation or asset-replacement workflow.
/**
 * generate_missing_rhyming.js
 * Generates missing rhyming words audio files.
 * Run: node tools/generate_missing_rhyming.js
 */

const https = require('https');
const fs    = require('fs');
const path  = require('path');

const OUTPUT_DIR = path.join(
  __dirname, '..', 'assets', 'audio', 'phonics', 'rhyming_words'
);
if (!fs.existsSync(OUTPUT_DIR)) fs.mkdirSync(OUTPUT_DIR, { recursive: true });

const missing = [
  { text: 'Ball',  file: 'word_ball.mp3'  },
  { text: 'Snake', file: 'word_snake.mp3' },
];

function download(text, filename) {
  return new Promise((resolve, reject) => {
    const outPath = path.join(OUTPUT_DIR, filename);
    if (fs.existsSync(outPath)) {
      console.log(`  skip (exists): ${filename}`);
      return resolve();
    }
    const encoded = encodeURIComponent(text);
    const url = `https://translate.google.com/translate_tts?ie=UTF-8&q=${encoded}&tl=en&client=tw-ob`;
    const file = fs.createWriteStream(outPath);
    const req = https.get(url, { headers: { 'User-Agent': 'Mozilla/5.0' } }, (res) => {
      if (res.statusCode !== 200) {
        file.close(); fs.unlinkSync(outPath);
        return reject(new Error(`HTTP ${res.statusCode}`));
      }
      res.pipe(file);
      file.on('finish', () => { file.close(); console.log(`  ✓  ${filename}`); resolve(); });
    });
    req.on('error', (err) => {
      file.close();
      if (fs.existsSync(outPath)) fs.unlinkSync(outPath);
      reject(err);
    });
  });
}

async function main() {
  console.log(`\nGenerating missing rhyming words audio → ${OUTPUT_DIR}\n`);
  for (const { text, file } of missing) {
    try {
      await download(text, file);
      await new Promise(r => setTimeout(r, 500));
    } catch (e) {
      console.error(`  ✗  ${file} — ${e.message}`);
    }
  }
  console.log('\n✅ Done!\n');
}
main();

