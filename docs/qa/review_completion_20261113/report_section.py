"""Current review completion and reference/native comparison workbench."""
import html
import json


def augment(page, root):
    import re
    qa = root/'docs/qa/review_completion_20261113'
    if not (qa/'summary.json').exists():
        return page
    data = json.loads((qa/'summary.json').read_text(encoding='utf-8'))
    esc = lambda value: html.escape(str(value), quote=True)
    labels = {
        'maps':'Karten', 'buildings':'Gebäude', 'personnel':'Personen',
        'props':'Ausstattung', 'terrain':'Boden und Felsen', 'vehicles':'Fahrzeuge',
        'ui':'Sternkarte und Smart Mobile',
        'ai_concept_not_native':'KI-Zielbild · keine Spielaufnahme',
        'existing_asset_under_review':'Bestehendes Asset in Prüfung',
        'implemented_awaiting_native_validation':'Umgesetzt · Bildprüfung läuft',
        'native_compared_geometry_retained':'Nativ verglichen · Geometrie erhalten',
        'native_fix_verified':'Korrektur nativ geprüft',
        'native_review_pending_corrections':'Nativ geprüft · weitere Korrekturen laufen',
        'native_cap_shadow_fix_verified':'Kappenschatten nativ geprüft',
        'native_module_seam_fix_verified':'Modulanschlüsse nativ geprüft',
        'native_palette_fix_verified':'Farbkorrektur nativ geprüft',
        'existing_2d_target_or_reference_not_native':'Vorhandenes Zielbild · keine Spielaufnahme',
        'existing_original_fictional_portrait_atlas_opened':'Geprüfte Originalporträts',
        'existing_shared_style_reference_not_exact_layout_not_native':'Gemeinsame Stilvorlage · kein exakter Kartenplan',
        'native_godot_gl_compatibility_opened':'Geöffnete native Godotaufnahme · Compatibility',
    }
    display = lambda value: labels.get(value, value)
    titles = {
        'satellite_crash_site':'Satelliten-Absturzstelle',
        'trade_outpost':'Handelsaußenposten',
        'fortified_outpost':'Gesicherter Außenposten',
        'polisa_station':'Freie Raumstation Polisa',
        'Ground_Mission02_128x128':'Großes Gelände und Landepad',
        'station_outpost_64x64':'Modulare Station',
    }
    cards = ''
    for item in data.get('areas', []):
        cards += f'<details class="review-detail" data-completion-area="{esc(item["id"])}"><summary><strong>{esc(item["title"])}</strong> · {esc(item["status"])}</summary><p>{esc(item["change"])}</p><p><strong>Geprüft:</strong> {esc(item["evidence"])}</p><p><strong>Grenzen:</strong> {esc(item.get("limits", ""))}</p><label>Eigene Prüfung<select data-export-key="completion.{esc(item["id"])}.decision"><option value="unchecked">Noch nicht selbst geprüft</option><option value="accepted">Passt</option><option value="revise">Überarbeiten</option></select></label><label>Notiz<textarea data-export-key="completion.{esc(item["id"])}.note" rows="2"></textarea></label></details>'
    tests = ''.join(f'<tr><td>{esc(c["name"])}</td><td>{esc(c["assertions"])}</td><td>{esc(c["status"])}</td></tr>' for c in data.get('checks', []))
    chain = data.get('campaign_sequence', {})
    attempt = data.get('campaign_attempt', {})
    if attempt:
        cards += '<p><strong>Offener Kampagnennachweis:</strong> '+esc(attempt['scope'])+'</p>'
    if chain:
        cards += '<p><strong>Kampagnennachweis:</strong> '+esc(chain['scope'])+' Der frühere abgebrochene Lauf bleibt als solcher im Archiv; seine '+esc(chain['prefix_assertions_excluded'])+' bestandenen Einzelprüfungen werden nicht zusätzlich mitgezählt.</p>'
    section = f'''<article class="card full" id="review-completion"><div class="eyebrow">UMSETZUNG DER OFFENEN PUNKTE · 13. NOVEMBER 2026</div><h2>{esc(data['title'])}</h2><p>{esc(data['description'])}</p><p><a href="#graphics-workbench">Grafikvergleich</a> · <a href="#kenney-usage">Kenney-Assetkatalog</a></p><p><strong>{esc(data['assertions'])} Assertions in {len(data.get('checks', []))} akzeptierten Prüfläufen.</strong> {esc(data.get('verification_note', ''))}</p>{cards}<details class="review-detail"><summary>Aktuelle Regressionen</summary><div class="table-wrap"><table><thead><tr><th>Prüfung</th><th>Assertions</th><th>Ergebnis</th></tr></thead><tbody>{tests}</tbody></table></div></details><p><a href="../qa/review_completion_20261113/README.md">Umsetzung und Prüfgrenzen</a> · <a href="../qa/review_completion_20261113/summary.json">Testindex</a> · <a href="../tasks/REVIEW_COMPLETION_2026_11_13.md">Auftrag und Akzeptanz</a></p><p class="source">{esc(data.get('source', ''))}</p></article>'''
    inventory_path = qa/'graphics_inventory.json'
    if inventory_path.exists():
        inventory = json.loads(inventory_path.read_text(encoding='utf-8'))
        assets = inventory.get('assets', [])
        ui_inventory = root/'docs/qa/starmap_mobile_20261113/ui_gallery.json'
        if ui_inventory.exists():
            assets = assets + json.loads(ui_inventory.read_text(encoding='utf-8')).get('assets', [])
        options = ''.join(f'<option value="{esc(g)}">{esc(display(g))}</option>' for g in sorted({a['group'] for a in assets}))
        gallery = ''
        for asset in assets:
            asset_id = ''.join(c if c.isalnum() or c == '_' else '_' for c in asset['id'])
            pictures = ''
            for stage, label in [('reference', 'Zielreferenz'), ('before', 'Nativ vorher'), ('after', 'Nativ nachher')]:
                record = asset.get(stage)
                if not isinstance(record, dict) or not record.get('path'):
                    reason = record.get('unavailable_reason', 'Kein separates Bild dokumentiert.') if isinstance(record, dict) else 'Kein separates Bild dokumentiert.'
                    pictures += f'<div class="asset-stage" data-stage="{stage}" data-unavailable="true" hidden><p>{esc(label)}: {esc(reason)}</p></div>'
                    continue
                file_path = record['path'].replace('\\', '/')
                relative = '../' + file_path.removeprefix('docs/') if file_path.startswith('docs/') else '../../' + file_path
                caption = display(record.get('status', label))
                pictures += f'<figure class="asset-stage" data-stage="{stage}" {"" if stage == "after" else "hidden"}><button type="button" class="asset-image-button" aria-label="{esc(asset["title"] + ": " + label + " vergrößern")}"><img loading="lazy" src="{esc(relative)}" alt="{esc(asset["title"] + ": " + label)}"></button><figcaption>{esc(caption)}</figcaption><details><summary>Quelle und SHA-256</summary><p class="source">{esc(file_path)}<br>{esc(record.get("sha256", ""))}</p></details></figure>'
            gallery += f'<article class="asset-entry" data-asset-id="{esc(asset_id)}" data-group="{esc(asset["group"])}" data-search="{esc((asset["title"] + " " + asset.get("change", "")).lower())}"><div class="eyebrow">{esc(display(asset["group"]))} · {esc(display(asset.get("status", "")))}</div><h3>{esc(titles.get(asset['id'], asset["title"]))}</h3>{pictures}<p>{esc(asset.get("change", ""))}</p><p>{esc(asset.get("remaining", ""))}</p><label>Bewertung<select data-export-key="graphics.{asset_id}.decision"><option value="unchecked">Noch nicht selbst geprüft</option><option value="accepted">Passt</option><option value="revise">Überarbeiten</option></select></label><label>Kommentar<textarea rows="2" data-export-key="graphics.{asset_id}.note"></textarea></label></article>'
        section += f'''<article class="card full" id="graphics-workbench"><h2>Karten, Boden und Assets vergleichen</h2><p>Referenzen zeigen das Ziel; native Aufnahmen zeigen den tatsächlichen Godotstand. Alle Einträge wechseln gemeinsam zwischen Vorher und Nachher. Technische Prüfung und dein Gestaltungsurteil bleiben getrennt.</p><div class="asset-filters"><label>Suchen<input id="asset-search" type="search" data-export-key="graphics.search" placeholder="Karte, Gebäude, Person …"></label><label>Gruppe<select id="asset-group" data-export-key="graphics.group"><option value="all">Alle Gruppen</option>{options}</select></label><label>Vergleichsansicht<select id="asset-stage" data-export-key="graphics.stage"><option value="after">Nativ nachher</option><option value="before">Nativ vorher</option><option value="reference">Zielreferenz</option></select></label></div><p id="asset-count" aria-live="polite"></p><div class="asset-gallery">{gallery}</div><p><a href="../qa/review_completion_20261113/graphics_inventory.json">Referenz- und Assetinventar</a></p></article><dialog id="asset-dialog"><button id="asset-dialog-close" type="button">Schließen</button><img alt=""><p></p></dialog>'''
    if (root/'docs/qa/starmap_mobile_20261113/references/sources.json').exists():
        section += '''<article class="card full" id="ui-design-sources"><h3>Vom echten Spielstand zum kompakten UI</h3><p>Die dritte Bild-KI-Revision erhielt die tatsächliche Sternkarte, das Smart-Mobile-Fenster und den Charakterbogen als Eingaben. Die Entwürfe dienten als Ausgangspunkt; die anschließenden Nutzerkorrekturen verfeinern Layout und Bedienung. Die Galerie zeigt die separat geprüfte Godot-Umsetzung. Farbige Bilder, Porträts und Ausrüstungsicons bleiben erhalten.</p><p><a href="../qa/starmap_mobile_20261113/references/README.md">Referenzen, Revisionen und Grenzen</a> · <a href="../qa/starmap_mobile_20261113/references/concept_v3_prompt.txt">Verwendeter Bild-KI-Prompt</a> · <a href="../qa/starmap_mobile_20261113/references/sources.json">Bildquellen und Prüfsummen</a></p><p><a href="../qa/starmap_mobile_20261113/references/user_person_dock_and_briefing_feedback.json">Konkrete Nutzerkorrekturen: Name direkt bearbeiten, Porträt-/Ranganordnung, zwei Trenner und Bild neben Auftragsdaten</a>.</p><p>Offizielle Inspiration: <a href="https://support.robertsspaceindustries.com/hc/en-us/articles/360019449994-How-to-Quantum-Travel">RSI-Sternkarte mit Zielinformationen</a> und <a href="https://robertsspaceindustries.com/en/comm-link/engineering/14466-Design-Notes-MobiGlas">mobiGlas-Designnotizen von 2015</a>. Die kompakten Panels sind eine eigene Umsetzung; RSI-Bedienelemente werden nicht als Spielassets übernommen.</p></article>'''
    concepts = root/'docs/qa/hex_surface_design_20261113/references'
    if (concepts/'cliff_detail_proposal.png').exists():
        section += '''<article class="card full" id="terrain-design-studies"><div class="eyebrow">BILD-KI · ECHTE KARTEN ALS EINGABE</div><h2>Freie Flächen und Steilklippen</h2><p>Diese Bilder sind Gestaltungsentwürfe. Sie sind keine nativen Spielaufnahmen und belegen weder Performance noch eine bereits identische Umsetzung.</p><h3>Steilklippen: rechts gewählt</h3><button type="button" class="asset-image-button" aria-label="Klippenvorschläge vergrößern"><img loading="lazy" src="../qa/hex_surface_design_20261113/references/cliff_detail_proposal.png" alt="Klippenstudie: links geschichteter Sandstein, rechts der gewählte kantige Bruchstein"></button><p><strong>Deine Entscheidung: rechts, Bruchstein.</strong> Kantige Bruchflächen und wenig Geröll dienen als Vorlage. Höhen, Wege und begehbare Hexflächen bleiben erhalten. Die tatsächliche Umsetzung wird getrennt in der nativen Galerie geprüft.</p><label>Kommentar zur Umsetzung<textarea rows="2" data-export-key="terrain.cliffs.note"></textarea></label><h3>Freie Flächen: noch offen</h3><button type="button" class="asset-image-button" aria-label="Geländevorschläge vergrößern"><img loading="lazy" src="../qa/hex_surface_design_20261113/references/map_detail_proposal.png" alt="Vorschläge für ruhige freie Wüstenflächen und lesbare Hügel mit Hexraster"></button><p>Vorgeschlagen sind sparsame Steine, Mineralflecken und Erosionsspuren. Breite Wege und Landezonen bleiben frei. Die alte HUD-Aufnahme wurde nur zur Beachtung belegter Bildschirmbereiche mitgegeben; ihr früheres Quadratgitter ist keine Vorlage.</p><label>Gestaltungsentscheidung<select data-export-key="terrain.open_ground.decision"><option value="unchecked">Noch offen</option><option value="accepted">Richtung gefällt</option><option value="revise">Überarbeiten</option></select></label><label>Kommentar<textarea rows="2" data-export-key="terrain.open_ground.note"></textarea></label><p>Verworfen: dicke weiße Bodenklumpen und der anschließende dunkelgraue Stationsentwurf. Positiv benannt: das weiße Lagerhaus und sein Winkel.</p><p><a href="../qa/hex_surface_design_20261113/references/README.md">Revisionen und Nutzerentscheidung</a> · <a href="../qa/hex_surface_design_20261113/references/cliff_detail_proposal_prompt.txt">Klippenprompt</a> · <a href="../qa/hex_surface_design_20261113/references/map_detail_proposal_prompt.txt">Geländeprompt</a> · <a href="../qa/hex_surface_design_20261113/references/detail_provenance.json">Eingaben und Prüfsummen</a></p></article>'''
    css = '''
#terrain-design-studies label{display:grid;gap:6px;margin:12px 0}#terrain-design-studies select,#terrain-design-studies textarea{box-sizing:border-box;width:100%;min-width:0}
#graphics-workbench,#review-completion{scroll-margin-top:80px}.asset-filters{display:grid;grid-template-columns:2fr 1fr 1fr;gap:12px}.asset-filters label,.asset-entry label,#review-completion label{display:grid;gap:6px;margin:12px 0}.asset-entry{padding:18px;border:1px solid #395460;border-radius:14px;min-width:0}.asset-gallery{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:16px}.asset-entry figure{margin:0}.asset-stage[hidden],.asset-entry[hidden]{display:none}.asset-image-button{display:block;width:100%;padding:0;border:0;background:#06131a;cursor:zoom-in}.asset-image-button img{display:block;width:100%;height:auto}.asset-entry .source{overflow-wrap:anywhere;font-size:12px}.asset-entry select,.asset-entry textarea,.asset-filters input,.asset-filters select,#review-completion select,#review-completion textarea{box-sizing:border-box;width:100%;min-width:0}#asset-dialog{max-width:94vw;max-height:94vh;background:#101f29;color:#e4edf1;border:1px solid #607d8b;border-radius:12px;padding:12px}#asset-dialog::backdrop{background:#000c}#asset-dialog img{display:block;max-width:88vw;max-height:76vh;object-fit:contain}#asset-dialog-close{display:block;margin:0 0 10px auto}.table-wrap{max-width:100%;overflow:auto}@media(max-width:700px){.asset-gallery,.asset-filters{grid-template-columns:minmax(0,1fr)}}
'''
    js = '''
(()=>{const search=document.querySelector('#asset-search'), group=document.querySelector('#asset-group'),stage=document.querySelector('#asset-stage');if(!search)return;const entries=[...document.querySelectorAll('.asset-entry')];function update(){let count=0;for(const entry of entries){entry.hidden=!(group.value==='all'||entry.dataset.group===group.value)||!entry.dataset.search.includes(search.value.toLocaleLowerCase());if(!entry.hidden)count++;for(const picture of entry.querySelectorAll('.asset-stage'))picture.hidden=picture.dataset.stage!==stage.value}document.querySelector('#asset-count').textContent=count+' von '+entries.length+' Einträgen'}for(const control of [search,group,stage]){control.addEventListener('input',update);control.addEventListener('change',update)}update();const dialog=document.querySelector('#asset-dialog');document.querySelector('#asset-dialog-close').addEventListener('click',()=>dialog.close());for(const button of document.querySelectorAll('.asset-image-button'))button.addEventListener('click',()=>{const image=button.querySelector('img');dialog.querySelector('img').src=image.src;dialog.querySelector('img').alt=image.alt;dialog.querySelector('p').textContent=image.alt;dialog.showModal()});dialog.addEventListener('click',event=>{if(event.target===dialog)dialog.close()})})();
'''
    import importlib.util
    usage_spec = importlib.util.spec_from_file_location('kenney_usage', qa/'kenney_usage_catalog.py')
    usage = importlib.util.module_from_spec(usage_spec)
    usage_spec.loader.exec_module(usage)
    section += usage.section(root)
    css += usage.CSS
    js += usage.JS
    page = page.replace('<section id="overview" class="tab-panel active">', '<section id="overview" class="tab-panel active">'+section, 1)
    if 'id="review-completion"' not in page:
        # Keep placement robust against nonsemantic class changes in the template.
        page = re.sub(r'(<section[^>]*id="overview"[^>]*>)', lambda match: match[0]+section, page, count=1)
    if 'id="review-completion"' not in page:
        raise RuntimeError('Overview insertion point missing')
    page = page.replace('</style>', css+'</style>', 1).replace('</body>', '<script>'+js+'</script></body>', 1)
    page = page.replace('Architektur- und Gestaltungsvorschläge bleiben separat dokumentiert.', 'Die anschließende Umsetzung von Hex, Architektur, Bedienung und Grafik steht mit ihren aktuellen Nachweisen direkt darunter.')
    for heading in ['2 · Architektur', '3 · Bedienbarkeit', '4 · Visuelle Gestaltung']:
        page = page.replace('<h2>'+heading+'</h2>', '<h2>'+heading+' · ursprüngliche Empfehlungen</h2><p>Historischer Auftrag aus dem ersten Review. Der aktuelle Umsetzungsstand und die neuen Vergleiche stehen oben.</p>')
    page = page.replace('Die umfassende Migration weiterer globaler Zufallsquellen bleibt eine separate Architekturentscheidung.', 'Der anschließende Umsetzungsdurchlauf hat auch Disziplin und Fehlidentifikation an den gespeicherten Root-Zufall gebunden; Nachweise siehe oben.')
    page = page.replace('<strong>Weiter offen:</strong> Personensnapshots in der Basisvisualisierung als ungemessener Kandidat,', '<strong>Damals noch offen:</strong> Personensnapshots in der Basisvisualisierung (inzwischen durch die oben geprüfte schmale Ownerprojektion ersetzt),')
    header, tail = page.split('</header>', 1)
    header = re.sub(r'<h1>.*?</h1>', '<h1>Hex, Bedienung<br>&amp; Grafik</h1>', header, count=1, flags=re.S)
    header = re.sub(r'<p class="lead">.*?</p>', lambda _: '<p class="lead">'+esc(data['description'])+'</p>', header, count=1, flags=re.S)
    count_text = f'{int(data["assertions"]):,}'.replace(',', '.')
    header = re.sub(r'[\d.]+ Prüfungen bestanden', count_text+' aktuelle Prüfschritte bestanden', header, count=1)
    header = header.replace('<span class="pill">Headless</span>', '<span class="pill">Headless &amp; native Bilder</span>')
    header = re.sub(r'<p>Fixstand .*?</p>', lambda _: '<p>'+esc(data.get('source', ''))+'</p>', header, count=1, flags=re.S)
    page = header+'</header>'+tail
    return page
