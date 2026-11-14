const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto');
const {chromium}=require(process.argv[2]);
const origin='https://sternenbuergerchen-spielanleitung.klabauta.chatgpt.site';
(async()=>{const checks=[],errors=[];let browser;const check=(ok,label)=>{checks.push({ok:!!ok,label});if(!ok)throw Error(label);};try{
 for(const asset of ['index.html','style.css','combat.js','guide.js','assets/home.png','assets/jobs.png','assets/starmap.png','assets/Rajdhani-SemiBold.ttf','assets/OFL.txt']){
  const response=await fetch(origin+'/'+asset);check(response.status===200,'Anonymous HTTP 200 '+asset);
  const content=Buffer.from(await response.arrayBuffer());const local=fs.readFileSync(path.resolve(__dirname,'../../player_guide',asset));
  if(asset==='index.html'){
   const html=content.toString('utf8'),original=local.toString('utf8'),end='</body></html>\n',prefix=original.slice(0,-end.length);
   check(original.endsWith(end)&&html.startsWith(prefix)&&html.endsWith(end),'Complete authored HTML preserved');
   const edge=html.slice(prefix.length,-end.length);
   check(edge===''||(edge.startsWith('<script>(function(){function c(){')&&edge.endsWith('</script>')&&edge.includes('/cdn-cgi/challenge-platform/scripts/jsd/main')&&edge.includes('window.__CF$cv$params')),'Only observed Cloudflare security script appended');
  }else check(crypto.createHash('sha256').update(content).digest('hex')===crypto.createHash('sha256').update(local).digest('hex'),'Published bytes match '+asset);
 }
 browser=await chromium.launch({channel:'chrome',headless:true});const context=await browser.newContext({viewport:{width:390,height:844}});const page=await context.newPage();page.on('pageerror',e=>errors.push(String(e)));
 await page.goto(origin,{waitUntil:'networkidle'});check(await page.title()==='Sternenbürgerchen · Spielanleitung','Fresh anonymous browser opens real guide');
 await page.locator('#moving').check();check((await page.locator('#chance').textContent()).includes('33,6'),'Live calculator works');
 check(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1),'Live mobile layout fits');check(errors.length===0,'No runtime errors');
}catch(e){errors.push(String(e));process.exitCode=1;}finally{if(browser)await browser.close();const result={url:origin,anonymous:true,passed:checks.filter(c=>c.ok).length,failed:checks.filter(c=>!c.ok).length+(errors.length?1:0),checks,errors};fs.writeFileSync(path.join(__dirname,'guide/public_verification.json'),JSON.stringify(result,null,2));console.log(JSON.stringify(result));}})();
