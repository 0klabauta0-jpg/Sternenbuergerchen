// Standalone offline artifact QA. The CLI browser does not support file://;
// this owned headless Chrome checks only the generated local workbench.
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const {pathToFileURL} = require('url');
const {chromium} = require('C:/Users/bjoer/AppData/Local/npm-cache/_npx/31e32ef8478fbf80/node_modules/playwright');
const root = path.resolve(__dirname, '../../..');
const file = path.join(root, 'docs/reports/STERNENBUERGERCHEN_GRAFIK_2026-11-01.html');
const out = path.join(__dirname, 'browser_qa');
fs.mkdirSync(path.join(out,'downloads'), {recursive:true});
const digest = p => crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex');
const checks = [], screens = [], errors = [], requests = [];
function check(value,label){checks.push({label,passed:!!value});if(!value)throw Error(label);}
(async()=>{
 const browser = await chromium.launch({channel:'chrome',headless:true});
 const context = await browser.newContext({viewport:{width:1440,height:1000},acceptDownloads:true});
 await context.route(/^https?:/, route=>{requests.push(route.request().url());return route.abort();});
 const page = await context.newPage();
 page.on('pageerror', e=>errors.push(String(e)));
 page.on('console', m=>{if(m.type()==='error')errors.push(m.text());});
 async function shot(name){const p=path.join(out,name+'.png');await page.screenshot({path:p,fullPage:false});screens.push({path:path.relative(root,p).replaceAll('\\','/'),sha256:digest(p)});}
 try {
  await page.goto(pathToFileURL(file).href,{waitUntil:'load'});
  check((await page.title()).includes('Sternen'),'report title');
  check((await page.locator('#pendingBanner').innerText()).includes('Aktueller Adoptionsstand'),'released adoption banner');
  const data = await page.evaluate(()=>JSON.parse(document.querySelector('#reportData').textContent));
  check(data.pairs.length===6 && data.runtime_controls.length===6,'six fixed pairs and six actual startup views');
  check(data.verification.code_commit==='177991ac4962c17be0d02ef909949826967c7f57' && data.verification.main_integrated===true,'actual integrated source commit');
  check(data.pending.length===0,'no invented pending acceptance');
  for(const asset of data.assets){
   check(asset.exists && asset.sha256 && asset.path,'asset source identity '+asset.id);
   check(fs.existsSync(path.join(root,asset.path)) && digest(path.join(root,asset.path))===asset.sha256,'actual source bytes '+asset.id);
  }
  const decodes = await page.evaluate(async()=>{
   const d=JSON.parse(document.querySelector('#reportData').textContent), result=[];
   for(const a of d.assets)for(const key of ['thumb','full']){
    const image = new Image();image.src=a[key];
    try{await image.decode();result.push({id:a.id,key,ok:image.naturalWidth>0});}catch(e){result.push({id:a.id,key,ok:false});}
   }
   return result;
  });
  for(const row of decodes)check(row.ok,'embedded derivative decode '+row.id+'/'+row.key);
  await shot('desktop_start');
  for(const pair of data.pairs){
   await page.selectOption('#viewSelect',pair.id);
   await page.locator('#vergleich').scrollIntoViewIfNeeded();
   check((await page.locator('#beforeCaption').innerText()).includes('P07') || (await page.locator('#beforeCaption').innerText()).includes('R02'),'before status '+pair.id);
   check((await page.locator('#afterImage').getAttribute('src')).startsWith('data:image/'),'actual paired image '+pair.id);
   check(pair.camera_match===true,'same native camera '+pair.id);
   await shot('desktop_pair_'+pair.id);
  }
  await page.locator('[data-mode="wipe"]').click();
  check(await page.locator('#pairWipe').isVisible(),'wipe mode visible');
  await page.locator('#wipeRange').fill('31');
  await page.locator('#wipeRange').dispatchEvent('input');
  check((await page.locator('#wipeRange').inputValue())==='31','wipe parameter changes');
  await page.locator('[data-mode="side"]').click();
  await page.locator('#afterButton').click();
  check(await page.locator('#imageDialog').isVisible(),'large source image dialog');
  await page.locator('#zoomImage').click();await shot('desktop_dialog');
  await page.locator('#nextImage').click();
  check((await page.locator('#dialogTitle').innerText()).length>2,'dialog navigation');
  await page.locator('#closeDialog').click();
  await page.selectOption('#viewSelect','cutlass_front');
  await page.fill('#comparisonNote','QA_Main_Ref03_Cutlass');
  const choice = await page.locator('#comparisonDecision option').nth(1).getAttribute('value');
  await page.selectOption('#comparisonDecision',choice);
  for(const control of data.runtime_controls){
   await page.selectOption('#runtimeSelect',control.id);
   await page.locator('#runtime').scrollIntoViewIfNeeded();
   check((await page.locator('#runtimeImage').getAttribute('src')).startsWith('data:image/'),'actual normal-start image '+control.id);
   await shot('desktop_runtime_'+control.id);
  }
  await page.locator('#catalogDetails').evaluate(e=>e.open=true);
  await page.locator('[data-group="after"]').click();
  await page.fill('#searchInput','Cutlass');
  check((await page.locator('#gallery [data-open]').count())===2,'catalog search and group intersect');
  await page.locator('[data-group="all"]').click();await page.fill('#searchInput','');
  check((await page.locator('#gallery [data-open]').count())===data.assets.length,'catalog returns every asset');
  await page.fill('#playtestNote','QA_Main_NormalStart');
  await page.fill('#globalNotes','QA_Main_UI_Next');
  await page.locator('#showJsonButton').click();
  let text=await page.locator('#jsonOutput').inputValue();let exported=JSON.parse(text);
  check(exported.schema==='sternenbuergerchen.html_workbench.v1','required offline export schema');
  check(text.includes('QA_Main_Ref03_Cutlass') && text.includes('QA_Main_NormalStart') && text.includes('QA_Main_UI_Next'),'asset, playtest and global notes exported');
  const names=[];
  for(let i=0;i<2;i++){
   const event = page.waitForEvent('download');await page.locator('#exportButton').click();const download=await event;
   names.push(download.suggestedFilename());const p=path.join(out,'downloads',download.suggestedFilename());await download.saveAs(p);
   check(JSON.parse(fs.readFileSync(p,'utf8')).schema==='sternenbuergerchen.html_workbench.v1','actual downloaded JSON '+i);
  }
  check(names[0]!==names[1],'unique filenames for repeated exports');
  await page.reload({waitUntil:'load'});await page.locator('#showJsonButton').click();
  check((await page.locator('#jsonOutput').inputValue()).includes('QA_Main_UI_Next'),'local notes survive reload');
  await context.clearCookies();
  await page.setViewportSize({width:390,height:844});
  await page.locator('#vergleich').scrollIntoViewIfNeeded();await shot('mobile_pair');
  check(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1),'mobile has no horizontal document overflow');
  await page.locator('#afterButton').click();await shot('mobile_dialog');await page.locator('#closeDialog').click();
  await page.locator('#notizen').scrollIntoViewIfNeeded();await shot('mobile_notes');
  check(errors.length===0,'no browser/page/console errors');
  check(requests.length===0,'no external requests');
  fs.writeFileSync(path.join(out,'browser_qa.json'),JSON.stringify({passed:checks.length,failed:0,checks,screens,errors,external_requests:requests,asset_count:data.assets.length,derivative_decodes:decodes.length,html_sha256:digest(file),html_bytes:fs.statSync(file).size,mode:'standalone offline Chrome file artifact; no server',downloads:names},null,2));
  console.log(JSON.stringify({passed:checks.length,images:data.assets.length,screens:screens.length,html_sha256:digest(file)}));
 }catch(e){
  await shot('failure');fs.writeFileSync(path.join(out,'diagnostic_browser_qa.json'),JSON.stringify({error:String(e),checks,errors,external_requests:requests,screens,html_sha256:digest(file)},null,2));throw e;
 }finally{await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
