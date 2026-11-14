// DOM-only interaction checks. This does not verify rendering in a browser.
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const crypto = require('node:crypto');
const { parseHTML } = require(process.argv[2] || 'linkedom');
const root = path.resolve(__dirname, '..');
const source = fs.readFileSync(path.join(root, 'GALERIE.html'), 'utf8');
const manifest = JSON.parse(fs.readFileSync(path.join(root, 'HERKUNFT.json'), 'utf8'));
const checks = [];
function check(label, body) { body(); checks.push({ label, pass: true }); }
const storage = new Map();
let download = null;
function boot() {
  const { document, window } = parseHTML(source);
  const dialog = document.getElementById('lightbox');
  dialog.showModal = () => dialog.setAttribute('open', '');
  dialog.close = () => dialog.removeAttribute('open');
  document.getElementById('jsonOutput').select = () => {};
  // linkedom's select.value is read-only: supply the browser's writable value.
  document.querySelectorAll('select').forEach(select => {
    let value = select.querySelector('option')?.getAttribute('value') || '';
    Object.defineProperty(select, 'value', { get: () => value, set: v => { value = v; } });
  });
  const rawCreate = document.createElement.bind(document);
  document.createElement = name => {
    const element = rawCreate(name);
    if (name === 'a') element.click = () => { download = { href: element.href, filename: element.download }; };
    return element;
  };
  const context = vm.createContext({ document, window, localStorage: { getItem: k => storage.get(k) || null, setItem: (k, v) => storage.set(k, v) }, navigator: {}, Blob, URL, setTimeout: fn => fn() });
  const script = [...document.querySelectorAll('script')].find(s => s.id !== 'galleryData').textContent;
  vm.runInContext(script, context, { timeout: 5000 });
  return { document, window };
}
const { document, window } = boot();
const fire = el => el.dispatchEvent(new window.Event('input', { bubbles: true }));
const visible = () => [...document.querySelectorAll('.image-card')].filter(c => !c.hidden);
check('95 unique original images', () => { assert.equal(manifest.image_count, 95); assert.equal(new Set(manifest.items.map(i => i.sha256)).size, 95); });
check('All 95 copied files match SHA256', () => { for (const i of manifest.items) assert.equal(crypto.createHash('sha256').update(fs.readFileSync(path.join(root, i.file))).digest('hex'), i.sha256); });
check('Explicitly rejected deck absent from gallery items and image files', () => {
  const banned = new Set(manifest.excluded.map(i => i.sha256));
  assert(!manifest.items.some(i => banned.has(i.sha256) || /Deck_nur_weisse_Halle/.test(i.file)));
  assert(!fs.existsSync(path.join(root, '90_Teilweise_bestaetigt_und_aeltere_Varianten/Deck_nur_weisse_Halle_bestaetigt.png')));
});
check('95 cards and image links', () => { assert.equal(document.querySelectorAll('.image-card').length, 95); assert.equal(document.querySelectorAll('.preview img').length, 95); });
check('No external script, stylesheet or image dependencies', () => { assert.equal(document.querySelectorAll('script[src],link[rel="stylesheet"]').length, 0); for (const i of document.querySelectorAll('.preview img')) assert(!/^(https?:|\/\/)/.test(i.getAttribute('src'))); });
check('Initial count and all cards visible', () => { assert.equal(visible().length, 95); assert.equal(document.getElementById('resultCount').textContent, '95 von 95 Bildern'); });
const search = document.getElementById('search');
check('Search finds early Rostgrenze references', () => { search.value = 'Rostgrenze'; fire(search); assert(visible().length >= 2); assert(visible().every(c => /rostgrenze/i.test(c.textContent))); });
check('Empty search has zero results', () => { search.value = 'ZZZZ_MISSING_IMAGE'; fire(search); assert.equal(visible().length, 0); });
document.getElementById('resetFilters').click();
check('Reset restores every image', () => assert.equal(visible().length, 95));
const status = document.getElementById('status');
check('User-reference filter shows exactly 9', () => { status.value = 'user_reference'; fire(status); assert.equal(visible().length, 9); });
check('Positive filter excludes open/historical/partial images', () => { status.value = 'positive'; fire(status); assert.equal(visible().length, 35); assert(visible().every(c => ['confirmed','direction','user_reference'].includes(c.dataset.status))); });
document.getElementById('resetFilters').click();
check('September website category shows 6 targets', () => { const group = document.getElementById('group'); group.value = 'Webseite / September'; fire(group); assert.equal(visible().length, 6); });
document.getElementById('resetFilters').click();
check('Large-image dialog opens correct original and closes', () => { const button = document.querySelector('.preview'); button.click(); assert(document.getElementById('lightbox').hasAttribute('open')); assert.equal(document.getElementById('lightboxImage').getAttribute('src'), button.dataset.file); document.getElementById('closeLightbox').click(); assert(!document.getElementById('lightbox').hasAttribute('open')); });
const note = document.querySelector('.image-note');
const decision = document.querySelector('.decision');
check('Notes and decisions persist to browser storage', () => { note.value = 'QA – local test'; fire(note); decision.value = 'good'; fire(decision); const saved = JSON.parse(storage.get('sb-image-reference-notes-v2')); assert.equal(saved[note.dataset.exportKey], note.value); assert.equal(saved[decision.dataset.exportKey], 'good'); });
check('Reload restores notes and decisions', () => { const next = boot(); assert.equal(next.document.querySelector('.image-note').value, 'QA – local test'); assert.equal(next.document.querySelector('.decision').value, 'good'); });
document.getElementById('exportJsonButton').click();
const exported = JSON.parse(document.getElementById('jsonOutput').value);
check('JSON export uses required workbench schema and all images', () => { assert.equal(exported.schema, 'sternenbuergerchen.html_workbench.v1'); assert.equal(exported.metadata.images.length, 95); assert.equal(exported.computed.image_count, 95); assert.equal(exported.controls[decision.dataset.exportKey], 'good'); assert(Object.values(exported.notes).includes('QA – local test')); });
check('Download uses Blob URL and timestamped JSON filename', () => { assert(download.href.startsWith('blob:')); assert(download.filename.endsWith('.json')); assert(download.filename.startsWith('sternenbuergerchen_bildreferenzen_')); });
check('Responsive rules and viewport declaration present (static check only)', () => { assert(document.querySelector('meta[name="viewport"]')); assert(source.includes('@media(max-width:600px)')); });
const result = { date: '2026-11-14', kind: 'DOM-only integration checks using linkedom; not rendered browser QA', passed: checks.length, failed: 0, image_count: 95, checks, limitations: ['Browser security policy rejected file:// navigation. No alternate browser route attempted.', 'Desktop/mobile rendering and actual browser download not visually verified.', 'PNG/JPEG decoding was verified separately with Pillow.'] };
fs.writeFileSync(path.join(__dirname, 'GALERIE_PRUEFUNG.json'), JSON.stringify(result, null, 2));
console.log(JSON.stringify({ passed: checks.length, failed: 0, images: 95, rendered_browser_qa: false }));
