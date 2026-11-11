"""Offline graphics review, derived from the repository workbench template."""
from pathlib import Path
import hashlib
import json
import re
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
TEMPLATE = ROOT / 'docs/reports/_html_workbench_template.html'
style = re.search(r'<style>(.*?)</style>', TEMPLATE.read_text(encoding='utf-8'), re.S)[1]
views = {'front': 'Vorne', 'quarter': 'Dreiviertel', 'side': 'Seite', 'rear': 'Hinten', 'top': 'Oben'}
catalog = {'classes': {}, 'views': views, 'variants': {}}


def frame_bounds(file, index, columns, minimum_y=20, maximum_y=None):
    """Read image bounds only; leave the source PNG completely unchanged."""
    pixels = np.asarray(Image.open(file).convert('RGB')).astype(np.int16)
    height, width = pixels.shape[:2]
    left, right = round(index * width / columns), round((index + 1) * width / columns)
    top, bottom = minimum_y, min(maximum_y or height, height)
    region = pixels[top:bottom, left:right]
    background = (region[:, :6].mean(axis=1) + region[:, -6:].mean(axis=1)) * .5
    foreground = np.abs(region - background[:, None, :]).sum(axis=2) > 40
    foreground[:, :12] = False
    foreground[:, -12:] = False
    row_ids = np.flatnonzero(foreground.sum(axis=1) > 4)
    col_ids = np.flatnonzero(foreground.sum(axis=0) > 4)
    if not len(row_ids) or not len(col_ids):
        raise ValueError(f'No visible figure in {file.name}, panel{index}')
    return {'width': width, 'height': height,
        'panel': {'x': left, 'y': top, 'width': right-left, 'height': bottom-top},
        'body': {'x': left+int(col_ids[0]), 'y': top+int(row_ids[0]),
                 'width': int(col_ids[-1]-col_ids[0]+1), 'height': int(row_ids[-1]-row_ids[0]+1)}}


for index, (key, label) in enumerate([('light', 'Leicht'), ('medium', 'Mittel'), ('heavy', 'Schwer')]):
    file = ROOT / f'art/armor_orc_morozov_20261111/{key}_turnaround_ai_r04.png'
    catalog['classes'][key] = {'label': label, 'index': index,
        'target': f'../../art/armor_orc_morozov_20261111/{file.name}',
        'sha256': hashlib.sha256(file.read_bytes()).hexdigest(),
        'frames': {view: frame_bounds(file, panel, 4, 50 if key == 'light' else 20, 810)
                   for view, panel in [('front', 0), ('quarter', 0), ('rear', 1), ('side', 2), ('top', 3)]}}
for key, label, folder in [('r04', 'R04 · technischer Entwurf', 'armor_orc_morozov_20261111'),
                           ('r05_flat', 'R05 · vor der Wölbung (verworfen)', 'armor_kenney_r05_flat_20261111'),
                           ('r05', 'R05 · gewölbte Schalen', 'armor_kenney_r05_20261111')]:
    directory = ROOT / 'docs/qa' / folder
    available = all((directory / f'native_{view}.png').exists() for view in views)
    catalog['variants'][key] = {'label': label, 'available': available,
        'images': {view: f'../qa/{folder}/native_{view}.png' for view in views},
        'frames': {view: {armor: frame_bounds(directory / f'native_{view}.png', data['index'], 3, 55)
                         for armor, data in catalog['classes'].items()} for view in views} if available else {},
        'status': 'Nativer Modellstand; keine automatische Stilfreigabe' if available else 'Noch in Arbeit'}

page = r'''<!doctype html><html lang="de"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Rüstung · Vorlage und Modell</title><style>__STYLE__
main{max-width:1260px}.row{display:flex;flex-wrap:wrap;gap:12px;align-items:end}.row label{flex:1;min-width:145px}
.compare{display:grid;grid-template-columns:1fr 1fr;gap:18px;margin-top:18px}.pane{background:var(--panel);border:1px solid var(--line);padding:16px;border-radius:8px}
.frame{position:relative;overflow:hidden;height:clamp(460px,68vh,760px);background:#152831;margin:14px auto;width:100%}
.frame img{display:block;position:absolute;max-width:none;transform-origin:top left}.frame.target{background:#cec7bf}
.frame img.mono{filter:grayscale(1)}.caption{min-height:46px;font-size:14px}.small{font-size:13px}.criteria{display:grid;grid-template-columns:repeat(3,1fr);gap:14px;margin-top:18px}
.criteria article{border:1px solid var(--line);padding:14px;border-radius:8px}.criteria label{display:flex;gap:9px;align-items:start;margin:8px 0}.criteria input{width:auto;min-height:0;margin-top:5px}
dialog{background:var(--panel);color:var(--text);border:1px solid var(--line);border-radius:8px;width:min(1500px,96vw);max-height:95vh;padding:14px}dialog::backdrop{background:#000b}
dialog img{max-width:100%;max-height:80vh;object-fit:contain;display:block;margin:10px auto}footer textarea{max-height:100px}.note-panel{margin-top:18px}
.toolbar{position:static;backdrop-filter:none;margin-top:20px}.frame img{pointer-events:none}
@media(max-width:700px){.compare,.criteria{grid-template-columns:1fr}.frame{height:560px}header{padding:20px 16px}.row label{min-width:130px}dialog{width:98vw}}
</style></head><body data-report-id="armor_comparison_20261111" data-report-schema="sternenbuergerchen.html_workbench.v1">
<header><h1>Rüstung · Vorlage und Modell</h1><p>Kenney-Proportionen bleiben die Grundlage. ORC prägt leicht/mittel, Morozov die schwere Formfamilie.</p>
<div class="meta-row"><span class="pill">11.11.2026</span><span class="pill good">2D-Vorlagen vom Nutzer bestätigt</span><span class="pill warn">Native Stilabnahme separat</span></div></header>
<main><nav class="tabbar" aria-label="Arbeitsbereiche"><button class="tab active" data-tab="comparison">Vergleich</button><button class="tab" data-tab="review">Prüfung & Notizen</button><button class="tab" data-tab="sources">Quellen & Grenzen</button></nav>
<p class="small">Neuere Vorgabe zu diesen Tafeln: Auch leicht erhält feste Wangen und Kinnschutz. Leicht und mittel sollen mit klarem geschlossenem Visier weltraumtauglich wirken. Platten näher an den Körper führen, stärker der Körperrundung folgend wölben und übermäßige Dicke reduzieren. Diese Korrekturen haben Vorrang vor den älteren Bilddetails.</p>
<section id="comparison" class="tab-panel active"><div class="row" style="margin-top:18px">
<label>Rüstung<select id="armor" data-control="armor"><option value="light">Leicht</option><option value="medium">Mittel</option><option value="heavy">Schwer</option></select></label>
<label>Blickrichtung<select id="view" data-control="view"></select></label>
<label>Modellstand<select id="variant" data-control="variant"></select></label>
<label>Darstellung<select id="tone" data-control="tone"><option value="color">Farbe</option><option value="mono">Graustufen</option></select></label></div>
<div class="compare"><article class="pane"><h2>Bestätigte 2D-Richtung</h2><p class="caption" id="targetCaption"></p><div class="frame target"><img id="targetImage" alt="Generierte Rüstungsvorlage"></div><button class="secondary" id="openTarget">Gesamte Tafel öffnen</button></article>
<article class="pane"><h2>Nativer Modellstand</h2><p class="caption" id="nativeCaption"></p><div class="frame"><img id="nativeImage" alt="Tatsächliches Modell in Godot"><p id="pending" hidden style="padding:20px">Der neue Modellstand wird gerade erstellt.</p></div><button class="secondary" id="openNative">Gesamte Aufnahme öffnen</button></article></div>
<p class="small">Vorlage und Modell werden ohne Verzerrung auf dieselbe sichtbare Figurenhöhe eingepasst; Kopf und Stiefel bleiben vollständig im Bild. Die Originaldateien bleiben unverändert. Bei Dreiviertel bleibt die vordere 2D-Vorlage sichtbar; die KI-Draufsicht ist geneigt. Der native obere Blick ist senkrecht. Graustufen sind ein Anzeigefilter.</p></section>
<section id="review" class="tab-panel"><div class="criteria" id="criteria"></div><article class="pane note-panel"><h2>Entscheidung je Rüstung</h2><p>Lokale Arbeitsnotizen, keine Änderung an Spiel oder Projektdateien.</p><label>Rüstung<select id="noteArmor"><option value="light">Leicht</option><option value="medium">Mittel</option><option value="heavy">Schwer</option></select></label><label>Visuelles Urteil<select id="decision"><option value="unreviewed">Noch nicht bewertet</option><option value="close">Nah an der Vorlage</option><option value="revise">Weiter überarbeiten</option></select></label><label>Konkrete Abweichung / Wunsch<textarea id="note" placeholder="Zum Beispiel: Kinnrahmen zu breit, Schulter noch zu flach …"></textarea></label></article></section>
<section id="sources" class="tab-panel"><article class="pane" style="margin-top:18px"><h2>Was ist hier zu sehen?</h2><p>Die linken Tafeln entstanden mit der eingebauten Bilder-KI aus dem bestehenden Kenney-Modell und den Star-Citizen-Referenzen. Sie sind Modellvorlagen. Die rechten Bilder zeigen tatsächliche native Modelle; ein bestandener Import ist keine gestalterische Abnahme.</p><p>R04 war ein technischer Entwurf. Astra überarbeitet insbesondere den anatomischen Sitz, Schulterdächer, Brustflächen und die geschlossenen Helme mit Wangen-/Kinnschutz. Ausrüstungswerte und Inventar verbleiben bei den bestehenden Ownern.</p><p>Eine geringe Meshzahl beweist keine allgemeine Framerate. Sitz-/Transportextreme bleiben getrennt zu prüfen. Fahrzeugmodelle sind zurückgestellt.</p><p><a href="../../art/armor_orc_morozov_20261111/README.md">Bildquellen, Prompts und Herkunft</a> · <a href="https://starcitizen.tools/Field_Recon_Suit">Field Recon Suit · zusätzliche Scout-Referenz</a> · <a href="https://starcitizen.tools/ORC-mkV">ORC-mkV</a> · <a href="https://starcitizen.tools/Morozov-SH">Morozov-SH</a></p><p class="small">Abgeleitet aus docs/reports/_html_workbench_template.html. Die Seite funktioniert lokal ohne Server und externe Laufzeitabhängigkeiten.</p></article></section></main>
<footer class="toolbar"><div class="export-actions"><button id="exportJsonButton">JSON exportieren</button><button class="secondary" id="copyJsonButton">JSON kopieren</button><label>JSON importieren<input id="importJsonInput" type="file" accept="application/json,.json"></label><span id="status" role="status" class="small">Notizen werden in diesem Browser lokal gespeichert.</span></div><textarea id="jsonOutput" readonly aria-label="JSON-Export" placeholder="Export erscheint hier …"></textarea></footer>
<dialog id="imageDialog"><div class="row"><strong id="dialogTitle"></strong><button id="closeDialog">Schließen</button></div><img id="dialogImage" alt="Unveränderte vollständige Bilddatei"></dialog>
<script>
const catalog=__CATALOG__;
const $=id=>document.getElementById(id), key='sternenbuergerchen.armor_comparison_20261111.v1';
const checkNames={silhouette:'Klassen ohne Farbe unterscheidbar',helmet:'Helm / Kopf / Kragen passen',seal:'Wangen, Kinn und Visier bilden einen geschlossenen Helm',fit:'Platten sitzen am Körper ohne übermäßigen Vorbau',wrap:'Gewölbte Plattenschalen folgen der Körperrundung',rear:'Rückseite folgt derselben Konstruktion',poses:'Lauf / Feuer / Kopfdrehung geprüft',owner:'Ausrüsten / Ablegen geprüft'};
let state={controls:{armor:'medium',view:'front',variant:catalog.variants.r05.available?'r05':'r04',tone:'color'},notes:{light:'',medium:'',heavy:''},decisions:{light:'unreviewed',medium:'unreviewed',heavy:'unreviewed'},checks:{}};
function validated(p){
 if(!p||p.schema!=='sternenbuergerchen.html_workbench.v1'||p.report_id!=='armor_comparison_20261111')throw Error('Dieser Export gehört nicht zu diesem Rüstungsvergleich.');
 const next=JSON.parse(JSON.stringify(state)),c=p.controls||{},notes=p.notes||{},choices=p.active_choices||{},checks=c.checks||{};
 for(const [k,allowed] of Object.entries({armor:Object.keys(catalog.classes),view:Object.keys(catalog.views),variant:Object.keys(catalog.variants),tone:['color','mono']}))if(c[k]!==undefined){if(!allowed.includes(c[k]))throw Error('Ungültiges Bedienfeld: '+k);next.controls[k]=c[k];}
 if(!catalog.variants[next.controls.variant].available)next.controls.variant='r04';
 for(const a of Object.keys(catalog.classes)){if(notes[a]!==undefined){if(typeof notes[a]!=='string'||notes[a].length>20000)throw Error('Ungültige Notiz');next.notes[a]=notes[a];}if(choices[a]!==undefined){if(!['unreviewed','close','revise'].includes(choices[a]))throw Error('Ungültiges Urteil');next.decisions[a]=choices[a];}}
 for(const a of Object.keys(catalog.classes))for(const k of Object.keys(checkNames)){const id=a+'.'+k;if(checks[id]!==undefined){if(typeof checks[id]!=='boolean')throw Error('Ungültiger Prüfstatus');next.checks[id]=checks[id];}}
 return next;
}
function payload(){return {schema:'sternenbuergerchen.html_workbench.v1',report_id:'armor_comparison_20261111',title:document.title,exported_at:new Date().toISOString(),controls:{...state.controls,checks:{...state.checks}},notes:{...state.notes},active_choices:{...state.decisions},computed:{reviewed_classes:Object.values(state.decisions).filter(v=>v!=='unreviewed').length,candidate_available:catalog.variants.r05.available},metadata:{source_template:'_html_workbench_template.html',image_catalog:catalog,only_local_review_notes:true}};}
function save(){try{localStorage.setItem(key,JSON.stringify(payload()));}catch{} }
function message(s){$('status').textContent=s;}
for(const [id,entries] of [['view',catalog.views],['variant',catalog.variants]])for(const [value,item] of Object.entries(entries)){const option=new Option(typeof item==='string'?item:item.label+(item.available?'':' · in Arbeit'),value);if(id==='variant'&&!item.available)option.disabled=true;$(id).append(option);}
for(const a of Object.keys(catalog.classes)){const article=document.createElement('article'),h=document.createElement('h3');h.textContent=catalog.classes[a].label;article.append(h);for(const [k,label] of Object.entries(checkNames)){const row=document.createElement('label'),input=document.createElement('input');input.type='checkbox';input.dataset.check=a+'.'+k;input.addEventListener('change',()=>{state.checks[input.dataset.check]=input.checked;save();});row.append(input,document.createTextNode(label));article.append(row);}$('criteria').append(article);}
function fitFigures(){const a=catalog.classes[state.controls.armor],view=state.controls.view,v=catalog.variants[state.controls.variant];if(!v.available)return;const entries=[[$('targetImage'),a.frames[view]],[$('nativeImage'),v.frames[view][state.controls.armor]]];if(entries.some(([img])=>!img.parentElement.clientWidth))return;
 const bodyHeight=Math.min(...entries.map(([img,f])=>Math.min(img.parentElement.clientHeight-32,(img.parentElement.clientWidth-32)*f.body.height/f.body.width)));
 for(const [img,f] of entries){const scale=bodyHeight/f.body.height,frame=img.parentElement;img.style.width=f.width*scale+'px';img.style.height=f.height*scale+'px';img.style.left=(frame.clientWidth-f.body.width*scale)/2-f.body.x*scale+'px';img.style.top=(frame.clientHeight-bodyHeight)/2-f.body.y*scale+'px';img.style.transform='none';img.style.clipPath=`inset(${100*f.panel.y/f.height}% ${100*(f.width-f.panel.x-f.panel.width)/f.width}% ${100*(f.height-f.panel.y-f.panel.height)/f.height}% ${100*f.panel.x/f.width}%)`;}
}
function render(){for(const [k,v] of Object.entries(state.controls))$(k).value=v;const a=catalog.classes[state.controls.armor],view=state.controls.view,v=catalog.variants[state.controls.variant],name={front:'Vorne',quarter:'Vorne als Annäherung',rear:'Hinten',side:'Seite',top:'Oben · geneigte KI-Ansicht'}[view];
 $('targetImage').src=a.target;const image=$('nativeImage');image.hidden=!v.available;$('pending').hidden=v.available;if(v.available)image.src=v.images[view];$('openNative').disabled=!v.available;
 for(const id of ['targetImage','nativeImage'])$(id).classList.toggle('mono',state.controls.tone==='mono');$('targetCaption').textContent=`${a.label} · ${name} · generierte Modellvorlage`;$('nativeCaption').textContent=`${v.label} · ${catalog.views[view]} · ${v.status}`;
 for(const input of document.querySelectorAll('[data-check]'))input.checked=!!state.checks[input.dataset.check];renderNote();requestAnimationFrame(fitFigures);}
function renderNote(){const a=$('noteArmor').value;$('note').value=state.notes[a];$('decision').value=state.decisions[a];}
for(const el of document.querySelectorAll('[data-control]'))el.addEventListener('change',()=>{state.controls[el.id]=el.value;if(el.id==='armor')$('noteArmor').value=el.value;render();save();});
$('noteArmor').addEventListener('change',renderNote);$('note').addEventListener('input',()=>{state.notes[$('noteArmor').value]=$('note').value;save();});$('decision').addEventListener('change',()=>{state.decisions[$('noteArmor').value]=$('decision').value;save();});
for(const tab of document.querySelectorAll('[data-tab]'))tab.addEventListener('click',()=>{for(const b of document.querySelectorAll('[data-tab]'))b.classList.toggle('active',b===tab);for(const s of document.querySelectorAll('.tab-panel'))s.classList.toggle('active',s.id===tab.dataset.tab);requestAnimationFrame(fitFigures);});
function showImage(kind){const v=catalog.variants[state.controls.variant];$('dialogImage').src=kind==='target'?catalog.classes[state.controls.armor].target:v.images[state.controls.view];$('dialogTitle').textContent=kind==='target'?'Vollständige 2D-Modellvorlage':'Vollständige native Aufnahme';$('imageDialog').showModal();}
$('openTarget').onclick=()=>showImage('target');$('openNative').onclick=()=>showImage('native');$('closeDialog').onclick=()=>$('imageDialog').close();
function exportText(){return $('jsonOutput').value=JSON.stringify(payload(),null,2);}
$('exportJsonButton').onclick=()=>{const text=exportText(),url=URL.createObjectURL(new Blob([text],{type:'application/json'})),a=document.createElement('a');a.href=url;a.download='armor-review_'+new Date().toISOString().replace(/[:.]/g,'-')+'.json';document.body.append(a);a.click();a.remove();setTimeout(()=>URL.revokeObjectURL(url),1000);message('JSON als Download und im Textfeld bereit.');};
$('copyJsonButton').onclick=async()=>{const text=exportText();try{await navigator.clipboard.writeText(text);message('JSON kopiert.');}catch{$('jsonOutput').focus();$('jsonOutput').select();message('JSON im Textfeld markiert.');}};
$('importJsonInput').onchange=async e=>{try{const f=e.target.files[0];if(!f)return;const next=validated(JSON.parse(await f.text()));state=next;$('noteArmor').value=state.controls.armor;render();save();message('Lokale Arbeitsnotizen importiert.');}catch(error){message('Import abgelehnt: '+error.message);}finally{e.target.value='';}};
try{const saved=localStorage.getItem(key);if(saved)state=validated(JSON.parse(saved));}catch{message('Gespeicherte Notizen konnten nicht gelesen werden; Standardansicht geöffnet.');}
$('noteArmor').value=state.controls.armor;render();window.addEventListener('resize',fitFigures);for(const img of [$('targetImage'),$('nativeImage')])img.addEventListener('load',fitFigures);window.armorWorkbench={payload,validated,catalog,fitFigures};
</script></body></html>'''
page = page.replace('__STYLE__', style).replace('__CATALOG__', json.dumps(catalog, ensure_ascii=False))
page = '\n'.join(line.rstrip() for line in page.splitlines()) + '\n'
destination = ROOT / 'docs/reports/armor_comparison_20261111.html'
destination.write_text(page, encoding='utf-8', newline='\n')
print(destination)
