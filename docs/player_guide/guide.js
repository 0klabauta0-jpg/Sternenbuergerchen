(function(){
  'use strict';
  const $=id=>document.getElementById(id);
  const pct=x=>new Intl.NumberFormat('de-DE',{maximumFractionDigits:2}).format(x*100)+' %';
  const num=x=>new Intl.NumberFormat('de-DE',{maximumFractionDigits:4}).format(x);
  const form=$('hit-form');
  function updateCalculator(){
    const read=id=>$(id).type==='checkbox'?$(id).checked:$(id).value;
    const result=GuideCombat.calculate({weapon:read('weapon'),accuracy:read('accuracy'),ownCover:read('own-cover'),targetCover:read('target-cover'),height:read('height'),roll:read('roll'),moving:read('moving'),flank:read('flank'),spotted:read('spotted'),support:read('support'),attack:read('attack'),profile:read('profile'),evasion:read('evasion'),baseDamage:read('base-damage'),targetDamage:read('target-damage')});
    $('chance').textContent=pct(result.chance);$('damage').textContent=result.damage;
    $('roll-result').textContent='Wurf '+num(result.roll)+' → '+(result.hit?'Treffer':'Verfehlt');
    $('breakdown').textContent='Angepasste Waffenbasis '+pct(result.base)+' · vor Begrenzung '+pct(result.raw)+' · begrenzt '+pct(result.standing)+' · Bewegungsfaktor '+num(result.movement)+' → '+pct(result.chance)+(read('flank')?' · Zieldeckung durch Flanke: 0':'');
  }
  form.addEventListener('input',updateCalculator);form.addEventListener('change',updateCalculator);form.addEventListener('submit',e=>e.preventDefault());
  $('reset-calc').addEventListener('click',()=>{form.reset();updateCalculator();});updateCalculator();
  const chapters=Array.from(document.querySelectorAll('[data-chapter]'));
  const norm=s=>s.toLocaleLowerCase('de-DE').normalize('NFD').replace(/[\u0300-\u036f]/g,'').replace(/ß/g,'ss');
  const searchIndex=new Map(chapters.map(s=>[s,norm(s.textContent)]));
  function search(){const query=norm($('search').value.trim());let count=0;for(const chapter of chapters){const visible=!query||searchIndex.get(chapter).includes(query);chapter.hidden=!visible;if(visible)count++;document.querySelector('nav a[href="#'+chapter.id+'"]').hidden=!visible;}$('search-result').hidden=!query;$('search-result').textContent=count?count+' passende Kapitel':'Kein Kapitel gefunden. Suche kürzer oder verwende einen anderen Begriff.';}
  $('search').addEventListener('input',search);
  document.querySelectorAll('a[href^="#"]').forEach(a=>a.addEventListener('click',()=>{if($('search').value){$('search').value='';search();}}));
  const steps=Array.from(document.querySelectorAll('[data-step]'));const storageKey='sternenbuergerchen.guide.checklist.v1';
  try{const saved=JSON.parse(localStorage.getItem(storageKey)||'{}');steps.forEach(s=>s.checked=saved[s.dataset.step]===true);}catch(_e){}
  function updateSteps(){const done=steps.filter(s=>s.checked).length;$('step-progress').textContent=done+' / '+steps.length+' Schritte abgehakt';try{localStorage.setItem(storageKey,JSON.stringify(Object.fromEntries(steps.map(s=>[s.dataset.step,s.checked]))));}catch(_e){}}
  steps.forEach(s=>s.addEventListener('change',updateSteps));$('reset-steps').addEventListener('click',()=>{steps.forEach(s=>s.checked=false);updateSteps();});updateSteps();
  const dialog=$('image-dialog');document.querySelectorAll('[data-image]').forEach(button=>button.addEventListener('click',()=>{$('large-image').src=button.dataset.image;$('large-image').alt=button.querySelector('img').alt;$('large-caption').textContent=button.dataset.caption;dialog.showModal();}));
  dialog.querySelector('button').addEventListener('click',()=>dialog.close());dialog.addEventListener('click',e=>{if(e.target===dialog)dialog.close();});
})();
