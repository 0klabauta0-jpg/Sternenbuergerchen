# TASK_292 - Editor Hill Cliff Grid Depth Repair

## Ziel
Hoehen, Bodenplatten, alte Cliffs/Rampen und Editor-Grid sollen im 2.5D-Editor wieder raeumlich stimmig wirken. Grid-/Hoehenlinien duerfen nicht sichtbar durch hohe Waende, Rocks, Cliffs oder andere blockierende Objekte laufen.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_291 - Editor Terrain Visual Recovery Coordinator
- TASK_182 - Terrain Hill Rules Contract
- TASK_185 - Hill Visuals and Edge Lines Patch
- aktuelle `TerrainMap3DView`
- `data/terrain_3d_asset_mapping.json`

## Kontext
Im Screenshot schneiden gelbe Grid-Linien durch Waende und Rocks. Die H=2-Plattform wirkt wie ein aufgesetzter Deckel, waehrend Cliff-Unterbau, Bodenplatten-Dicke und Wandhoehe optisch nicht mehr zusammenpassen. Der alte einzelne Cliff links wirkt in der Richtung plausibel, die aktuelle Hoehenkante dagegen nicht.

## Umfang
1. Hoehen-Massstab pruefen:
   - `height_step`, Bodenplatten-Dicke und Standard-Wandhoehe gegeneinander kalibrieren.
   - Zielbild: Eine H=2-Bodenplatte soll eine sichtbare Dicke haben; ihre Unterkante soll ungefaehr auf der passenden Oberkante einer Standardmauer liegen.
   - H=1 und H=2 muessen klar unterscheidbar sein, ohne dass Objekte halb im Boden stecken.
2. Cliff-/Ramp-Anker reparieren:
   - Alte Space-Kit-Cliffs/Rampen als Hauptreferenz nutzen, solange Nature-Cliffs nicht sauber kalibriert sind.
   - Cliffs/Rampen fuellen die Hoehendifferenz zwischen niedrigerem Nachbar und oberem Tile.
   - Die Datenentscheidung bleibt auf dem hoeheren Tile, aber das sichtbare Cliff-/Ramp-Modell wird auf dem niedrigeren Nachbartile verankert; Ecken sitzen auf dem diagonalen unteren Aussentile.
   - Cliffs stehen nicht oben auf dem Plateau.
   - Rampen duerfen nur bei `edge_type = slope` verwendet werden.
3. Grid-/Hoehenlinien depth-aware machen:
   - Linien liegen auf der jeweiligen Tile-Oberseite, aber werden von 3D-Objekten verdeckt.
   - Linien laufen nicht durch hohe Mauern, Rocks, Cactus/Bush-Blocker oder Cliff-Waende.
   - Selection darf sichtbar bleiben, aber nicht als gelbes Gitternetz alles ueberdecken.
   - Optional: eigenes Grid mit `NoDepthTest=false` oder getrennte Liniensegmente, die vor Blockern enden.
4. Referenz-Fixture:
   - H=0/H=1/H=2, Wand, Rock, Cliff, Ramp, Sand/Rock/Road-Surface.
   - Mindestens ein Fall, bei dem eine Linie hinter einer Wand verschwinden muss.
5. Verifier:
   - Render-Snapshot prueft Hoehenkante: `base_y < top_y`, korrekte Edge-Rolle, kein Ramp-Modell bei Cliff.
   - Grid-Material oder Grid-Segmente pruefen, dass sie nicht als immer-vorne Overlay durch Objekte gezeichnet werden.
   - Wand-/Rock-Objekte sitzen auf der Tile-Oberseite.

## Nicht-Ziele
- Keine neuen Terrain-Felder.
- Keine Gameplay-Regel-Aenderungen fuer LOS, Cover oder Movement.
- Keine komplette Uebernahme der Nature-Cliffs, solange sie optisch nicht passen.
- Keine finale UI-Neugestaltung.

## Akzeptanzkriterien
- [x] H=0, H=1 und H=2 wirken im Editor raeumlich stabil und wiederholbar.
- [x] Alte Cliffs/Rampen schliessen Hoehenkanten, statt oben drauf zu stehen.
- [x] Grid-Linien werden von hohen Waenden/Rocks/Cliffs verdeckt oder sichtbar unterbrochen.
- [x] Eine Standardmauer und eine H=2-Bodenplatte haben eine nachvollziehbare gemeinsame Hoehenreferenz.
- [x] Sand/Rock/Road bleiben auf Hoehen lesbar.
- [x] Ein neuer oder erweiterter Verifier deckt die Regression aus dem Screenshot ab.
- [ ] Manueller Sichtcheck bestaetigt Rotation, Zoom und Pitch.

## Erwartete Dateien
- `scripts/terrain/terrain_map_3d_view.gd`
- `data/terrain_3d_asset_mapping.json`
- optional `scripts/terrain/terrain_map_renderer.gd`
- optional `maps/editor_terrain_visual_recovery_reference.json`
- `scripts/tests/task_292_editor_hill_cliff_grid_depth_repair.gd`
- `docs/manual_checks/editor_hill_cliff_grid_depth_checklist.md`
- `docs/tasks/TASK_292_editor_hill_cliff_grid_depth_repair.md`

## Lokale Pruefung
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_292_editor_hill_cliff_grid_depth_repair.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_183_editor_hill_authoring_verifier.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_185_hill_visuals_edge_lines_verifier.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_252_nature_cliff_hill_edge_visual_mapping.gd`
- [ ] Manueller Editor-Sichtcheck mit Screenshot.
- [ ] `git diff --check`

## Risiken
- Ein zu starkes immer-vorne Grid macht den Editor bedienbar, aber zerstoert die 3D-Lesbarkeit.
- Ein zu stark depth-tested Grid kann hinter Bodenplatten verschwinden; Selection braucht ggf. einen eigenen, dezenteren Hover-/Selection-Kanal.
- Kalibrierung nach Screenshot darf nicht die gespeicherten Map-Daten veraendern.

## Naechster Schritt
Nach stabilem Hoehen-/Grid-Fix kann TASK_293 Licht und Schatten fuer die Lesbarkeit einstellen.
