"""Build a standalone mobile workbench from the repository's export template."""
import html
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
QA = Path(__file__).resolve().parent
REPORT = ROOT / 'docs/reports/SPIELREVIEW_2026_11_12.html'

def esc(value):
    return html.escape(str(value), quote=True)

def collect():
    reports = []
    for folder in ['broad', 'followup', 'campaign', 'final', 'multicraft/verified', 'campaign-verified']:
        reports.extend((QA / folder).glob('*/metadata/report.json'))
    final = {}
    for path in sorted(reports, key=lambda p: p.stat().st_mtime):
        data = json.loads(path.read_text(encoding='utf-8'))
        for check in data['checks']:
            relocated = dict(check)
            # Reports retain original execution paths; render their copied logs
            # relative to this checkout without rewriting historical evidence.
            relocated['log'] = str(ROOT / Path(check['log']).relative_to(Path(data['project'])))
            final[check['name']] = dict(relocated, report=str(path.relative_to(ROOT)))
    return final

checks = collect()
good = sum(bool(item['passed']) for item in checks.values())
hex_path = ROOT / 'docs/qa/hex_runtime_followup_20261113/summary.json'
hex_data = json.loads(hex_path.read_text(encoding='utf-8')) if hex_path.exists() else None
hex_section = ''
main_path = ROOT / 'docs/qa/main_hex_review_20261113/summary.json'
main_data = json.loads(main_path.read_text(encoding='utf-8')) if main_path.exists() else None
main_section = ''
import_path = ROOT / 'docs/qa/editor_import_font_20261113/summary.json'
import_data = json.loads(import_path.read_text(encoding='utf-8')) if import_path.exists() else None
import_section = ''
perf_path = ROOT / 'docs/qa/performance_review_20261113/summary.json'
perf_data = json.loads(perf_path.read_text(encoding='utf-8')) if perf_path.exists() else None
perf_section = ''
if perf_data:
    perf_section = '''<article class="card full"><div class="eyebrow">PERFORMANCE-REVIEW · 13. NOVEMBER 2026</div><h2>Drei gemessene CPU-Probleme behoben</h2><p><strong>177 Regressionen ohne Fehler.</strong> Simulation/Hexsicht, Netzwerkverteilung und Begegnungsfenster geprüft. Qualität, Karten, Akteure und Spielregeln bleiben erhalten.</p><ul><li><strong>Hexsicht: 4,330 → 2,591 ms (−40 %).</strong> 64 gerichtete Paare mit vier Lesern pro Tick. Bisher fehlte der angebotene Cacheanschluss; Terrainantworten werden jetzt sicher innerhalb eines Ticks geteilt. Blickwinkel, Reichweite, Höhe, Zell- und Terrainänderungen bleiben korrekt.</li><li><strong>Snapshotpacken: 0,936 → 0,313 ms (−67 %).</strong> Drei Empfänger desselben Teams lösen nur noch einen Packvorgang aus. Vergleich mit 96 Units für Serialisierung/ZSTD; RPC-Zeit ist ausgeschlossen. Tatsächliche drei ENet-Clients prüfen Teamtrennung, gesperrte Empfänger und zuverlässige Zustandsmeldungen.</li><li><strong>Begegnungsfenster: 12,428 → 0,013 ms im verborgenen Zustand.</strong> Je 20 Leseaufrufe an einer echten kleinen Startkampagne. Sichtbar: 11,858 → 0,031 ms. Das Fenster liest nur noch seinen Encounterzustand statt der vollständigen Kampagne; Phasen, Buttons und Commands bleiben erhalten.</li></ul><p>Alle Angaben sind <strong>Mediane aus je 30 lokalen CPU-Samples</strong> nach Warmup. Gemessen auf Ryzen 7 7800X3D, Godot 4.6.2, Windows, Headless. Diese Verbesserungen einzelner Pfade sind keine Gesamtspiel-FPS- oder GPU-Zusage. Für den Begegnungsread entspricht die Einsparung etwa 0,6 ms pro Poll in der Startkampagne.</p><p>Zusätzlich bestanden: 600 Ticks Legacy-Kampf mit identischem Ergebnis, Frontier-LOS/FoW sowie vorhandene echte Hex-/ENet-/Checkpointprüfungen. Quellen und echte Spielerprofile bleiben unverändert. Frühe Fehler in Testfixtures sind getrennt von den bestätigten roten Produktrepros dokumentiert.</p><p><strong>Weiter offen:</strong> Personensnapshots in der Basisvisualisierung als ungemessener Kandidat, native GPU-/Framezeiten, große Kartenlast, Streaming, Autosave-I/O, Langzeit-Speicher und Internetlatenz. Keine neue EXE.</p><p><a href="../qa/performance_review_20261113/README.md">Performancebericht und genaue Prüfgrenzen</a> · <a href="../qa/performance_review_20261113/summary.json">Messwerte und Testindex</a></p></article>'''
if import_data:
    import_section = '''<article class="card full"><div class="eyebrow">EDITOR-NACHPRÜFUNG · 13. NOVEMBER 2026</div><h2>Frischer Gesamtimport läuft durch</h2><p>Eine vollständige Quellkopie von Main <strong>6bdc3b5ef</strong> wurde mit leerem Cache und allen aktivierten Plugins importiert: <strong>Exit 0, 358 Sekunden, 21.074 erzeugte Importdateien</strong>. Alle 33.838 Originalquellen blieben unverändert; es wurde kein vorhandener Cache übernommen.</p><p><strong>Drei isolierte Fontproben bestanden.</strong> TTF und OTF werden geladen und zur Textmessung verwendet. Aus dem frisch erzeugten Gesamtcache wurden anschließend beide Fonts und das echte Hauptmenü erfolgreich geladen und das Menü instanziiert. Der Runtime-Profilguard und der Vergleich des echten Spielerprofils bestehen.</p><p>Der frühere Abbruch ist durch Windows als nativer Godot-Zugriffsfehler bestätigt. Er ist in diesen Proben <strong>nicht reproduziert</strong>; ein behobener sporadischer Absturz wird deshalb nicht behauptet. Fonts, Plugins und Engine wurden nicht auf Verdacht geändert. Beim Editorende bleibt eine Diagnose zu einem unbeanspruchten StringName; keine Script-/Enginefehler oder ObjectDB-Leakmeldung im neuen Import.</p><p>Der erste Gesamtimport setzt ein privates APPDATA, enthält aber noch keinen Vorher/Nachher-Vergleich des echten Profils. Der anschließende Runtimecheck besitzt diesen Vergleich und prüft den tatsächlichen user://-Pfad. Die neuen Runner sichern außerdem Zeitlimits samt Launcher-Kindprozess ab; ein echter Timeouttest besteht.</p><p><a href="../qa/editor_import_font_20261113/README.md">Diagnose, Rohlogs und genaue Prüfgrenzen</a></p></article>'''
if main_data:
    main_rows = ''.join('<li>' + esc(item['name']) + ': <strong>' + str(item['assertions']) + '/0</strong></li>' for item in main_data['checks'])
    main_section = f'''<article class="card full"><div class="eyebrow">MAININTEGRATION · 13. NOVEMBER 2026</div><h2>Aktuellen Main-Verbund geprüft</h2><p>Die passenden Änderungen wurden gezielt auf Mainbasis <strong>{esc(main_data['base_main'])}</strong> übertragen. Neuere Kampagnen-, Missionssave-, Orbit- und Sternkartenfunktionen bleiben erhalten. Ganze ältere Kandidatenbäume wurden nicht gemergt.</p><ul>{main_rows}</ul><p><strong>207 Assertions ohne Fehler</strong>, alle Quellen-/Profil-/Canaryguards grün. Der echte Missionslauf prüft Save, Fortsetzen, Heimkehr und Chipupload.</p><p>Eine frische rote Peerprüfung hat einen fehlenden Driveranschluss im alten Main aufgedeckt: Trotz aktuellem Hexfacing blieb ein rückwärtiger Gegner sichtbar. Der vorhandene Hex-Sichtadapter ist nun eng angebunden; Legacy-Sicht bleibt erhalten.</p><p>Die Save-UI unterscheidet echte Kampagnensaves von reinen Nichtkampagnen-Szenenbookmarks. Die früher pauschale Beschriftung wurde dafür an die aktuellen Mainowner angepasst.</p><p>Der vollständige Editorimport endete beim Fontreimport mit Exit1 ohne weitere Diagnose. Für die bestandenen tatsächlichen Runtimechecks wurden vorhandene reine Importcachedateien aus dem unveränderten Mainressourcenstand verwendet. Kein sauberer frischer Gesamtimport oder EXE-/GPU-Nachweis.</p><p><a href="../qa/main_hex_review_20261113/README.md">Frische Main-Evidenz, Portumfang und Grenzen</a></p></article>'''
if main_data and import_data:
    main_section = main_section.replace(
        'Der vollständige Editorimport endete beim Fontreimport mit Exit1 ohne weitere Diagnose.',
        'Bei der damaligen Mainintegration endete der Editorimport beim Fontreimport mit Exit1. Die neue Diagnose und der erfolgreiche frische Nachimport stehen oben.')
    main_section = main_section.replace(
        'Kein sauberer frischer Gesamtimport oder EXE-/GPU-Nachweis.',
        'Dieser damalige Runtimeverbund allein war kein frischer Importnachweis. EXE-/GPU-Nachweise bleiben offen.')
if hex_data:
    hex_rows = ''.join('<li>' + esc(item['name']) + ': ' + esc(item.get('result', 'noch offen')) + '</li>' for item in hex_data.get('checks', []))
    hex_section = f'''<article class="card full"><div class="eyebrow">FORTSETZUNG · 13. NOVEMBER 2026</div><h2>Hex: tatsächlichen Kandidaten weitergeführt</h2>
    <p>Der aktuelle Abgleich hat den getrennten Karten-Kandidaten <strong>1b924b640</strong> gefunden. Dort sind AP0–AP8 bereits implementiert und begrenzt geprüft. Der ursprüngliche Reviewbranch enthielt diese spätere Integration nicht. Die alte Aussage „nur geplant“ gilt daher nicht für diesen Kandidaten.</p>
    <p><strong>Neuer Anschluss:</strong> echter lokaler ENet-Transport mit opt-in Hexzustand, Kontext-/Sichtgrenzen und zentraler Würfelfolge einschließlich Rootcheckpoint-Restore. Keine erneute Implementierung bereits fertiger Planpakete.</p>
    <p><strong>Gefundener Produktfehler behoben:</strong> Gültige Bewegungsbefehle tragen eine Trupp-ID. Der Bewegungs-Savecodec konnte dieses Feld bisher nicht speichern. Jetzt bleibt <code>fireteam_id</code> als geprüfter String beim vollständigen Root-JSON-Roundtrip erhalten; falsche Typen und unbekannte Felder werden weiterhin abgewiesen.</p>
    <p>Stand dieses Anschlusses: <strong>{esc(hex_data['status'])}</strong></p><ul>{hex_rows}</ul>
    <p>Historische AP6–8-Belege: {esc(hex_data['historical_ap678'])}. Sie werden hier nicht als erneut ausgeführte gemeinsame Suite ausgegeben. Die früheren 26 Reviewchecks unten gehören ebenfalls zu ihrer alten Quellbasis.</p>
    <p>Große A/B/C-/GPU-/FPS-Abnahme, Internet/Latenz/Paketverlust und Produktionskartenaktivierung bleiben offen. Der begrenzte AP9-Netzanteil ist keine vollständige AP9-Freigabe. Die bestehende Orbitalbegegnung bleibt ein eigenes vereinfachtes Modell; es wurden keine neuen Würfel- oder Rüstungsregeln erfunden.</p>
    <p>Die neue Probe verwendet sechs Felder, Capability-NPCs und manuelle Rootticks. Der Restore erfolgt bei unverändertem Simulationstick nach reinen RNG-Lesezugriffen. Er belegt exakte Zufallsfortsetzung, keine Wiederherstellung einer laufenden Mehrspielerpartie mit Tickrücksprung oder Rejoin.</p>
    <p class="source">Kandidat: {esc(hex_data['candidate_branch'])} · Commit {esc(hex_data.get('candidate_commit', 'noch nicht gespeichert'))} · Ausgang {esc(hex_data['candidate_base'])}</p>
    <p><a href="../qa/hex_runtime_followup_20261113/README.md">Neue Hex-Evidenz und Commitgrenzen</a></p></article>'''
(QA / 'final_checks.json').write_text(json.dumps({
    'basis': 'cfddc129b', 'scope': 'bounded_headless_game_review',
    'selected': len(checks), 'passed': good, 'failed': len(checks) - good,
    'checks': checks,
}, ensure_ascii=False, indent=2), encoding='utf-8')
rows = ''
for name, item in checks.items():
    log_path = Path(item['log'])
    text = log_path.read_text(encoding='utf-8', errors='replace') if log_path.exists() else ''
    summaries = [line for line in text.splitlines() if any(token in line for token in [
        'RESULTS:', 'RESULTS passed=', 'GAME_REVIEW_', 'failures=', 'CHAIN:',
        'Prepared Skirmish', 'HPA_PRUNING_TOTALS', 'FRONTIER_HEX_MOVEMENT',
        'MULTICRAFT_REVIEW', 'BASE_PERSONNEL_', 'PREPARATION_CONTINUE',
    ])]
    summary = summaries[-1] if summaries else 'Siehe vollständiges Log und Runnerreport.'
    if len(summary) > 180:
        summary = summary[:177] + '…'
    relative_log = '../../' + log_path.relative_to(ROOT).as_posix()
    badge = 'bestanden' if item['passed'] else 'offen / fehlgeschlagen'
    rows += f'<article class="result"><div class="result-head"><strong>{esc(name)}</strong><span class="badge {"ok" if item["passed"] else "warn"}">{badge}</span></div><p>{esc(summary)}</p><a href="{esc(relative_log)}">Testlog öffnen</a><small>{item["elapsed"]:.2f} s · Exit {item["exit_code"]} · {item["error_count"]} Enginefehler</small></article>'

template = (ROOT / 'docs/reports/_html_workbench_template.html').read_text(encoding='utf-8')
style = template.split('<style>', 1)[1].split('</style>', 1)[0]
script = template.split('<script>', 1)[1].split('</script>', 1)[0]
footer = template.split('  <footer', 1)[1].split('  <script>', 1)[0]
footer = '<footer' + footer
body = f'''
<header><div class="eyebrow">STERNENBÜRGERCHEN · {'13. NOVEMBER 2026' if hex_data else '12. NOVEMBER 2026'}</div>
<h1>Spielreview &amp;<br>Fehlerbehebung</h1>
<p class="lead">{'Hex-Fortsetzung und ursprünglicher Spielreview. Neue und frühere Nachweise bleiben getrennt.' if hex_data else 'Drei konkrete Probleme korrigiert. Breite technische Prüfung ohne Übernahme von Maus, Tastatur oder Spielfenstern.'}</p>
<div class="meta-row">{'<span class="pill good">Hex: 22 neu + 30 Nachbar grün</span>' if hex_data and hex_data.get('passed') else ''}<span class="pill">Review vom 12.11.: {good}/{len(checks)} bestanden</span><span class="pill">Godot 4.6.2</span><span class="pill">Headless</span></div>
<p>Ursprüngliche Reviewbasis cfddc129b · {'Mainintegration 6bdc3b5ef · Nachprüfung siehe unten.' if main_data else 'neue Hexbasis siehe Fortsetzung · keine Mainintegration.'}</p></header>
<main>
<nav class="tabbar" aria-label="Berichtbereiche">
<button class="tab active" data-tab-target="overview">Ergebnis</button><button class="tab" data-tab-target="coverage">Spielsysteme</button><button class="tab" data-tab-target="evidence">Tests</button><button class="tab" data-tab-target="decisions">Notizen</button>
</nav>
<section id="overview" class="tab-panel active">
<div class="grid">
{perf_section}
{import_section}
{main_section}
{hex_section}
<article class="card full"><h2>Was jetzt korrigiert ist</h2>
<div class="finding"><span class="number">01</span><div><h3>Aussteigen am richtigen Schiff</h3><p>Das Personenpanel drängte jeder Aktion das erste Schiff auf. Beim Aussteigen darf nun der Runtime-Owner das tatsächliche Schiff der Person bestimmen. Eine ausdrücklich übergebene Schiff-ID bleibt erhalten; eine falsche wird weiterhin abgelehnt.</p><p class="source">explorable_homebase.gd · _personnel_action</p></div></div>
<div class="finding"><span class="number">02</span><div><h3>Boarding nach Continue konsistent</h3><p>Der Restore berücksichtigt alle vorhandenen Schiffe und vollständigen Teams. Personenanwesenheit und Trupp-Payload stimmen nach dem Laden zusammen. Teilweise oder über verschiedene Schiffe verteilte Teams erzeugen keinen erfundenen Abflug-Payload.</p><p class="source">meta_layer_flow.gd · _seed_singleplayer_bootstrap_homebase_payload</p></div></div>
<div class="finding"><span class="number">03</span><div><h3>Szenenneustart wird ehrlich benannt</h3><p>„Mission speichern/laden“ sicherte nur einen Szenenpfad. Die Oberfläche sagt jetzt „Szenenstart merken“ und „Gemerkte Szene neu starten“ und erklärt, dass Fortschritt nicht gespeichert wird. Im Hauptmenü kann kein laufender Einsatz vorgetäuscht werden. Der echte Kampagnen-Checkpoint bleibt davon getrennt.</p><p class="source">global_escape_menu.gd · main_menu_screen.gd</p></div></div>
</article>
<article class="card full warning"><h2>Präzisierung zur ersten Review</h2><p>Die natürliche zweite Kampagnen-Buccaneer ist ein Fighter und darf derzeit keine Trupp-Payload transportieren. Die frühere Behauptung eines zuvor möglichen Truppabflugs war zu weitgehend. Die Regression prüft den allgemeinen Mehrschiff-Restore mit einem ausdrücklich zulässigen zweiten Dropship und erhält die Fighter-Sperre.</p></article>
<article class="card full"><h2>Was dieser Durchlauf belegt</h2><p>Konkrete Fehler wurden vor der Reparatur mit roten Verhaltenstests nachgewiesen. Die finalen Prüfungen verwenden isolierte Spielerprofile. Ein unabhängiger Agent hat die Produktpatches und Tests gegengeprüft. Vorhandenes fremdes Grafik-WIP wurde erhalten.</p><p>Kein vollständiger menschlicher Durchlauf, keine GPU-/Stil-/FPS-Abnahme und keine Internet-Multiplayerfreigabe. Einzelne alte Testvorbedingungen waren nach dem Flotten-/Inventarumbau veraltet; deren Korrekturen werden getrennt von Produktfixes dokumentiert.</p></article>
</div></section>
<section id="coverage" class="tab-panel"><div class="grid">
<article class="card full"><h2>Kampf, Würfeln und Hexfelder</h2><p><strong>Aktiv:</strong> MissionCombatLoopDriver entscheidet auf der Authority, CombatFireDecisionResolver erzeugt Schadenseffekte und SimulationRoot löst sie über DamageModel auf. Ein zentral gesetzter Zufallsstartwert liefert reproduzierbare Treffer. Der aktuelle „Wurf“ ist ein Wert zwischen 0 und 1, kein nachgewiesenes D6-System.</p><p>Hexlinien, Hexnachbarn und physische Distanzen sind tatsächlich an Sicht und Bewegung angebunden. Der Schablonenpfad ist eine AreaOrder-Ziel-/Stellungsschablone. Flächen-/Kegel-/Abweichungswürfe sind keine durch diesen Auftrag ergänzten Kampfregeln.</p><p><strong>Aktueller Kandidatenstand:</strong> Logische Hexsicht/Erkennung und zeitliche Feld-/Kantenreservierungen sind inzwischen im getrennten AP0–AP8-Kandidaten verbunden. Das ist ausdrücklich keine Aktivierung auf allen Produktionskarten. Die neue Fortsetzung prüft den begrenzten echten Peeranschluss und die zentralen Würfel-/Restoregrenzen.</p></article>
<article class="card full"><h2>Konkurrierende Kampfsysteme?</h2><p>Im untersuchten aktiven Bodenmissionspfad wurde kein zweiter unabhängiger Schadensowner nachgewiesen. RuntimeLeader/FTLTask bleiben Kompatibilitätspfade. Produktive Missionslogik liegt historisch teilweise unter scripts/tests; der Ordnername allein beweist keinen toten Code.</p><p><strong>Eine wichtige Ausnahme:</strong> Die orbitale Cutlass-/Buccaneer-Begegnung nutzt einen separaten CampaignSpaceEncounter-Owner mit festem Schaden pro Sekunde und eigenen Hüllenwerten. Dort wird nicht gewürfelt und keine Hexschablone benutzt. Dieser begrenzte Kampagnenpfad konkurriert nicht um Boden-Unit-Schaden, verwendet aber andere Kampfregeln. Ein spielweit einheitliches Würfel-/Schablonensystem ist daher ausdrücklich noch nicht erreicht. Eine Vereinheitlichung braucht einen eigenen Design-/Migrationstask.</p><p>Overwatch enthält auffällige Nebenpfade, sein regulärer Readiness-Producer liefert derzeit jedoch false. Deshalb kein bestätigter aktiver Fehler und kein blindes Entfernen. Vor einer Reaktivierung Feuerregeln, Waffenkennung und Fire-Event-Verknüpfung absichern.</p></article>
<article class="card full"><h2>Multiplayer</h2><p>SP-/Host-Parität, Fremdkommandos, Snapshotticks und taktische Replikation wurden geprüft. Zusätzlich verbindet eine echte lokale ENet-Verbindung zwei Multiplayer-Subtrees: produktive Snapshot-Chunk-RPCs übertragen acht Hostticks und Lebenspunkte. Clienttickversuche verursachen keinen eigenen Schadenscommit und verbrauchen keine Kampfzufallswerte.</p><p>Das ist echte lokale Netzwerkübertragung mit kleinen Unit-Fixtures; keine vollständige Lobby-/Missionspartie zwischen zwei Rechnern. Latenz, Paketverlust, NAT und Internet bleiben offen.</p></article>
<article class="card full"><h2>Pause und Bedienung</h2><p>ESC und Einstellungen lassen die Physik weiterlaufen. Das entspricht dem Projektbrief „Echtzeit ohne Pause“. Der Test öffnet die echten Controls per API und zählt weiterlaufende Physikticks; es werden keine OS-Tasten gesendet.</p><p><strong>Vorschläge:</strong> Während Kampf und Reisen die laufende Simulation im ESC-Menü auffälliger kennzeichnen; für jedes Schiff dieselbe Auswahl-/Abflug-/Boarding-Rückmeldung verwenden; fehlende Gegenstände mit Bestand und Bezugsquelle erklären.</p></article>
<article class="card full"><h2>Grafik und UI</h2><p>Grafikeinstieg, aktives Hexprofil, Kartenressourcen und UI-Verträge sind technisch geprüft. Headless liefert keine Aussage über Clipping, Materialwirkung, Schatten oder native Lesbarkeit. Die bereits vor diesem Auftrag vorhandenen Terrain-/Shaderänderungen sind keine abgenommenen Änderungen dieses Durchlaufs.</p><p><strong>Vorschläge:</strong> Native Sichtprüfung auf 1280×720, FullHD und Ultrawide; Kontrast von Auswahl/Deckung/Schablone vergleichen; lange deutsche Beschriftungen, kleine Inventarflächen und Mehrschiffansichten gezielt prüfen.</p></article>
<article class="card full"><h2>Performance</h2><p>Dirty-Flags, Caches und getaktete Aktualisierung sind in den geprüften Hotpaths vorhanden. Die Hex-Bewegungsfixture prüft gleiche Nachbarschrittzeiten in sechs Richtungen. Der HPA-Verifier vergleicht tatsächlich ausgewertete Wege und prüft weniger lokale A*-Aufrufe. Daraus folgt kein pauschaler FPS-Gewinn.</p><p><strong>Nächster Messpunkt:</strong> Vollständige Checkpoint-Aufbereitung mit JSON-Signatur alle 250 ms bei großen Rostern und mehreren Schiffen profilieren. CPU-Zeit, Allokationen und Schreibvorgänge getrennt messen, bevor eine zusätzliche Cacheebene eingeführt wird.</p></article>
</div></section>
<section id="evidence" class="tab-panel"><div class="grid"><article class="card full"><h2>Ursprünglicher Review · 12.11.2026</h2><p>Diese Ergebnisse gehören zu ihrer damaligen Reviewbasis; sie sind kein neuer gemeinsamer Lauf auf dem späteren Hex-Kandidaten. Dessen neue Nachweise stehen in der Fortsetzung auf der Ergebnisseite.</p><p>Erfolgsmarker, Exitcode, Zeitlimit sowie Script-/Runtime-/Leakfehler werden gemeinsam geprüft. Frühere Fehlversuche und rote Repros bleiben in den Rohlogs erhalten. Reine falsch gewählte Runner-Marker wurden korrigiert; Produktassertions wurden dafür nicht abgeschwächt.</p><div class="results">{rows}</div></article>
<article class="card full"><h2>Prüfgrenzen und Rohdaten</h2><p>Der Editor-Import beendet sich mit Exit 0, meldet aber beim Beenden nach dem Plugin-Unload einen ObjectDB-Leak. Dessen Ursache wurde nicht eingegrenzt. Er ist deshalb kein sauberer Import-PASS; diese Diagnose ist vom Ergebnis der Runtimeprüfungen getrennt.</p><p><a href="../qa/game_review_20261112/README.md">Evidenzindex</a> · <a href="../qa/game_review_20261112/combat_audit.md">Combat-Quellaudit</a> · <a href="../tasks/GAME_REVIEW_FIXES_2026_11_12.md">Task und Scope</a></p><p>Alle Inhalte dieses Berichts sind eingebettet. Die vertiefenden Loglinks benötigen zusätzlich den Projektordner.</p></article></div></section>
<section id="decisions" class="tab-panel"><div class="grid"><article class="card full"><h2>Entscheidungen und Notizen</h2><p>Diese Felder sind persönliche Reviewnotizen. Sie verändern keinen Spielzustand.</p>
<label>Priorität für den nächsten Durchlauf<select data-export-key="review.next_priority"><option value="hex">Hexsicht / Feldreservierungen nach bestehendem Plan</option><option value="ui">Native UI- und Grafikprüfung</option><option value="network">Mehrrechner-Netzwerktests</option><option value="checkpoint">Checkpoint-Profiling</option></select></label>
<label class="checkline"><input type="checkbox" data-export-key="review.read"><span>Bericht gelesen</span></label>
<label>Eigener Prüfstatus<select data-export-key="review.playtest_status"><option value="pending">Noch nicht selbst gespielt</option><option value="checked">Selbst geprüft</option><option value="issue">Rückfrage / neuer Fehler</option></select></label>
<label>Kommentare<textarea data-export-key="review.comment" placeholder="Was fällt dir auf? Welcher Ablauf soll als Nächstes geprüft werden?"></textarea></label>
<div contenteditable="true" data-note-key="review.notes" data-placeholder="Weitere Notizen …" aria-label="Weitere Notizen"></div>
</article></div></section>
</main>
'''
extra = '''
:root{font-family:system-ui,-apple-system,"Segoe UI",sans-serif;--accent:#fac77a}
html{overflow-wrap:anywhere}body{font-size:16px}header{padding-top:36px}main{max-width:980px}
.eyebrow{font-size:12px;letter-spacing:.12em;color:var(--cyan);margin-bottom:16px}
.lead{max-width:680px;font-size:18px;line-height:1.55}h1{font-size:clamp(32px,7vw,60px)}
.card{padding:22px;border-radius:14px}.card h2{margin-bottom:12px}.card p{line-height:1.7}
.finding{display:flex;gap:16px;padding:22px 0;border-top:1px solid var(--line)}
.number{font-size:22px;color:var(--accent);font-weight:700;flex:0 0 30px;white-space:nowrap}.source,small{font-size:12px;color:var(--muted)}
.warning{border-color:#886945}.tabbar{position:sticky;top:0;z-index:5;background:var(--bg);gap:4px;padding-top:6px}
.tab{flex:1;padding:12px 8px;min-height:48px}.results{display:grid;gap:10px}.result{padding:14px;background:#101a21;border-radius:8px}
.result-head{display:flex;justify-content:space-between;gap:8px;flex-wrap:wrap}.badge{font-size:12px;border:1px solid var(--line);border-radius:20px;padding:3px 9px}
.badge.ok{color:var(--green)}.badge.warn{color:var(--accent)}small{display:block;margin-top:8px}a{color:var(--cyan)}
label{display:block;margin-top:18px}button,input,select{min-height:44px}.toolbar{position:static;margin-top:12px}
textarea,select{max-width:100%}.toolbar textarea{flex-basis:100%;min-width:0}code{white-space:pre-wrap}
@media(max-width:480px){main{width:calc(100% - 24px)}header{padding:28px 16px 20px}.card{padding:17px}.tab{font-size:13px;padding:12px 5px}.finding{gap:10px}.pill{font-size:11px}.export-actions{width:100%}.export-actions button{flex:1}.toolbar{padding:16px}.result{padding:12px}}
'''
script += '''
document.querySelectorAll('.tab').forEach(button => button.addEventListener('click', () => {
  window.scrollTo(0, document.querySelector('main').offsetTop);
}));
'''
page = '<!doctype html><html lang="de"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>SternenBürgerchen · Spielreview 12.11.2026</title><style>' + style + extra + '</style></head><body data-report-id="spielreview_20261112" data-report-schema="sternenbuergerchen.html_workbench.v1">' + body + footer + '<script>' + script + '</script></body></html>'
if hex_data:
    page = page.replace('Spielreview 12.11.2026</title>', 'Spielreview / Hex-Fortsetzung 13.11.2026</title>')
if main_data:
    page = page.replace('Hex: 22 neu + 30 Nachbar grün', 'Main: 207 Assertions grün')
if perf_data:
    page = page.replace('Main: 207 Assertions grün', 'Performance: 177 Prüfungen grün')
REPORT.write_text('\n'.join(line.rstrip() for line in page.splitlines()) + '\n', encoding='utf-8')
print(json.dumps({'report': str(REPORT), 'checks': len(checks), 'passed': good}, ensure_ascii=False))
