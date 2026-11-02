# Cutlass R02: dokumentierter technischer Zwischenstand

Der Nutzer hat R01 gestalterisch abgelehnt und anschliessend auch den verbleibenden Vorlagenabstand von R02 kritisiert. **R02 ist keine gestalterisch freigegebene Schiffgrafik.** Die weitere Arbeit an beiden Schiffen wurde auf ausdruecklichen Nutzerwunsch in einen separaten Astra-Ultra-Chat verlegt (`01a197d8-ebd0-7100-8d12-21ff6bc52c0d`). In diesem Teilauftrag folgen keine weiteren Modellrunden.

Ausgewaehlt und fuer den nativen Import eingefroren ist ausschliesslich **Iteration02**: `source/iteration02/cutlass_01.blend`, Export `Assets/curated/frontier_illustrated_20261101/ships_pass04_r02/cutlass_01.glb`. SHA-256: `561cbe1297f2f6c72bd14c7c8f4ae33bc53ced7464d44a6a4bdfa49947fcda50`.

| Kennzahl | Iteration02 |
|---|---:|
| Dreiecke | 16.696 |
| Source-Vertices | 8.540 |
| Editierbare Teile | 104 |
| Export | 1 Mesh, 9 Materialien, 1 Node |
| Breite x Laenge x Hoehe | 11,6645 x 16,0000 x 5,4443 m |
| Bei RuntimeScale 0,22 | 2,5662 x 3,5200 x 1,1977 m |

16 m Gesamtlange sind eine bewusst stilisierte Normierung, keine kanonischen Star-Citizen-Masse. Pivot ist im XY-Zentrum der gesamten Boundingbox auf Bodenhoehe Z0; Blender -Y wird Godot +Z vorne. Das vierfuessige statische Landegestell ist eine eigene Standhilfe. Kein Collision-, Navigation-, Licht-, Animations- oder Gameplayknoten ist enthalten. Farben sind konstante matte Materialfelder, keine Texturen; warme Duessenvertiefungen sind nicht emissiv.

Die gross geoeffneten Ziele bleiben `08_cutlass_vorne_wimmel.png` und `09_cutlass_hinten_wimmel.png` unter `docs/reports/assets/grafik-2026-11-01/`. Beide Ansichten werden als ein zusammenhaengendes Schiff interpretiert. Alle neuen Vertices wurden vom Generator konstruiert; R01-, hochpolygonale Drake-OBJ- und Stockschiff-Geometrie wurde nicht importiert. Fruehere eigene Generator-Hilfsmuster wurden ueberarbeitet. Schiffsentwurf und Name orientieren sich an Drake/Star Citizen; keine Herkunft als offizielles Spielmesh und keine Kenney-Lizenz werden behauptet.

Iteration01 ist als eigene editierbare Hauptformstudie erhalten. Sie ersetzt den duennen spitzen Bug durch eine breite stumpfere Kanzel, Brettfluegel durch profilierte massive Frontschultern und den schmalen Cargo-Quader durch schraeg gestufte Volumen. Iteration02 teilt die langen Dachschultern, senkt grosse Dach-/Fluegelfelder geometrisch ein, gibt dem geschlossenen Heck ein dreiteiliges Rampentor mit Schwelle und Scharnieren und verbindet die Motorsegmente deutlicher. Zwoelf vereinzelte Nieten und wenige Ockerflaechen greifen die letzte Nutzersteuerung auf.

Die Messung in `qa/iteration02/form_comparison.json` zeigt gegen R01: Kanzelbreite 2,196 auf 3,055 m; Laenge/Breite-Verhaeltnis 1,935 auf 1,426. Der Cargo-Koerper ist 6,235 statt 5,184 m breit; die Frontschulter hat 1,894 statt 0,407 m geometrische Hoehe. Die Kanzel ist damit gedrungener, nicht absolut kuerzer. Diese nachgewiesenen Formaenderungen bedeuten keine Nutzerabnahme. Restabstand: weiterhin saubere symmetrische Flaechen, wenig gebrochene industrielle Staffelung, vereinfachte Cowl-/Fensterkonturen, relativ breiter Mittelruecken und keine gemalten Gebrauchsspuren.

Beide erhaltenen Iterationen bestehen die vollstaendige Source-QA mit null Fehlern und null Warnungen; UV-QA ist fuer die untexturierten Farbmaterialien deaktiviert. Initiale fehlgeschlagene Rohberichte bleiben als `initial_source_raw_failed.json` erhalten. Kollabierte Bevel-Ecken wurden bereinigt, acht zunaechst schwebende Nieten buendig eingesetzt und deckungsgleiche Rampenkontaktflaechen korrigiert. Die frische GLB-Roh-QA fuer die ausgewaehlte Iteration02 meldet ebenfalls null Fehler und null Warnungen. Keine teuren Geometriepruefungen wurden ausgelassen.

Der Roundtrip erhaelt Positionen und Material-Dreieckszahlen exakt (maximaler beidseitiger Vertex-Abstand 0 m). Eine zusaetzliche Normalenpruefung deckte einen Fehler in der Reihenfolge der Exportnormalenuebertragung auf; er wurde vor dem Freeze korrigiert. Die erhaltene maximale Winkelabweichung nach Kodierung/Rekonstruktion betraegt 0,3033 Grad, innerhalb der expliziten 0,5-Grad-Pruefgrenze. Normalen werden deshalb nicht als bitgleich bezeichnet. Frische GLB-Bilder wurden geoeffnet und geprueft.

24 geoeffnete Bilder unter `qa/iteration01/` und `qa/iteration02/` zeigen Quelle, Drahtgitter, Teilfarben, Vorder-/Rueck-/Seiten-/Draufsicht und Spielabstand. R01-Vergleiche halten Kamera, Zielpunkt und orthografischen Ausschnitt gleich. Zusaetzliche EEVEE-Front-/Heckpaare (`presentation_r01_*.png`, `presentation_r02_*.png`) verwenden frische GLBs bei gleicher Kamera, weicher Beleuchtung, Belichtung und Aufloesung. Workbench und EEVEE sind getrennte Blender-Routen. Root meldet den nativen Import/Capture als erfolgt; dessen Belege und die weitere Nutzerbewertung gehoeren zum separaten Report.

`manifest.json` enthaelt Hashes, Auswahlstatus, Quelle/Export, Roh-QA, Messungen, Bilder und Grenzen. R01-Quell-/Exporthashes werden dort gegen den unveraenderten historischen Stand geprueft. Gebaeude, Buccaneer, Runtime, Report und Git-Commits wurden von diesem Teilauftrag nicht geaendert. Arbeit auf dem bestehenden, noch nicht integrierten Branch `task/grafikreferenzen-20261101`; kein Commit oder Push durch diesen Agenten.

Reproduktion aus dem Repository-Root mit Blender 5.2.3; Neubau ersetzt den eingefrorenen R02-Kandidaten und muss mit der Integration koordiniert werden:

```powershell
$cutlassBlender = 'C:/Users/bjoer/AppData/Local/Programs/Blender Foundation/Blender 5.2/blender.exe'
$cutlassScripts = 'art/frontier_illustrated_20261101/ships/pass04_r02/cutlass/generator'
& $cutlassBlender --background --factory-startup --python-exit-code 1 --python "$cutlassScripts/build_cutlass.py" -- 1
& $cutlassBlender --background --factory-startup --python-exit-code 1 --python "$cutlassScripts/review_cutlass.py" -- 1
& $cutlassBlender --background --factory-startup --python-exit-code 1 --python "$cutlassScripts/build_cutlass.py" -- 2
& $cutlassBlender --background --factory-startup --python-exit-code 1 --python "$cutlassScripts/review_cutlass.py" -- 2
& $cutlassBlender --background --factory-startup --python-exit-code 1 --python "$cutlassScripts/verify_roundtrip.py"
& $cutlassBlender --background --factory-startup --python-exit-code 1 --python "$cutlassScripts/measure_forms.py"
& $cutlassBlender --background --factory-startup --python-exit-code 1 --python "$cutlassScripts/presentation.py"
python "$cutlassScripts/finalize_manifest.py"
```

Die QA verwendet den lokalen Blender-Asset-QA-Skill, dessen Importpfad im Generator angegeben ist. `finalize_manifest.py` erst nach tatsaechlichem Oeffnen der erzeugten Bilder ausfuehren.
