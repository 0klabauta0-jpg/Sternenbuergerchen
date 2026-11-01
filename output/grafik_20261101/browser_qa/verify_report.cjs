const { chromium } = require('C:/Users/bjoer/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { pathToFileURL } = require('url');
const root = path.resolve(__dirname, '../../..');
const html = path.join(root, 'docs/reports/STERNENBUERGERCHEN_GRAFIK_2026-11-01.html');
const artifacts = __dirname;
const downloadDir = path.join(artifacts, 'downloads');
fs.mkdirSync(downloadDir, {recursive:true});
const hash = () => crypto.createHash('sha256').update(fs.readFileSync(html)).digest('hex');
const report = {html, html_sha256_start:hash(), started_at:new Date().toISOString(), checks:[], screenshots:[], console_errors:[], page_errors:[], external_requests:[], failures:[]};
function check(name, value, detail={}) {
  report.checks.push({name, pass:!!value, ...detail});
  if (!value) report.failures.push({name, ...detail});
}
const assert = (value, message) => { if(!value) throw new Error(message); };
let browser;
async function decodedDOMImages(page) {
  return page.locator('img[src]').evaluateAll(async imgs=>Promise.all(imgs.map(async i=>{
    i.loading='eager';
    try{await i.decode();}catch(_){}
    return {alt:i.alt,pass:i.complete&&i.naturalWidth>0,width:i.naturalWidth,height:i.naturalHeight};
  })));
}
async function screenshot(page, filename) {
  const target=path.join(artifacts,filename);
  await decodedDOMImages(page);
  await page.screenshot({path:target, fullPage:false});
  report.screenshots.push(target);
}
function instrument(page, label) {
  page.on('console', msg => {if(msg.type()==='error') report.console_errors.push({label,text:msg.text()});});
  page.on('pageerror', err => report.page_errors.push({label,message:err.message}));
  page.on('request', req => {if(/^https?:/i.test(req.url())) report.external_requests.push({label,url:req.url()});});
}
async function open(context,label) {
  await context.setOffline(true);
  const page=await context.newPage(); instrument(page,label);
  await page.goto(pathToFileURL(html).href,{waitUntil:'load'});
  await page.waitForFunction(()=>window.reportWorkbench && window.reportWorkbench.assetCount>0);
  const loaded=await decodedDOMImages(page);
  check(label+'_initial_DOM_images_loaded',loaded.every(i=>i.pass),{count:loaded.length,failures:loaded.filter(i=>!i.pass)});
  return page;
}
async function noOverflow(page,name) {
  const dimensions=await page.evaluate(()=>({viewport:innerWidth,document:document.documentElement.scrollWidth,body:document.body.scrollWidth}));
  check(name,Math.max(dimensions.document,dimensions.body)<=dimensions.viewport,{dimensions});
}
async function clickEngine(page, view) {
  await page.locator(`button[data-engine-view="${view}"]`).click();
  await page.waitForFunction(()=>{const i=document.querySelector('#engineImage');return i.complete&&i.naturalWidth>0;});
  return page.locator('#engineViewTitle').innerText();
}
async function run() {
  browser=await chromium.launch({executablePath:'C:/Users/bjoer/AppData/Local/ms-playwright/chromium-1234/chrome-win64/chrome.exe',headless:true,args:['--disable-gpu']});
  const context=await browser.newContext({viewport:{width:1440,height:1000},acceptDownloads:true});
  const page=await open(context,'desktop');
  await page.screenshot({path:path.join(artifacts,'01_desktop_top.png')});
  report.screenshots.push(path.join(artifacts,'01_desktop_top.png'));
  report.dom_inventory=await page.locator('input,button,select,textarea,[contenteditable=true]').evaluateAll(es=>es.map(e=>({tag:e.tagName,id:e.id,text:(e.textContent||'').trim().slice(0,80),type:e.type,exportKey:e.dataset.exportKey,noteKey:e.dataset.noteKey})));
  check('desktop_viewport',await page.evaluate(()=>innerWidth===1440&&innerHeight===1000));
  await noOverflow(page,'desktop_horizontal_overflow_zero');
  const decoded=await page.evaluate(async()=>{
    const assets=JSON.parse(document.querySelector('#reportData').textContent).assets;
    return Promise.all(assets.map(a=>new Promise(resolve=>{const i=new Image();i.onload=()=>resolve({id:a.id,width:i.naturalWidth,height:i.naturalHeight,pass:i.naturalWidth>0});i.onerror=()=>resolve({id:a.id,pass:false});i.src=a.full;})));
  });
  check('all_embedded_full_images_decode',decoded.every(x=>x.pass),{count:decoded.length,failures:decoded.filter(x=>!x.pass)});
  check('seven_current_targets',await page.locator('#targetGallery .art-card').count()===7);

  const engineTitles={};
  for(const v of ['overview','hex_grid','crew','workshop','walk_pose','baseline']) {
    engineTitles[v]=await clickEngine(page,v);
    check('engine_selector_'+v,await page.locator(`button[data-engine-view="${v}"]`).getAttribute('aria-pressed')==='true' && await page.locator('#engineImageButton').getAttribute('data-open')==='engine_'+v,{title:engineTitles[v]});
  }
  check('engine_six_distinct_titles',new Set(Object.values(engineTitles)).size===6,{titles:engineTitles});
  await clickEngine(page,'crew');
  await page.locator('#engineImage').scrollIntoViewIfNeeded();
  await screenshot(page,'02_desktop_engine_crew.png');
  await page.locator('#engineImageButton').click();
  await page.locator('#imageDialog[open]').waitFor();
  const titleBefore=await page.locator('#dialogTitle').innerText();
  check('lightbox_source_and_hash', (await page.locator('#dialogPath').innerText()).length>0 && /^[a-fA-F0-9]{64}$/.test(await page.locator('#dialogHash').innerText()));
  await page.locator('#zoomImage').click();
  check('lightbox_zoom_on',await page.locator('#zoomImage').getAttribute('aria-pressed')==='true');
  await page.locator('#zoomImage').click();
  await screenshot(page,'03_desktop_lightbox.png');
  await page.locator('#closeDialog').focus();
  await page.keyboard.press('ArrowRight');
  check('lightbox_arrow_right',await page.locator('#dialogTitle').innerText()!==titleBefore);
  await page.keyboard.press('ArrowLeft');
  check('lightbox_arrow_left',await page.locator('#dialogTitle').innerText()===titleBefore);
  await page.locator('#dialogNotes').fill('QA: native stock view note');
  await page.locator('#dialogDecision').selectOption('direction_ok');
  await page.locator('#dialogNotes').focus();
  await page.keyboard.press('ArrowLeft');
  check('lightbox_text_cursor_does_not_navigate',await page.locator('#dialogTitle').innerText()===titleBefore);
  await page.keyboard.press('Escape');
  check('lightbox_escape_closes',await page.locator('#imageDialog').evaluate(e=>!e.open));
  await page.locator('#engineImageButton').click();
  await page.locator('#closeDialog').click();
  check('lightbox_close_button',await page.locator('#imageDialog').evaluate(e=>!e.open));

  const groupCounts={all:7,terrain:1,buildings:1,people:1,cutlass:2,buccaneer:2};
  for(const [g,n] of Object.entries(groupCounts)) {
    await page.locator(`button[data-filter="${g}"]`).click();
    check('catalog_group_'+g,await page.locator('#targetGallery .art-card').count()===n,{expected:n,actual:await page.locator('#targetGallery .art-card').count()});
  }
  await page.locator('button[data-filter="people"]').click();
  await page.locator('#searchInput').fill('Buccaneer');
  check('combined_filter_empty_state',await page.locator('#targetGallery .art-card').count()===0 && await page.locator('#targetGallery .empty').isVisible());
  await page.locator('button[data-filter="all"]').click();
  check('search_buccaneer',await page.locator('#targetGallery .art-card').count()===2);
  await page.locator('#searchInput').fill('CUTLASS');
  check('search_case_insensitive',await page.locator('#targetGallery .art-card').count()===2);
  await page.locator('#searchInput').fill('');
  await page.locator('#archiveDetails > summary').click();
  check('archive_five_preserved_targets',await page.locator('#archiveGallery .art-card').count()===5);
  await page.locator('#archiveDetails > summary').click();

  await page.locator('details.old-ship-studies > summary').click();
  await page.locator('button[data-view="rear"]').click();
  let ids=await page.locator('#shipComparisons .compare-image').evaluateAll(es=>es.map(e=>e.dataset.open));
  check('ship_rear_views',ids.length===6 && ids.every(x=>x.endsWith('_rear')),{ids});
  await page.locator('button[data-view="front"]').click();
  ids=await page.locator('#shipComparisons .compare-image').evaluateAll(es=>es.map(e=>e.dataset.open));
  check('ship_front_views',ids.length===6&&ids.every(x=>x.endsWith('_front')),{ids});
  await page.locator('button[data-distance="distance"]').click();
  ids=await page.locator('#shipComparisons .compare-image').evaluateAll(es=>es.map(e=>e.dataset.open));
  check('ship_distance_state',await page.locator('button[data-view="rear"]').isDisabled() && ids.filter(x=>x.endsWith('_distance')).length===4,{ids});
  await page.locator('button[data-distance="near"]').click();
  await page.locator('button[data-view="rear"]').click();
  check('ship_near_restores_rear_control',!(await page.locator('button[data-view="rear"]').isDisabled()));
  await page.locator('#ship-decision-cutlass').selectOption('revise');
  await page.locator('#ship-note-cutlass').fill('QA: quieter engine mass, preserve pair');

  const terrainCard=page.locator('#targetGallery .art-card').filter({has:page.locator('[data-open="terrain"]')});
  await terrainCard.locator('details.review > summary').click();
  await page.locator('#decision-terrain').selectOption('main_reference');
  await page.locator('#note-terrain').fill('QA: retain warm terrain panels');
  await page.locator('#globalNotes').fill('QA: local notes export — äöü');
  await page.locator('[data-export-key="review.wimmelbild"]').check();
  await page.locator('[data-export-key="review.detail_level"]').check();
  await page.locator('[data-export-key="review.native_gap_understood"]').check();
  const editable=page.locator('[data-note-key]');
  let editableKey=null;
  if(await editable.count()) {editableKey=await editable.first().getAttribute('data-note-key');await editable.first().fill('QA: editable note persisted');}
  await page.locator('button[data-filter="buccaneer"]').click();
  await page.locator('#searchInput').fill('Buccaneer');
  await page.reload({waitUntil:'load'});
  await page.waitForFunction(()=>window.reportWorkbench);
  check('localstorage_global_note',await page.locator('#globalNotes').inputValue()==='QA: local notes export — äöü');
  check('localstorage_checkbox',await page.locator('[data-export-key="review.wimmelbild"]').isChecked());
  check('localstorage_choices',await page.locator('button[data-filter="buccaneer"]').getAttribute('aria-pressed')==='true' && await page.locator('button[data-view="rear"]').getAttribute('aria-pressed')==='true' && await page.locator('button[data-engine-view="crew"]').getAttribute('aria-pressed')==='true');
  await page.locator('details.old-ship-studies > summary').click();
  check('localstorage_ship_note',await page.locator('#ship-note-cutlass').inputValue()==='QA: quieter engine mass, preserve pair');
  check('localstorage_ship_decision',await page.locator('#ship-decision-cutlass').inputValue()==='revise');
  if(editableKey)check('localstorage_contenteditable',await page.locator(`[data-note-key="${editableKey}"]`).innerText()==='QA: editable note persisted');

  const downloads=[];
  for(let i=0;i<2;i++) {
    const promise=page.waitForEvent('download');
    await page.locator('#exportJsonButton').click();
    const download=await promise;const target=path.join(downloadDir,download.suggestedFilename());
    await download.saveAs(target);downloads.push(target);
  }
  check('timestamped_distinct_downloads',downloads[0]!==downloads[1],{downloads});
  const exported=JSON.parse(fs.readFileSync(downloads[1],'utf8'));
  check('json_required_schema',exported.schema==='sternenbuergerchen.html_workbench.v1' && ['report_id','title','exported_at','controls','notes','active_choices','computed','metadata'].every(k=>k in exported));
  check('json_actual_controls',exported.controls.catalog.search==='Buccaneer' && exported.controls.review.wimmelbild===true && exported.controls.review.detail_level===true && exported.controls.review.native_gap_understood===true);
  check('json_actual_notes_and_decisions',exported.notes.global==='QA: local notes export — äöü' && exported.notes.assets.terrain==='QA: retain warm terrain panels' && exported.controls.asset_decisions.terrain==='main_reference' && exported.notes.assets.engine_crew==='QA: native stock view note' && exported.controls.asset_decisions.engine_crew==='direction_ok' && exported.notes.ships.cutlass==='QA: quieter engine mass, preserve pair' && exported.controls.ship_decisions.cutlass==='revise');
  check('json_active_choices',exported.active_choices.group==='buccaneer'&&exported.active_choices.view==='rear'&&exported.active_choices.distance==='near'&&exported.active_choices.engine_view==='crew');
  check('json_asset_assignments_and_status',exported.metadata.asset_assignments.length===decoded.length&&exported.metadata.asset_assignments.every(a=>a.id&&a.path&&a.status&&/^[0-9a-f]{64}$/i.test(a.sha256)),{count:exported.metadata.asset_assignments.length});
  check('json_visible_text_fallback',await page.locator('#jsonOutput').isVisible()&&JSON.parse(await page.locator('#jsonOutput').inputValue()).exported_at===exported.exported_at);
  check('import_optional_absent',await page.locator('input[type=file]').count()===0,{note:'No import control; contract makes import optional.'});
  await noOverflow(page,'desktop_overflow_after_controls');

  const mobileContext=await browser.newContext({viewport:{width:390,height:844},isMobile:true,deviceScaleFactor:1,acceptDownloads:true});
  const mobile=await open(mobileContext,'mobile');
  await screenshot(mobile,'04_mobile_top.png');
  await noOverflow(mobile,'mobile_horizontal_overflow_zero');
  await clickEngine(mobile,'crew');
  await mobile.locator('#engineImage').scrollIntoViewIfNeeded();
  await screenshot(mobile,'05_mobile_engine_crew.png');
  await mobile.locator('#engineImageButton').click();
  await screenshot(mobile,'06_mobile_lightbox.png');
  await noOverflow(mobile,'mobile_lightbox_horizontal_overflow_zero');
  check('mobile_dialog_image_loaded',await mobile.locator('#dialogImage').evaluate(i=>i.complete&&i.naturalWidth>0));
  await mobile.locator('#closeDialog').click();
  await mobile.locator('button[data-filter="people"]').click();
  check('mobile_filter_people',await mobile.locator('#targetGallery .art-card').count()===1);
  await mobile.locator('#searchInput').fill('zzznomatch');
  check('mobile_search_empty',await mobile.locator('#targetGallery .empty').isVisible());
  await noOverflow(mobile,'mobile_overflow_after_search');
  await mobileContext.close();
  await context.close();
}
(async()=>{
  try{await run();}catch(error){report.failures.push({name:'script_exception',message:error.message,stack:error.stack});}
  finally{
    if(browser)await browser.close();
    report.html_sha256_end=hash();report.html_changed_during_run=report.html_sha256_start!==report.html_sha256_end;
    check('console_errors_zero',report.console_errors.length===0,{errors:report.console_errors});
    check('page_errors_zero',report.page_errors.length===0,{errors:report.page_errors});
    check('external_requests_zero',report.external_requests.length===0,{requests:report.external_requests});
    report.completed_at=new Date().toISOString();report.pass=report.failures.length===0;
    fs.writeFileSync(path.join(artifacts,'browser_qa.json'),JSON.stringify(report,null,2));
    console.log(JSON.stringify({pass:report.pass,checks:report.checks.length,failures:report.failures,html_changed_during_run:report.html_changed_during_run,screenshots:report.screenshots},null,2));
    if(!report.pass)process.exitCode=1;
  }
})();
