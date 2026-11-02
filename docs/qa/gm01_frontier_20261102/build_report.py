"""Derive the local map review workbench from the repository template."""
from pathlib import Path
import html
import hashlib
import json

ROOT = Path(__file__).resolve().parents[3]
QA = Path(__file__).resolve().parent
REPORT = ROOT / 'docs/reports/STERNENBUERGERCHEN_GM01_FRONTIER_2026-11-02.html'
template = (ROOT/'docs/reports/_html_workbench_template.html').read_text(encoding='utf-8')


def image(path, caption):
    src = '../' + path.relative_to(ROOT/'docs').as_posix()
    return f'<figure><a href="{src}"><img loading="lazy" src="{src}" alt="{html.escape(caption)}"></a><figcaption>{html.escape(caption)}</figcaption></figure>'


def main():
    reports = sorted((QA/'checks_final').glob('*/metadata/report.json'))
    latest = {}
    for path in reports:
        for check in json.loads(path.read_text(encoding='utf-8'))['checks']:
            latest[check['name']] = check
    assert len(latest) == 24 and all(c['passed'] for c in latest.values())
    records = json.loads((QA/'frontier_capture_results.json').read_text(encoding='utf-8'))
    map_sha = hashlib.sha256((ROOT/'maps/Ground_Mission01_32x32.json').read_bytes()).hexdigest()
    views = {}
    for record in records:
        size = 'x'.join(str(x) for x in record['logical_size'])
        assert record['exit_code'] == 0 and record['error_count'] == 0
        report = json.loads((ROOT/record['source_report']).read_text(encoding='utf-8'))
        assert report['facts']['default_map']['sha256'] == map_sha, 'Native captures still describe a superseded map'
        stage = next(s for s in report['stages'] if s['id'] == 'mission_started')
        assert stage['details']['render']['grid_topology'] == 'hex_axial_v1'
        views[size] = {c['id']: ROOT/c['path'].removeprefix('res://') for c in report['captures']}
    assert set(views) == {'1920x1080', '1280x720'}
    captures = views['1920x1080']
    terrain = json.loads((ROOT/'maps/Ground_Mission01_32x32.json').read_text(encoding='utf-8'))
    solid_count = sum(t.get('object_type_id') == 'frontier_scene_solid' for t in terrain['tiles'])
    cover_count = sum(bool(t.get('walkable')) and t.get('cover_value', 0) > 0 for t in terrain['tiles'])
    before = ROOT/'docs/qa/ui_native_r4_20261102/captures/mission_frontier_1920x1080.png'
    summary = '<section id="overview" class="tab-panel active"><div class="grid"><article class="card full"><h2>Die reguläre Standardkarte, neu gebaut</h2><p>Menü → Singleplayer → Heimatbasis → Grid Sweep lädt weiterhin dieselbe GM01. Jetzt stehen hier die neuen cremefarbenen Außenpostengebäude, erodierte Felsgruppen, zwei flache Landevorfelder und verbundene Servicewege. Die Cutlass kommt über den echten Transportablauf.</p>'
    summary += image(captures['07_outpost_overview'], 'Neu · echte GM01 nach normalem Aussteigen und GO · 1920×1080 · Vulkan')
    summary += image(captures['08_eastern_supply'], 'Neu dazu · östlicher Versorgungsbereich mit Zufahrt und Felszügen')
    summary += '<details><summary>Die größere spielbare Fläche ansehen · 48×48 Hexfelder</summary>' + image(captures['09_expanded_map'], 'Echte größere Standardkarte · 2304 echte Hexfelder · keine bloße Hintergrundvergrößerung') + '</details>'
    summary += '<p>Die Aufnahme läuft mit echten Teams, Sichtbarkeitsmasken und Missionstimer. Keine Previewbürger, keine statischen Schiffe und kein nachbearbeitetes Ersatzbild.</p></article>'
    summary += '<article class="card wide"><h2>Vorher</h2>' + image(before, 'Vorher · UI R4 mit Frontier-Farbprofil, aber alter Stationskarte') + '</article>'
    summary += '<article class="card"><h2>Was ich mir dabei gedacht habe</h2><p>Der warme Felsrahmen und die hellen Module übernehmen die vorhandene Grafikfamilie. Das westliche Vorfeld gibt der Cutlass und dem Trupp Platz. Der Hof verbindet Einstieg, Hallenfront und Ziel; niedrige Kisten und Felsen bieten erkennbare Deckung. Die kleine östliche Frachtterrasse erhält den vorhandenen Höhen- und Rampenweg.</p><p>Die Gebäude sind geschlossene Außenhüllen. Innenräume und Gebäudeeintritt werden hier nicht versprochen.</p></article></div></section>'
    playtest = '<section id="playtest" class="tab-panel"><div class="grid"><article class="card full"><h2>Landung und Bedienung</h2>'
    playtest += image(captures['04_lz_approach'], 'Cutlass im echten Anflug auf die gewählte Landezone')
    playtest += image(views['1280x720']['06_go_movement'], 'Kompaktes UI auf der neu gebauten Standardkarte · echte 1280×720')
    playtest += '</article><article class="card wide"><h2>Geprüft</h2><p>24 gezielte Engine-Gates ohne Script- oder Leakfehler: Kartenfakten, breite A*/HPA-Routen, echte Spawnabstände, Save/Load, Renderer-Lebenszyklus, Editor-Schutz, Gegner und bestehende Hex-/Sichtbarkeitswege. Dazu zwei normale zeitgesteuerte Startläufe mit isolierten Testprofilen bei 1920×1080 und 1280×720.</p><p>Der ältere Zieleroberungs-Verifier nutzt beschleunigte Simulationsschritte. Er ist ein zusätzlicher Logikcheck; die gezeigte Landung und das Aussteigen laufen in normaler Zeit.</p><p><a href="../qa/gm01_frontier_20261102/README.md">Nachweise, Befehle und Grenzen</a></p></article><article class="card"><h2>Dein Playtest</h2><label class="checkline"><input type="checkbox" data-export-key="playtest.style"> Grafikstil passt</label><label class="checkline"><input type="checkbox" data-export-key="playtest.paths"> Laufwege gut erkennbar</label><label class="checkline"><input type="checkbox" data-export-key="playtest.hex"> Hexfelder gut erkennbar</label><label class="checkline"><input type="checkbox" data-export-key="playtest.landing"> Landezone gut nutzbar</label><textarea data-export-key="playtest.observation" placeholder="Was soll in der nächsten Runde anders werden?"></textarea></article></div></section>'
    decisions = '<section id="decisions" class="tab-panel"><div class="grid"><article class="card wide"><h2>Feste Komposition und klare Daten</h2><p>Auf deine weiteren Wünsche wächst die spielbare Karte auf 48×48 echte Hexfelder, ungefähr 48×41 Meter in der Spielebene. Navigation und Deckung verwenden sechs Nachbarn; das Raster ist dezent sichtbar. Die sichtbaren Festkörperhüllen werden konservativ in SOLID_COUNT gespeicherte Hinderniszellen übersetzt; COVER_COUNT begehbare Nachbarzellen erhalten passende Deckungswerte. Das ist die vorhandene Raster-Navigation, keine behauptete genaue Mesh- oder Physiknavigation. Szenario, acht Gegner, Taktiken, Zielradius und Zeitlimit bleiben unverändert.</p><p>Die Grafik liest diese Fakten. Im Karteneditor ist dieses Ensemble bewusst vor freiem Bemalen, Löschen und Verschieben geschützt; Ansicht und unveränderter Save/Load sind möglich. Eine freie Platzierungsbearbeitung wäre eine eigene spätere Aufgabe.</p><p>Das frühere dunkle Quadrat war die alte Sichtmaske über dem größeren Sandhintergrund. Ein temporärer schwarzer Schutzkasten erzeugte beim Neuaufbau das Aufblitzen. Bekanntes Gelände bekommt diesen Kasten jetzt nicht mehr; unbekanntes Gelände bleibt geschützt. Die Masken folgen echten Hexflächen. Es verbleiben merkliche UI-/Transport-Zeitspitzen; eine insgesamt flüssige Performance ist noch nicht abgenommen. Der gezielte CPU-Vergleich für acht Radiusabfragen sank im Median von 20,8 auf 2,4 ms (32 warme Messpaare), ohne Ergebnisänderung. Das ist kein Gesamt-FPS-Nachweis. Vollständiger Kampagnen-, Balance-, Mehrspieler- und Langzeittest sowie Main-Integration sind nicht Teil dieser Runde.</p></article><article class="card"><h2>Nächste Richtung</h2><div data-choice-group="review.direction" class="button-row"><button type="button" class="choice active" data-choice-value="keep">Basis behalten</button><button type="button" class="choice" data-choice-value="polish">Grafik verfeinern</button><button type="button" class="choice" data-choice-value="layout">Anordnung ändern</button></div><label>Schwerpunkt<select data-export-key="review.focus"><option value="style">Stil und Gelände</option><option value="play">Spielbarkeit</option><option value="ui">UI auf neuer Karte</option><option value="performance">Tempo und Reaktion</option></select></label><div contenteditable="true" data-note-key="review.notes" data-placeholder="Deine Anmerkungen …"></div></article></div></section>'
    content = (summary + playtest + decisions).replace('SOLID_COUNT', str(solid_count)).replace('COVER_COUNT', str(cover_count))
    start = template.index('    <section id="overview"')
    end = template.index('  </main>', start)
    result = template[:start] + content + '\n' + template[end:]
    result = result.replace('Workbench Report Template', 'GM01 · Neuer Frontier-Außenposten')
    result = result.replace('template_workbench', 'gm01_frontier_20261102')
    result = result.replace('Kurze Beschreibung des Reports. Diese Vorlage ist fuer Playtests, Entscheidungen und kontrollierte Arbeitsstaende gedacht.', 'Standardkarte mit den integrierten Frontier-Grafiken neu gebaut · native Spielaufnahmen · 02.11.2026')
    result = result.replace('Task: TASK_000', 'Task: GM01 Frontier').replace('Stand: Entwurf', 'Stand: lokal geprüft')
    result = result.replace('</style>', 'figure{margin:16px 0}img{display:block;width:100%;height:auto;border:1px solid var(--line);border-radius:6px}figcaption{font-size:13px;color:var(--muted);margin-top:7px}.card p{max-width:100ch}\n</style>')
    result = result.replace('<footer class="toolbar">', '<!-- Abgeleitet von docs/reports/_html_workbench_template.html; Export enthält nur Arbeitsnotizen. -->\n<footer class="toolbar">')
    REPORT.write_text(result, encoding='utf-8', newline='\n')
    print(REPORT)


if __name__ == '__main__':
    main()
