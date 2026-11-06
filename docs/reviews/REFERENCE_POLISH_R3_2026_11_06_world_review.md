# R3 World: fokussierte Quellpruefung

Lesende Pruefung am2026-11-07, keine eigenen Engine-/Import-/Produktlaeufe.
Umfang: neuer Dressinghelper, neue GM01-Kontext-/Installationspfade und nur
die Dressing-/FoW-Integrationshunks des TerrainView. Komponenten- und neuer
GPU-Verifier wurden als getrennte Nachweise gelesen.

## Gepruefter aktueller Pin

| Quelle | SHA256 |
| --- | --- |
| frontier_reference_dressing.gd | `698eaa71163b94f35a90813b1ce5978eb4da86bf37c909034d3ca74aabb4152e` |
| frontier_gm01_layout.gd | `525ec41d9e8abefac8dbe6a983d6f17d9b167dbb21c8e7d318763b27d3310def` |
| terrain_map_3d_view.gd | `e87cfe88e3723e973a2cce8d5092c28e3b3c2b5d4ef3c683c05d061ed85a5a75` |
| reference_polish_r3_20261106_world_dressing_verifier.gd | `9c7dba991d2e42e2bc152eed06eece233beab196160a52317a66dece418278ee` |
| reference_polish_r3_20261106_world_gpu_verifier.gd | `b954736817882ac965abd583f6b135ef4cb6c060c30770b69da98ff8d63b8e02` |

## Befunde

Keine zusaetzliche konkrete P1-/P2-Verletzung von FoW, Zelleinschluss,
Gameplay-Ownership oder Hotpathbegrenzung im aktuellen Umfang gefunden.

Der bekannte Reusebefund war im zuerst gelesenen Helperpin
`926208632039243bea088d4395fc7916068844f028157442b5f3398f906e7f90`
noch vorhanden. Der aktuelle Hunk behebt ihn quellenmaessig: erst vollstaendige
Validierung, dann eigene kanonische Placement-Signatur und Vergleich der vier
tatsaechlichen Mesh-/Materialressourcen; identische Installation kehrt vor
Layer-/Slot-/Sichtwrites zurueck. Die erweiterte Fixture prueft diesen Pfad,
eine gefaelschte Signatur und andere Mesh-/Materialidentitaeten. Ein neuer
Engine-PASS dieses Pins wird durch diese Review nicht behauptet.

Ein kleiner konkreter API-Randfall bleibt unterhalb P2:
`frontier_gm01_layout.gd:138` versteckt die vorherige Layer vor dem Install-
Aufruf. Liefert der Helper danach `reused=true`, ist ein alleiniger Aufruf
von `refresh_reference_dressing()` mit unveraenderten Daten nicht
sichtneutral: Layer.visible ist false, der Cache behaelt seinen alten
visible_count. Der aktuelle TerrainView publiziert im selben render_map
anschliessend erneut; deshalb wurde daraus keine sichtbare Spielregression
abgeleitet. Der direkte Helper-Reusepfad selbst hat diesen Seiteneffekt nicht.

## Gepruefte Grenzen und Nachweisstand

Blackout liest fuer jeden Slot ausschliesslich dessen gespeicherte Quellzelle;
fehlende und alte known-States bleiben unsichtbar. Kontextwechsel loeschen den
Renderer-Cellcache vor neuer bounded Publikation. Off/known geben bewusst
statisches Terrain frei. Eine grosse MultiMesh-AABB besitzt keine gemeinsame
any_visible-Freigabe. Neue/replatzierte Instanzen beginnen versteckt.

Die maximal0.49-Planeunits aus Zentrumsoffset plus Radius liegen innerhalb
der Hex-Inkreisgrenze0.5. Der Source-AABB wird durch den realen Transform
auf Radius und Bodenhoehe normalisiert; Mesh und Material bleiben fremde
unmutierte Quellen. Blockerrechtecke, gemessene volle Padbounds, bestehende
Pfadsamples/-breiten und Tuerpunkte werden mit Footprintabstand ausgeschlossen.

Das Maparray wird fuer die Planung einmal kalt indiziert; maximal512
Kandidaten und480 Sichtslots, keine neue per-frame Mapsuche. Der Renderer
publiziert den Helper nach vorhandenen Reset-/Batch-/Deltaereignissen statt
pro Terraintile. Snapshot liest nur skalare Diagnose. Gameplay-/Nav-/LOS-/
Coverwerte werden in den neuen Pfaden nicht geschrieben.

CPU-Cache-/Komponententests beweisen keine gerenderten GPU-Slots. Roots neuer
GPU-Lauf muss die reale FoW-Projektion in beiden Winkeln, Vollbildbilder und
Quellenstabilitaet nachweisen; dieser Nachweis war bei dieser Quellpruefung
noch offen. Normales Spiel, Maprand/Picking und gleiche Vergleichskamera
bleiben ebenfalls separate Gates.

## Implementer-Nachtrag: finale Komponenten- und GPU-Bindung

Dieser Nachtrag stammt vom World-Implementer; er ersetzt nicht die oben
stehende unabhaengige lesende Beurteilung des damaligen Pins. Produktquellen
sind seit dem finalen Fix eingefroren. Alle genannten Engineprozesse liefen
ausschliesslich bei Root; hier wurden deren Logs/Reports lokal gelesen.

Die unabhaengige Wrapper-Beobachtung wurde zuerst als echter RED reproduziert
(`world_wrapper_red/20261106T232532Z-f17de236`:42PASS/1FAIL). Ausschliesslich
ein gueltiges `installed && reused` stellt nun die vorherige `visible`-
Eigenschaft wieder her. Neue oder ungueltige Plaene bleiben verborgen.
Der anschliessende Wrapper-GREEN war43PASS/0FAIL.

Die Permutation derselben semantischen Clusterzentren wurde ebenfalls als
echter RED reproduziert (`world_center_order_red/20261106T232805Z-00ea3a52`:
44PASS/1FAIL; keine Kontextmutation). Der Helper sortiert ausschliesslich
seine eigene Kopie endlicher Vector2-Zentren nach X/Y. Seed, Mapreihenfolge
und Builderreihenfolge sind damit getrennte, konkret gepruefte Invarianten.

| Finale Quelle | SHA256 |
| --- | --- |
| frontier_reference_dressing.gd | `b67d0a1756c82d44394ab518960125a8b60d8496c06d4342afc0ad568b1cd91a` |
| frontier_gm01_layout.gd | `7827ae90a46d842c19e0fee730f75bc840988feb02abaeb434ffd84d1d470d8f` |
| terrain_map_3d_view.gd | `e87cfe88e3723e973a2cce8d5092c28e3b3c2b5d4ef3c683c05d061ed85a5a75` |
| reference_polish_r3_20261106_world_dressing_verifier.gd | `ad32367ad287af26970b9a552cfdbf3bb721b6f4d4891bc979e93a081a599968` |
| reference_polish_r3_20261106_world_gpu_verifier.gd | `b954736817882ac965abd583f6b135ef4cb6c060c30770b69da98ff8d63b8e02` |

Finale CPU-Evidenz:
`output/reference_polish_r3_20261106/world_all_final_green/20261106T232912Z-4d0ad6cb`:
45PASS/0FAIL. Prueft auch echte9408-cell-GM01, Source-AABB-Transforms,
alleinigen oeffentlichen Wrapperrefresh, kanonische Signatur und beide
Mesh-/Materialidentitaeten. Ein unveraenderter Plan erhaelt Layer, beide
Batches, publizierte Sichtbarkeit und skalare Receipt ohne Transformarbeit.

Finale native GPU-Evidenz:
`output/reference_polish_r3_20261106/world_gpu_final/20261106T232940Z-273e078e`:
56PASS/0FAIL im finalen Log, Windows/Vulkan/Forward+,3440x1440 Vollbild.
Zwei Kamerawinkel pruefen Off, komplett unbekannten Blackout, gemischte
sichtbare/erkundete/unbekannte Quellzellen beider tatsaechlicher MultiMeshes
und Known-Terrain. Acht echte PNGs und `captures/native_world_gpu.json`
liegen separat. Beide Rootreports melden Exit0, keine Enginefehler,
verifizierte Isolation, stabile Quellpins und unveraenderten geschuetzten
Roster nach Bytes/Groesse/mtime. Das Bildmanifest zaehlt55PASS vor seiner
eigenen Datei-Oeffnen-Pruefung; deren PASS ergibt den Logendstand56PASS.

Die echte GM01 erhaelt62 Props in zwei Batches nach512 begrenzten Kandidaten;
480 ist nur das Budget. Die finalen Bilder `00_angle0_off.png`,
`05_angle1_blackout_unknown.png` und `06_angle1_blackout_mixed.png` wurden
direkt geoeffnet. Die Off-Aufnahme zeigt niedrige Pflanzen-/Geroellgruppen
bei erhaltenen Gebaeuden, Servicewegen und Pads. Der unbekannte Ausschnitt
bleibt schwarz; im gemischten Ausschnitt sind nur die wenigen aufgedeckten
Hexflaechen lesbar. Der native Slotreadback prueft tatsaechliche Renderer-
Transforms; er ist keine automatische pixelweise Erkennung jedes kleinen
Props und kein physischer Gameplay-/Missionsbeweis.

Offen fuer Root bleiben regulaeres Spielen mit Soldaten/HUD, matched
Vorher/Nachher-Kamera34 und neue Produktkamera22, Picking-/Maprandnachbarn,
Performance mit neuer Szene sowie Main-Integration. Die technische World-
Freigabe behauptet keine vollstaendige Gleichheit zum illustrierten2D-
Original und keine menschliche Gestaltungsabnahme.
