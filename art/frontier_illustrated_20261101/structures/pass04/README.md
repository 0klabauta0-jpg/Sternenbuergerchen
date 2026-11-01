# Pass04: bewohnte Kenney-Sets und stationaere Versorgung

Separate visuelle Kandidaten fuer `ART_2026_11_01_pass04`. Die Pass03-BLENDs
und -GLBs bleiben bytegleich. Das Manifest prueft deren SHA-256 gegen die
vorherigen Pass03-Metadaten; Haus-/Hallen-BBoxen sind unveraendert.

| Kandidat | Dreiecke | Exportmaterialien | Editierbare Teile | BBox Blender X/Y/Z in m |
|---|---:|---:|---:|---|
| habitat_cutaway_01 | 5.077 | 12 | 104 | 6,90 / 7,10 / 3,005 |
| freihafen_hall_01 | 6.393 | 12 | 126 | 10,50 / 6,95 / 4,20 |
| utility_fuel_01 | 3.100 | 6 | 32 | 4,68 / 3,24 / 2,67 |

Alle GLBs: ein Mesh/ein Node, keine Animation, Skin, eingebettete Textur,
Kamera, Licht, Collision oder Navigation. Ursprung mittig in der gesamten
XY-BBox, minZ=0, Blender vorne -Y / Godot vorne +Z, Laufzeitskalierung 0,35.
Die neue Utility bleibt eine feste Versorgungsbaugruppe ohne Fahrzeug- oder
Betankungsmechanik.

## Gestaltung und Herkunft

Haus und Halle laden die geprueften Pass03-Quellen direkt. Raeume, Buehne,
Kenney-Moebel, Ladeachse und Framing bleiben erhalten. Ergaenzt sind wenige
warme Schalenvarianten, breite staubfarbene Sockelfelder, eine asymmetrisch
gestellte Lagergruppe, jeweils ein echter Factory-Wartungskoffer und kurze
anliegende Serviceleitungen. Die Rueckwaende bleiben bewusst hoch; der
Schnitt ist von vorne und rechts lesbar.

Die neue Utility hat zwei aufrecht angeordnete echte Kenney-`detail-tank`-
Derivate auf einem tragenden Rahmen mit Fuessen und Laengsauflagen. Echte
Factory-Geometrie liefert Pumpe (`machine-connection-pipe`), Bedienfeld
(`screen-panel-small`) und Verteilerventil (`pipe-large-valve`). Die eigenen
Ergaenzungen sind Rahmen, Kabinett, Anschluesse, Verteilerrohre und zwei
gebogene Leitungen. Die vorstehenden Baender/Halter bleiben erkennbare Teile
des Tank-Originals; kein Radfahrzeug und kein liegender Tank auf einer Platte.

`manifest.json` fuehrt 14 tatsaechlich genutzte Kenney-GLBs mit CC0-Lizenz-
Datei, SHA-256, Instanzen und Bearbeitungsschritten auf. Die vier zusaetzlich
benoetigten Factory-Dateien liegen bytegleich unter `source_assets/`, mitsamt
Originalatlas und Lizenz. Aeltere kuratierte Originaldateien bleiben dort,
wo Pass03 sie bereits referenziert. Es wird reale Geometrie uebernommen,
nicht nur ein Stilname verwendet. Die Exportpalette ersetzt die Quellatlanten.

Die drei Nutzerbilder (Rostgrenze, Freihafen und Aussenposten-Stilstudie)
sind im Manifest mit Hash referenziert. Als zusaetzliche Industriequelle
wurden zwei grosse Bilder der offiziellen
[RSI Idris Deck Gallery](https://robertsspaceindustries.com/en/comm-link/engineering/13360-WIP-Idris-Deck-Gallery)
geoeffnet: Powerplant 1 und 6. RSI bezeichnet sie als WIP-In-Engine-Bilder
von 2013. Sie sind keine Belege fuer heutiges Gameplay. Die Quelle dient
sichtbaren Kupplungen, unterstuetzten Baugruppen und grossen Materialzonen;
ihre Bilder werden nicht als Spieltextur eingesetzt. Bilddateien und
Seiten-Snapshot liegen unter `references/`, URLs und Hashes im Manifest.

## Pruefung und Warnungen

Blender 5.2.3 LTS: Source-QA fuer alle drei Modelle bestanden, danach frischer
GLB-Import aus leerer Factory-Szene ohne Reparatur. Positionen in beide
Richtungen, BBoxen und Dreieckszahlen pro Material stimmen exakt ueberein
(maximaler Vertex-Abstand jeweils 0 m). Finale Rohdaten liegen in `qa/`.
Die finale Montagekorrektur ist `build_r02.log`; `build_r01.log` bleibt als
nicht bestandene Zwischeniteration nachvollziehbar und gilt nicht als Abnahme.

Pro Modell wurden final vorne, hinten, oben, Spielabstand, Zufallsfarben und
Wireframe sowie frischer GLB vorne/Spielabstand geoeffnet (24 Ansichten).
Das sind Workbench-Geometrie-/Palettenansichten; die native Beleuchtung und
die Platzierung prueft der uebergeordnete Grafikpass.

Die akzeptierten Warnungen sind einzeln in Roh-QA und Manifest erhalten:

- Verdeckte Ruecken-an-Ruecken-Kontakte: uebernommene Wand-/Halterkontakte
  bei Haus/Halle; zwei Kabinett-/Servicedeck-Paare bei Utility. In den
  geoeffneten Ansichten kein sichtbares Z-Fighting.
- Doppelte Positionen an gesplitteten Original-Montagenaehten und
  Schlauch-Endkappen; keine losen Vertices oder schwebenden Teile.
- Einige uebernommene offene Kenney-Schalengrenzen. Keine Zusage fuer
  wasserdichte Druck-/Fertigungsmodelle.
- GLB-Normalen-/Materialgrenzen behalten zusaetzliche Vertexkopien. Die
  Geometrie ist identisch; Schlaeuche erscheinen nach Import aus der Naehe
  etwas facettierter als die geglaetteten Source-Kurven.
- Keine UVs fuer die absichtlich untexturierte Farbpalette.

Der begrenzte Farbumsatz veraendert keine Raumfunktion. Die Gebrauchsspuren
bleiben grobe Sockel-/Paneelfelder ohne Kleindetailrauschen. Im Spielabstand
sind kleine Serviceanschluesse nachrangig. Dies ist keine gestalterische
Nutzerabnahme und kein Gameplay-/Performance-Nachweis.

## Reproduktion

Vom Projektroot mit installiertem Blender 5.2.3; jeder Blender-Aufruf startet
mit `--background --factory-startup --python-exit-code 1 --python` und dem
jeweiligen folgenden Skript. Nacheinander ausfuehren:

1. `art/frontier_illustrated_20261101/structures/pass04/generator/build_pass04.py`
2. `art/frontier_illustrated_20261101/structures/pass04/generator/review_pass04.py`
3. `art/frontier_illustrated_20261101/structures/pass04/generator/verify_roundtrip.py`
4. Mit normalem Python: `art/frontier_illustrated_20261101/structures/pass04/generator/finalize_manifest.py`

Die ersten drei Aufrufe fuer neue Nachweise in die im Manifest genannten
Logdateien umleiten. Das Finalisierungsskript prueft Erfolg und Quellen-
Integritaet streng. Es veraendert weder GLBs noch BLEND-Dateien.
Der Build verwendet die im Manifest gehashten Pass03-Helfer und die
unveraenderte lokale `blender-asset-qa/scripts/qa_check.py`. Neue
Factory-Quellkopien werden zusaetzlich gegen ihren lokalen Originalpack
geprueft; dessen Pfad ist als Provenienz im Manifest erhalten.

GLB-SHA-256:

```text
habitat_cutaway_01  6524cd513b1d474dba4a855ef1dad32ec4539513acb46bf73cd1b44463a2d50f
freihafen_hall_01   cc17a4cebc805a3f165eecd0e3bef95b7a92e851dc592fb8867b92597a894508
utility_fuel_01     7e7c54b23548b95ee0483a9233f2c5fd256eaac5a01f153c8b8b7c2a1240b274
```
