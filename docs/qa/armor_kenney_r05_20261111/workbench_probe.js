async page => {
 const storageKey='sternenbuergerchen.armor_comparison_20261111.v1';
 const prior=await page.evaluate(k=>localStorage.getItem(k),storageKey);
 await page.evaluate(k=>localStorage.removeItem(k),storageKey);
 try {
 const checks=[],errors=[];const check=(ok,label)=>{if(!ok)throw Error(label);checks.push(label);};
 page.on('pageerror',e=>errors.push(String(e)));page.on('console',m=>{if(m.type()==='error')errors.push(m.text());});
 await page.reload();await page.waitForFunction(()=>document.querySelector('#targetImage').naturalWidth>0&&document.querySelector('#nativeImage').naturalWidth>0);
 check(await page.title()==='Rüstung · Vorlage und Modell','Offline report opens');
 const ready=await page.evaluate(()=>window.armorWorkbench.catalog.variants.r05.available);
 const variant=ready?'r05':'r04';await page.selectOption('#variant',variant);
 const variants=await page.evaluate(()=>Object.keys(window.armorWorkbench.catalog.variants).filter(k=>window.armorWorkbench.catalog.variants[k].available));
 for(const testedVariant of variants){
 await page.selectOption('#variant',testedVariant);
 for(const armor of ['light','medium','heavy']){
  await page.selectOption('#armor',armor);
  for(const view of ['front','side','rear','top','quarter']){
   await page.selectOption('#view',view);await page.waitForFunction(()=>document.querySelector('#nativeImage').complete&&document.querySelector('#nativeImage').naturalWidth>0);
   check(await page.locator('#nativeImage').isVisible(),testedVariant+'/'+armor+'/'+view+' native image loads');
   const fitted=await page.evaluate(()=>{window.armorWorkbench.fitFigures();const s=window.armorWorkbench.payload().controls,c=window.armorWorkbench.catalog;const specs=[['targetImage',c.classes[s.armor].frames[s.view]],['nativeImage',c.variants[s.variant].frames[s.view][s.armor]]];const bounds=specs.map(([id,f])=>{const image=document.getElementById(id),frame=image.parentElement,scale=parseFloat(image.style.width)/f.width,top=parseFloat(image.style.top)+f.body.y*scale;return {top,bottom:top+f.body.height*scale,height:frame.clientHeight};});return bounds.every(b=>b.top>=15&&b.bottom<=b.height-15)&&Math.abs(bounds[0].top-bounds[1].top)<1&&Math.abs(bounds[0].bottom-bounds[1].bottom)<1;});
   check(fitted,testedVariant+'/'+armor+'/'+view+' whole figures fit at matching height');
  }
 }
 }
 await page.selectOption('#variant',variant);
 await page.selectOption('#armor','medium');await page.selectOption('#view','front');await page.selectOption('#tone','mono');
 check(await page.locator('#targetImage').evaluate(e=>e.classList.contains('mono')),'Grayscale applies to reference and model');
 await page.selectOption('#tone','color');await page.click('#openTarget');check(await page.locator('#imageDialog').isVisible(),'Full reference opens in dialog');await page.click('#closeDialog');
 await page.click('[data-tab="review"]');await page.locator('[data-check="medium.wrap"]').check();
 await page.selectOption('#noteArmor','medium');await page.fill('#note','QA-Mittel: Schulterübergang vergleichen.');await page.selectOption('#decision','revise');
 await page.selectOption('#noteArmor','light');check(await page.inputValue('#note')==='','Notes are independent per class');
 await page.fill('#note','QA-Leicht: Abdeckung.');await page.selectOption('#decision','close');
 await page.reload();await page.click('[data-tab="review"]');await page.selectOption('#noteArmor','medium');
 check(await page.inputValue('#note')==='QA-Mittel: Schulterübergang vergleichen.','Notes survive reload');
 check(await page.locator('[data-check="medium.wrap"]').isChecked(),'Check status survives reload');
 const downloadPromise=page.waitForEvent('download');await page.click('#exportJsonButton');const download=await downloadPromise;
 await download.saveAs('C:/dev/SternenBuergerchen-worktrees/native-glut-maps-20261110/output/playwright/armor_review/roundtrip.json');
 const exported=JSON.parse(await page.inputValue('#jsonOutput'));
 check(exported.schema==='sternenbuergerchen.html_workbench.v1'&&exported.controls.checks['medium.wrap']===true,'Export captures controls and checkbox');
 check(exported.active_choices.light==='close'&&exported.notes.medium.includes('Schulter'),'Export captures class judgments and notes');
 const before=await page.evaluate(()=>JSON.stringify(window.armorWorkbench.payload().notes));
 await page.locator('#importJsonInput').setInputFiles({name:'bad.json',mimeType:'application/json',buffer:Buffer.from('{"schema":"wrong"}')});
 await page.waitForFunction(()=>document.querySelector('#status').textContent.includes('abgelehnt'));
 check((await page.locator('#status').textContent()).includes('abgelehnt'),'Foreign schema rejected');
 check(await page.evaluate(()=>JSON.stringify(window.armorWorkbench.payload().notes))===before,'Rejected import preserves state');
 await page.fill('#note','Changed after export');
 await page.locator('#importJsonInput').setInputFiles('C:/dev/SternenBuergerchen-worktrees/native-glut-maps-20261110/output/playwright/armor_review/roundtrip.json');
 await page.waitForFunction(()=>document.querySelector('#status').textContent.includes('importiert'));
 await page.selectOption('#noteArmor','medium');check(await page.inputValue('#note')==='QA-Mittel: Schulterübergang vergleichen.','Valid file import restores review notes');
 await page.click('[data-tab="comparison"]');await page.selectOption('#armor','medium');await page.selectOption('#view','front');
 await page.screenshot({path:'C:/dev/SternenBuergerchen-worktrees/native-glut-maps-20261110/output/playwright/armor_review/desktop.png',fullPage:true});
 await page.setViewportSize({width:390,height:844});
 check(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1),'Mobile has no horizontal overflow');
 await page.screenshot({path:'C:/dev/SternenBuergerchen-worktrees/native-glut-maps-20261110/output/playwright/armor_review/mobile.png',fullPage:true});
 await page.setViewportSize({width:1600,height:1000});
 check(errors.length===0,'No page or console errors');
 check(await page.locator('footer').evaluate(e=>getComputedStyle(e).position==='static'),'Export toolbar stays below figures without overlay');
 await page.evaluate(({checks,errors,variant})=>{window.__armorQA={checks,errors,variant};localStorage.removeItem('sternenbuergerchen.armor_comparison_20261111.v1');},{checks,errors,variant});
 console.log(JSON.stringify({checks,errors,variant}));
 } finally {await page.evaluate(({k,v})=>{if(v===null)localStorage.removeItem(k);else localStorage.setItem(k,v);},{k:storageKey,v:prior});}
}
