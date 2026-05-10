# TASK_298 - Editor Terrain Visual Playability Smoke

## Ziel
Nach TASK_292 bis TASK_297 soll ein konzentrierter Playability- und Visual-Smoke sicherstellen, dass Hoehen, Cliffs, Props, Licht, Toolbar, Palette und rechter Inspector zusammen bedienbar bleiben.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_292 - Editor Hill Cliff Grid Depth Repair
- TASK_293 - Editor Lighting Shadow Readability Pass
- TASK_294 - Nature Prop Scale Cover Visibility Repair
- TASK_295 - Map Editor Paint Toolbar Tools Polish
- TASK_296 - Map Editor Palette Taxonomy Space Station Assets
- TASK_297 - Map Editor Inspector Collapsible Panels

## Kontext
Die angesprochenen Probleme haengen zusammen: ein Grid-Fix kann Selection verschlechtern, groessere Props koennen Kanten verdecken, bessere Schatten koennen kleine Props verschwinden lassen, und neue Palette/Toolbar kann wieder Bedienbarkeit kosten. Deshalb braucht der Abschluss eine gebuendelte Pruefung.

## Umfang
1. Automatisierter Smoke:
   - Editor-Szene instanziert.
   - Referenz-Map laedt.
   - Toolbar-Tools wechseln.
   - Palette-Gruppen vorhanden.
   - Tile Properties bleiben sichtbar.
   - Collapse Panels funktionieren.
   - Render-Snapshot meldet Grid, Selection, Height Edges, Props, Light.
2. Visuelle Checkliste:
   - Grid laeuft nicht durch hohe Waende/Rocks.
   - H=0/H=1/H=2 sind lesbar.
   - Cliff/Ramp korrekt.
   - Cactus/Bush/Tree/Rock sichtbar.
   - Licht/Schatten verbessern Tiefe.
   - Space-Station-Assets sinnvoll skaliert.
3. Bediencheck:
   - Boden malen loescht keine Objekte.
   - Eraser loescht nur erwartete Ebene.
   - Select zeigt klare Auswahl.
   - Undo fuer Brush/Height/Eraser.
   - Right panel bleibt erreichbar.
4. Performance:
   - Keine neue Warnungsflut.
   - Node-/Draw-Budget gegen TASK_170/TASK_255 pruefen.

## Nicht-Ziele
- Keine neuen Features im Smoke selbst.
- Kein Ersatz fuer finale manuelle Art-Direction.
- Kein Commit/Push ohne explizite Freigabe, falls das aktuelle Arbeitsmodell das so vorsieht.

## Akzeptanzkriterien
- [x] Automatisierter TASK_298-Smoke laeuft gruen.
- [ ] Manuelle Sichtcheckliste ist ausgefuellt.
- [x] Keine Regression bei TASK_183, TASK_185, TASK_229, TASK_252, TASK_253, TASK_254.
- [x] Performance-/Warning-Gate bleibt akzeptabel oder dokumentiert konkrete Follow-ups.
- [x] Offene optische Restpunkte sind als kleine Folge-Tasks dokumentiert, nicht im Code versteckt.

## Erwartete Dateien
- `scripts/tests/task_298_editor_terrain_visual_playability_smoke.gd`
- `docs/manual_checks/editor_terrain_visual_playability_smoke.md`
- optional `docs/reports/editor_terrain_visual_recovery_report.md`
- `docs/tasks/TASK_298_editor_terrain_visual_playability_smoke.md`

## Lokale Pruefung
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_298_editor_terrain_visual_playability_smoke.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_183_editor_hill_authoring_verifier.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_185_hill_visuals_edge_lines_verifier.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_229_map_editor_usability_authoring_pass.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_252_nature_cliff_hill_edge_visual_mapping.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_253_nature_ground_surface_editor_palette_pass.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_254_nature_trees_rocks_vegetation_cover_props.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_170_performance_warning_gate_verifier.gd`
- [ ] `git diff --check`

## Risiken
- Wenn der Smoke zu viel auf einmal repariert, wird er selbst wieder ein Feature-Task. Er soll nur pruefen und kleine Restpunkte dokumentieren.
- Visuelle Akzeptanz bleibt teilweise manuell; der Headless-Test kann Lesbarkeit nur indirekt pruefen.

## Naechster Schritt
Nach TASK_298 koennen weitere Editor-Folgearbeiten wieder einzeln geschnitten werden, z.B. NPC-Platzierung im Editor oder Mehrtile-Gebaeude-Snapping.
