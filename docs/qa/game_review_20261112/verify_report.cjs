// Private headless browser only; never attaches to the user's browser.
const { chromium } = require(process.argv[2]);
const fs = require('node:fs');
const path = require('node:path');
const { pathToFileURL } = require('node:url');

(async () => {
  const qa = process.argv[3] ? path.resolve(process.argv[3]) : __dirname;
  const report = process.argv[4] ? path.resolve(process.argv[4]) : path.resolve(__dirname, '../../reports/SPIELREVIEW_2026_11_12.html');
  const browser = await chromium.launch({ channel: 'chrome', headless: true });
  const context = await browser.newContext({ viewport: { width: 390, height: 844 }, acceptDownloads: true });
  await context.setOffline(true);
  // Exercise the mobile/unsupported-folder fallback without any OS picker.
  await context.addInitScript(() => Object.defineProperty(window, 'showDirectoryPicker', { value: undefined }));
  const page = await context.newPage();
  const errors = [];
  page.on('pageerror', error => errors.push(String(error)));
  const assertions = [];
  function check(ok, label) {
    assertions.push({ ok: !!ok, label });
    if (!ok) throw new Error(label);
  }
  try {
    await page.goto(pathToFileURL(report).href);
    check(page.url().startsWith('file:'), 'Report opens directly as a local file while offline');
    for (const width of [320, 390, 768, 1440]) {
      await page.setViewportSize({ width, height: 844 });
      for (const tab of ['overview', 'coverage', 'evidence', 'decisions']) {
        await page.locator(`[data-tab-target="${tab}"]`).click();
        check(await page.locator(`#${tab}`).isVisible(), `Tab ${tab} works at width ${width}`);
        const fits = await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth + 1);
        check(fits, `No horizontal overflow: ${tab}, ${width}px`);
      }
    }
    await page.setViewportSize({ width: 390, height: 844 });
    if (await page.locator('[data-export-key="astra.reviewed.C1"]').count()) {
      await page.locator('[data-tab-target="overview"]').click();
      check(await page.locator('[data-export-key^="astra.reviewed."]').count() === 9, 'All nine original findings are individually reviewable');
      if (await page.locator('[data-fixed-finding]').count()) {
        check(await page.locator('[data-fixed-finding]').count() === 10, 'Nine review fixes and the additional regression finding have current results');
        check(await page.getByText('9 von 9 Codefehlern behoben', {exact: true}).count() === 1, 'Current status distinguishes fixes from historical review');
        await page.locator('[data-fixed-finding="C10"] summary').click();
        check(await page.locator('[data-fixed-finding="C10"] p').isVisible(), 'Additional casualty fix can be expanded on a phone');
        check(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth + 1), 'Expanded fix explanation fits the phone viewport');
        await page.locator('[data-fixed-finding="C10"] summary').click();
      }
      await page.locator('.review-detail summary').first().click();
      await page.locator('[data-export-key="astra.reviewed.C1"]').check();
      check(await page.locator('[data-export-key="astra.reviewed.C1"]').isChecked(), 'Expanded finding supports a review decision');
      await page.getByText('Native Bildbelege ansehen', { exact: true }).click();
      for (const img of await page.locator('.review-image').all()) {
        await img.scrollIntoViewIfNeeded();
        await img.evaluate(image => image.decode());
        check(await img.evaluate(image => image.naturalWidth > 0), 'Historical native screenshot loads offline');
      }
      for (const width of [320, 390, 768, 1440]) {
        await page.setViewportSize({ width, height: 844 });
        check(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth + 1), `Expanded review and images fit ${width}px`);
      }
      await page.setViewportSize({ width: 390, height: 844 });
      await page.getByText('Native Bildbelege ansehen', { exact: true }).click();
      await page.locator('.review-detail summary').first().click();
    }
    await page.locator('[data-tab-target="decisions"]').click();
    await page.locator('[data-export-key="review.next_priority"]').selectOption('ui');
    await page.locator('[data-export-key="review.read"]').check();
    await page.locator('[data-export-key="review.comment"]').fill('Handyprüfung: ÄÖÜ, Schiff 2');
    await page.locator('[data-note-key="review.notes"]').fill('Offline-Notiz');
    const pending = page.waitForEvent('download');
    await page.locator('#exportJsonButton').click();
    const download = await pending;
    const exportPath = path.join(qa, 'mobile_export.json');
    await download.saveAs(exportPath);
    const payload = JSON.parse(fs.readFileSync(exportPath, 'utf8'));
    check(payload.schema === 'sternenbuergerchen.html_workbench.v1', 'Downloaded JSON uses the required workbench schema');
    check(payload.controls.review.read === true && payload.controls.review.next_priority === 'ui', 'Checkbox and selection survive JSON export');
    check(payload.controls.review.comment === 'Handyprüfung: ÄÖÜ, Schiff 2', 'German text roundtrips exactly');
    check(payload.notes.review.notes === 'Offline-Notiz', 'Editable notes survive JSON export');
    if (payload.controls.astra) check(payload.controls.astra.reviewed.C1 === true, 'New finding decision survives JSON export');
    check(await page.locator('#jsonOutput').inputValue() === JSON.stringify(payload, null, 2), 'Visible JSON fallback equals downloaded export');
    check(errors.length === 0, 'No browser JavaScript errors');
    await page.locator('[data-tab-target="overview"]').click();
    await page.evaluate(() => window.scrollTo(0, 0));
    await page.screenshot({ path: path.join(qa, 'report_top_390.png'), fullPage: false });
    await page.screenshot({ path: path.join(qa, 'report_mobile_390.png'), fullPage: true });
  } finally {
    fs.writeFileSync(path.join(qa, 'mobile_verification.json'), JSON.stringify({ assertions, errors, passed: assertions.filter(a => a.ok).length, failed: assertions.filter(a => !a.ok).length }, null, 2));
    await browser.close();
  }
  console.log(`REPORT_MOBILE passed=${assertions.length} failed=0`);
})().catch(error => { console.error(error); process.exitCode = 1; });
