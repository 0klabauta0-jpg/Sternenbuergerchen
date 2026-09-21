"""Build the local, self-contained visual acceptance report from real captures."""
from pathlib import Path
import base64
import html

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'output'
DOWNLOADS = Path.home() / 'Downloads'

def figure(path, caption):
    data = base64.b64encode(path.read_bytes()).decode('ascii')
    return f'<figure><a href="data:image/png;base64,{data}" target="_blank"><img loading="lazy" src="data:image/png;base64,{data}" alt="{html.escape(caption)}"></a><figcaption>{html.escape(caption)}</figcaption></figure>'

def pair(title, reference, actual, note):
    return f'<section><h2>{title}</h2><p>{note}</p><div class="pair">' + figure(reference, 'Deine Zielvorlage') + figure(OUT / actual, 'Echter Godot-Spielstand N7 · 21.09.2026') + '</div></section>'

def build():
    page = '''<!doctype html><html lang="de"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Sternenbürgerchen · N7 Referenzabgleich</title><style>
    :root{color-scheme:dark}*{box-sizing:border-box}body{margin:0;background:#091820;color:#eee8da;font:17px/1.65 system-ui,sans-serif}main{max-width:1500px;margin:auto;padding:32px 24px}h1{font-size:clamp(32px,5vw,60px);line-height:1.1}h2{color:#efae63}p{max-width:85ch}section{margin-top:50px;border-top:1px solid #34505b;padding-top:24px}.pair{display:grid;grid-template-columns:1fr 1fr;gap:16px}figure{margin:0;background:#142730;padding:8px;border:1px solid #34505b}img{width:100%;height:auto;display:block}figcaption{font-size:14px;padding:10px;color:#b5c7cc}a{color:#69d0c8}nav{display:flex;gap:18px;flex-wrap:wrap}.status{padding:20px;background:#193039;border-left:4px solid #f1a64e}li{margin:8px 0}table{border-collapse:collapse;width:100%}td,th{padding:12px;text-align:left;border-bottom:1px solid #34505b}@media(max-width:850px){.pair{grid-template-columns:1fr}main{padding:22px 14px}table{font-size:14px}}
    </style><main><p>ROSTGRENZE · ENTWICKLUNGSSTAND N7 · 21. SEPTEMBER 2026</p><h1>Zwei Teams.<br>Bis zu acht Commander je Team.</h1><nav><a href="#spiel">Spielumfang</a><a href="#grafik">Grafikvergleich</a><a href="#pruefung">Prüfung</a><a href="#offen">Nächster Ausbau</a><a href="index.html">Vollständiger Spielplan</a></nav>
    <div class="status"><strong>Implementiert und geprüft, mit klaren Grenzen.</strong><p>Koop innerhalb eines Teams und PvP zwischen zwei Teams können gleichzeitig stattfinden. 16 echte lokale Produktprozesse wurden über LAN und authentifizierte WebSockets verbunden. Der öffentliche Internetweg wurde zusätzlich mit zwei Prozessen geprüft. Ein Test mit zwei verschiedenen Haushalten steht noch aus.</p></div>
    <section id="spiel"><h2>Was du jetzt spielen kannst</h2><ul>
    <li><strong>Team-Lobby:</strong> Multiplayer → Team-Modus vor dem Hosten einschalten. Der Host verteilt bis zu 16 Menschen auf zwei Teams, wählt Heimatplaneten und startet die Partie. Ungleiche Teamgrößen sind möglich. Bei geöffneter Lobby bleibt die Simulation angehalten. Innerhalb eines Teams dürfen alle Crew und Schiff befehligen.</li>
    <li><strong>Vier Heimatwelten:</strong> Rostwelt, Frostmark, Schlacke und Grünschiefer. Eigene persistente Ressourcen und NPC-Zustände pro Planet, private Teamwirtschaft. Treffen Teams auf demselben Planeten zusammen, teilen sie dort Fundstellen und Gegner. Die Welten verwenden vorerst dieselben Kartenlayouts mit anderen Gelände-Paletten.</li>
    <li><strong>Bodenkampf gegen das andere Team:</strong> gleiche Karte und Ebene, Reichweite, Hindernisse, Rüstung, Schaden und Wiederkehr werden geprüft. Kein Schaden durch Befehle auf fremde Team-Inventare. Noch kein Kampf zwischen den beiden Spielerschiffen.</li>
    <li><strong>Bunker mit Ebenen:</strong> Ein Einsatzort mit getrennten Figurenpositionen oben und unten. Nur ausgewählte Personen fahren im Aufzug; Schiff und andere Crew bleiben zurück. Der Ebenenschalter ändert lokal die Ansicht und merkt sich den Kameraausschnitt. Kämpfe und Arbeiten laufen auf ihrer Ebene weiter.</li>
    <li><strong>Forschung:</strong> sichtbarer Baum mit Kanten, Kosten, Technik- und Werkbankanforderungen. Werkbank II ermöglicht Materialforschung, Legierungsherstellung und anschließend Medizinforschung mit effizienter Med-Ladungsherstellung. Echte Materialreservierung, Arbeitszeit, Freischaltungen und Speichern/Laden. Ein eigener Forschungsraum folgt später.</li>
    <li><strong>Spielerführung:</strong> Auftrags-PC bei neuem Auftrag und Lager für die Blackbox-Abgabe werden markiert. Sanfte Bewegung, statische Hilfe oder aus sind lokal wählbar.</li>
    <li><strong>Erste KI:</strong> kann regelgebundene Basisaufgaben wie Reparatur und Herstellung mit vorhandenen Materialien erledigen. Noch keine selbständig reisende oder taktisch angreifende Fraktion.</li></ul></section>
    <section id="grafik"><h2>Grafik: Ziel und tatsächlicher Stand</h2><p>Die unteren Bilder sind echte native Godot-Aufnahmen. Für Übersichtsaufnahmen wurden Kamera und Testzustand gezielt gesetzt; sie belegen das Rendering, nicht den gesamten Spielablauf. Die Systemkartenaufnahme verwendet einen Team-Testzustand. Verbindungs- und Spielablaufnachweise sind getrennt darunter aufgeführt.</p><p>Neu sind sieben eigene Blender-Requisiten, eingerichtete Räume, zusätzliche Felslagen und Geröllgruppen, Lagerhallen mit Frachtgruppen, Zielvorschauen, Planetenkörper sowie das umgebaute Dossier. Die Vorlagen bleiben das Ziel: vor allem verknüpfte große Felsmassive, Schattenwirkung, Materialabstimmung und die vielen kleinen funktionalen Details fehlen noch in vergleichbarer Dichte.</p></section>'''
    for title, suffix, capture, note in [
        ('Heimatbasis', '01_48_58', 'n7-gallery-base.png', 'Eigene Betten, Werkstattwand, Regale, Tisch und Schränke; beleuchtete Wege und terrassierte Umgebung. Der derzeitige Detailgrad bleibt sichtbar unter dem Konzept.'),
        ('Freihafen', '01_48_52', 'n7-gallery-distribution_friendly.png', 'Größere Hallen, Frachtgruppen, Regale, Tanks und Fahrbahnmarkierungen. Zusammenhängende Architektur und dichterer Betrieb benötigen eine weitere Gestaltungsrunde.'),
        ('Systemkarte', '01_49_07', 'n7-chart-teams.png', 'Stern, Bahnen, Gürtel, texturierte Planeten, vier Startwelten und echte Ortsvorschau. Die hochwertige illustrative Ausarbeitung der Vorlage ist noch nicht erreicht.'),
        ('Crew-Dossier', '01_49_15', 'n7-dossier.png', 'Crew links, Figur und Ausrüstung in der Mitte, echte Bestände rechts. Werte stammen aus dem Spiel. Eigene aufwendige Gegenstandsillustrationen fehlen noch.')]:
        ref = DOWNLOADS / f'Codex-Bild 21. Sept. 2026, {suffix}.png'
        page += pair(title, ref, capture, note)
    original = Path.home() / 'AppData/Local/Temp/codex-clipboard-81f72d59-a8af-405d-8c1f-88dcb4dec8af.png'
    page += pair('Das Urbild bleibt die Geländereferenz', original, 'n7-gallery-rust.png', 'Flächige geschichtete Felsen, großzügige Zwischenräume und kleine Detailgruppen statt beliebig verteilter Spitzen. Der Ist-Stand zeigt Fortschritt, aber noch nicht die Geschlossenheit des Urbilds.')
    page += '<section><h2>Forschung und Bunkerebenen im Spiel</h2><div class="pair">' + figure(OUT/'n7-blueprints-initial.png','Forschungsbaum im nativen Fenster') + figure(OUT/'n7-bunker-lower.png','Eine Person unten, andere Crew weiterhin oben') + '</div></section>'
    page += '''<section id="pruefung"><h2>Was geprüft wurde</h2><table><tr><th>Bereich</th><th>Nachweis</th></tr>
    <tr><td>16 Commander</td><td>16 echte Produktprozesse; 8 + 8 über ENet und authentifizierte WebSockets. Gültiger Befehl akzeptiert, gefälschte Host-Zuweisung abgelehnt.</td></tr>
    <tr><td>Öffentliche Internet-Einladung</td><td>73 Prüfungen bestanden, zwei Prozesse durch öffentlichen WSS-Tunnel; beide auf einem Rechner.</td></tr>
    <tr><td>Teamzustand</td><td>21 Kampagnen- und 21 Weltintegritätsprüfungen; getrennte Planeten, gemeinsame Bestände vor Ort, Host-Team nach Laden und eingefrorene Lobby.</td></tr>
    <tr><td>PvP-Spielweg</td><td>9 Prüfungen: beide Teams über normale Befehle einsteigen, reisen, landen, kämpfen und aktiven Kampf speichern/laden. Dieser Test nutzt den Kern ohne Netzwerk.</td></tr>
    <tr><td>Bestehender Spielkreis</td><td>76 native Produktprüfungen, 104 Kern-, 147 Boden-, 162 Navigations- und 164 Welterweiterungsprüfungen.</td></tr>
    <tr><td>Ebenen und Forschung</td><td>10 Kernprüfungen plus 9 native Fensterprüfungen für Ebenen; 9 Forschungsprüfungen einschließlich Reservierung und erneuter Kostenvermeidung.</td></tr>
    <tr><td>Oberfläche</td><td>22 Dossier- und 9 Referenz-UX-Prüfungen; tatsächliche Bildschirmaufnahmen. Menschliche Spielspaß- und Stilabnahme bleibt offen.</td></tr></table></section>
    <section id="offen"><h2>Die nächsten Ausbauten</h2><ol><li>Gelände und Bauwerke enger an den Vorlagen ausarbeiten: zusammenhängende Mesas, eingebettete Wege, stimmige Lichtführung, größere Vielfalt funktionaler Requisiten.</li><li>Eigene Layouts und Biome für die drei zusätzlichen Heimatwelten.</li><li>Gegnerische Schiffe, Schiff-gegen-Schiff-PvP und gemeinsam sichtbare Raumkämpfe.</li><li>Reisende KI-Fraktionen, Rekrutierung, baubare Erweiterungen, eigener Forschungsraum und umfangreichere Crewprogression.</li><li>Mehrere Haushalte, lange Sitzungen, Wiederverbindungen und belastbare Multiplayer-Balance praktisch erproben.</li></ol><p>Begehbare Schiffsinnenräume bleiben wie vereinbart ein späterer Ausbau. Das stabile N6-Paket wird separat erhalten. Diese N7-Runde ist kein Abschluss der gesamten Spielvision.</p></section></main></html>'''
    target = OUT / 'N7_REFERENZABGLEICH.html'
    target.write_text(page, encoding='utf-8')
    print(target)

if __name__ == '__main__':
    build()
