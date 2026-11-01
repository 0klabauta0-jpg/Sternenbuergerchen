const {chromium}=require('C:/Users/bjoer/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const fs=require('fs'),path=require('path'),crypto=require('crypto'),{pathToFileURL}=require('url');
const out=__dirname,root=path.resolve(out,'../../..'),html=path.join(root,'docs/reports/STERNENBUERGERCHEN_GRAFIK_2026-11-01.html');
const hash=()=>crypto.createHash('sha256').update(fs.readFileSync(html)).digest('hex');
const report={html_sha256_start:hash(),checks:[],errors:[],screenshots:[]};
const check=(name,pass,extra={})=>report.checks.push({name,pass:!!pass,...extra});
(async()=>{
 const b=await chromium.launch({executablePath:'C:/Users/bjoer/AppData/Local/ms-playwright/chromium-1234/chrome-win64/chrome.exe',headless:true,args:['--disable-gpu']});
 try{
  for(const [name,width,height] of [['desktop',1440,1000],['mobile',390,844]]){
   const c=await b.newContext({viewport:{width,height},isMobile:name==='mobile'});await c.setOffline(true);
   const p=await c.newPage();p.on('pageerror',e=>report.errors.push(e.message));
   await p.goto(pathToFileURL(html).href,{waitUntil:'load'});
   const section=p.locator('#naechste-grafikschritte');await section.waitFor();
   const cards=section.locator('.next-art-card');check(name+'_six_roadmap_cards',await cards.count()===6);
   if(name==='desktop'){
    const intro=await section.locator('.next-art-intro').innerText();
    check('kenney_provisional_and_future_armor',intro.includes('vorläufig')&&intro.includes('Rüstung')&&intro.includes('Aussehen'));
    for(let i=0;i<6;i++){
     const card=cards.nth(i),text=await card.innerText();
     check('roadmap_card_'+(i+1)+'_goal_gap_proposal_comparison',text.includes('Ziel:')&&text.includes('Sichtbarer Abstand.')&&text.includes('Was ich ändern würde.')&&text.includes('Vergleich danach.'),{heading:await card.locator('h3').innerText()});
    }
   }
   const dims=await p.evaluate(()=>({width:innerWidth,scroll:document.documentElement.scrollWidth,body:document.body.scrollWidth}));
   check(name+'_roadmap_horizontal_overflow_zero',Math.max(dims.scroll,dims.body)<=dims.width,{dimensions:dims});
   const screenshot=path.join(out,name==='desktop'?'08_desktop_roadmap.png':'09_mobile_roadmap.png');
   await section.screenshot({path:screenshot});report.screenshots.push(screenshot);await c.close();
  }
 }catch(e){report.errors.push(e.message);}
 await b.close();report.html_sha256_end=hash();
 report.pass=report.errors.length===0&&report.checks.every(c=>c.pass)&&report.html_sha256_start===report.html_sha256_end;
 fs.writeFileSync(path.join(out,'roadmap_section.json'),JSON.stringify(report,null,2));console.log(JSON.stringify(report,null,2));if(!report.pass)process.exitCode=1;
})();
