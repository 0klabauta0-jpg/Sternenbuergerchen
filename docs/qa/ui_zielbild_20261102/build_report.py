"""Build the local target-image workbench only after fresh captures exist.

Derived from the repository workbench template and GM01 report builder.
Reads evidence, validates native image dimensions/hashes, writes only the new HTML.
No engine, image editing, network dependency or historical report mutation.
"""
from pathlib import Path
import hashlib
import html
import json

ROOT = Path(__file__).resolve().parents[3]
QA = Path(__file__).resolve().parent
REPORT = ROOT / "docs/reports/STERNENBUERGERCHEN_UI_ZIELBILD_2026-11-02.html"
SIZES = ("1920x1080", "1280x720")
SCREENS = {
    "mission": ("Mission / Befehlsband", "mockup_a5_mission_zweireihig.png"),
    "homebase": ("Heimatbasis", "menu_heimatbasis.png"),
    "fob": ("FOB / Ausrüstung", "menu_fob_loadout.png"),
    "debrief": ("Nachbesprechung", "menu_debrief.png"),
}
HISTORY = {
    "mission": {size: f"docs/qa/gm01_frontier_20261102/captures/mission_frontier_{size}.png" for size in SIZES},
    "homebase": {
        "1920x1080": "docs/qa/gm01_frontier_20261102/frontier/1920x1080_20261102T140614Z/startup_captures/02_homebase.png",
        "1280x720": "docs/qa/gm01_frontier_20261102/frontier/1280x720_20261102T141144Z/startup_captures/02_homebase.png",
    },
    "fob": {
        "1920x1080": "docs/qa/ui_native_r4_20261102/captures/fob_populated_1920x1080.png",
        "1280x720": "docs/qa/ui_native_r4_20261102/captures/fob_1280x720.png",
    },
    "debrief": {size: f"docs/qa/ui_native_r4_20261102/captures/debrief_portraits_{size}.png" for size in SIZES},
}


def read_json(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def project_path(value):
    path = (ROOT / str(value).removeprefix("res://")).resolve()
    assert path.is_relative_to(ROOT), f"Evidence outside project: {value}"
    assert path.is_file(), f"Missing evidence: {path}"
    return path


def relative(path):
    return "../" + path.relative_to(ROOT / "docs").as_posix()


def image_record(path, size=None, expected_hash=None, **metadata):
    path = project_path(path)
    data = path.read_bytes()
    assert data[:8] == b"\x89PNG\r\n\x1a\n", f"Not a PNG: {path}"
    dimensions = [int.from_bytes(data[16:20], "big"), int.from_bytes(data[20:24], "big")]
    if size:
        assert dimensions == [int(part) for part in size.split("x")], f"Scaled or wrong-size capture: {path}"
    sha = hashlib.sha256(data).hexdigest()
    if expected_hash:
        assert sha == expected_hash, f"Capture hash mismatch: {path}"
    return {"image": relative(path), "sha256": sha, "dimensions": dimensions, **metadata}


def records_by_key(group, key):
    """Newest record per key; a newer failure is never hidden by older success."""
    result = {}
    for manifest in sorted((QA / group).glob("*/capture_results.json")):
        rows = read_json(manifest)
        assert isinstance(rows, list), f"Unexpected capture manifest: {manifest}"
        for row in rows:
            result[key(row)] = (row, manifest)
    return result


def collect_captures():
    normal = records_by_key("normal_start", lambda row: "x".join(map(str, row["logical_size"])))
    fixtures = records_by_key("fixtures", lambda row: (row["view"], row["variant"], row["size"]))
    result = {screen: {} for screen in SCREENS}
    map_sha = digest(ROOT / "maps/Ground_Mission01_32x32.json")
    normal_summaries = []
    for size in SIZES:
        assert size in normal, f"Fresh normal-start captures missing: {size}"
        row, manifest = normal[size]
        assert row.get("exit_code") == 0 and row.get("error_count") == 0, f"Normal start failed: {manifest}"
        assert row.get("fixture") is False and row.get("source_capture") is True
        assert row.get("scaled_capture") is False and row.get("synthetic_image_fallback") is False
        source = project_path(row["source_report"])
        startup = read_json(source)
        assert startup["failed"] == 0 and startup["passed"] > 0
        assert startup["facts"]["default_map"]["sha256"] == map_sha, "Captures describe a superseded GM01"
        captures = {item["id"]: item for item in startup["captures"]}
        normal_summaries.append({"size": size, "passed": startup["passed"], "failed": startup["failed"], "source": relative(source)})
        for screen, capture_id in (("mission", "07_outpost_overview"), ("homebase", "02_homebase")):
            capture = captures[capture_id]
            result[screen][size] = image_record(capture["path"], size, capture["sha256"],
                kind="normal_start", renderer="vulkan", metadata=relative(source), manifest=relative(manifest), capture_id=capture_id)
        for screen, variant in (("fob", "populated"), ("debrief", "portraits")):
            key = (screen, variant, size)
            assert key in fixtures, f"Fresh native fixture capture missing: {key}"
            record, fixture_manifest = fixtures[key]
            assert record.get("passed") is True and record.get("exit_code") == 0 and record.get("error_count") == 0
            evidence = record["evidence"]
            assert evidence["fixture_data"] is True and evidence["source_capture"] is True
            assert evidence["synthetic_image_fallback"] is False and evidence["scaled_capture"] is False
            result[screen][size] = image_record(evidence["image"], size, record["image_sha256"],
                kind="native_fixture", renderer="gl_compatibility", variant=variant, metadata=relative(fixture_manifest))
    return result, normal_summaries


def collect_checks():
    expected = {item["name"] for item in read_json(QA / "checks_final.json")["checks"]}
    latest = {}
    for source in sorted((QA / "headless").glob("*/checks/*/metadata/report.json")):
        for check in read_json(source).get("checks", []):
            if check.get("name") in expected:
                latest[check["name"]] = {"name": check["name"], "passed": check.get("passed") is True, "metadata": relative(source)}
    return {"expected": sorted(expected), "records": latest, "missing": sorted(expected - latest.keys()),
            "passed": sum(check["passed"] for check in latest.values()),
            "failed": sum(not check["passed"] for check in latest.values())}


def figure(record, caption):
    src = html.escape(record["image"], quote=True)
    return f'<figure><a href="{src}"><img loading="lazy" src="{src}" alt="{html.escape(caption, quote=True)}"></a><figcaption>{html.escape(caption)}</figcaption></figure>'


def review_fields(screen):
    return f'''<div class="review-fields"><label>Dein Urteil<select data-export-key="screens.{screen}.status"><option value="open">Offen</option><option value="closer">Näher am Ziel</option><option value="change">Überarbeiten</option><option value="accepted">Stil passt für mich</option></select></label><label>Nächster Schwerpunkt<select data-export-key="screens.{screen}.focus"><option value="frames">Rahmen / Hierarchie</option><option value="density">Kompaktheit / Lesbarkeit</option><option value="portraits">Personenkarten</option><option value="scene">Szene / Modelle</option></select></label><textarea data-export-key="screens.{screen}.note" placeholder="Was passt, was fehlt? Bitte sichtbare Stelle nennen."></textarea></div>'''


def comparison_section(captures, evidence):
    content = '''<section id="comparison" class="tab-panel"><div class="grid"><article class="card full"><h2>Erst Regeln prüfen, dann die Originale vergleichen</h2><p>Der MD-Audit wurde vor diesem direkten Bildvergleich abgeschlossen. Die bestätigten Original-2D-Ziele bleiben maßgeblich; keine neue Stilvorgabe aus Brückenbildern. Historische Screenshots bleiben unverändert. Unterschiede in Personenanzahl, Werten, Enable-Zuständen und Belegung sind keine Sollwerte aus dem Konzept.</p><p>Gelockerte Zwischenfestlegungen: schlichte Rahmen,64px-/160px-Maße, kleine Portraits und die bisherige Bühnenrestfläche sind keine ewigen Grenzen. Dekorative Raster-/Nine-Patch-/mehrschichtige Rahmen dürfen echte native Controls ergänzen. Identität, Cutlass, Texte, Zustandsbesitz, Fokus und tatsächliche Funktionen bleiben verbindlich.</p><p><a href="../qa/ui_zielbild_20261102/BILDVERGLEICH.md">Vollständiger direkter Bildvergleich</a> · <a href="../dev/ui_native_design_contract.md">fortgeschriebener UI-Vertrag</a> · <a href="../dev/gm01_frontier_map_contract.md">GM01-/Sichtvertrag</a></p></article>'''
    descriptions = {
        "mission": "Randband und zwei Reihen sind vorhanden. Diese Runde bearbeitet Rahmen, Hierarchie, Kompaktheit und Hexerkennbarkeit. Die größeren Modell-/Geländeformen und die gemeinsame illustrierte Portraitfamilie bleiben eine eigene offene Arbeit.",
        "homebase": "Normaler Startlauf mit echten aktuellen Daten. Die historische und neue Aufnahme zeigen nicht die erfundenen Beispielpersonen der Vorlage. Eine reichere Schiff-/Crewbühne und weitreichende belegungsabhängige Neuverteilung sind durch einen Rahmenpass noch nicht gelöst.",
        "fob": "Echte native Controls mit ausdrücklich gesetzten Testdaten, GL Compatibility. Dieses Fixture ist kein normaler Boardingnachweis. Die entfernte Außenpostenbühne ersetzt noch nicht die nahe Flugdeckkomposition des Originals.",
        "debrief": "Echte native Controls mit Portrait-Testdaten, GL Compatibility. Keine erfundenen Ereignisse, Gesundheitswerte oder Entwicklungspunkte ergänzen. Ergebnisgewichtung und sichtbare Karten dürfen verbessert sein; die erzählerische Rückkehrszene bleibt offen.",
    }
    for screen, (title, target_name) in SCREENS.items():
        target = image_record(ROOT / "docs/reports/assets/ui-2026-11-01" / target_name, kind="approved_2d_target")
        evidence["targets"][screen] = target
        content += f'<article id="compare-{screen}" class="card full"><h2>{html.escape(title)}</h2><p>{html.escape(descriptions[screen])}</p>'
        for size in SIZES:
            historical = image_record(HISTORY[screen][size], size, kind="historical_native")
            evidence["historical"].setdefault(screen, {})[size] = historical
            if size == "1280x720":
                content += '<details class="small-view"><summary>Dieselben Originalziele mit echter 1280×720-Darstellung vergleichen</summary>'
            content += f'<div class="comparison" data-screen="{screen}" data-size="{size}">'
            content += '<div><h3>Bestätigtes Original · 2D-Ziel</h3>' + figure(target, "Bild-KI-Konzept · Stilziel, Beispielinhalt") + '</div>'
            historic_note = "Historischer GM01-Stand" if screen in ("mission", "homebase") else "Historischer R4-Stand"
            if screen == "fob" and size == "1280x720":
                historic_note += " · Standardfixture, anderer Belegungszustand"
            content += '<div><h3>Historisch · native Engine</h3>' + figure(historical, historic_note + " · " + size) + '</div>'
            current = captures[screen][size]
            kind = "normaler Startlauf · Vulkan" if current["kind"] == "normal_start" else "ausdrückliche Testdaten · GL Compatibility"
            content += '<div><h3>Neue Runde · native Engine</h3>' + figure(current, size + " · " + kind) + f'<p><a href="{html.escape(current["metadata"], quote=True)}">Originalmetadaten</a> · SHA-256 im JSON-Export</p></div></div>'
            if size == "1280x720":
                content += '</details>'
        content += review_fields(screen) + '</article>'
    return content + '</div></section>'


def main():
    captures, normal_summaries = collect_captures()
    checks = collect_checks()
    evidence = {"targets": {}, "historical": {}, "captures": captures, "checks": checks, "normal_start": normal_summaries,
        "grid_topology": "hex_axial_v1", "scope": "Local visual iteration; no campaign, performance, export, release or user style acceptance."}
    comparison = comparison_section(captures, evidence)
    overview = '''<section id="overview" class="tab-panel active"><div class="grid"><article class="card full"><h2>Näher an die bestätigten 2D-Vorlagen</h2><p>Reihenfolge: alte Dokumentgrenzen geprüft und bereinigt → echte Enginebilder direkt mit den Originalen verglichen → begrenzte native UI-/Rasterrunde. Die neuen Bilder zeigen den tatsächlich aufgenommenen Stand. Ob die Stilnähe reicht, bleibt deine Entscheidung.</p>'''
    overview += figure(captures["mission"]["1920x1080"], "Neue native Mission · normaler GM01-Start und echte Spielzeit · 1920×1080 · Vulkan")
    overview += '''<p>Im Tab „Audit + Vergleich“ stehen für jeden Screen Original, historischer nativer Stand und neue native Aufnahme nebeneinander. 1280×720 ist dort separat aufklappbar; Klick auf ein Bild öffnet das unveränderte Original.</p></article><article class="card wide"><h2>Was diese Runde anfasst</h2><p>Gemeinsame Rahmen-/Eckensprache, klarere Abschnittsgewichte, ein 128px-Band mit zwei Reihen 52px-Tasten und besser erkennbare echte Hexfelder. Bestehende Controls senden weiter dieselben Commands; die UI besitzt keinen eigenen Gameplayzustand.</p><h3>Was sichtbar offen bleibt</h3><p>Die gemalten Gebäude haben tiefere Portale, stärker gestaffelte Dächer und reichere Kontaktzonen. Die native Fels-/Bodenkomposition und entfernte Menübühne bleiben einfacher. Echte Pixelportraits sind noch keine gemeinsame illustrierte Portraitfamilie. Ein Rahmenpass ist keine abgeschlossene Modell-, Portrait- oder Szenenrevision.</p><p>Konkreter Modellpfad: GM01 blendet die geladenen Habitat-/Hallen-Schnittmodelle aus und zeigt die prozeduralen Außenhüllen aus <code>frontier_closed_buildings.gd</code>. Ein GLB-Austausch allein ändert diese sichtbare Silhouette nicht. <a href="../qa/ui_zielbild_20261102/NACHPRUEFUNG.md">Neue Bildnachprüfung und Ansatz für die Modellrunde</a></p></article><article class="card"><h2>Sichtmaske: weiterhin vorhanden</h2><p>Im bekannten Terrainmodus entfällt der frühere schwarze Aufbau-Schutzkasten. Die zellbasierte Terrain-Bodenmaske bleibt erhalten; bekannte, aktuell ungesehene Frontier-Zellen werden schwach abgedunkelt. Unbekanntes Terrain bleibt geschützt.</p><p>Der unabhängige Gegner-Sichtfilter bleibt aktiv. Ein deutlicheres Raster oder hellerer Boden bedeutet keine Freigabe versteckter Gegner. Ein Standbild belegt außerdem keine Flackerfreiheit im Zeitverlauf.</p></article></div></section>'''
    status = f'{checks["passed"]} von {len(checks["expected"])} vorgesehenen Gates als bestanden dokumentiert'
    if checks["failed"]:
        status += f';{checks["failed"]} fehlgeschlagen'
    if checks["missing"]:
        status += '; noch ohne Ergebnis: ' + ', '.join(checks["missing"])
    rows = ''.join(f'<li>{html.escape(name)}: ' + (f'<a href="{html.escape(checks["records"][name]["metadata"], quote=True)}">' + ('PASS' if checks["records"][name]["passed"] else 'FAIL') + '</a>' if name in checks['records'] else 'nicht nachgewiesen') + '</li>' for name in checks["expected"])
    normal_rows = ''.join(f'<li>{item["size"]}: <a href="{html.escape(item["source"], quote=True)}">{item["passed"]} vorhandene Normalstartchecks bestanden,{item["failed"]} fehlgeschlagen</a></li>' for item in normal_summaries)
    playtest = f'''<section id="playtest" class="tab-panel"><div class="grid"><article class="card wide"><h2>Vorhandene technische Ergebnisse</h2><p>{html.escape(status)}. Zahlen werden aus den frischen Ergebnisdateien gelesen, nicht aus früheren Runden übernommen.</p><ul>{rows}</ul><h3>Normale Spielroute</h3><ul>{normal_rows}</ul><p>Die gezielten Engine-Gates und normalen Startläufe ersetzen keine menschliche Prüfung von Stil, Rastererkennbarkeit, Lesbarkeit oder Flackerfreiheit. FOB/Debrief sind separate native Testfixtures. Keine pauschale Gameplay-, Leistungs-, Kampagnen-, EXE- oder Releaseabnahme.</p><p><a href="../qa/ui_zielbild_20261102/README.md">Nachweise und reproduzierbare Befehle</a></p></article><article class="card"><h2>Deine Sichtprüfung</h2><label class="checkline"><input type="checkbox" data-export-key="playtest.style"> Gemeinsamer Stil erkennbar</label><label class="checkline"><input type="checkbox" data-export-key="playtest.compact"> Befehlsband kompakt genug</label><label class="checkline"><input type="checkbox" data-export-key="playtest.hex1920"> Hexfelder bei 1920×1080 erkennbar</label><label class="checkline"><input type="checkbox" data-export-key="playtest.hex1280"> Hexfelder bei 1280×720 erkennbar</label><label class="checkline"><input type="checkbox" data-export-key="playtest.readable"> Texte und Zustände verständlich</label><label class="checkline"><input type="checkbox" data-export-key="playtest.temporal"> Im eigenen Spieltest kein schwarzes Aufblitzen</label></article><article class="card wide"><h2>Beobachtung und nächste Runde</h2><textarea data-export-key="playtest.observation" placeholder="Konkreter Screen, Auflösung und sichtbare Stelle …"></textarea><div contenteditable="true" data-note-key="review.notes" data-placeholder="Weitere Notizen für den nächsten Chat …"></div></article><article class="card"><h2>Entscheidung</h2><div data-choice-group="review.direction" class="button-row"><button type="button" class="choice active" data-choice-value="open">Offen</button><button type="button" class="choice" data-choice-value="polish">Weiter verfeinern</button><button type="button" class="choice" data-choice-value="models">Modelle / Szene als Nächstes</button></div></article></div></section>'''
    template = (ROOT / "docs/reports/_html_workbench_template.html").read_text(encoding="utf-8")
    start = template.index('    <section id="overview"')
    end = template.index('  </main>', start)
    result = template[:start] + overview + comparison + playtest + '\n' + template[end:]
    result = result.replace('Workbench Report Template', 'UI · Direkter Zielbildvergleich')
    result = result.replace('template_workbench', 'ui_zielbild_20261102')
    result = result.replace('Kurze Beschreibung des Reports. Diese Vorlage ist fuer Playtests, Entscheidungen und kontrollierte Arbeitsstaende gedacht.', 'Bestätigte Originale neben echten nativen Aufnahmen · Dokumentaudit vor visueller Runde ·02.11.2026')
    result = result.replace('Task: TASK_000', 'Task: UI-Zielbildabgleich').replace('Stand: Entwurf', 'Stand: neue native Aufnahmen · Stilurteil offen')
    nav_start, nav_end = result.index('    <nav class="tabbar"'), result.index('    </nav>') + len('    </nav>')
    nav = '<nav class="tabbar" aria-label="Reportbereiche"><button class="tab active" type="button" data-tab-target="overview">Überblick</button><button class="tab" type="button" data-tab-target="comparison">Audit + Vergleich</button><button class="tab" type="button" data-tab-target="playtest">Prüfung + Notizen</button></nav>'
    result = result[:nav_start] + nav + result[nav_end:]
    css = 'main{width:min(1680px,calc(100vw - 32px))}figure{margin:14px 0}img{display:block;width:100%;height:auto;border:1px solid var(--line);border-radius:4px}figcaption{font-size:12px;color:var(--muted);margin-top:7px}.comparison{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:14px;margin-top:18px}.review-fields{display:grid;grid-template-columns:1fr 1fr 2fr;gap:12px;margin-top:18px}.small-view{margin-top:18px;border-top:1px solid var(--line);padding-top:12px}summary{cursor:pointer;color:var(--cyan)}.toolbar{position:static}.card p{max-width:110ch}.review-fields textarea{min-height:82px}@media(max-width:950px){.comparison,.review-fields{grid-template-columns:1fr}}'
    result = result.replace('</style>', css + '\n</style>')
    result = result.replace('<footer class="toolbar">', '<!-- Abgeleitet von docs/reports/_html_workbench_template.html; Export enthält nur Arbeitsnotizen. -->\n<footer class="toolbar">')
    evidence_json = json.dumps(evidence, ensure_ascii=False).replace('<', '\\u003c')
    result = result.replace('    (function () {', '    const reportEvidence = ' + evidence_json + ';\n    (function () {')
    result = result.replace('computed: {},', 'computed: { screens_total: 4, compared_sizes: ["1920x1080", "1280x720"] },')
    result = result.replace('metadata: { url: window.location.href, user_agent: navigator.userAgent }', 'metadata: { url: window.location.href, user_agent: navigator.userAgent, evidence: reportEvidence }')
    REPORT.write_text(result, encoding="utf-8", newline="\n")
    print(REPORT)


if __name__ == "__main__":
    main()
