"""Rebuild the offline gallery from HERKUNFT.json. Images stay byte-identical."""
from pathlib import Path
import json
import html
import re

BASE = Path(__file__).resolve().parents[1]
REPO = BASE.parent
data = json.loads((BASE / "HERKUNFT.json").read_text(encoding="utf-8"))
template = Path("C:/dev/SternenBuergerchen/docs/reports/_html_workbench_template.html").read_text(encoding="utf-8")
style = re.search(r"<style>(.*?)</style>", template, re.S).group(1)
groups = sorted({x["group"] for x in data["items"]})
esc = html.escape
options = ''.join(f'<option>{esc(g)}</option>' for g in groups)
classes = data["review_classes"]
status_options = ''.join(f'<option value="{k}">{esc(v)}</option>' for k, v in classes.items())
cards = []
for item in data["items"]:
    key = item["sha256"][:16]
    file = esc(item["file"], quote=True)
    title = esc(item["title"])
    cls = item["review_class"]
    cards.append(f'''<article class="image-card" data-group="{esc(item['group'])}" data-status="{cls}" data-key="{key}">
      <button class="preview" type="button" aria-label="Großansicht: {title}" data-file="{file}" data-title="{title}"><img src="{file}" alt="{title}" loading="lazy"></button>
      <div class="card-body"><span class="badge {cls}">{esc(classes[cls])}</span><h3>{title}</h3><p class="date">{esc(item['date'])} · {esc(item['group'])}</p>
      <p>{esc(item['status'])}</p>
      <details><summary>Herkunft & Beleg</summary><p>{esc(item['source'])}</p><p>{esc(item['evidence'])}</p><p>SHA-256: {item['sha256']}</p></details>
      <label>Deine Bewertung<select class="decision" data-export-key="images.{key}.decision"><option value="unmarked">Noch nicht markiert</option><option value="good">Gut / als Referenz behalten</option><option value="partial">Nur teilweise brauchbar</option><option value="bad">Schlecht / aussortieren</option></select></label>
      <label>Notiz<textarea class="image-note" data-export-key="images.{key}.note" rows="2" placeholder="Was gefällt, was soll anders sein?"></textarea></label>
      <a class="original" href="{file}" target="_blank" rel="noopener">Original öffnen</a></div></article>''')

page = '''<!doctype html><html lang="de"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Sternenbürgerchen · Bildreferenzen</title><style>''' + style + '''
body{background:#10161a}a{color:#80dbe0}header h1{font-size:clamp(26px,4vw,42px)}main{width:min(1600px,calc(100% - 32px))}.intro{max-width:1050px}.filters{display:flex;flex-wrap:wrap;gap:12px;margin:18px 0;align-items:end}.filters label{flex:1 1 220px}.filters button{flex:0 0 auto}.gallery{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(100%,350px),1fr));gap:20px}.image-card{min-width:0;background:#182129;border:1px solid #3b4d5c;border-radius:10px;overflow:hidden}.image-card[hidden]{display:none}.preview{display:block;width:100%;height:auto;padding:0;border:0;border-radius:0;background:#0a1014;cursor:zoom-in;aspect-ratio:16/9}.preview img{display:block;width:100%;height:100%;object-fit:contain}.card-body{padding:16px}.card-body h3{margin-top:12px;line-height:1.35;color:#edf5f8}.card-body label{display:block;margin-top:14px;font-size:14px}.card-body p{font-size:14px}.date{color:#a8b6c1}.badge{font-size:12px;display:inline-block;padding:4px 8px;border-radius:5px;background:#334250;color:#d8e5ee}.badge.confirmed,.badge.direction{background:#244937;color:#b3edc6}.badge.user_reference{background:#244554;color:#b4e6f0}.badge.partial{background:#594a22;color:#ffe293}.badge.open{background:#424550;color:#dce0ef}details{margin-top:12px;font-size:13px;overflow-wrap:anywhere}summary{cursor:pointer}textarea.image-note{min-height:65px}select{min-height:42px}.original{display:inline-block;margin-top:12px}#resultCount{padding:10px 0;font-weight:600}.gallery-tools{position:sticky;top:0;z-index:4;background:#10161af5;border-bottom:1px solid #3b4d5c;padding:8px 0}.toolbar{position:static;display:block}.toolbar .export-actions{margin-bottom:12px}#jsonOutput{width:100%;min-height:120px}dialog{padding:16px;max-width:min(96vw,1800px);max-height:94vh;background:#10161a;color:#edf5f8;border:1px solid #758997;border-radius:8px}dialog::backdrop{background:#000d}dialog img{display:block;max-width:100%;max-height:75vh;object-fit:contain}dialog .dialog-head{display:flex;gap:16px;justify-content:space-between;align-items:center;margin-bottom:12px}.warning{border-left:3px solid #ffd34d;padding-left:14px}.links{display:flex;gap:16px;flex-wrap:wrap;margin-top:16px}#saveStatus{font-size:13px}.overall{margin:28px 0}.overall textarea{min-height:80px}@media(max-width:600px){main{width:calc(100% - 24px)}header{padding:22px 14px}.filters{gap:8px}.filters label{flex-basis:100%}.gallery-tools{position:static}.gallery{grid-template-columns:1fr}.card-body{padding:14px}.toolbar{padding:18px 14px}dialog{width:96vw}}
</style></head><body data-report-id="bildreferenzen_20261114" data-report-schema="sternenbuergerchen.html_workbench.v1">
<header><h1>Sternenbürgerchen · Bildreferenzen</h1><p class="intro">__COUNT__ wiedergefundene Bilder · April bis November 2026 · Originale unverändert. Rüstungen, frühe Spielszenen, Basis, Freihafen, Sternkarten, Menüs und Menschen.</p>
<p class="intro warning">Die grüne Kennzeichnung belegt positive Rückmeldung oder eine gewählte Richtung. Nutzerreferenzen, historische Bilder und offene Bewertungen sind gesondert markiert. Das zuletzt abgelehnte orange Deckbild ist ausgeschlossen. Ein Zielbild bestätigt keine 3D-Umsetzung.</p>
<div class="links"><a href="README.md">Ordnerübersicht</a><a href="HERKUNFT.json">Herkunft & Prüfsummen</a><a href="https://sternenbuergerchen-neustart.klabauta.chatgpt.site" target="_blank" rel="noopener">Frühere Webseite</a><a href="#notizen">Notizen & Export</a></div></header>
<main><section aria-label="Bildsuche"><div class="gallery-tools"><div class="filters"><label>Suche<input id="search" data-export-key="filters.search" type="search" placeholder="z. B. Rostgrenze, Hangar, Inventar"></label><label>Rubrik<select id="group" data-export-key="filters.group"><option value="">Alle Rubriken</option>__GROUPS__</select></label><label>Belegter Status<select id="status" data-export-key="filters.status"><option value="">Alle Status</option><option value="positive">Bestätigt / gewählte Richtung / Nutzerreferenz</option>__STATUSES__</select></label><button id="resetFilters" type="button">Filter zurücksetzen</button></div><div id="resultCount" role="status" aria-live="polite"></div></div><div class="gallery">__CARDS__</div></section>
<section id="notizen" class="overall"><h2>Notizen & Entscheidungen</h2><p>Bewertungen werden nur in diesem Browser als Arbeitsnotizen gespeichert. Mit JSON exportieren kannst du sie weitergeben; die dokumentierte Herkunft bleibt unverändert.</p><label>Allgemeine Notiz<textarea data-export-key="review.note" id="overallNote" placeholder="Welche Vorlagen sollen wir als Nächstes verwenden?"></textarea></label><p id="saveStatus" role="status"></p></section></main>
<footer class="toolbar"><div class="export-actions"><button id="exportJsonButton" type="button">JSON exportieren</button><button id="copyJsonButton" class="secondary" type="button">JSON kopieren</button><span id="exportStatus" role="status">Download funktioniert ohne Server. Der vollständige Text erscheint zusätzlich unten.</span></div><textarea id="jsonOutput" readonly aria-label="JSON-Export" placeholder="Hier erscheint dein Export."></textarea></footer>
<dialog id="lightbox"><div class="dialog-head"><h2 id="lightboxTitle"></h2><button id="closeLightbox" type="button">Schließen</button></div><img id="lightboxImage" alt=""></dialog>
<script id="galleryData" type="application/json">__DATA__</script>
<script>
(()=>{'use strict';const data=JSON.parse(document.getElementById('galleryData').textContent),cards=[...document.querySelectorAll('.image-card')],search=document.getElementById('search'),group=document.getElementById('group'),status=document.getElementById('status'),key='sb-image-reference-notes-v2',fields=[...document.querySelectorAll('[data-export-key]')];
function filter(){let count=0;const q=search.value.trim().toLocaleLowerCase('de');cards.forEach(card=>{const match=(!q||card.textContent.toLocaleLowerCase('de').includes(q))&&(!group.value||card.dataset.group===group.value)&&(!status.value||(status.value==='positive'?['confirmed','direction','user_reference'].includes(card.dataset.status):card.dataset.status===status.value));card.hidden=!match;if(match)count++});document.getElementById('resultCount').textContent=count+' von '+cards.length+' Bildern';}
function snapshot(){const controls={};fields.forEach(f=>controls[f.dataset.exportKey]=f.value);return controls;}
function save(){try{localStorage.setItem(key,JSON.stringify(snapshot()));document.getElementById('saveStatus').textContent='Arbeitsnotizen lokal im Browser gespeichert.'}catch(e){document.getElementById('saveStatus').textContent='Browserspeicher nicht verfügbar. Bitte JSON exportieren.'}}
try{const old=JSON.parse(localStorage.getItem(key)||'{}');fields.forEach(f=>{if(Object.prototype.hasOwnProperty.call(old,f.dataset.exportKey))f.value=String(old[f.dataset.exportKey])})}catch(e){}
fields.forEach(f=>f.addEventListener('input',()=>{filter();save()}));[group,status].forEach(f=>f.addEventListener('change',()=>{filter();save()}));document.getElementById('resetFilters').addEventListener('click',()=>{search.value='';group.value='';status.value='';filter();save()});
const dialog=document.getElementById('lightbox');document.querySelectorAll('.preview').forEach(b=>b.addEventListener('click',()=>{document.getElementById('lightboxTitle').textContent=b.dataset.title;const img=document.getElementById('lightboxImage');img.src=b.dataset.file;img.alt=b.dataset.title;dialog.showModal()}));document.getElementById('closeLightbox').addEventListener('click',()=>dialog.close());dialog.addEventListener('click',e=>{if(e.target===dialog)dialog.close()});
function buildExport(){const controls=snapshot(),notes={};data.items.forEach(i=>{const k=i.sha256.slice(0,16);if(controls['images.'+k+'.note'])notes[i.file]=controls['images.'+k+'.note']});return {schema:'sternenbuergerchen.html_workbench.v1',report_id:'bildreferenzen_20261114',title:document.title,exported_at:new Date().toISOString(),controls,notes,active_choices:{},computed:{image_count:data.image_count,visible_count:cards.filter(c=>!c.hidden).length},metadata:{source_manifest:'HERKUNFT.json',images:data.items.map(i=>({file:i.file,sha256:i.sha256,documented_status:i.review_class})),excluded:data.excluded.map(i=>({sha256:i.sha256,reason:i.reason}))}};}
function exportText(){const text=JSON.stringify(buildExport(),null,2);document.getElementById('jsonOutput').value=text;return text;}
document.getElementById('exportJsonButton').addEventListener('click',()=>{const text=exportText(),url=URL.createObjectURL(new Blob([text],{type:'application/json'})),a=document.createElement('a');a.href=url;a.download='sternenbuergerchen_bildreferenzen_'+new Date().toISOString().replace(/[:.]/g,'-')+'.json';document.body.appendChild(a);a.click();a.remove();setTimeout(()=>URL.revokeObjectURL(url),1000);document.getElementById('exportStatus').textContent='JSON-Download gestartet; vollständiger Text steht unten.'});
document.getElementById('copyJsonButton').addEventListener('click',async()=>{const text=exportText();try{await navigator.clipboard.writeText(text);document.getElementById('exportStatus').textContent='JSON kopiert.'}catch(e){document.getElementById('jsonOutput').focus();document.getElementById('jsonOutput').select();document.getElementById('exportStatus').textContent='Text ausgewählt. Mit Strg+C kopieren.'}});filter();})();
</script></body></html>'''
page = page.replace('__COUNT__',str(len(data['items']))).replace('__GROUPS__',options).replace('__STATUSES__',status_options).replace('__CARDS__','\n'.join(cards)).replace('__DATA__',json.dumps(data,ensure_ascii=False).replace('<','\\u003c'))
page = '\n'.join(line.rstrip() for line in page.splitlines()) + '\n'
(BASE/'GALERIE.html').write_text(page,encoding='utf-8')
lines=['# Sternenbürgerchen · Gesammelte Bildreferenzen','',f"{len(data['items'])} eindeutige Bilder. [Galerie öffnen](GALERIE.html) – mit Suche, Rubriken, Statusfilter, Großansicht, Bewertungen und JSON-Export.",'',
'Der Ordnername bleibt für vorhandene Links erhalten. **Nicht alle Bilder sind bestätigt.** Der jeweilige Status steht in der Galerie und in [HERKUNFT.json](HERKUNFT.json). Das ausdrücklich abgelehnte orange Deckbild wurde entfernt; seine Originalquelle im Projekt bleibt erhalten.','',
'## Schnellzugriff','',
'- `01_Ruestungen`: die drei gesuchten Modellvorlagen für Leicht, Mittel und Schwer.',
'- `05_Fruehe_Szenenreferenzen`: Rostgrenze-Cutaway, Freihafen und taktische Rostwelt.',
'- `06_Anfang_April_Hintergruende`: Crewraum, Hangar, Außenposten, Asteroidenflug und Shadowfall.',
'- `07_Webseite_September`: frühe Basis-/Freihafen-, Sternkarten- und Inventarziele.',
'- `80_Weitere_Entwuerfe_Status_beachten`: weitere eigene Menüs, Schiffe, Porträts und Icons. Offene Bewertungen bleiben offen.',
'- `90_Teilweise_bestaetigt_und_aeltere_Varianten`: begrenzte Zustimmungen und frühere Rüstungsformen.','',
'## Frühere Webseite','',
'[Sternenbürgerchen · Zwei Freunde. Eine Basis. Eine Zukunft.](https://sternenbuergerchen-neustart.klabauta.chatgpt.site) wurde über Sites wiedergefunden. Die lokalen archivierten N7-/N8-Seiten belegen die Bildzuordnung. Details: [FRUEHE_WEBSEITE.json](Quellen/FRUEHE_WEBSEITE.json). Native Spielaufnahmen dieser Seiten sind keine generierten Ziele und wurden nicht beigepackt.','',
'## Prüfstand & Grenzen','',
'Alle Bildkopien sind unverändert, anhand SHA-256 dedupliziert und dekodierbar. 18 DOM-Funktionsprüfungen bestanden (Suche, Status/Rubrik, Großansicht, Speichern/Neuladen und JSON/Downloadlogik). Die Browserrichtlinie blockiert file://; Desktop-/Mobildarstellung und tatsächlicher Browserdownload sind daher nicht visuell geprüft. Historische Nutzerreferenzen können unbekannte Originalprompts haben. Bewertungen und Richtungsentscheidungen sind keine native Modellabnahme. Keine garantierte Vollständigkeit aller historischen Chats.','',
'Die Galerie funktioniert lokal per Dateiöffnung ohne Server und externe Bibliotheken. Browsernotizen ändern den belegten Quellenstatus nicht. JSON-Export enthält sämtliche Notizen und Entscheidungen.','']
for g in groups:
    lines += [f'## {g}','']
    for i in data['items']:
        if i['group']==g:lines.append(f"- [{i['title']}](<{i['file']}>) · {classes[i['review_class']]}")
    lines.append('')
(BASE/'README.md').write_text('\n'.join(lines),encoding='utf-8')
print(f"Built gallery for {len(cards)} images")
