# GM01 Frontier: große Hex-Standardkarte

## Dispatch und Wahrheit
`grid_sweep` lädt weiterhin `maps/Ground_Mission01_32x32.json` über `ground_mission01_default.json`. Der historische Dateiname bleibt für bestehende Referenzen erhalten; der Inhalt heißt `GM01 Frontier Hex 96x98`. Auch FOB-Transfer nutzt diese Karte. Das Szenario überschreibt den Setup-Pfad und bleibt bytegleich, einschließlich acht Gegnern, Taktiken, Zielradius96 und Zeitlimit1200s.

`TerrainMapData` speichert optional `authored_visual_layout_id`. Fehlend bedeutet bisherigen Tilepfad; unbekannte IDs bleiben als Daten erhalten, ohne erratene Grafik. Map-/Registry-/Simulationsdaten besitzen Walkability, LOS, Höhe, Deckung, Marker und Patrolpfade. Der Renderer liest nur.

## Hexfläche und Autorierung
Auf den weiteren Nutzerwunsch „sichtbarer Boden muss bespielbar sein“ wächst die tatsächliche Karte auf96Spalten×98versetzteZeilen mit9408gespeicherten Zellen. Offsetspalten liegen in-24..71, Zeilen r in-25..72; axial q=Spalte-floor(r/2). Negative q und negative r sind echte Koordinaten, kein Anzeigeoffset. Die frühere dekorative96×84m-Plane wird durch die exakte Vereinigung dieser Hexpolygone ersetzt (AABB ca96,5×85,16m). Bestehende Modell-, Marker-, Patrol- und Shaderweltanker bleiben unverschoben. Freier neuer Boden ist tatsächlich auswählbar und navigierbar; sichtbare feste Hüllen bleiben Hindernisse.

`frontier_gm01_layout.gd` baut genau `gm01_frontier_outpost_v1`: originale Habitat-/Hallen-/Fuelmodelle, geschlossene Außenhüllen, dünne Vorfelder, ursprüngliche Geologie/Worklife sowie Ostversorgung und zwei Zufahrten.56sichtbare Hüllen und8Wege, keine Previewbürger oder statischen Schiffe. Die Cutlass bleibt echte Runtime.

`build_gm01_frontier.gd` läuft ausschließlich offline. Hexpolygon-/Rect-Kontakt (0,015m Toleranz) erzeugt gespeicherte Solidzellen passend zu allen sichtbaren Hüllen; der neue Stand hat 1046 Solidzellen und 560 begehbare Deckungsnachbarn. Die Zählwerte sind im jeweiligen Authoring-/QA-Ergebnis belegt. Straßen werden an Hexzentren klassifiziert, Deckung aus sechs Nachbarn. Das ist vorhandene Raster-Navigation, keine exakte Mesh-/Physiknavigation. Die Frachtterrasse besitzt den geprüften echten Hextripel (6,24)H0→(7,24)H1/slope→(8,24)H1, physisch x18→19→20 bei z20,7846. Der neue westliche GO-Prüfpunkt (-8,12) liegt physisch bei x=-2m / z≈10,3923m und damit jenseits der früheren x0-Grenze.

## Visuals und Bounds
Die konkrete Stage wird beim kalten Konfigurieren einmal unter WorldRoot gebaut, wiederverwendet und beim Mapwechsel entfernt. Gespeicherte `frontier_scene_solid`-Zellen bekommen keine zweiten Objektfallbacks; der zusammenhängende Boden ersetzt nurH0-Kappen. Runtime-Groundpolygone stammen ausschließlich aus den tatsächlich geladenen MapData-Zellen, nicht aus dem Offline-Default. Ein anderer Zellumfang unter derselben Layout-ID aktualisiert die Groundgeometrie; Legacy-/unbekannte Layouts behalten keine alte Fläche zurück. Renderingbudget und tatsächliche höchste Visualhöhe werden kalt an der Stage erfasst. Keine Komplettaufbauten pro Frame.

Das feste Ensemble hält seine tatsächlichen Zellen, Hexlinien und Bodenmaske vollständig resident. Der Größenwechsel über4096Zellen darf hier nicht plötzlich ein kleineres Chunkraster oder eine Chunkmaske mitten im unverändert großen Ground einführen. Kamerafahrten lösen deshalb keine kompletten Grid-/FoW-Neuaufbauten aus. Andere große Karten behalten ihre vorhandene Streamingroute. FoW entsteht weiterhin in512erBatches und danach über Dirty-Deltas; unbekannte Fläche bleibt bis zum Abschluss geschützt.9408Zellen und die vollständigen Overlaymeshes erhöhen den kalten Aufbau-/Speicherbedarf; daraus folgt kein allgemeiner FPS-Nachweis.

Echte Hexkanten sind standardmäßig aktiviert und liegen über der Bodenmaske. Aktivierte Geometrie allein belegt ihre Erkennbarkeit noch nicht: Das dezente Raster muss bei normalem Spielabstand in tatsächlichen1280×720- und1920×1080-Aufnahmen menschlich als Hexfelder lesbar sein. Strichstärke und Kontrast dürfen anhand dieses Bildvergleichs angepasst werden; die sechseckige Topologie, das Picking und Kartenfakten bleiben unverändert. Kamera/Panning/Framing/Chunkbounds und Briefing-Minimap verwenden tatsächliche physische Tilepositionen; negative Axialkoordinaten sind gültig.

## Sichtmaske und schwarzes Aufblitzen
Der frühere dunkle kleinere Kasten war die Sichtmaske der gespeicherten Zellen über einer größeren Bodenfläche. Zusätzlich erzeugte der Batchaufbau bisher vorübergehend einen schwarzen Schutzkasten. Im Standardmodus `known_terrain` ist das Terrain bereits bekannt; nur der schwarze Aufbau-Schutzkasten ist hier entfernt. Die zellbasierte Terrain-Bodenmaske bleibt bestehen: bekannte, aktuell ungesehene Zellen des festen Frontier-Ensembles werden weiterhin schwach braun abgedunkelt (derzeit Alpha0,08). Das ist keine Aussage, dass Gegner sichtbar wären.

Dynamische Feindsicht verwendet einen davon unabhängigen Sichtfilter. Terrainbekanntheit, Bodenabdunklung und Darstellung gegnerischer Runtimeakteure sind getrennte Zustände; eine optische Masken-/Rasteranpassung darf keinen unbekannten Gegner preisgeben. Für eine neue Bildrunde dieselbe Kamera mit dokumentiertem Terrainmodus und Sichtzustand vergleichen und die Maskenwirkung ausdrücklich beurteilen.

`unexplored_blackout` behält den Schutz bis zur fertigen unbekannten Terrainmaske. Diese liegt über der tatsächlichen hohen Grafik, unabhängig von den begrenzten Gameplay-Objekthöhenklassen. Authored-Hexmasken verwenden sechs flache Dreiecke, keine doppelten Prismenseiten. Mehrframe-Gates prüfen bekannten und unbekannten Modus sowie versteckte Gegner.

## Editor
Das feste Ensemble besitzt noch keinen freien Multi-Cell-Platzierungseditor. Genau diese Layout-ID ist sichtbar vor Terrain-, Objekt-, Höhen-, Marker- und Patroländerungen geschützt. Ansicht, Auswahl, Kamera und unverändertes Save/SaveAs bleiben möglich. Der interne Hüllentyp ist kein Palettenasset. Andere Karten bleiben editierbar.

## Prüfung und Grenzen
Gezielte Verifier prüfen deterministische Bytes, echte6Kanten, breiteA*/HPA-Routen, Original-Spawnabstände, Save/Load, Editor, Kamera, Minimap und Sichtmasken. Normale Menü-/Heimatbasis-/LZ-/Drop-/GO-Läufe verwenden separate Userdaten, normale Zeit und echte Runtimeakteure. Der alte TASK1179-Zielcheck bleibt ausdrücklich beschleunigte Logikprobe mit geerbtem Deployshortcut.

Die große Hexkarte legte eine teure bestehende Coverbewertung offen. Identische Scorings werden nur innerhalb derselben synchronen Unit-Auswahl lazy wiederverwendet; Kandidaten, Scores, LOS, Range, Comparator und Reihenfolge bleiben erhalten. Zusätzlich prüft die Registry Radiusdistanzen vor den teureren Walkability-/Cover-Gettern. Ergebnis und Einfügereihenfolge bleiben identisch. Kein dauerhafter Cache, keine Zeit- oder Gegnerregeländerung. Legacy-Referenzfälle und native profilierte Vergleiche sichern den Eingriff ab.

Keine volle Kampagnen-, Balance-, Mehrspieler-, Langzeit- oder EXE-Abnahme. Der Osthof besitzt breite geprüfte Wege; eine Kameraansicht ist kein tatsächlicher Truppmarsch dorthin. Mainintegration ist ein eigener Schritt.
