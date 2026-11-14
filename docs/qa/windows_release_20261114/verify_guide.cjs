const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const {pathToFileURL}=require('node:url');
const root=path.resolve(__dirname,'../../..');
const guide=path.join(root,'docs/player_guide');
const {calculate,weapons}=require(path.join(guide,'combat.js'));
const checks=[],errors=[];
function check(ok,label){checks.push({ok:!!ok,label});assert.ok(ok,label);}
function near(actual,expected,label){check(Math.abs(actual-expected)<1e-10,label);}
(async()=>{
 const out=path.resolve(process.argv[3]||path.join(__dirname,'guide'));fs.mkdirSync(out,{recursive:true});
 let browser;
 try{
  const source=fs.readFileSync(path.join(root,'scripts/core/weapon_data.gd'),'utf8');
  for(const [id,weapon]of Object.entries(weapons)){
   const block=source.match(new RegExp('\\t"'+id+'": \\{([\\s\\S]*?)\\n\\t\\}'))?.[1];check(!!block,id+' exists in runtime');
   for(const [key,field]of [['chance','base_hit_chance'],['damage','damage_per_hit'],['range','effective_tile_range']])near(weapon[key],Number(block.match(new RegExp('"'+field+'": ([0-9.]+)'))[1]),id+' '+field+' matches source');
  }
  const example={weapon:'rifle',accuracy:50,ownCover:20,targetCover:40,height:1,roll:.3};
  let r=calculate(example);near(r.chance,.42,'Worked standing example 42%');check(r.damage===37&&r.hit,'Worked damage 37 and roll .30 hits');
  near(calculate({...example,moving:true}).chance,.336,'Moving example 33.6%');
  check(!calculate({...example,roll:.42}).hit,'Exact decimal threshold misses');
  near(calculate({weapon:'rifle',accuracy:50,attack:100,moving:true}).chance,.76,'Upper cap before movement, then .8 multiplier');
  near(calculate({weapon:'rifle',accuracy:0,targetCover:80,height:-2,profile:-100,moving:true}).chance,.05,'Minimum after movement remains 5%');
  near(calculate({...example,flank:true}).chance,.76,'Flank changes chance and removes target cover');
  check(calculate({...example,flank:true}).damage===52,'Flank damage 40 x 1.3');
  near(calculate({...example,spotted:true}).chance,.27,'Spotted contact costs 15 points before accuracy');
  near(calculate({weapon:'sniper',accuracy:50,support:22,spotted:true,flank:true}).base,.82,'Ordered support/contact/flank calculation');
  check(calculate({...example,targetDamage:0}).damage===0,'Zero target multiplier prevents damage');
  check(Number.isFinite(calculate({accuracy:Infinity,targetCover:NaN}).chance),'Invalid nonfinite input produces finite explanatory result');
  const {chromium}=require(process.argv[2]);browser=await chromium.launch({channel:'chrome',headless:true});
  const context=await browser.newContext({viewport:{width:390,height:844}});const page=await context.newPage();page.on('pageerror',e=>errors.push(String(e)));
  await page.goto(pathToFileURL(path.join(guide,'index.html')).href);await page.evaluate(()=>document.fonts.ready);
  check(await page.locator('[data-chapter]').count()===10,'Ten complete guide chapters');
  check((await page.locator('#chance').textContent()).includes('42'),'Calculator renders example');
  await page.locator('#moving').check();check((await page.locator('#chance').textContent()).includes('33,6'),'Calculator reacts to movement');
  await page.locator('#reset-calc').click();await page.locator('#roll').fill('0.42');check((await page.locator('#roll-result').textContent()).includes('Verfehlt'),'UI explains strict threshold');
  await page.locator('#reset-calc').click();
  for(const width of [320,390,768,1440]){await page.setViewportSize({width,height:900});check(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1),'No horizontal page overflow at '+width);}
  await page.setViewportSize({width:390,height:844});await page.locator('#search').fill('Satelliten');check(await page.locator('[data-chapter]:visible').count()<10&&await page.locator('[data-chapter]:visible').count()>0,'Search filters chapters');
  await page.locator('#search').fill('unfindbar98765');check(await page.locator('[data-chapter]:visible').count()===0,'Truthful empty search state');await page.locator('#search').fill('');
  await page.locator('[data-step="crew"]').check();await page.reload();check(await page.locator('[data-step="crew"]').isChecked(),'Checklist persists locally');await page.locator('#reset-steps').click();check(!(await page.locator('[data-step="crew"]').isChecked()),'Checklist reset');
  const imageButton=page.locator('[data-image]').first();await imageButton.focus();await page.keyboard.press('Enter');check(await page.locator('#image-dialog').evaluate(el=>el.open),'Image opens with keyboard');await page.keyboard.press('Escape');check(!(await page.locator('#image-dialog').evaluate(el=>el.open)),'Image closes with Escape');
  check(await imageButton.evaluate(el=>el===document.activeElement),'Image focus restored');
  const anchors=await page.locator('a[href^="#"]').evaluateAll(nodes=>nodes.map(n=>n.getAttribute('href')));for(const a of anchors)check(await page.locator(a).count()===1,'Anchor '+a+' resolves');
  for(const image of await page.locator('main img').all()){await image.scrollIntoViewIfNeeded();await image.evaluate(el=>el.decode());check(await image.evaluate(el=>el.naturalWidth>0),'Native image loads');}
  await page.evaluate(()=>{document.activeElement.blur();window.scrollTo({top:0,behavior:'instant'});});await page.screenshot({path:path.join(out,'guide_mobile.png')});await page.locator('.calculator').scrollIntoViewIfNeeded();await page.screenshot({path:path.join(out,'calculator_mobile.png')});
  await page.setViewportSize({width:1440,height:1000});await page.evaluate(()=>window.scrollTo({top:0,behavior:'instant'}));await page.screenshot({path:path.join(out,'guide_desktop.png')});
  check(errors.length===0,'No browser JavaScript errors');
 }catch(e){errors.push(String(e));process.exitCode=1;}finally{if(browser)await browser.close();const result={passed:checks.filter(c=>c.ok).length,failed:checks.filter(c=>!c.ok).length+(errors.length?1:0),checks,errors};fs.writeFileSync(path.join(out,'verification.json'),JSON.stringify(result,null,2));console.log(JSON.stringify({passed:result.passed,failed:result.failed,errors}));}
})();
