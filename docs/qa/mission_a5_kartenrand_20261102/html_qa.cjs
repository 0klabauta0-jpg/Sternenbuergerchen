const fs=require('fs'),vm=require('vm'),assert=require('assert'),crypto=require('crypto'),path=require('path');
const report='docs/reports/STERNENBUERGERCHEN_MISSION_A5_2026-11-02.html';
const outPath='docs/qa/mission_a5_kartenrand_20261102/html_export_qa.json';
const reportBytes=fs.readFileSync(report),html=reportBytes.toString('utf8'),source=html.match(/<script>([\s\S]*?)<\/script>/)[1],checks=[];
const reportHash=crypto.createHash('sha256').update(reportBytes).digest('hex');
function check(name,fn){try{fn();checks.push({name,status:'PASS'});}catch(error){checks.push({name,status:'FAIL',error:String(error.message||error)});throw error;}}
async function checkAsync(name,fn){try{await fn();checks.push({name,status:'PASS'});}catch(error){checks.push({name,status:'FAIL',error:String(error.message||error)});throw error;}}
function saveResult(status,error){const result={schema:'sternenbuergerchen.ui_native_html_offline_qa.v1',status,tested_at:new Date().toISOString(),runtime:process.version,report,report_sha256:reportHash,scope:'Actual full inline JavaScript executed in Node VM with a minimal synthetic DOM and mocked Blob/URL/clipboard/download APIs. No browser layout, real filesystem download, browser clipboard or Godot acceptance.',browser_status:'NOT_RUN_OFFLINE_DOM_ONLY',exported_controls:document.querySelectorAll('[data-export-key]').length,checks,repro_command:'node docs/qa/mission_a5_kartenrand_20261102/html_qa.cjs'};if(error)result.error=String(error.stack||error);fs.writeFileSync(outPath,JSON.stringify(result,null,2)+'\n');console.log(JSON.stringify({status,checks:checks.length,report_sha256:reportHash,output:outPath},null,2));}
check('Final inline JavaScript compiles',()=>new vm.Script(source));
let focused=null,downloads=[],clipboard=[],revoked=[],createdBlobs=[];
function attrName(key){return 'data-'+key.replace(/[A-Z]/g,x=>'-'+x.toLowerCase());}
function matches(node,selector){
 if(selector.includes(' ')){const parts=selector.trim().split(/\s+/),last=parts.pop();if(!matches(node,last))return false;let ancestor=node.parent;while(ancestor){if(matches(ancestor,parts.join(' ')))return true;ancestor=ancestor.parent;}return false;}
 let s=selector,checked=s.endsWith(':checked');if(checked)s=s.slice(0,-8);if(checked&&!node.checked)return false;
 const attr=/\[([^\]^=]+)(\^=|=)?(?:"([^"]*)"|'([^']*)')?\]/g;let m;
 while((m=attr.exec(s))){const value=node.getAttribute(m[1]);if(value===null)return false;if(m[2]==='='&&value!==(m[3]??m[4]))return false;if(m[2]==='^='&&!value.startsWith(m[3]??m[4]))return false;}
 s=s.replace(attr,'');const id=s.match(/#([\w-]+)/);if(id&&node.id!==id[1])return false;
 for(const c of s.matchAll(/\.([\w-]+)/g))if(!node.className.split(/\s+/).includes(c[1]))return false;
 const tag=s.match(/^[a-z][\w-]*/i);return !tag||node.tagName===tag[0].toLowerCase();
}
class Element{
 constructor(tag){this.tagName=tag;this.attrs={};this.children=[];this.parent=null;this.events={};this._value=null;this.checked=false;this._text='';this.tabIndex=0;this.hidden=false;this.dataset=new Proxy({}, {get:(_,k)=>this.attrs[attrName(k)],set:(_,k,v)=>(this.attrs[attrName(k)]=String(v),true)});this.classList={toggle:(name,on)=>{const a=this.className.split(/\s+/).filter(Boolean),i=a.indexOf(name),has=i>=0;const next=on===undefined?!has:on;if(next&&!has)a.push(name);if(!next&&has)a.splice(i,1);this.className=a.join(' ');}};}
 setAttribute(k,v){this.attrs[k]=String(v);if(k==='checked')this.checked=true;if(k==='hidden')this.hidden=true;if(k==='value')this._value=String(v);if(k==='tabindex')this.tabIndex=Number(v);}
 getAttribute(k){return Object.hasOwn(this.attrs,k)?this.attrs[k]:null;}
 get id(){return this.attrs.id||'';}set id(x){this.attrs.id=x;}
 get className(){return this.attrs.class||'';}set className(x){this.attrs.class=x;}
 get type(){return this.attrs.type||'';}set type(x){this.attrs.type=x;}
 get value(){if(this._value!==null)return this._value;if(this.tagName==='select'){const options=this.querySelectorAll('option');return (options.find(x=>x.getAttribute('selected')!==null)||options[0])?.value||'';}return this.tagName==='textarea'?this._text:this.attrs.value||'';}set value(x){this._value=String(x);}
 get textContent(){return this._text+this.children.map(x=>x.textContent).join('');}set textContent(x){this._text=String(x);this.children=[];}
 get innerText(){return this.textContent;}set innerText(x){this.textContent=x;}
 set innerHTML(x){this.children=[];this._text='';parseInto(String(x),this);}
 appendChild(x){x.parent=this;this.children.push(x);return x;}
 remove(){if(this.parent)this.parent.children=this.parent.children.filter(x=>x!==this);}
 querySelectorAll(s){const out=[];function visit(x){for(const child of x.children){if(matches(child,s))out.push(child);visit(child);}}visit(this);return out;}
 querySelector(s){return this.querySelectorAll(s)[0]||null;}
 closest(selector){let node=this;while(node){if(matches(node,selector))return node;node=node.parent;}return null;}
 addEventListener(k,fn){(this.events[k]??=[]).push(fn);}
 async fire(k,event={}){for(const fn of this.events[k]||[])await fn(event);}
 click(){if(this.tagName==='a'&&this.download)downloads.push({filename:this.download,href:this.href});return this.fire('click');}
 focus(){focused=this.id||this;document.activeElement=this;}
 select(){this.selected=true;}
 showModal(){this.open=true;}
 close(){this.open=false;return this.fire('close');}
}
function parseInto(str,root){const stack=[root],voids=new Set(['area','base','br','col','embed','hr','img','input','link','meta','param','source','track','wbr']);for(const t of str.matchAll(/<!--[\s\S]*?-->|<![^>]*>|<\/?[a-zA-Z][^>]*>|[^<]+/g)){const token=t[0];if(token.startsWith('<!--')||token.startsWith('<!'))continue;if(token.startsWith('</')){const tag=token.match(/^<\/([\w-]+)/)[1].toLowerCase();let i=stack.length-1;while(i>0&&stack[i].tagName!==tag)i--;stack.length=Math.max(i,1);continue;}if(token.startsWith('<')){const tag=token.match(/^<([\w-]+)/)[1].toLowerCase(),e=new Element(tag);const attr=token.slice(tag.length+1,-1);for(const a of attr.matchAll(/([^\s=/>]+)(?:\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s>]+)))?/g))e.setAttribute(a[1],a[2]??a[3]??a[4]??'');stack[stack.length-1].appendChild(e);if(!voids.has(tag)&&!token.endsWith('/>'))stack.push(e);}else stack[stack.length-1]._text+=token;}}
const tree=new Element('document');parseInto(html.replace(/<style>[\s\S]*?<\/style>/g,'').replace(/<script>[\s\S]*?<\/script>/g,''),tree);
for(const element of tree.querySelectorAll('*')){element.classList.add=(...names)=>names.forEach(name=>element.classList.toggle(name,true));element.classList.remove=(...names)=>names.forEach(name=>element.classList.toggle(name,false));}
const document={title:tree.querySelector('title').textContent,body:tree.querySelector('body'),activeElement:null,querySelector:s=>tree.querySelector(s),querySelectorAll:s=>tree.querySelectorAll(s),createElement:tag=>new Element(tag)};
const fakeURL={createObjectURL(blob){createdBlobs.push(blob);return 'blob:test/'+createdBlobs.length},revokeObjectURL(url){revoked.push(url)}};
const context={document,location:{href:'file:///local/STERNENBUERGERCHEN_MISSION_A5_2026-11-02.html'},navigator:{userAgent:'NodeVM synthetic DOM',clipboard:{writeText:async s=>clipboard.push(s)}},Blob,URL:fakeURL,setTimeout:fn=>fn(),console};
context.window=context;document.getElementById=id=>document.querySelector("#"+id);vm.createContext(context);vm.runInContext(source,context);
const $=s=>document.querySelector(s),$$=s=>document.querySelectorAll(s),ids=$$('[id]').map(e=>e.id);

const REVIEW_SECTIONS=['team','dropship','protocol','stance','hud','edge'];

// Executes the actual repository-template JavaScript. The DOM is synthetic;
// no browser layout or real browser filesystem/download is claimed.
(async()=>{
 check('Unique IDs, two three-way comparisons and unchanged local images',()=>{
  assert.equal(new Set(ids).size,ids.length);
  assert(html.includes('Abgeleitet von docs/reports/_html_workbench_template.html'));
  assert.equal($$('.tab').length,3);
  assert.equal($$('.comparison').length,2);
  assert.equal($$('.small-view').length,1);
  for(const panel of $$('.comparison'))assert.equal(panel.querySelectorAll('img').length,3);
  for(const img of $$('img'))assert(fs.existsSync(path.resolve(path.dirname(report),img.getAttribute('src'))));
  assert(!/<(?:script|link)[^>]*(?:src|href)=["']https?:/i.test(html));
  assert(!/\b(?:fetch|XMLHttpRequest|WebSocket)\s*\(/.test(source));
 });
 check('Manual visual judgements start open',()=>{
  assert.equal($$('.tab-panel.active').length,1);
  assert.equal($$('.tab-panel.active')[0].id,'overview');
  for(const box of $$('input[type="checkbox"]'))assert(!box.checked);
  for(const section of REVIEW_SECTIONS)assert.equal($('[data-export-key="sections.'+section+'.status"]').value,'open');
  assert.equal($$('[data-choice-value="open"]')[0].className.includes('active'),true);
 });
 await checkAsync('Three tabs select exactly one panel',async()=>{
  for(const button of $$('.tab')){
   await button.click();
   assert.equal($$('.tab-panel.active').length,1);
   assert.equal($$('.tab-panel.active')[0].id,button.dataset.tabTarget);
  }
 });
 for(const section of REVIEW_SECTIONS){
  $('[data-export-key="sections.'+section+'.status"]').value='change';
  $('[data-export-key="sections.'+section+'.note"]').value='Konkreter Vergleich '+section+' – ÄÖÜ ß';
 }
 $('[data-export-key="playtest.hex1280"]').checked=true;
 $('[data-export-key="playtest.observation"]').value='Randfelder und Truppkarte prüfen.';
 $('[data-note-key="review.notes"]').innerText='Original A5 bleibt die Gestaltungsautorität.';
 await $('[data-choice-value="polish"]').click();
 await $('#exportJsonButton').click();
 const payload=JSON.parse($('#jsonOutput').value);
 check('Export retains hidden-tab notes, manual state and UTF-8',()=>{
  assert.equal(payload.schema,'sternenbuergerchen.html_workbench.v1');
  assert.equal(payload.report_id,'mission_a5_kartenrand_20261102');
  assert.deepEqual(Array.from(payload.computed.compared_sizes),['1920x1080','1280x720']);
  assert(payload.computed.saved_cell_count>0);
  assert.equal(payload.controls.playtest.hex1280,true);
  assert.equal(payload.controls.playtest.observation,'Randfelder und Truppkarte prüfen.');
  assert.equal(payload.notes.review.notes,'Original A5 bleibt die Gestaltungsautorität.');
  assert.equal(payload.active_choices.review.direction,'polish');
  for(const section of REVIEW_SECTIONS){
   assert.equal(payload.controls.sections[section].status,'change');
   assert.equal(payload.controls.sections[section].note,'Konkreter Vergleich '+section+' – ÄÖÜ ß');
  }
 });
 check('Target, historical and new native PNG hashes and bounds facts match',()=>{
  const evidence=payload.metadata.evidence;
  assert.equal(evidence.grid_topology,'hex_axial_v1');
  assert.equal(evidence.rendered_fow.passed,true);
  assert.equal(evidence.rendered_fow.headless,false);
  assert.equal(evidence.rendered_fow.project_restored_byte_exact,true);
  assert.equal(evidence.rendered_groups.passed,true);
  assert.equal(evidence.rendered_groups.headless,false);
  assert.equal(evidence.post_capture_input_fix.verified_exactly_one_call_relocated,true);
  const records=[evidence.target,...Object.values(evidence.historical)];
  assert.equal(Object.keys(evidence.normal).length,2);
  for(const row of Object.values(evidence.normal)){
   records.push(...Object.values(row.frames));
   assert.equal(row.summary.fixture,false);
   assert.equal(row.summary.transport_details_capture.opened,true);
   assert.equal(row.summary.character_details_capture.opened,true);
   assert(row.frames['03b_dropship_details'] && row.frames['05b_character_details']);
   assert.equal(row.summary.profile.ground_matches_saved_hex_coverage,true);
   assert.equal(row.summary.profile.authored_ground_cell_count,evidence.saved_cell_count);
   if(row.edge_walk_probe.requested){
    assert.equal(row.edge_walk_probe.passed,true);
    assert.equal(row.edge_walk_probe.no_private_actor_or_timer_writes,true);
    assert(row.frames['11_old_border_crossed']);
   }
  }
  assert(evidence.normal['1920x1080'].frames['10_all_saved_hexes']);
  for(const record of records){
   const file=path.resolve(path.dirname(report),record.image),bytes=fs.readFileSync(file);
   assert.equal(crypto.createHash('sha256').update(bytes).digest('hex'),record.sha256,file);
   assert.deepEqual([bytes.readUInt32BE(16),bytes.readUInt32BE(20)],record.dimensions,file);
   if(record.metadata)assert(fs.existsSync(path.resolve(path.dirname(report),record.metadata)));
  }
 });
 await checkAsync('Download fallback produces unique safe filenames and actual JSON',async()=>{
  await $('#exportJsonButton').click();
  assert.equal(downloads.length,2);
  assert.notEqual(downloads[0].filename,downloads[1].filename);
  assert(downloads[0].filename.endsWith('_01.json'));
  assert(downloads[1].filename.endsWith('_02.json'));
  assert(!/[\\/:]/.test(downloads[0].filename));
  assert.equal(JSON.parse(await createdBlobs[0].text()).report_id,'mission_a5_kartenrand_20261102');
  assert.equal(revoked.length,2);
 });
 await checkAsync('Copy and unavailable-clipboard fallback',async()=>{
  await $('#copyJsonButton').click();assert.equal(clipboard.length,1);
  context.navigator.clipboard=null;
  await $('#copyJsonButton').click();assert.equal(document.activeElement,$('#jsonOutput'));assert($('#jsonOutput').selected);
 });
 await checkAsync('Import changes review controls only and preserves real evidence',async()=>{
  const imported={controls:{sections:{hud:{status:'closer',note:'Importierte Sichtprüfung'}},playtest:{hex1280:false}},notes:{review:{notes:'Import bleibt Arbeitsnotiz.'}},active_choices:{review:{direction:'accept'}},metadata:{evidence:{forged:true}}};
  await $('#importJsonInput').fire('change',{target:{files:[{text:async()=>JSON.stringify(imported)}]}});
  const restored=JSON.parse($('#jsonOutput').value);
  assert.equal(restored.controls.sections.hud.status,'closer');
  assert.equal(restored.controls.sections.hud.note,'Importierte Sichtprüfung');
  assert.equal(restored.controls.playtest.hex1280,false);
  assert.equal(restored.notes.review.notes,'Import bleibt Arbeitsnotiz.');
  assert.equal(restored.active_choices.review.direction,'accept');
  assert.equal(restored.metadata.evidence.forged,undefined);
 });
 await checkAsync('Unavailable folder API retains download/text export fallback',async()=>{
  await $('#chooseExportFolderButton').click();
  assert($('#exportStatus').textContent.length>0);
  await $('#exportJsonButton').click();
  assert(downloads.length>=3);
  assert.doesNotThrow(()=>JSON.parse($('#jsonOutput').value));
 });
 saveResult('PASS');
})().catch(error=>{saveResult('FAIL',error);process.exitCode=1;});


