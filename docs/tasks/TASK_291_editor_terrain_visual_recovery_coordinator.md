# TASK_291 - Editor Terrain Visual Recovery Coordinator

## Ziel
Die aktuelle Editor-2.5D-Darstellung von Hoehen, Klippen, Rampen, Bodenplatten, Grid-Linien und platzierbaren Objekten soll wieder auf eine klare visuelle Wahrheit zurueckgefuehrt werden. Dieser Task ist der Vorkoordinator fuer TASK_292 bis TASK_298 und verhindert, dass jeder Folgepatch eine eigene Hoehenlogik erfindet.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_182 - Terrain Hill Rules Contract
- TASK_183 - Editor Hill Authoring Patch
- TASK_185 - Hill Visuals and Edge Lines Patch
- TASK_229 - Map Editor Usability Authoring Pass
- TASK_251 bis TASK_255 - Nature Kit Terrain Pass
- der aktuelle User-Screenshot mit durch Waende/Felsen sichtbaren gelben Grid-Linien und falsch wirkenden Cliffs

## Kontext
Der Editor ist gerade taktisch schwer lesbar:

- Gelbe Boden-/Grid-Linien laufen sichtbar durch hohe Mauern und Rocks. Das zerstoert den 3D-Eindruck.
- Nature Cactus, Bush Cover und aehnliche Props sind zu klein oder zu schlecht sichtbar.
- Licht/Schatten setzen relevante Kartenbereiche in unguenstige Dunkelheit.
- Hoehen, Bodenplattendicke, Cliff-Unterbau und Mauern wirken nicht mehr wie das fruehere, bessere Setup.
- Die alten Cliffs wirkten links im Screenshot grundsaetzlich plausibel, aber aktuelle gestreckte/neu verankerte Varianten passen nicht sauber zu H=1/H=2.

## Kanonische Zielannahmen fuer die Folge-Tasks
Diese Annahmen muessen in TASK_292 anhand Code, alter Docs und Sichtcheck bestaetigt oder bewusst korrigiert werden:

- `height_level` bleibt Gameplay-Wahrheit: 0, 1, 2.
- Ein Standard-Wandobjekt steht auf der jeweiligen Tile-Oberseite und repraesentiert ungefaehr eine Hoeheneinheit.
- Fuer H=2 soll die Unterkante der sichtbaren oberen Bodenplatte ungefaehr mit der Oberkante einer Standardmauer auf H=0/H=1 vergleichbar sein; die Bodenplatte selbst hat sichtbare Dicke.
- Cliffs/Rampen fuellen die Seite zwischen niedrigerem Nachbarn und erhoehtem Tile. Sie stehen nicht dekorativ oben auf dem Plateau.
- Grid-/Hoehenlinien sind Editor-Hilfen, aber muessen im 3D-Bild hinter hohen Objekten, Waenden, Rocks, Cliffs und sichtbaren Kanten verschwinden oder deutlich darunter liegen.
- Gameplay-Regeln fuer Walkability, LOS und Cover duerfen nicht aus der Optik abgeleitet werden; die Visuals muessen die bestehenden Daten darstellen.

## Umfang
1. Audit der relevanten Dateien:
   - `scripts/terrain/terrain_map_3d_view.gd`
   - `scripts/terrain/terrain_map_renderer.gd`
   - `data/terrain_3d_asset_mapping.json`
   - `data/terrain_object_catalog.json`
   - `data/nature_kit_asset_catalog.json`
   - `data/space_setpiece_catalog.json`
   - `docs/dev/terrain_height_hill_rules.md`
   - bestehende TASK_182/TASK_183/TASK_185/TASK_252/TASK_253/TASK_254 Docs und Verifier
2. Kleine Referenz-Map definieren:
   - H=0 Boden
   - H=1 Plateau mit Wand und Rock
   - H=2 Plateau mit Bodenplattendicke
   - Cliff-Seite
   - Rampen-Seite
   - Nature Cactus/Bush/Tree/Rock
   - Grid, Selection und Tile-Property-Auswahl
3. Entscheiden, welche visuellen Werte zentral werden:
   - `height_step`
   - Bodenplatten-Dicke
   - Wandhoehe
   - Cliff-/Ramp-Scale und Y-Anker
   - Objekt-Scale fuer Nature-Props
   - Grid-Render-Modus und Occlusion-Verhalten
   - Licht-Rotation und Schattenstaerke
4. Folge-Tasks in dieser Reihenfolge festziehen:
   - TASK_292: Hoehen-/Cliff-/Grid-Depth-Fix
   - TASK_293: Licht, Schatten und Prop-Sichtbarkeit
   - TASK_294: Nature-Prop-Scale und Cover-Lesbarkeit
   - TASK_295: Editor-Toolbar Paint-like Tools
   - TASK_296: Tile-Palette Taxonomie und Space-Station-Kit
   - TASK_297: rechter Inspector mit einklappbaren Bereichen
   - TASK_298: Playability-/Visual-Smoke fuer den Gesamtpass

## Nicht-Ziele
- Keine neuen Gameplay-Hoehenstufen.
- Keine neue Pathfinding- oder LOS-Logik.
- Kein kompletter Editor-Neubau.
- Kein Asset-Massenimport ohne kuratierte, projektlokale Subsets.

## Akzeptanzkriterien
- [x] Ein kurzer Diagnosebericht benennt, warum Grid-Linien aktuell durch Waende/Rocks laufen.
- [x] Der visuelle Hoehenkanon ist in einem Dev-Dokument oder direkt in TASK_292 eindeutig festgehalten.
- [x] Eine kleine Referenz-Map oder Fixture ist fuer alle Folge-Verifier wiederverwendbar.
- [x] Die Folge-Tasks haben klare Abhaengigkeiten und pruefbare Akzeptanzkriterien.
- [x] Alte gute Cliff-/Ramp-Referenzen werden nicht ueberschrieben, sondern als Vergleich dokumentiert.

## Erwartete Dateien
- `docs/tasks/TASK_291_editor_terrain_visual_recovery_coordinator.md`
- optional `docs/dev/editor_terrain_visual_recovery_contract.md`
- optional `maps/editor_terrain_visual_recovery_reference.json`
- optional `scripts/tests/task_291_editor_terrain_visual_recovery_coordinator.gd`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_183_editor_hill_authoring_verifier.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_185_hill_visuals_edge_lines_verifier.gd`
- [ ] Manueller Godot-Screenshot der Referenz-Map vor Folgepatches.
- [ ] `git diff --check`

## Risiken
- Wenn der Koordinator die Hoehengeometrie nicht hart genug festlegt, entstehen erneut scheinbar kleine Visual-Fixes, die die Lesbarkeit verschlechtern.
- Grid-Linien sind hilfreich, duerfen aber nicht als dauerhafte Vordergrund-Deko alles ueberzeichnen.
- Nature-Kit-Props muessen sichtbar sein, duerfen aber keine falschen Cover-/LOS-Werte vortaeuschen.

## Naechster Schritt
TASK_292 startet mit dem eigentlichen Hoehen-, Cliff- und Grid-Depth-Reparaturpatch.
