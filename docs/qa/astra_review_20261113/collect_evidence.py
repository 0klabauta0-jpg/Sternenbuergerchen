"""Preserve review probes, original logs and source guards without user profiles."""
from pathlib import Path
import hashlib, json, re, zipfile

QA = Path(__file__).resolve().parent
ROOT = QA.parents[2]
SOURCE = ROOT/'tmp/astra_review_20261113'
summary = json.loads((QA/'summary.json').read_text(encoding='utf-8'))
runs = []
with zipfile.ZipFile(QA/'reproduction_evidence.zip','w',zipfile.ZIP_DEFLATED) as archive:
    for path in sorted(SOURCE.glob('*')):
        if path.suffix in ['.gd','.py']:
            archive.write(path,'tmp/astra_review_20261113/'+path.name)
    for path in sorted((SOURCE/'runs').glob('*/report.json')):
        data = json.loads(path.read_text(encoding='utf-8'))
        log = path.with_name('output.log')
        text = log.read_text(encoding='utf-8',errors='replace')
        markers = [line for line in text.splitlines() if line.startswith(('ASTRA_FINDING_','ASTRA_NETWORK_REVIEW ','HEX_REVIEW_','UI_PROBE'))]
        rejected_fixture = path.parent.name == 'encounter_root_4f731895ce434acc869e28d82cc16c14'
        expected_json_error = data['case']=='campaign'
        runs.append({'run':path.parent.name,'case':data['case'],'engine_exit':data['exit_code'],
            'guards':data['guards'],'errors':data['errors'],'markers':markers,
            'observation_checks':len(re.findall(r'^PASS[: ]',text,re.M)),
            'classification':'rejected_fixture_setup' if rejected_fixture else 'reproduced_with_expected_json_error' if expected_json_error else 'reproduced',
            'report_sha256':hashlib.sha256(path.read_bytes()).hexdigest(), 'log_sha256':hashlib.sha256(log.read_bytes()).hexdigest()})
        for file in [path,log]: archive.write(file,'runs/'+path.parent.name+'/'+file.name)
summary['reproduction_runs'] = runs
summary['evidence_zip_sha256'] = hashlib.sha256((QA/'reproduction_evidence.zip').read_bytes()).hexdigest()
for item in summary['visual_images']:
    item['sha256'] = hashlib.sha256((ROOT/item['path']).read_bytes()).hexdigest()
summary['reference_images'] = ['docs/reports/assets/ui-2026-11-01/menu_heimatbasis.png','docs/reports/assets/ui-2026-11-01/menu_fob_loadout.png','docs/reports/assets/ui-2026-11-01/mockup_a5_mission_zweireihig.png','docs/reports/assets/grafik-2026-11-01/08_cutlass_vorne_wimmel.png']
summary['additional_images_viewed'] = ['docs/qa/shared_personnel_equipment_20261110/images/inventory_1920.png','docs/qa/flight_polish_20261110/after_cruise.png','docs/qa/character_navigation_20261110/images/details_1280.png']
summary['image_sha256'] = {p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in summary['reference_images']+summary['additional_images_viewed']}
(QA/'summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
lines=['# Code-, Architektur-, Usability- und Gestaltungsreview · 13.11.2026','',
    'Produktbasis: **9fdeb866b** (integrierter Main). Urteil: **Änderungen erforderlich**. VierP1 und fünfP2; keine Produkt-/Assetänderungen. Frühere177Regressionen bleiben historische gezielte Nachweise, keine Gesamtfreigabe.','',
    '## Codebefunde','', 'P1 = zeitnah beheben (Multiplayer-Manipulation oder blockierter Kampagnen-/Ladepfad). P2 = relevanter Funktionsfehler mit konkreter Bedingung. Evidenzsicherheit ist getrennt von Priorität.','']
for f in summary['findings']:
    p,n=f['where'].rsplit(':',1)
    lines += [f"### {f['id']} · {f['priority']} · {f['title']}",'',f"Quelle: [{f['where']}](../../{p}#L{n}).",'',f['detail'],'', '**Nachweis:** '+f['evidence'],'','**Kleinster sinnvoller Folgeschritt:** '+f['fix'],'','**Regression:** '+f['regression'],'']
lines += ['## Architektur','', 'Grundarchitektur tragfähig, ihre Grenzen aber verletzt. PROJECT_BRIEF, ARCHITECTURE, DECISIONS und konkrete Contracts sind die geltende Grundlage; fehlende Plugin-GDD-/ADR-Verzeichnisse sind kein Fehler. Kein neuer Engine-Kompatibilitätsmangel nachgewiesen; lokale Proben liefen auf Godot4.6.2.','',
    '| Anforderung | Befund |','|---|---|','| Host bestimmt Gameplaywerte | C1/C2 verletzen bestehenden Authorityvertrag |','| UI liest ohne Mutation | C8/C9 zeigen fehlende Read-/Inputgrenzen |','| Einheitliche aktive Hexentscheidungen | C6/C7; nur ein Teil der Karten nutzt opt-in Hexregeln |','| Ownergebundene Reise und Speicherung | Gute Grundtrennung, aber C3–C5 an Übergängen |','| Registry, begrenzter Cache, frisches Teamfanout | Im geprüften Ausschnitt sinnvoll; kein weiterer Defekt im jüngsten Fanout/Cache nachgewiesen |','| Mainvertrag und Prüfungen passen zusammen | Cachevertrag veraltet; kombinierte Übergangstests fehlen |','']
for section,key in [('Architekturmaßnahmen','architecture'),('Usability','usability'),('Visuelle Gestaltung','visual')]:
    lines += ['## '+section,'']
    for item in summary[key]:
        lines += ['### '+item['title'],'',item['text'],'','**Vorschlag / Prüfung:** '+item['next'],'']
        if item.get('where'): lines += ['Quelle: `'+item['where']+'`.','']
lines += ['## Bildgrundlage und Grenzen','', 'Fünf native Bilder plus vier Originalziele vom Fachagenten angesehen; Root zusätzlich Sternkarte und älteren720p-Charakterbogen. Historische Bilder sind keine frische Mainabnahme. Stilvorschläge sind fachliche Einschätzungen, keine gemessenen Nutzertestresultate.','']
for item in summary['visual_images']: lines += ['- '+item['label']+': `'+item['path']+'`; SHA256 `'+item['sha256']+'`.']
lines += ['', 'Quellenabgleich: personnel_body_preview.gd:27, personnel_inventory_panel.gd:240, star_map_canvas.gd:359, singleplayer_job_board_presenter.gd:29/74, character_sheet_view.gd:179. Die Sternkarte zeigt eine Zwei-Owner-Fixture; deren Testnamen werden nicht als Katalogfehler bewertet.','',
    '**Positiv:** Einheitliche Petrol/Cyan/Creme-Palette, reale Crew-/Pilot-/Abfluggates und explizite Auftrags-/Anfluginformationen. Die Cutlass-Silhouette und Palette passen im betrachteten Bild zur zugeordneten Vorlage. Keine Pause im Einsatz ist ausdrücklich gewollt.','',
    '## Vorgehensreihenfolge','', '1. C1/C2: Multiplayer-Eingangsgrenzen schließen.','2. C3/C4/C5: Begegnungsabschluss und eindeutige Save-/Rollbackwahl sichern.','3. C6/C7/C8: Sicht, Schuss und Zufallsentscheidung durchgängig verbinden.','4. C9 und Speicher-/Ausstiegshinweise: verlässliche Bediengrenzen.','5. Danach kleine visuelle Vergleichsrunde, beginnend mit einer Person und der Sternkarte.','',
    '## Prüfmethodik / ausgeschlossene Verdachtsfälle','',summary['limits'],'',
    'Sieben verwertbare Reproduktionsläufe (UI, Hex, Diagnose, Netzwerk, Kampagne, Fleetgrenze, Rootabschluss). PASS bedeutet in diesen Proben: Fehler beobachtet, ausdrücklich nicht Fehler repariert. Alle Produktquellenhashes und echten Profilfingerabdrücke blieben identisch; private user://-Canarys vorhanden.','',
    'Die Kampagnenprobe meldet40Beobachtungschecks und0fehlgeschlagene Checks bei Engineexit0. Der erwartete Parserfehler stammt ausschließlich aus der absichtlich beschädigten privaten Testdatei. Der strenge Wrapper endet deshalb1; dies wird nicht als fehlerfreies Runtimegate verkauft. Ein früher Rootabschluss-Fixture benutzte den falschen Admissionseinstieg und scheiterte9mal; als Harnessfehler verworfen. Die korrigierte tatsächliche Ownerbindung hat17/0 und keine Enginefehler. Beide Rohlogs erhalten.','',
    'Overwatch wurde nicht als aktiver Fehler aufgenommen: regulärer Readiness-Producer liefertfalse. Der neue Cache bewahrt Keys/Revision/Facingfilter; sein Vergleich mit derselben LOS-Query übersah jedoch C6. Keine zusätzliche Fehlermeldung nur wegen großer Dateien oder unter scripts/tests liegender Produktkomponenten.','',
    'Vollständige Rohlogs, Quellhashes und Proben: docs/qa/astra_review_20261113/reproduction_evidence.zip; strukturierte Ergebnisse: summary.json. Wiederausführung: ZIPs tmp/astra_review_20261113 unter denselben Projektroot extrahieren und python tmp/astra_review_20261113/run_probe.py <case> starten. Nur mit passender Godot4.6.2 und vorhandenen Importressourcen.']
report = ROOT/'docs/reviews/ASTRA_REVIEW_2026_11_13.md'
report.write_text('\n'.join(lines)+'\n',encoding='utf-8')
(QA/'README.md').write_text('# Review-Evidenz · 13.11.2026\n\nSiehe [vollständigen Review](../../reviews/ASTRA_REVIEW_2026_11_13.md), summary.json und reproduction_evidence.zip.\n\nDie sieben ausgewählten Läufe reproduzieren neun offene Fehler. Keine Fix-/Regressionserfolgsmeldung. Ein verworfener Rootfixturefehler sowie die erwartete beschädigte-JSON-Diagnose bleiben in den Rohdaten sichtbar. Originalprofile und Produktquellen unverändert.\n',encoding='utf-8')
print(json.dumps({'findings':len(summary['findings']),'runs':len(runs),'all_profile_source_guards':all(all(r['guards'].values()) for r in runs),'zip_bytes':(QA/'reproduction_evidence.zip').stat().st_size}))
