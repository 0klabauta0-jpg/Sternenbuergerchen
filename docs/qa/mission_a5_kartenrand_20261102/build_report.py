"""Build the mission-only local workbench after actual accepted captures exist."""
from pathlib import Path
import hashlib
import html
import json

ROOT = Path(__file__).resolve().parents[3]
QA = Path(__file__).resolve().parent
REPORT = ROOT / 'docs/reports/STERNENBUERGERCHEN_MISSION_A5_2026-11-02.html'
SIZES = ('1920x1080', '1280x720')
TARGET = 'docs/reports/assets/ui-2026-11-01/mockup_a5_mission_zweireihig.png'
BEFORE = 'docs/qa/ui_zielbild_20261102/normal_start/20261102T162357_805920Z'


def read_json(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def local(value):
    path = (ROOT / str(value).removeprefix('res://')).resolve()
    assert path.is_relative_to(ROOT) and path.is_file(), f'Missing local evidence: {path}'
    return path


def rel(path):
    return '../' + path.relative_to(ROOT / 'docs').as_posix()


def image_record(path, size=None, expected_hash=None, **extra):
    path = local(path)
    data = path.read_bytes()
    assert data[:8] == b'\x89PNG\r\n\x1a\n', path
    dimensions = [int.from_bytes(data[16:20], 'big'), int.from_bytes(data[20:24], 'big')]
    if size:
        assert dimensions == [int(x) for x in size.split('x')], f'Wrong actual resolution: {path}'
    if expected_hash:
        assert digest(path) == expected_hash, f'Image bytes changed: {path}'
    return {'image': rel(path), 'sha256': digest(path), 'dimensions': dimensions, **extra}


def figure(record, caption):
    src = html.escape(record['image'], quote=True)
    return f'<figure><a href="{src}"><img loading="lazy" src="{src}" alt="{html.escape(caption, quote=True)}"></a><figcaption>{html.escape(caption)}</figcaption></figure>'


def collect_normal():
    latest = {}
    for manifest in sorted((QA / 'normal_start').glob('*/capture_results.json')):
        for row in read_json(manifest):
            latest['x'.join(map(str, row['logical_size']))] = row
    result = {}
    map_sha = digest(ROOT / 'maps/Ground_Mission01_32x32.json')
    for size in SIZES:
        assert size in latest, f'Accepted normal route missing: {size}'
        row = latest[size]
        source = local(row['source_report'])
        newest_process = sorted((QA / 'normal_start').glob(f'*/{size}/process.json'))[-1]
        assert source.parent == newest_process.parent, f'Newest {size} attempt is not accepted; no older success fallback'
        process = read_json(newest_process)
        assert process['exit_code'] == 0 and process['error_count'] == 0 and process['project_restored_byte_exact']
        assert row['normal_start_failures'] == 0 and row['normal_start_checks'] > 0
        assert row['fixture'] is False and row['source_capture'] and not row['scaled_capture'] and not row['synthetic_image_fallback']
        startup = read_json(source)
        assert startup['failed'] == 0 and startup['facts']['default_map']['sha256'] == map_sha
        frames = {}
        for capture in startup['captures']:
            frames[capture['id']] = image_record(capture['path'], size, capture['sha256'], kind='normal_start', renderer='vulkan', metadata=rel(source), render=capture.get('render_observation', {}), bounds=capture.get('bounds_observation', {}))
        assert all(key in frames for key in ['03b_dropship_details', '05b_character_details', '06_go_movement', '07_outpost_overview', '08_eastern_supply', '09_expanded_map'])
        edge = row.get('edge_walk_probe', {})
        if edge.get('requested'):
            assert edge.get('passed') and edge.get('no_private_actor_or_timer_writes') and '11_old_border_crossed' in frames
        result[size] = {'frames': frames, 'summary': row, 'edge_walk_probe': edge, 'metadata': rel(source)}
    return result


def collect_checks():
    expected = {row['name'] for row in read_json(QA / 'checks_final.json')['checks']}
    latest = {}
    for source in sorted((QA / 'headless').glob('*/checks/*/metadata/report.json')):
        for row in read_json(source).get('checks', []):
            if row.get('name') in expected:
                latest[row['name']] = {'name': row['name'], 'passed': row.get('passed') is True, 'metadata': rel(source)}
    return {'expected': sorted(expected), 'records': latest, 'missing': sorted(expected - latest.keys()), 'passed': sum(x['passed'] for x in latest.values()), 'failed': sum(not x['passed'] for x in latest.values())}


def review_fields(section):
    return f'''<div class="review-fields"><label>Dein Urteil<select data-export-key="sections.{section}.status"><option value="open">Offen</option><option value="closer">Näher an der Vorlage</option><option value="change">Noch ändern</option></select></label><label>Notizen<textarea data-export-key="sections.{section}.note" placeholder="Konkrete Stelle und gewünschte Änderung …"></textarea></label></div>'''


def review_checklist():
    return '''<h3>Direkt an diesen Stellen vergleichen</h3><table class="review-table"><thead><tr><th>Bereich</th><th>2D-Ziel / sichtbares Prüfkriterium</th><th>Funktionsbeleg separat</th></tr></thead><tbody>
<tr><td>Fireteam links unten</td><td>Klare Teamkennung und echte Belegung, dominante zusammengehörige Portraitreihe, ein kurzer bestätigter Zustand. Über dem unteren Band; kein zweiter NPC-Kartenstreifen quer über die Karte.</td><td>Original-Unit-ID per Portrait-Doppelklick; Auswahl, volle Charakterdetails und mehrere echte Teams bleiben erreichbar.</td></tr>
<tr><td>Cutlass oben rechts</td><td>Ganzes echtes Cutlassmodell als kleine Identitätsvorschau, lesbarer Hauptzustand und kurze Lande-/Dropaktion in einem kompakten Block.</td><td>Reale Sperren und Callbacks; zusätzliche Schiffskarten, Richtung und weitere Werkzeuge bleiben im vollständigen nativen Details-Popup.</td></tr>
<tr><td>Protokoll rechts</td><td>Ruhiger Petrolblock über dem Band, kurze lesbare echte Ereigniszeilen und Zeitangaben, keine technischen IDs als Hauptüberschrift.</td><td>Filter bleibt bedienbar; lange reale Meldungen behalten ihren vollständigen Text in einem erreichbaren Detail-/Tooltip-/Scrollpfad.</td></tr>
<tr><td>Haltung unter Teamidentität</td><td>Schmalere zusammengehörige Gruppe mit vollständigen Wörtern Vorsichtig / Normal / Offensiv und zugeordneter Feuerregel.</td><td>Ausgewählt, bestätigt und angefragt bleiben getrennt; Pending-, Reject- und Timeout-Rückmeldung darf nicht abgeschnitten werden.</td></tr>
<tr><td>Boden und Kartenkante</td><td>Jede sichtbare freie Bodenfläche gehört zur tatsächlich gespeicherten Hexunion. Keine innerhalb der Landschaft endende Rasterfläche vor weiterem dekorativem Sand.</td><td>Hexdaten, Polygonabdeckung, Picker, sechs Nachbarn, A*/HPA, FoW und Roundtrip werden getrennt geprüft; ein echter Randmarsch belegt zusätzlich genau diesen Weg.</td></tr>
</tbody></table>'''


def main():
    normal = collect_normal()
    checks = collect_checks()
    rendered_path = sorted((QA / 'rendered_fow').glob('*/process.json'))[-1]
    rendered_fow = read_json(rendered_path)
    assert rendered_fow['passed'] and rendered_fow['headless'] is False and rendered_fow['project_restored_byte_exact']
    group_path = sorted((QA / 'rendered_groups').glob('*/process.json'))[-1]
    rendered_groups = read_json(group_path)
    assert rendered_groups['passed'] and rendered_groups['headless'] is False and rendered_groups['sources_unchanged']
    input_fix = read_json(QA / 'POST_CAPTURE_INPUT_FIX.json')
    assert digest(local(input_fix['current_source'])) == input_fix['current_sha256']
    map_data = read_json(ROOT / 'maps/Ground_Mission01_32x32.json')
    tiles = map_data['tiles']
    grid = map_data['grid_size']
    for size in SIZES:
        profile = normal[size]['summary']['profile']
        assert profile.get('ground_matches_saved_hex_coverage') is True
        assert profile.get('authored_ground_cell_count') == len(tiles)
    target = image_record(TARGET, kind='approved_2d_target')
    historical = {size: image_record(f'{BEFORE}/{size}/startup_captures/06_go_movement.png', size, kind='historical_native') for size in SIZES}
    evidence = {'target': target, 'historical': historical, 'normal': normal, 'checks': checks, 'grid_topology': map_data['grid_topology'], 'saved_cell_count': len(tiles), 'grid_size': grid, 'map_sha256': digest(ROOT / 'maps/Ground_Mission01_32x32.json'), 'scope': 'Real native normal route and separate additional physical edge probe; not a campaign, performance, release or user-style acceptance.'}
    evidence['rendered_fow'] = {**rendered_fow, 'metadata': rel(rendered_path)}
    evidence['rendered_groups'] = {**rendered_groups, 'metadata': rel(group_path)}
    evidence['post_capture_input_fix'] = input_fix

    overview = '<section id="overview" class="tab-panel active"><div class="grid"><article class="card full"><h2>Mission näher an A5, echter Boden bis zur Hexkante</h2><p>Die linke Fireteamkarte, die kompakte Cutlasskarte und das Protokoll werden direkt an der bestätigten Originalvorlage beurteilt. Das akzeptierte kompakte Befehlsband bleibt Grundlage. Die Bilder sind unveränderte Engineaufnahmen; die Bild-KI-Vorlage ist das Stilziel.</p>'
    overview += figure(normal['1920x1080']['frames']['06_go_movement'], 'Neue Mission · echter normaler Start und Move/GO · 1920×1080 · Vulkan')
    overview += f'<p>Die gespeicherte Karte besitzt {grid["x"]}×{grid["y"]} echte Hexfelder ({len(tiles)} Zellen). Der bisherige innere Rand entstand, weil die sichtbare Bodenplatte deutlich größer als die gespeicherte Hexkarte war. Jetzt besteht auch der Boden aus den tatsächlichen gespeicherten Hexflächen bis zu ihrer gemeinsamen Außenkante. Außerhalb liegt ein klar abgesetzter petrolfarbener Hintergrund. Sichtbare Felsen/Gebäude bleiben Hindernisse.</p><p>Die Sichtmaske bleibt erhalten. Neue Sichtmeldungen setzen ihren laufenden Aufbau nicht mehr auf null zurück; bereits gebaute Felder werden aus den aktuellen vollständigen Sichtdaten korrigiert. Unbekannte Bereiche bleiben geschützt.</p></article>'
    overview += '<article class="card wide"><h2>Was ich mir bei der Gruppierung gedacht habe</h2><p>Eine portraitgeführte Teamkarte links bündelt Identität, Belegung und bestätigten Zustand. Einzelne Charakterdetails bleiben erreichbar, ohne einen zweiten Personenstreifen quer über die Karte zu legen. Rechts oben stehen Schiff und Landungsaktion zusammen; Details bleiben ein eigener erreichbarer Pfad. Das Protokoll liegt als ruhiger Block rechts über dem Band. Haltung und Feuerregeln gehören direkt unter die ausgewählte Teamidentität.</p><p>Die exakte vorhandene Ref03-Cutlass ersetzt das generische Beispielschiff der Illustration. Reale IDs, Zustände, vorhandene Commands und Feindsicht bestimmen den Inhalt.</p></article><article class="card"><h2>Verbleibender Vorlagenabstand</h2><p>Gelände, Kamera und uneinheitliche Portraitassets erreichen den gemalten Stil noch nicht. Die Teamkarte ist flacher und rechteckiger als das A5-Original, die Haltungswahl hat noch die native Goldkontur. Das Ziel-/Auftragsfeld bleibt textgeführt statt als Vorlagen-Dropdown dargestellt. Der erreichbare Charakterbogen ist weiterhin dicht und enthält englische Diagnosebezeichnungen; er ist ein konkreter nächster UI-Folgepunkt.</p><p>Das Nutzerurteil zur Zielnähe bleibt offen. Normale Gameplayzeit wird für die Aufnahmen nicht beschleunigt; technische Checks beweisen weder Gesamtperformance noch vollständige Kampagnen-/Mehrspieler- oder EXE-Freigabe.</p></article></div></section>'

    comparison = '<section id="comparison" class="tab-panel"><div class="grid"><article class="card full"><h2>Original · bisherige Engine · neue Engine</h2><p>Alle drei Bilder zeigen ihre eigene belegte Herkunft. Beispielpersonen und Zustände in der 2D-Vorlage sind keine Runtime-Sollwerte. Die neue Heroansicht entsteht vor dem zusätzlichen Randmarsch, damit die HUD-Gruppierung mit dem bisherigen Spielausschnitt verglichen werden kann.</p>'
    for size in SIZES:
        if size == '1280x720':
            comparison += '<details class="small-view"><summary>Echte 1280×720 vergleichen</summary>'
        comparison += f'<div class="comparison" data-size="{size}"><div><h3>Bestätigtes Original</h3>' + figure(target, 'A5 · 2D-Zielbild, kein Enginebild') + '</div><div><h3>Bisherige Engine</h3>' + figure(historical[size], size + ' · vorheriger unveränderter normaler Start') + '</div><div><h3>Neue Engine</h3>' + figure(normal[size]['frames']['06_go_movement'], size + ' · neue native Mission') + '</div></div>'
        if size == '1280x720':
            comparison += '</details>'
    comparison += review_checklist()
    for section, title in [('team', 'Fireteamkarte'), ('dropship', 'Cutlasskarte'), ('protocol', 'Protokoll'), ('stance', 'Haltung und Feuerregel')]:
        comparison += '<h3>' + title + '</h3>' + review_fields(section)
    comparison += '<details><summary>Tatsächlich geöffnete native Transport- und Charakterdetails</summary><p>Vorhandene GUI-Callbacks öffnen und schließen die wirklichen Detailflächen während derselben normalen Mission. Der Portrait-Doppelklick behält die ursprüngliche Unit-ID. Dies ist ein Callback-/Sichtbeleg, kein Betriebssystem-Maustest.</p>'
    for size in SIZES:
        comparison += figure(normal[size]['frames']['03b_dropship_details'], size + ' · native vollständige Transportdetails')
        comparison += figure(normal[size]['frames']['05b_character_details'], size + ' · bestehender Charakterbogen der tatsächlich angeklickten Person')
    comparison += '</details>' + review_fields('hud') + '</article><article class="card full"><h2>Kartenrand und Landschaft</h2>'
    comparison += figure(normal['1920x1080']['frames']['07_outpost_overview'], 'Gleicher Außenpostenausschnitt · Boden und Raster mit echten Feldern')
    comparison += '<details><summary>Größerer Kartenausschnitt</summary>' + figure(normal['1920x1080']['frames']['09_expanded_map'], 'Zentraler erweiterter Ausschnitt wie vorher · keine Gesamtansicht der neuen Karte') + '</details>'
    assert '10_all_saved_hexes' in normal['1920x1080']['frames']
    comparison += '<h3>Alle tatsächlich gespeicherten Hexfelder</h3>' + figure(normal['1920x1080']['frames']['10_all_saved_hexes'], 'Neue vollständige Kartenansicht · Bounds aus sämtlichen tatsächlich gespeicherten Hexzellen')
    ground_bounds = normal['1920x1080']['summary']['profile'].get('authored_ground_plane_bounds', {})
    comparison += '<p>Vom aktuellen Renderer gemeldete Bodenbounds: <code>' + html.escape(json.dumps(ground_bounds, ensure_ascii=False, sort_keys=True)) + '</code>. Der Ground-Cellcount stimmt mit der aktuellen gespeicherten Karte überein. Das beschreibt die tatsächliche Bodenmesh-Abdeckung, nicht eine nach außen verlängerte Rasterillustration.</p>'
    for size in SIZES:
        edge = normal[size]['edge_walk_probe']
        if edge.get('requested'):
            comparison += f'<h3>Tatsächlicher Marsch über die frühere Westgrenze · {size}</h3>' + figure(normal[size]['frames']['11_old_border_crossed'], 'Nach zusätzlichem echten Move/GO · ursprüngliche Runtimeakteure und normale Spielzeit')
            comparison += '<p>Der zusätzliche Auftrag führt auf das gespeicherte Hex (-8,12), physisch westlich der früheren x=0-Grenze. Die vorhandenen Commands werden ausgeführt; Positionen und Timer werden nur beobachtet. Ein Screenshot allein ersetzt die aufgezeichneten echten Vorher-/Nachherpositionen nicht.</p>'
    comparison += review_fields('edge') + '</article></div></section>'

    rows = ''.join(f'<li>{html.escape(name)}: {"PASS" if row["passed"] else "FAIL"} · <a href="{html.escape(row["metadata"], quote=True)}">Rohbericht</a></li>' for name, row in checks['records'].items())
    normal_rows = ''.join(f'<li>{size}: {normal[size]["summary"]["normal_start_checks"]} Checks, Exit0 ohne Engine-/Leakfehler. Zusätzlicher Randmarsch: {"geprüft" if normal[size]["edge_walk_probe"].get("passed") else "in dieser Auflösung nicht ausgeführt"}.</li>' for size in SIZES)
    playtest = f'<section id="playtest" class="tab-panel"><div class="grid"><article class="card wide"><h2>Technische Ergebnisse</h2><p>{checks["passed"]} von {len(checks["expected"])} ausgewählten Gates als bestanden dokumentiert; {checks["failed"]} fehlgeschlagen, {len(checks["missing"])} fehlend. Die Zahlen stammen aus den neuen Ergebnissen.</p><ul>{rows}</ul><h3>Normaler Spielstart</h3><ul>{normal_rows}</ul><p><a href="../qa/mission_a5_kartenrand_20261102/README.md">Befehle, Quellenpins und Grenzen</a></p><p>Die ursprünglichen Transfer-/Ausladezeitfenster bleiben unverändert. Nur der zusätzliche Randauftrag erhält nach der normalen Route ein eigenes begrenztes Beobachtungsfenster. Die 350ms-Audiofreigabe erfolgt erst nach Entfernen der Spielszene. Das ist keine Spielzeitbeschleunigung.</p></article><article class="card"><h2>Dein Spieltest</h2>'
    playtest = playtest.replace('<h3>Normaler Spielstart</h3>', f'<p>Zusätzlich separat unter Vulkan: tatsächliche Masken-Slotfarben und Positionen aller9408 Zellen bei fortlaufenden Sichtänderungen sowie Modus-/Teamwechsel. <a href="{rel(rendered_path)}">Nativer FoW-Rohbeleg</a>. Headless prüft Zustände und Fortschritt; Dummy-GPU-Werte gelten ausdrücklich nicht als Renderbeweis.</p><h3>Normaler Spielstart</h3>')
    playtest = playtest.replace('<h3>Normaler Spielstart</h3>', f'<p>Nach den unveränderten Normalstart-PNGs wurde ausschließlich ein Aufruf zur Tooltip-Eingabe hinter die alte Ignore-Rekursion verschoben. Die übrige Controllerquelle einschließlich Darstellung, Texten und Spielregeln bleibt unverändert. <a href="../qa/mission_a5_kartenrand_20261102/POST_CAPTURE_INPUT_FIX.json">Vorher-/Nachher-Quellenbeleg</a>; der aktuelle Eingabestand besitzt einen getrennten <a href="{rel(group_path)}">Vulkan-GUI-Gruppennachweis</a> für Fenster, Schrift, Fokus, Scroll und Tooltip-Hitfilter. Das ist kein Betriebssystem-Maustest.</p><h3>Normaler Spielstart</h3>')
    for key, label in [('hud','Trupp/Dropship/Protokoll entsprechen A5'),('stance','Haltungsbereich kompakt und lesbar'),('hex1920','Hexfelder bei 1920 sichtbar'),('hex1280','Hexfelder bei 1280 sichtbar'),('edge','Sichtbarer freier Boden ist auswählbar und erreichbar'),('details','Charakter-/Transportdetails bleiben erreichbar')]:
        playtest += f'<label class="checkline"><input type="checkbox" data-export-key="playtest.{key}"> {label}</label>'
    playtest += '</article><article class="card wide"><h2>Beobachtung</h2><textarea data-export-key="playtest.observation" placeholder="Konkrete Stelle, Auflösung und gewünschte Änderung …"></textarea><div contenteditable="true" data-note-key="review.notes" data-placeholder="Weitere Notizen …"></div></article><article class="card"><h2>Entscheidung</h2><div data-choice-group="review.direction" class="button-row"><button type="button" class="choice active" data-choice-value="open">Offen</button><button type="button" class="choice" data-choice-value="polish">Weiter verfeinern</button><button type="button" class="choice" data-choice-value="accept">Diese Gruppierung behalten</button></div></article></div></section>'

    template = (ROOT / 'docs/reports/_html_workbench_template.html').read_text(encoding='utf-8')
    start = template.index('    <section id="overview"')
    end = template.index('  </main>', start)
    result = template[:start] + overview + comparison + playtest + '\n' + template[end:]
    result = result.replace('Workbench Report Template', 'Mission · A5 und bespielbarer Kartenrand').replace('template_workbench', 'mission_a5_kartenrand_20261102')
    result = result.replace('Kurze Beschreibung des Reports. Diese Vorlage ist fuer Playtests, Entscheidungen und kontrollierte Arbeitsstaende gedacht.', 'Direkter A5-Vergleich · reale Mission und echte Hexabdeckung · 02.11.2026')
    result = result.replace('Task: TASK_000', 'Task: Mission A5 / Kartenrand').replace('Stand: Entwurf', 'Stand: native Runde, Stilurteil offen')
    result = result.replace('<button class="tab" type="button" data-tab-target="playtest">Playtest</button>', '<button class="tab" type="button" data-tab-target="comparison">Original + Engine</button>')
    result = result.replace('<button class="tab" type="button" data-tab-target="decisions">Entscheidungen</button>', '<button class="tab" type="button" data-tab-target="playtest">Prüfung + Notizen</button>')
    css = 'main{width:min(1680px,calc(100vw - 32px))}figure{margin:16px 0}img{display:block;width:100%;height:auto;border:1px solid var(--line)}figcaption{font-size:12px;color:var(--muted);margin-top:7px}.comparison{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:14px;margin:18px 0}.review-fields{display:grid;grid-template-columns:1fr 2fr;gap:14px;margin:18px 0}.review-table{width:100%;border-collapse:collapse;margin:14px 0}.review-table th,.review-table td{padding:10px;border:1px solid var(--line);text-align:left;vertical-align:top}.review-table th{color:var(--cyan)}.small-view{margin-top:18px}summary{cursor:pointer;color:var(--cyan)}.toolbar{position:static}@media(max-width:950px){.comparison,.review-fields{grid-template-columns:1fr}.review-table{display:block;overflow-x:auto}}'
    result = result.replace('</style>', css + '\n</style>')
    result = result.replace('<footer class="toolbar">', '<!-- Abgeleitet von docs/reports/_html_workbench_template.html; Export enthält Arbeitsnotizen. -->\n<footer class="toolbar">')
    result = result.replace('computed: {},', 'computed: { compared_sizes: ["1920x1080", "1280x720"], saved_cell_count: ' + str(len(tiles)) + ' },')
    result = result.replace('metadata: {', 'metadata: { evidence: ' + json.dumps(evidence, ensure_ascii=True).replace('</', '<\\/') + ',', 1)
    REPORT.write_text(result, encoding='utf-8', newline='\n')
    print(REPORT)


if __name__ == '__main__':
    main()
