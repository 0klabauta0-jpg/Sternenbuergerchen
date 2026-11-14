const fs=require('node:fs'),path=require('node:path');
const {pathToFileURL}=require('node:url');const {chromium}=require(process.argv[2]);
(async()=>{const checks=[],errors=[];const check=(ok,label)=>{checks.push({ok:!!ok,label});if(!ok)throw Error(label);};let browser;
try{browser=await chromium.launch({channel:'chrome',headless:true});const context=await browser.newContext({viewport:{width:390,height:844},acceptDownloads:true});await context.setOffline(true);await context.addInitScript(()=>Object.defineProperty(window,'showDirectoryPicker',{value:undefined}));const page=await context.newPage();page.on('pageerror',e=>errors.push(String(e)));
await page.goto(pathToFileURL(path.resolve(process.argv[3]||'docs/reports/SPIELREVIEW_2026_11_12.html')).href);
check(await page.locator('#windows-delivery').count()===1,'Current delivery section exists once');check(await page.locator('#review-completion').count()===1,'Prior evidence retained');
check((await page.locator('#windows-delivery').textContent()).includes('a377c7346'),'Actual EXE source displayed');
check(await page.locator('#windows-delivery a[href="https://sternenbuergerchen-spielanleitung.klabauta.chatgpt.site"]').count()===1,'Public guide linked');
check(await page.locator('#windows-delivery img').count()===9,'Six current captures and three user references retained');
check(await page.locator('#windows-delivery img').evaluateAll(async images=>{await Promise.all(images.map(i=>{i.loading='eager';return i.decode().catch(()=>{});}));return images.every(i=>i.naturalWidth>0);}), 'All revision images load offline');
for(const width of [320,390,1440]){await page.setViewportSize({width,height:844});check(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1),'Report fits '+width);}
await page.locator('[data-export-key="delivery.exe"]').selectOption('pass');await page.locator('[data-export-key="delivery.note"]').fill('Offline geprüfter Export');
await page.locator('[data-export-key="delivery.maps"]').selectOption('revise');
const download=page.waitForEvent('download');await page.locator('#exportJsonButton').click();await download;const exported=JSON.parse(await page.locator('#jsonOutput').inputValue());
check(exported.schema==='sternenbuergerchen.html_workbench.v1','Workbench schema retained');check(exported.controls.delivery.exe==='pass'&&exported.controls.delivery.note==='Offline geprüfter Export','Delivery assessment and notes exported');
check(exported.controls.delivery.maps==='revise','Map decision exported');
check(errors.length===0,'No JavaScript errors');
}catch(e){errors.push(String(e));process.exitCode=1;}finally{if(browser)await browser.close();const result={passed:checks.filter(c=>c.ok).length,failed:checks.filter(c=>!c.ok).length+(errors.length?1:0),checks,errors};fs.writeFileSync(path.join(__dirname,'delivery_report_verification.json'),JSON.stringify(result,null,2));console.log(JSON.stringify(result));}})();
