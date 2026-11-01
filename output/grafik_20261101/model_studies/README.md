# Cutlass / Buccaneer: isolierte Materialstudien

Stand: 01.11.2026. Dies sind native Blender-Materialproben auf den lokalen OBJ-Schiffquellen. Die Grundgeometrie wurde nicht ueberarbeitet oder vereinfacht. Die Originaldateien unter `C:/Users/bjoer/3D Objects/.../DRAKE/` wurden nur gelesen.

Die neuesten Nutzerwuensche "mehr im WimmelBildstil" und "ein bisschen weniger Details" verlangen in 3D weiterhin eine eigene Vereinfachung. Diese Materialproben zeigen eine vorangehende Farb-/Flaechenentscheidung und sind kein vollstaendig getroffenes neues Stilziel.

## Tatsaechliche Aenderung

- Gemeinsame Normalisierung auf nominal 37.50m Cutlass bzw. 15.25m Buccaneer; keine Behauptung ueber autoritative Original-OBJ-Einheiten.
- Slate-/Teal-Huelle, warme Elfenbein-Flaechen, kleine Ockerakzente, dunkle Cockpitflaechen und begrenzte warme Triebwerkdetails.
- Keine Mesh-Optimierung, LODs, Textur-/UV-Erstellung, Kollision, Navigation, Animation, produktive Szene oder Gameplay-Aenderung.
- Der Ausgangs-OBJ enthaelt keine Materialinformation. Der neutrale Vergleich ist neu erzeugtes Clay-Shading und nicht die urspruengliche Spielgrafik.

## Artefakte und Reproduktion

Je Schiff: `normalized_source.blend` (Orientierungsaudit), `neutral_source.blend` (PBR-Vergleichsszene), `material_candidate.blend` (editierbare Materialprobe), `material_candidate.glb`, `manifest.json`, `qa_check_raw.json` und Orientierungsbilder. `study_index.json` ordnet alle Vergleichsbilder zu. Die Bilder liegen unter `docs/reports/assets/grafik-2026-11-01/ship_studies/`.

Generatoren unter `../generator/`:

1. `create_ship_studies.py`: Blender 5.2.3, `-- --final` erstellt native Vergleiche und Exporte; ohne `--final` die Orientierungsansichten.
2. `verify_ship_wire.py`: echte Dreieckskanten mit temporaerem baryzentrischem Shader, ohne Quelle/Kandidat zu veraendern.
3. `godot_ship_import_smoke.gd`: frisches isoliertes Godot-4.6.2-Projekt mit Kopien beider GLBs und Script als `res://smoke.gd`; zuerst `--headless --editor --import`, dann nativer OpenGL-Lauf mit `--script res://smoke.gd --rendering-method gl_compatibility --resolution 1280x900`. Projekt fuer diese Pruefung: `%TEMP%/codex_ship_engine_smoke_20261101`.
4. `finalize_ship_studies.py`: technische Importassertions, Bildhashes, Index und Sichtpruefgrenzen.

`blender_studies_r03.log`, `blender_wire.log`, `godot_fresh_import.log` und die nativen Godot-Logs behalten die ausgefuehrten Pruefungen. Erste Beleuchtungs-/Maskenversuche in aelteren Blender-Logs sind Vorlaeufe und keine eigene Abnahme.

## Gepruefte Werte

| Schiff | Vertices Blender | Dreiecke Blender/GLB/Godot | Abmessungen Blender X/Y/Z in m | Materialien Godot |
|---|---:|---:|---|---:|
| Cutlass | 149983 | 265435 | 27.4504 / 37.5000 / 10.7465 | 6 |
| Buccaneer | 77966 | 132384 | 16.6336 / 15.2500 / 3.9056 | 6 |

Identische Normalisierungsgeometrie vor/nach der Materialzuordnung ist per Vertex-/Topologie-SHA nachgewiesen. Godot erhaelt 1 Mesh mit 6 Surfaces/Materialien je Schiff, keine Animation/Skins; Front in Blender +Y, nach glTF in Godot -Z. Der Pivot ist der Bounds-Mittelpunkt und kein Boden-/Landing-Gear-Pivot.

## Sichtpruefung und offene Fehler

Blender-Vorder-/Heckansichten, Abstandsbilder und echte Wire-Ansichten wurden geoeffnet. Die groben Materialmassen sind erkennbar; feine Source-Greebles und stellenweise unruhige Maskenkanten bleiben sichtbar. Das Abstandspaar ist ein illustrativer Abstandstest, kein produktiver Gameplay-Kameratest.

Godot wurde in einem frischen isolierten Temp-Projekt importiert. Die 4 tatsaechlich erzeugten nativen Vorder-/Heckaufnahmen wurden geoeffnet. Bounds, Orientierung, Pivot und Materialnamen stimmen. Schwarze Backface-Bereiche und gezacktes Shading zeigen aber vorhandene Source-Normalen-/Topologiefehler. Der visuelle Runtime-Gate ist NICHT bestanden.

Der unveraenderte `qa_check_raw.json` meldet fuer beide `pass: false`:

- Cutlass: 301 geschlossene Inseln nach innen orientiert, 16 inkonsistente Kanten, 621 degenerierte Flaechen, 257 Null-Laengen-Kanten. 5 nichtmanifold Kanten, 30729 offene Kanten, 494 doppelte Vertices.
- Buccaneer: 421 geschlossene Inseln nach innen orientiert, 1430 inkonsistente Kanten, 6 degenerierte Flaechen. 748 nichtmanifold Kanten, 18395 offene Kanten, 321 doppelte Vertices.
- Teure Z-Fighting-/Floating-Paarpruefung oberhalb von 100000 Dreiecken uebersprungen. Leere Ergebnisarrays sind deshalb kein Nachweis von Fehlerfreiheit. UV-Pruefung deaktiviert; beide Quellen besitzen 0 UV-Layer, reine konstante Materialien benoetigen hier keine UVs.
- QA-Bodenhinweis ist fuer die frei schwebende, mittig zentrierte Schiffstudie bewusst akzeptiert. Die uebrigen Defekte wurden zur Quellen-/Geometrieerhaltung nicht still repariert.

**Ergebnis:** technische Datei-/Importpruefung mit korrekten Counts bestanden; Source-Mesh-QA und visuelle Runtime-Abnahme fehlgeschlagen/offen. Keine aktive Spieluebernahme und keine Runtime-Bereitschaft.
