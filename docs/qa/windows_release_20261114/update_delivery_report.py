"""Bounded update of the existing interactive report; preserve historical evidence."""
from pathlib import Path
import argparse, hashlib, json, re, shutil

parser = argparse.ArgumentParser()
parser.add_argument('--build')
parser.add_argument('--release-url')
args = parser.parse_args()
if args.build:
    assert re.fullmatch(r'[0-9a-f]{40}', args.build)
    assert args.release_url.startswith('https://github.com/0klabauta0-jpg/Sternenbuergerchen/releases/tag/')

root = Path(__file__).resolve().parents[3]
path = root / "docs/reports/SPIELREVIEW_2026_11_12.html"
html = path.read_bytes().decode("utf8")
start, end = "<!-- delivery-20261114:start -->", "<!-- delivery-20261114:end -->"
section = '''<article class="card full" id="windows-delivery"><div class="eyebrow">AUSLIEFERUNG · 14. NOVEMBER 2026</div>
<h2>Windows-Paket und öffentliche Spielanleitung</h2>
<p><a href="https://github.com/0klabauta0-jpg/Sternenbuergerchen/releases/tag/playtest-2026-11-14">Windows-Playtest auf GitHub</a> · <a href="https://sternenbuergerchen-spielanleitung.klabauta.chatgpt.site">Öffentliche Spielanleitung mit Trefferrechner</a></p>
<p>ZIP vollständig entpacken und SternenBuergerchen.exe starten. EXE, PCK und beide DLLs zusammenlassen. GitHub-Zugriff auf das private Repository erforderlich; die Spielanleitung ist öffentlich ohne Anmeldung.</p>
<p><strong>Ausgeliefert: a377c7346.</strong> Exportpipeline, Dateipaket, Prüfsummen und normaler Start der exportierten EXE im isolierten Headlessprofil bestanden. Der GitHub-Download hat dieselbe SHA256 wie die geprüfte ZIP. Kein nativer EXE-Sichttest oder vollständiger Kampagnensieg bestätigt.</p>
<p><strong>Anleitung:</strong> 68 lokale Prüfungen und 23 öffentliche Prüfungen bestanden. Erster Einsatz, Heimatbasis, Reise, Hex-/Höhenregeln, Waffen, Treffer und Schaden, Koop/PvP sowie Fehlersuche. Beispiele stimmen mit dem Bodenwaffenkatalog und der normalen Schussformel überein; Raumkampf bleibt getrennt erklärt.</p>
<details class="review-detail"><summary>Neues Kartenfeedback nach diesem Build</summary><p>Die nachfolgenden Wünsche sind ein separates Arbeitspaket und nicht in der oben verlinkten EXE enthalten: weniger weiße GM02-Karte; geschlossener Stationsgrundriss als Kreuz mit vier Räumen; saubere Böden und Türen; keine weißen Wüstenblumen; echte erhöhte Hexoberflächen auf großen Felsen; klarere Wege und passende Höhenvarianten; Handelssiedlung mit mindestens drei Gebäuden, ein bis zwei Pads und Frachtaufzug; örtlich gebundene Reparatur und Betankung.</p><p>Aktuelle Zuordnung: Die ersten beiden Nutzerbilder zeigen GM02 und Station64. Das dritte zeigt GM01 Frontier-Outpost; die Kampagnenkarte trade_outpost ist ein eigener Ort.</p><p>Stand dieser Veröffentlichung: Umsetzung und gezielte Prüfung laufen. Vorherbilder bestätigen die Bildprobleme. Noch keine Abnahme der neuen Variante.</p></details>
<label>EXE selbst gestartet<select data-export-key="delivery.exe"><option value="unchecked">Noch nicht geprüft</option><option value="pass">Start funktioniert</option><option value="fail">Startfehler</option></select></label>
<label>Beobachtung zur Auslieferung<textarea rows="2" data-export-key="delivery.note" placeholder="Build, Bildschirm und genaue Schritte …"></textarea></label></article>'''
image_dir = root / 'docs/reports/assets/map-services-20261114'
native = root / 'docs/qa/review_completion_20261113/map_services_accepted_native/da014e4eba514578be0d61542cc401aa/images'
images = [('Ground_Mission02_128x128.png', 'gm02_after.png', 'GM02: olivbrauner Boden, Schieferwege und warmer Beton statt weißer Gesamtfläche.'),
          ('station_outpost_64x64.png', 'station_after.png', 'Station: geschlossenes Kreuz, vier Räume und einzelne Türen. Seitliche Flächen sind Lager-/Reserveflächen.'),
          ('Ground_Mission01_32x32.png', 'gm01_after.png', 'GM01: erhöhte Hexkappen auf den großen Felsen; der braune Streifen wurde durch einen Geländeweg ersetzt.'),
          ('gm01_landing_mesa.png', 'mesa_after.png', 'Neue breite Mesa: vollständige Buccaneer-Standfläche geprüft; kleinere Kuppen passen nicht automatisch für jedes Schiff.'),
          ('trade_outpost_service_core.png', 'trade_after.png', 'Handelsort: drei Gebäude, zwei Pads und Frachtaufzug. Versorgung ist an Ort, angebotenen Dienst und eigenes Schiff gebunden.'),
          ('trade_outpost_local_hill.png', 'hill_after.png', 'Zusätzliche echte Hexhöhen am Handelsort; auch die Werkhofkarte enthält eine eigene Höhenvariante.')]
for src, dest, _ in images:
    shutil.copyfile(native / src, image_dir / dest)
manifest = {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(image_dir.glob('*.png'))}
(image_dir / 'SHA256.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf8')
gallery = '<details class="review-detail" open><summary>Kartenrevision: aktuelle Spielbilder</summary><div class="asset-gallery">'
for _, name, caption in images:
    gallery += f'<figure><a href="assets/map-services-20261114/{name}" target="_blank" rel="noopener"><img class="review-image" loading="lazy" src="assets/map-services-20261114/{name}" alt="{caption}"></a><figcaption>{caption}</figcaption></figure>'
gallery += '</div><p>Native Aufnahmen der tatsächlichen Variante; technische Prüfung bestanden, persönliche Gestaltungsgenehmigung noch offen.</p></details>'
gallery += '<details class="review-detail"><summary>Deine ursprünglichen Referenzbilder</summary><div class="asset-gallery">'
for name, label in [('user_gm02.png', 'Abgelehnte weiße Karte'), ('user_station.png', 'Stationsfeedback'), ('user_gm01.png', 'Felsen, Wege und Oberseitengrid')]:
    gallery += f'<figure><a href="assets/map-services-20261114/{name}" target="_blank" rel="noopener"><img class="review-image" loading="lazy" src="assets/map-services-20261114/{name}" alt="{label}"></a><figcaption>{label} · unverändertes Nutzerbild</figcaption></figure>'
gallery += '</div></details>'
detail_begin = section.index('<details class="review-detail">')
detail_end = section.index('</details>', detail_begin) + len('</details>')
section = section[:detail_begin] + '''<p><strong>Karten- und Servicerevision geprüft:</strong> 80 gezielte Runtimeprüfungen und 25 native Aufnahmeprüfungen bestanden. Zusätzlich geprüft: volle Schiffsstandfläche auf der Mesa, Höhenränder, Fracht in beide Richtungen samt Verkauf und Wiederherstellung, Reparatur des tatsächlichen Rumpfs sowie Abweisung fremder oder entfernter Schiffe. Keine weißen Blumen mehr auf den betroffenen Wüstenkarten.</p>''' + gallery + '''<label>Kartenvariante beurteilen<select data-export-key="delivery.maps"><option value="unchecked">Noch nicht beurteilt</option><option value="accept">Gestaltung passt</option><option value="revise">Weitere Änderung gewünscht</option></select></label>''' + section[detail_end:]
if args.build:
    section = section.replace('playtest-2026-11-14">Windows-Playtest auf GitHub', 'playtest-2026-11-14-r2">Windows-Playtest R2 auf GitHub')
    section = section.replace('Ausgeliefert: a377c7346.', 'Ausgeliefert: R2 · ' + args.build[:9] + '.')
    section = section.replace('Anleitung:</strong>', 'Anleitung für R2:</strong>')
    section += '<p>Das erste Paket a377c7346 bleibt als ältere Veröffentlichung erhalten.</p>'
else:
    section += '<p>Die erste EXE enthält diese neuen Kartenänderungen noch nicht. R2 wird nach dem Quellenabschluss separat gebaut.</p>'
section = section.replace('80 gezielte Runtimeprüfungen', '81 gezielte Runtimeprüfungen')
fragment = start + section + end
if start in html:
    begin, finish = html.index(start), html.index(end) + len(end)
    html = html[:begin] + fragment + html[finish:]
else:
    marker = '<section id="overview" class="tab-panel active">'
    assert html.count(marker) == 1
    html = html.replace(marker, marker + fragment, 1)
header_start, header_end = html.index("<header>"), html.index("</header>") + len("</header>")
html = html[:header_start] + '''<header><div class="eyebrow">STERNENBÜRGERCHEN · 14. NOVEMBER 2026</div>
<h1>EXE, Anleitung<br>&amp; Kartenrevision</h1>
<p class="lead">Das Windows-Playtestpaket ist auf GitHub; die Spielanleitung mit Trefferrechner ist öffentlich erreichbar. Die neuesten Karten- und Frachtwünsche folgen als eigene Revision. Das ausgelieferte Paket bleibt eindeutig seinem Quellstand zugeordnet.</p>
<div class="meta-row"><span class="pill good">EXE ausgeliefert</span><span class="pill good">Anleitung öffentlich</span><span class="pill">Godot 4.6.2</span><span class="pill warn">Neue Kartenrevision in Arbeit</span></div>
<p>Windows-Build a377c7346 · gezielte Paket- und Websiteprüfungen · vollständiger Kampagnensieg weiterhin unbestätigt.</p></header>''' + html[header_end:]
html = html.replace('Die neuesten Karten- und Frachtwünsche folgen als eigene Revision.', 'Die Karten-, Fracht- und Servicekorrekturen sind gezielt geprüft.')
html = html.replace('Neue Kartenrevision in Arbeit', 'Kartenrevision geprüft')
if args.build:
    html = html.replace('Windows-Build a377c7346 ·', 'Windows-Build R2 ' + args.build[:9] + ' ·')
path.write_bytes(html.encode("utf8"))
print("Delivery section updated; historical review retained.")
