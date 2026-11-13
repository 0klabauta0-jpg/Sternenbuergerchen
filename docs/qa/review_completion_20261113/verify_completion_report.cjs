// A fresh headless browser; no attachment to the user's browser or desktop.
const { chromium } = require(process.argv[2]);
const fs = require('node:fs');
const path = require('node:path');
const { pathToFileURL } = require('node:url');
(async () => {
  const output = path.resolve(process.argv[3]);
  const report = path.resolve(process.argv[4]);
  fs.mkdirSync(output, {recursive:true});
  const browser = await chromium.launch({channel:'chrome', headless:true});
  const context = await browser.newContext({viewport:{width:390,height:844},acceptDownloads:true});
  await context.setOffline(true);
  await context.addInitScript(()=>Object.defineProperty(window,'showDirectoryPicker',{value:undefined}));
  const page = await context.newPage();
  const checks=[], errors=[];
  page.on('pageerror',e=>errors.push(String(e)));
  const check=(ok,label)=>{checks.push({ok:!!ok,label});if(!ok)throw Error(label);};
  try {
    await page.goto(pathToFileURL(report).href);
    check(await page.locator('[data-completion-area]').count()>=5,'Five implementation areas present');
    const entries=page.locator('.asset-entry');
    const count=await entries.count();
    check(count>=6,'Map and asset groups have reviewable evidence');
    check(await page.locator('[data-asset-id="starmap_navigation"]').count()===1&&await page.locator('[data-asset-id="smart_mobile_jobs"]').count()===1,'Both requested UI revisions have their own comparisons');
    check(await entries.evaluateAll(nodes=>nodes.every(node=>node.querySelector('.asset-stage[data-stage="after"] img')&&['reference','before'].every(stage=>{const item=node.querySelector('.asset-stage[data-stage="'+stage+'"]');return item&&(item.querySelector('img')||(item.dataset.unavailable==='true'&&item.textContent.trim().length>30))}))), 'Every entry has native after evidence; missing historical/reference images are explicitly explained');
    for(const width of [320,390,768,1440]) {
      await page.setViewportSize({width,height:844});
      check(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1),'Gallery fits '+width+'px');
    }
    await page.setViewportSize({width:390,height:844});
    await page.locator('#asset-group').selectOption('maps');
    check(await page.locator('.asset-entry:visible').count()>0,'Map filter keeps actual map entries');
    check(await page.locator('.asset-entry:visible').count()<count,'Map filter hides other groups');
    await page.locator('#asset-search').fill('no-such-asset-783');
    check(await page.locator('.asset-entry:visible').count()===0,'Search has a truthful empty result');
    await page.locator('#asset-search').fill('');
    await page.locator('#asset-group').selectOption('all');
    for(const stage of ['before','after','reference']) {
      await page.locator('#asset-stage').selectOption(stage);
      check(await page.locator('.asset-entry:visible').count()===count,'Stage keeps asset selection: '+stage);
      check(await page.locator('.asset-stage:visible').evaluateAll((nodes,s)=>nodes.every(n=>n.dataset.stage===s),stage),'Comparison stage synchronized: '+stage);
    }
    await page.locator('#asset-stage').selectOption('after');
    const images=page.locator('.asset-image-button img');
    await images.evaluateAll(nodes=>nodes.forEach(image=>image.loading='eager'));
    for(const nativeImage of await images.all()) {
      await nativeImage.evaluate(image=>image.decode());
    }
    check(await images.evaluateAll(nodes=>nodes.length>0&&nodes.every(image=>image.complete&&image.naturalWidth>0)), 'Every linked reference, before and after image loads offline');
    const imageButton=page.locator('.asset-stage:visible .asset-image-button').first();
    await imageButton.locator('img').evaluate(image=>image.decode());
    await imageButton.click();
    check(await page.locator('#asset-dialog').isVisible(),'Native image opens in dialog');
    check(await page.locator('#asset-dialog img').evaluate(i=>i.complete&&i.naturalWidth>0),'Full native image loads offline');
    await page.keyboard.press('Escape');
    check(!(await page.locator('#asset-dialog').isVisible()),'Image dialog closes with Escape');
    const first=entries.first();
    const usage=page.locator('.usage-asset');
    check(await usage.count()>0,'Selected Kenney usage catalog is present');
    const usageImages=page.locator('.usage-asset img');
    await usageImages.evaluateAll(nodes=>nodes.forEach(image=>image.loading='eager'));
    for (const preview of await usageImages.all()) await preview.evaluate(image=>image.decode());
    check(await usageImages.evaluateAll(nodes=>nodes.length>0&&nodes.every(image=>image.complete&&image.naturalWidth>0)), 'Every selected Kenney source preview loads offline');
    await page.locator('#usage-search').fill('station_set_computer_wide');
    check(await page.locator('.usage-asset:visible').count()===1,'Asset catalog filters by exact source identifier');
    const usageCard=page.locator('.usage-asset:visible');
    await usageCard.locator('summary').click();
    await usageCard.locator('textarea').fill('Computer: Anschluss prüfen.');
    await page.locator('#usage-search').fill('');
    await first.locator('select[data-export-key]').selectOption('revise');
    await first.locator('textarea').fill('Bodenvergleich: Schatten prüfen. ÄÖÜ');
    const assetId=await first.getAttribute('data-asset-id');
    const downloadEvent=page.waitForEvent('download');
    await page.locator('#exportJsonButton').click();
    const download=await downloadEvent;
    const exported=path.join(output,'graphics_export.json');
    await download.saveAs(exported);
    const data=JSON.parse(fs.readFileSync(exported,'utf8'));
    check(data.schema==='sternenbuergerchen.html_workbench.v1','Export preserves workbench contract');
    check(data.controls.graphics[assetId].decision==='revise','Asset decision survives offline export');
    check(data.controls.graphics[assetId].note==='Bodenvergleich: Schatten prüfen. ÄÖÜ','Asset note survives offline export');
    check(data.controls.graphics.stage==='after','Comparison state is exported');
    check(data.controls.kenney.station_set_computer_wide.note==='Computer: Anschluss prüfen.','Individual asset finding survives offline JSON export');
    check(errors.length===0,'No JavaScript errors');
    await page.evaluate(()=>scrollTo(0,0));
    await page.screenshot({path:path.join(output,'completion_top_390.png')});
    await page.locator('#graphics-workbench').evaluate(node=>node.scrollIntoView({block:'start'}));
    await page.screenshot({path:path.join(output,'graphics_workbench_390.png')});
    await page.locator('#usage-search').fill('station_set_computer_wide');
    await page.locator('#kenney-usage').evaluate(node=>node.scrollIntoView({block:'start'}));
    await page.screenshot({path:path.join(output,'kenney_usage_390.png')});
  } finally {
    fs.writeFileSync(path.join(output,'completion_verification.json'),JSON.stringify({checks,errors,passed:checks.filter(c=>c.ok).length,failed:checks.filter(c=>!c.ok).length},null,2));
    await browser.close();
  }
  console.log('COMPLETION_REPORT passed='+checks.length+' failed=0');
})().catch(e=>{console.error(e);process.exitCode=1;});
