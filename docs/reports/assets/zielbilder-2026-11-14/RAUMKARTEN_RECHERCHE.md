# Raumkarten: Recherche und Vorgaben für Bilder 13–16

Stand: 14.11.2026. Dieser Nachtrag dokumentiert die Rückmeldung zur ersten
Bildserie und die daraus folgende Bildrevision. Er verändert keine Runtime,
Kartenquelle, Spielregel oder Integration.

## Auftrag und Nutzerfeedback

Der Nutzer bewertet die Bodenbilder insgesamt positiv. Nur die vier
Weltraumbilder 13–16 sollen ersetzt werden. Die neuen Bilder sollen den
tatsächlichen Aufbau der Spielkarten zeigen: große Hexkarten, kleiner
Schiffsmaßstab, Planet beziehungsweise Station am oberen Rand und freier
Weltraum darunter. Der gewünschte Star-Citizen-Bezug betrifft Material,
Bauweise und glaubwürdige Details; Kamera und Größenverhältnisse kommen aus
dem Spiel. Die bisherigen vier Weltraumbilder bleiben historische Varianten.

### Verbindliche jüngste Präzisierung: Polisar und Stationsgeometrie

Die folgende Nutzerpräzisierung hat für die neue Bildrevision Vorrang vor
älteren Benennungen und allgemeinen Stationsannahmen in diesem Dokument:

- Die Spielstation heißt im neuen Bild **Polisar**. Die bestehende Code-ID
  `polisa` bleibt unverändert; dies ist kein Auftrag zur Runtime-Umbenennung.
- **Leichte und mittlere Jäger belegen jeweils ein Hex.** Der belegte
  Zwei-Hex-Footprint der Cutlass bleibt als eigener Transporterschiff-Bezug
  erhalten; aus „mittlerer Jäger“ folgt keine Zwei-Hex-Größe.
- Maßgebliche Geometriequelle ist der neu angehängte Star-Citizen-Topview:
  `C:/Users/bjoer/AppData/Local/Temp/codex-clipboard-33db2b95-cd6b-4b6c-8df7-517ac1cf7251.png`.
  Der Hauptagent hat ihn gesehen und verwendet ihn zusammen mit der nativen
  Stationsansicht und der Detailstilreferenz für die Bildrevision. Der Pfad
  bezeichnet einen temporären Eingabeort; eine spätere Paketkopie und ihr
  Hash gehören in die Generation-/Quellmetadaten.
- Die **Ringe stehen senkrecht zur Kartenebene**. Die verbindende Querachse
  verläuft in X-Richtung, quer über die Karte. In echter Draufsicht erscheinen
  die Ringe als schmale Striche; in leicht schräger Ansicht als schmale
  Ellipsen. Keine flach auf der Kartenebene liegenden Kreisringe.
- Die jüngste **Nutzerannotation** konkretisiert diese Geometrie: Die blauen
  Markierungen meinen **Nabe/Querachse**; „Narbe“ ist eine Diktatabweichung.
  Die Nabe/Querachse dehnen beziehungsweise verlängern, die Ringe vergrößern.
  Die Hauptachse muss **exakt durch beide geometrischen Ringmittelpunkte**
  laufen, nicht unterhalb der Ringmitte. Ringzentrum und jeweiliges
  Achs-/Nabenkreuz fallen zusammen. Für Blender: Ringebenen YZ, vertikal Z,
  Hauptachse X; Ringmittelpunkte und Hauptachse besitzen dieselben Y-/Z-Werte.
  Plausible radiale und querlaufende Streben verbinden Ringe, Nabe und Achse.
- Die **linke Verlängerung** trägt Solarzellen/Paneelflügel oberhalb und
  unterhalb der Querachse in der Referenzansicht. An der **rechten
  Verlängerung** sitzen genau **vier Treibstofftanks: zwei oberhalb, zwei
  unterhalb**. Paneele, Tanks und Leitungen müssen sichtbar an der Struktur
  befestigt sein. Diese Bild-/Layoutpositionen führen keine neue spielbare
  Höhenebene ein.
- Die gerade vom Hauptagenten geöffnete native Ansicht
  `C:/dev/SternenBuergerchen-worktrees/space-air-parent-20261112/output/native_glut_maps/polisa_r08_20261111/polisa_r08_station_near.png`
  zeigt die vom Nutzer grundsätzlich gewünschte Padaufteilung: **zwei M-Pads
  links vorn, ein L-Pad zentral, vier S-Pads rechts im 2×2-Block**. Dazu kommt
  der Innenhof mit blauer Kugel und Shops.
- Diese Padaufteilung erhalten, die Pads jedoch kompakter gestalten und den
  Innenbereich vergrößern. **Zwei zusätzliche Dockports für Großschiffe**
  ergänzen; sie sind getrennte Dockanschlüsse, keine stillschweigend zu
  ersetzenden oder zusätzlichen Landepads.
- **Dock 1 und Dock 2 etwas weiter nach außen setzen**, ihre tragenden Arme
  entsprechend verlängern. Dockklammern und Anflugkorridore bleiben frei,
  insbesondere gegenüber den neuen Solarflügeln, Tanks und Ringstreben.
- Die obere Kartengrenze liegt **knapp hinter der Querachse beziehungsweise
  den Räumen**, sodass die vollständigen vorderen Räume innerhalb der Karte
  liegen. Sie darf die begehbaren vorderen Räume nicht abschneiden. Die obere
  beziehungsweise hintere Stationshälfte liegt außerhalb der Karte oder
  bleibt ausdrücklich nicht begehbare Dekoration.
- Die jüngste Annotation ändert **Kernräume, Padaufteilung und Kartengrenze
  nicht**. Präzisierung der räumlichen Reihenfolge von hinten nach vorn:
  hintere Dekoration → Kartengrenze → Querachse und vollständige vordere
  Räume → Pads → freier Anflugraum. Die Grenze liegt hinter der gemeinsamen
  hinteren Kontur von Achse/vorderen Räumen, nicht zwischen Achse und Räumen.
  Seitliche Achsenverlängerungen in X-Richtung verschieben diese Grenze nicht.

Diese Angaben sind die aktuelle gestalterische Zielvorgabe. Die genannten
Padklassen, neuen Großschiff-Dockports und die veränderte Raum-/Padproportion
beweisen keine entsprechend implementierte Dock-, Raum- oder Begehbarkeitslogik.

Die jüngste Vorgabe nennt automatischen Einflug von unten nach oben und
umgekehrten Ausflug, manuelle Übernahme, Abfangsituationen und Wracks. Diese
Szenen sind visuelle Zielvorgaben. Eine Illustration allein bestätigt weder
den Implementierungsstand noch spielbare Save-/Continue-/Kampfabläufe.

Die gesprochene Größe „256 × 512“ wird in der recherchierten Kartenquelle als
**512 Spalten × 256 Reihen** geführt. „UM“ konnte nicht als eigener
verifizierter Kartentyp zugeordnet werden; vorhandene Dokumente verwenden
OM beziehungsweise Orbitkarte. Es wird keine zusätzliche UM-Mechanik erfunden.

## Verifizierte Projektquellen

Das Hauptcheckout `C:/dev/SternenBuergerchen` stand bei der Recherche auf
`task/playtest-rework-plan-20261114` und enthielt die neueren Raumowner und
die AIR-LEGACY-Task-Datei nicht vollständig. Deshalb wurden die tatsächlichen
Dateien der vorhandenen Raum-/Stationsworktrees gelesen. Die folgenden
Zeilenangaben beziehen sich auf diesen gelesenen Stand, nicht auf eine
behauptete Main-Integration.

| Aussage | Gelesene Quelle und Zeilen |
|---|---|
| Planet oben; System unten. Einflug unten→oben, Ausflug oben→unten. Automatischer Durchflug bei freiem Weg abschaltbar. Optionale Asteroiden als Hindernisse. | `C:/dev/SternenBuergerchen-worktrees/space-air-parent-20261112/docs/dev/space_combat_contract.md`, Zeilen 41–56 |
| Strategische Sternkarte 256×256; lokaler Orbitbereich 512×256; Reise, Begegnung und Kampf teilen ihn. Warpankunft unten. Körper oben mittig mit 256 Feldern breitem und etwa vier Feldern tiefem Saum. | `C:/dev/SternenBuergerchen-worktrees/space-air-parent-20261112/docs/dev/space_combat_contract.md`, Zeilen 65–73 |
| Ein leichter Jäger entspricht einer logischen Hex-Ankerzelle. Position und Bugwinkel sind kontinuierlich, große Schiffe benötigen orientierte Mehrfeld-Footprints. Spielwirksam bleibt die Lage auf einer Ebene. | `C:/dev/SternenBuergerchen-worktrees/space-air-parent-20261112/docs/dev/space_combat_contract.md`, Zeilen 83–96 |
| Tatsächliches lokales Layout: `MAP_SIZE = Vector2i(512,256)`, unteres Eintrittsband `Rect2i(0,224,512,32)`, sichtbare Planetentiefe 4. | `C:/dev/SternenBuergerchen-worktrees/orbit-save-automatic-20261112/scripts/mission/orbit_approach_layout.gd`, Zeilen 4–10 und 26–35 |
| Routenplanung unterscheidet inbound/outbound, verweigert erkannte Kontakte und prüft den gesamten Weg samt Footprint gegen Hindernisse. | `C:/dev/SternenBuergerchen-worktrees/orbit-save-automatic-20261112/scripts/mission/orbit_auto_transit_planner.gd`, Zeilen 9–42 |
| Flugowner bewegt wirklich; Abschaltung und neue Kontakte lösen Bremsen aus. Dokumentierte Opt-in-/Savegrenzen bleiben relevant. | `C:/dev/SternenBuergerchen-worktrees/native-navigation-main-20261114/docs/tasks/AIR_LEGACY_RADAR_ORBIT_2026_11_12.md`, Zeilen 47–60 |
| Cutlass belegt zwei Hexzellen: `[[0,0],[1,0]]`. Buccaneer belegt eine: `[[0,0]]`. | `C:/dev/SternenBuergerchen-worktrees/polisa-playable-route-20261112/data/singleplayer/ship_equipment.json`, Zeilen 12–21 und 31–33 |
| Technische Orbitansicht projiziert dieselbe Ebene mit vertikaler Stauchung 0,72; Zoom 0,6–48. Darstellung ist keine Bewegungsautorität. | `C:/dev/SternenBuergerchen-worktrees/orbit-save-automatic-20261112/scripts/ui/orbit_area_canvas.gd`, Zeilen 2, 8–11 und 125–132 |
| Native 3D-Kartenkamera verwendet orthografische Projektion. | `C:/dev/SternenBuergerchen-worktrees/space-air-parent-20261112/scripts/terrain/terrain_map_3d_view.gd`, Zeile 3958 |
| Polisa-Gesamtaufnahme: Kamera yaw 0°, pitch 68°, size 320. | `C:/dev/SternenBuergerchen-worktrees/space-air-parent-20261112/art/polisa_r08_20261111/capture_r08.gd`, Zeile 23 |
| Polisa näher: yaw 24°, pitch 50°, size 62; weitere Stations-/Padansicht yaw 12°, pitch 50°, size 112. | `C:/dev/SternenBuergerchen-worktrees/space-air-parent-20261112/art/polisa_r08_20261111/layout_compiled.json`, Zeilen 971–973 und 1241–1243 |
| Aktuelle Reisevorgabe im Playtestplan: Orbitautomatik setzt nur eine ausdrücklich befohlene freie Reise fort. | `C:/dev/SternenBuergerchen/docs/tasks/PLAYTEST_REWORK_2026_11_14.md`, Zeilen 73–79 und 289–292 |
| Der ältere Reisevertrag trennt Reiseowner und UI-Kamera. Seine historischen Marker-/Orbitbeschränkungen sind kein vollständiger aktueller Raumkampfvertrag. | `C:/dev/SternenBuergerchen/docs/dev/orbit_quantum_travel_contract.md`, Zeilen 30–45 und 54–63; Ablösung der älteren Zielannahme in `space-air-parent-20261112/docs/dev/space_combat_contract.md`, Zeilen 80–84 |

Die genaue Zellbelegung, der räumliche Index und Flug-/Kampfzustände bleiben
bei bestehenden Daten- und Runtimeownern. Ein Bild darf kein zusätzliches
Stockwerk im Weltraum, keine freie 3D-Ausweichmechanik oder verdeckte zweite
Kartenwahrheit suggerieren.

## Polisa: sichtbare Station oben und separater Dock-Descriptor

Die tatsächlich geöffnete native Gesamtaufnahme
`C:/dev/SternenBuergerchen-worktrees/space-air-parent-20261112/output/native_glut_maps/polisa_r08_20261111/polisa_r08_whole_map.png`
zeigt die Station **am oberen Rand** einer breiten Karte mit viel schwarzem
Weltraum darunter. Sie ist der passende Kompositionsanker für Bild 16.

Im selben Ordner liegen die ergänzenden nativen Ansichten
`polisa_r08_station_near.png` und `polisa_r08_station_ports.png`. Diese
Dateipfade wurden verifiziert; die Gesamtaufnahme wurde in dieser Recherche
persönlich geöffnet. Sie zeigen einen vorhandenen authored R08-Kandidaten,
keine Behauptung vollständiger aktueller Kampagnenabnahme.

Davon getrennt enthält
`C:/dev/SternenBuergerchen-worktrees/orbit-save-automatic-20261112/scripts/mission/polisa_station_dock_layout.gd`
in Zeilen 13–16 einen technischen Dock-Descriptor: 512×256 Bounds,
Stationanker `(256,124)`, Block `(244,116,24,12)` und Gate `(256,133)`.
Dieser mittige Block ist nicht dieselbe Darstellung wie die native
R08-Station am oberen Rand. Beide Quellen werden nicht vermischt.

Historisch blieb Polisa direkt erreichbar, ohne obligatorische vorgeschaltete
Orbitkarte (`space-air-parent-20261112/docs/dev/space_combat_contract.md`,
Zeilen 75–78). Die aktuelle Nutzeranweisung bestimmt das neue Bildziel
„Station oben“. Sie ist keine stillschweigende Änderung der Reiseimplementierung.
Die tatsächlichen Orts-IDs heißen `polisa`; die Anzeige `POLISA` steht in
`polisa-playable-route-20261112/data/singleplayer/polisa_station.json`, Zeilen 2–3.
„Polysar“ und „Port Olisar“ werden als gesprochene beziehungsweise externe
Referenznamen behandelt, nicht ungeprüft als neue Karten-ID.

## Wrack und Gefecht: belegte Grenzen

`C:/dev/SternenBuergerchen-worktrees/polisa-playable-route-20261112/scripts/core/campaign_space_encounter.gd`
unterscheidet in Zeile 34 eine feindliche Cutlass und eine neutrale Buccaneer.
Zeilen 53–58 beziehungsweise 72–86 verarbeiten Hüllen-/Rettungszustände.
Ein eigener allgemeiner Weltraumwrack-Footprint oder eine fertige
Wrackbergemechanik wurde in dieser begrenzten Recherche nicht belegt.

`data/singleplayer/location_resources.json`, Zeilen 18–31, enthält zwar
`freighter_wreck_01`, jedoch unter `satellite_crash`: Das ist ein Bodenwrack
und kein Beleg für eine entsprechende Orbitmechanik. Der Raumkampfvertrag
schließt in Zeile 354 eine neu eingeführte Wrackbergungsökonomie aus.
Bild 15 darf ein beschädigtes/manövrierunfähiges Schiff mit nahen Helfern
zeigen; die Szene bleibt ein gewünschtes visuelles Ziel. Kein Abschleppen,
Enterspiel oder sichtbarer Fortschrittsbalken wird als vorhandene Funktion
behauptet.

## Ergänzende visuelle Recherche und Credits

Die folgenden beiden Referenzen wurden vom Hauptagenten geöffnet. Sie dienen
Material, Bauweise, Stationsgliederung, Beleuchtung und Funktionsflächen.
Ihre filmische Kamera oder astronomischen Größenverhältnisse werden nicht
zur Spielkamera übernommen.

1. **Nutzer-Screenshot Port Tressler**
   `C:/Users/bjoer/Pictures/StarCitizen - Screenshots/LIVE/4.6.0-live.11377160/ScreenShot-2026-01-31_14-40-04-D50.jpg`.
   Herkunft: lokale Star-Citizen-Sammlung des Nutzers. SHA-256:
   `079d72e910473a35e685465bd3895cfae4aa0173217cdbd2a197437a1342c03f`.
   Original bleibt unverändert; eine bytegleiche Paketkopie ist in sources.json nachgewiesen.

2. **Hasgaha: Port Olisar, 2023 / Alpha 3.19.**
   Quelle: [Screenshots of Port Olisar Over the Years, RSI Community Hub](https://robertsspaceindustries.com/community-hub/post/screenshots-of-port-olisar-over-the-years-03Z7D1CWw5L2H).
   Die Seite nennt Hasgaha als Autor und enthält die Ansicht „2023 Alpha 3.19“.
   **Screenshot-Credit: [Hasgaha](https://hasgaha.com).** Die auf der Quellseite
   genannte Nutzungserlaubnis bittet bei öffentlichen Projekten um Nennung
   und Rücklink. Diese Zuordnung bleibt bei einer späteren Referenzübernahme
   erhalten. Der Community-Hub-Text wurde am 14.11.2026 zusätzlich geprüft;
   das konkrete Bild wurde vom Hauptagenten gesichtet.

Die Referenznennung bedeutet keine direkte Übergabe dieser Dateien an einen
Bildgenerator. Tatsächliche Bild-Inputs, Textprompts und Originalausgaben
gehören weiterhin in die Generation-Metadaten des jeweiligen Bildes.

## Gemeinsame Bildkriterien

- Hohe taktische Kamera, orthografisch oder nahezu orthografisch; gleichmäßige
  Hexprojektion über die sichtbare Spielebene, kein Horizont mit perspektivisch
  zusammenlaufendem Raster.
- Grundkarte 512×256. Bilder können einen Spielausschnitt dieser großen Karte
  zeigen. Es wird **keine Garantie von 131.072 exakt zählbaren KI-Hexfeldern**
  behauptet. Die spätere echte Geometrie kommt aus dem Kartenowner.
- Leichte und mittlere Jäger jeweils ungefähr eine Zelle, Cutlass ungefähr zwei benachbarte
  Zellen; keine bildfüllenden Schiffsheroaufnahmen. Nahe Ausschnitte dürfen
  Details zeigen, behalten aber ihren Zellmaßstab.
- Gleichmäßige Zellgröße innerhalb eines Bildes; Grid nicht auf einzelne
  Schiffe, Triebwerke oder Asteroiden wickeln. Dunkler Raum bleibt zwischen
  Akteuren lesbar. Trümmer und Asteroiden bilden räumlich sinnvolle Gruppen.
- Star-Citizen-Anmutung durch funktionale Rahmen, Druckkörper, Segmentierung,
  Wartungsflächen, angedockte Technik und sparsame Warnmarkierungen; illustrierte
  große Formen und Wimmelbilddetails passend zur akzeptierten Bodenserie.
- Kleine zweckmäßige Effekte zeigen Bewegung, Treffer oder Schaden. Keine
  riesigen Laser, Explosionen oder Effektwolken, die Karte und Schiffe verdecken.
- Ein-/Ausflugrichtung und manuelle Übernahme sollen kompositorisch klar sein.
  Eine Bildserie beweist weder funktionierende Automatik noch Bedienung.

## Vier konkrete Ersatzmotive

| Bild | Zielkomposition | Wichtige Abgrenzung |
|---|---|---|
| 13 – Planetarer Orbitanflug | Große 512×256-Orbitkarte beziehungsweise repräsentativer weiter Ausschnitt. Oben schmaler atmosphärischer Planetensaum; unten freier Systemraum und Eintritt. Kleine Schiffe bewegen sich von unten nach oben; viel freier Flugraum. | Kein riesiger Planet mitten im Spielfeld, kein bildfüllendes Schiff und keine zusätzliche atmosphärische Bodenkarte. Ausflug ist dieselbe räumliche Ordnung in Gegenrichtung. |
| 14 – Raumkampf im Asteroidenfeld | Näherer Ausschnitt derselben Kartensprache. Wenige erkennbare Schiffe in Abfang-/Deckungsbewegung zwischen ungleich großen Asteroidengruppen; leichte und mittlere Ein-Hex-Jäger sowie Zwei-Hex-Transporter bleiben ablesbar. | Keine frei gestapelten Höhenebenen oder filmische Verfolgungskamera. Abfangsituation illustriert bestehendes Zielkonzept, keine komplette Spielabnahme. |
| 15 – Beschädigtes Schiff / Wrack | Kartenausschnitt mit havariertem Schiff, begrenztem Trümmerfächer und anfliegenden Helfern. Defekte Triebwerke und unterbrochene Beleuchtung machen den Zustand lesbar; ausreichend freie Manövrierfläche. | Bergung, Abschleppen oder Wrackökonomie sind nicht als implementiert belegt. Kein Reparatur-Minispiel oder zusätzlicher Ressourcenablauf wird erfunden. |
| 16 – Polisar am oberen Kartenrand | Taktische Station mit vergrößerten senkrechten Ringen; verlängerte Nabe/Querachse in X-Richtung exakt durch beide Ringzentren und plausibel verstrebt. Links Solarflügel ober-/unterhalb der Achse, rechts vier befestigte Tanks in 2+2-Anordnung. Zwei kompakte M-Pads links vorn, ein L-Pad zentral, vier S-Pads rechts im 2×2-Block; größerer Innenhof mit blauer Kugel und Shops; zwei zusätzliche, weiter außen liegende Großschiff-Dockports mit verlängerten Armen und freiem Anflug. Bestätigte Kernräume, Padaufteilung und Grenze bleiben erhalten: Grenze knapp hinter Querachse/vollständiger vorderer Raumkontur, viel freie Hexflugfläche darunter. | Hintere Hälfte außerhalb der Karte oder nicht begehbare Dekoration. Keine Achse unter den Ringzentren, keine flach liegenden Ringkreise, keine abgeschnittenen vorderen Räume und keine bildfüllende Hero-Station. Native R08-Topologie, technischer Dock-Descriptor und neues Bildziel bleiben getrennte Nachweise; Code-ID weiterhin `polisa`. |

## Erreichter Stand

Recherche und Bildvorgaben sind dokumentiert. Raumkarten 13–15 R03 und
Polisar R04 sind erzeugt; die aktiven Zuordnungen und tatsächlich verwendeten
Prompts/Eingaben stehen in prompts.json und generation_metadata.json.
R04 übernimmt die annotierte Naben-/Ringkorrektur, Streben, linke Solarflächen,
vier rechte Tanks und verlängerte Dockarme. Nutzerabnahme bleibt offen.
Der Modellierungsauftrag steht in POLISAR_BLENDER_AUFTRAG.md. Keine Modelle,
produktiven Karten oder Spielskripte wurden durch dieses Grafikpaket geändert.
