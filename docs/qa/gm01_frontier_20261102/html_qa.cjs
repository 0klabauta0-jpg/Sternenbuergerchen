const fs=require('fs'),vm=require('vm'),assert=require('assert'),crypto=require('crypto'),path=require('path');
const report='docs/reports/STERNENBUERGERCHEN_GM01_FRONTIER_2026-11-02.html';
const outPath='docs/qa/gm01_frontier_20261102/html_export_qa.json';
const reportBytes=fs.readFileSync(report),html=reportBytes.toString('utf8'),source=html.match(/<script>([\s\S]*?)<\/script>/)[1],checks=[];
const reportHash=crypto.createHash('sha256').update(reportBytes).digest('hex');
function check(name,fn){try{fn();checks.push({name,status:'PASS'});}catch(error){checks.push({name,status:'FAIL',error:String(error.message||error)});throw error;}}
async function checkAsync(name,fn){try{await fn();checks.push({name,status:'PASS'});}catch(error){checks.push({name,status:'FAIL',error:String(error.message||error)});throw error;}}
function saveResult(status,error){const result={schema:'sternenbuergerchen.ui_native_html_offline_qa.v1',status,tested_at:new Date().toISOString(),runtime:process.version,report,report_sha256:reportHash,scope:'Actual full inline JavaScript executed in Node VM with a minimal synthetic DOM and mocked Blob/URL/clipboard/download APIs. No browser layout, real filesystem download, browser clipboard or Godot acceptance.',browser_status:'NOT_RUN_OFFLINE_DOM_ONLY',exported_controls:document.querySelectorAll('[data-export-key]').length,checks,repro_command:'node docs/qa/gm01_frontier_20261102/html_qa.cjs'};if(error)result.error=String(error.stack||error);fs.writeFileSync(outPath,JSON.stringify(result,null,2)+'\n');console.log(JSON.stringify({status,checks:checks.length,report_sha256:reportHash,output:outPath},null,2));}
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
const context={document,location:{href:'file:///local/STERNENBUERGERCHEN_GM01_FRONTIER_2026-11-02.html'},navigator:{userAgent:'NodeVM synthetic DOM',clipboard:{writeText:async s=>clipboard.push(s)}},Blob,URL:fakeURL,setTimeout:fn=>fn(),console};
context.window=context;document.getElementById=id=>document.querySelector("#"+id);vm.createContext(context);vm.runInContext(source,context);
const $=s=>document.querySelector(s),$$=s=>document.querySelectorAll(s),ids=$$('[id]').map(e=>e.id);

(async()=>{
 check('Unique IDs, template and local image references',()=>{assert.equal(new Set(ids).size,ids.length);assert(html.includes('Abgeleitet von docs/reports/_html_workbench_template.html'));for(const img of $$('img'))assert(fs.existsSync(path.resolve(path.dirname(report),img.getAttribute('src'))));assert.equal($$('img').length,6);assert(!/<(?:script|link)[^>]*(?:src|href)=["']https?:/i.test(html));});
 await checkAsync('Three tabs select exactly one panel',async()=>{for(const button of $$('.tab')){await button.click();assert.equal($$('.tab-panel.active').length,1);assert.equal($$('.tab-panel.active')[0].id,button.dataset.tabTarget);}});
 $('[data-export-key="playtest.style"]').checked=true;
 $('[data-export-key="playtest.observation"]').value='Mehr Sand am Rand — ÄÖÜ ß';
 $('[data-note-key="review.notes"]').innerText='Cutlass und Gelände passen.';
 await $('[data-choice-value="polish"]').click();
 await $('#exportJsonButton').click();
 const payload=JSON.parse($('#jsonOutput').value);
 check('Export includes hidden-tab values and UTF-8 notes',()=>{assert.equal(payload.schema,'sternenbuergerchen.html_workbench.v1');assert.equal(payload.report_id,'gm01_frontier_20261102');assert(payload.controls.playtest.style);assert.equal(payload.controls.playtest.observation,'Mehr Sand am Rand — ÄÖÜ ß');assert.equal(payload.notes.review.notes,'Cutlass und Gelände passen.');assert.equal(payload.active_choices.review.direction,'polish');assert.equal(downloads.length,1);assert(downloads[0].filename.endsWith('.json'));});
 await checkAsync('Copy and unavailable-clipboard fallback',async()=>{await $('#copyJsonButton').click();assert.equal(clipboard.length,1);context.navigator.clipboard=null;await $('#copyJsonButton').click();assert.equal(document.activeElement,$('#jsonOutput'));assert($('#jsonOutput').selected);});
 saveResult('PASS');
})().catch(error=>{saveResult('FAIL',error);console.error(error.stack);process.exitCode=1;});
