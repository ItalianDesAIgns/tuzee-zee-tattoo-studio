// Render tools/og-card.html to site/media/og.jpg (1200x630) with headless Chrome.
// Needs the local server on :4180 (node tools/serve.mjs) and puppeteer-core.
// Usage: node tools/build_og_card.mjs [path-to-puppeteer-core-dir]
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import { resolve, dirname } from 'node:path';

const here = dirname(fileURLToPath(import.meta.url));
const require = createRequire(process.argv[2] ? resolve(process.argv[2], 'x.js') : import.meta.url);
const puppeteer = require('puppeteer-core');
const out = resolve(here, '../site/media/og.jpg');

const browser = await puppeteer.launch({ executablePath: 'C:/Program Files/Google/Chrome/Application/chrome.exe', headless: true });
const page = await browser.newPage();
await page.setViewport({ width: 1200, height: 630, deviceScaleFactor: 1 });
await page.goto('http://localhost:4180/tools/og-card.html', { waitUntil: 'networkidle0' });
await page.evaluate(() => document.fonts.ready);
await page.screenshot({ path: out, type: 'jpeg', quality: 86 });
await browser.close();
console.log('saved', out);
