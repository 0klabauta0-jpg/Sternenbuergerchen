const {chromium}=require('C:/Users/bjoer/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const fs=require('fs'),path=require('path'),{pathToFileURL}=require('url');
const out=__dirname,root=path.resolve(out,'../../..');
(async()=>{
 const b=await chromium.launch({executablePath:'C:/Users/bjoer/AppData/Local/ms-playwright/chromium-1234/chrome-win64/chrome.exe',headless:true,args:['--disable-gpu']});
 const c=await b.newContext({viewport:{width:390,height:844},isMobile:true});await c.setOffline(true);
 const p=await c.newPage(),r={checks:[],errors:[]};
 p.on('pageerror',e=>r.errors.push(e.message));
 try{
  await p.goto(pathToFileURL(path.join(root,'docs/reports/STERNENBUERGERCHEN_GRAFIK_2026-11-01.html')).href);
  await p.locator('button[data-engine-view="crew"]').click();await p.locator('#engineImageButton').click();
  await p.locator('#dialogNotes').scrollIntoViewIfNeeded();
  await p.locator('#dialogNotes').click();await p.locator('#dialogNotes').fill('QA mobile: accessible dialog note');
  await p.locator('#dialogDecision').selectOption('revise');
  r.checks.push({name:'mobile_note_click_and_edit',pass:await p.locator('#dialogNotes').inputValue()==='QA mobile: accessible dialog note'});
  await p.screenshot({path:path.join(out,'07_mobile_note_edit.png')});
  await p.locator('#closeDialog').click();await p.locator('#engineImageButton').click();
  r.checks.push({name:'mobile_note_reopen_persisted',pass:await p.locator('#dialogNotes').inputValue()==='QA mobile: accessible dialog note'});
  r.checks.push({name:'mobile_decision_reopen_persisted',pass:await p.locator('#dialogDecision').inputValue()==='revise'});
  await p.locator('#closeDialog').click();
 }catch(e){r.errors.push(e.message);}
 await b.close();r.pass=r.errors.length===0&&r.checks.every(x=>x.pass);
 fs.writeFileSync(path.join(out,'mobile_notes_followup.json'),JSON.stringify(r,null,2));console.log(JSON.stringify(r,null,2));if(!r.pass)process.exitCode=1;
})();
