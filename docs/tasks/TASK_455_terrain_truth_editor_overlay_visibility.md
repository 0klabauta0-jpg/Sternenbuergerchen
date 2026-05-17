# TASK_455 - Terrain Truth Editor Overlay Visibility

## Ziel / Problem
Der Terrain-Truth-Audit aus TASK_454 liefert die richtigen Diagnosewerte, ist aber im Godot-Fenster noch zu indirekt. Fuer den naechsten Fireteam-/Terrain-Pass sollen Boden, Objektlayer, Wandsegmente und Blocker-Art direkt im bestehenden MapEditor-DBG-Overlay lesbar sein.

## Sinnhaftigkeit / Ursache
Die aktuellen Playtest-Fragen drehen sich darum, ob Buesche wirklich auf Bodentiles sitzen, ob Mauern als Kante oder als ganzes Tile blocken und ob Hoehen-/LOS-Signale zur Runtime-Wahrheit passen. Ohne sichtbares Overlay bleibt das Debugging zu sehr JSON-/Snapshot-Arbeit.

## Umfang
- MapEditor-Tile-Property-Overlay zeigt kompakte Terrain-Truth-Labels.
- Wandsegment-Kandidaten werden als gelbe Kantenlinie im Tile sichtbar.
- Drawn Nodes bekommen die wichtigsten Auditwerte als Meta-Daten fuer Tests und spaetere Dev-Panels.
- Headless-Test fuer sichtbare Segmentlinien, Labels, Meta-Daten und Snapshot-Werte.

## Nicht-Ziele
- Keine Umstellung des aktiven Combat-/Mission-LOS-Pfads.
- Keine Aenderung an Pathfinding, Combat oder Fireteam-Behavior.
- Kein Terrain3D-Prototyp.
- Kein Umbau der Drillmap.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_454_terrain_truth_visual_audit.md`
- `docs/dev/terrain_truth_visual_audit_contract.md`
- `docs/tasks/TASK_379_mapeditor_tile_property_grid_overlay.md`
- `docs/dev/editor_terrain_visual_recovery_contract.md`

## Akzeptanzkriterien
- Wandtiles mit Segmentdaten zeichnen im DBG-Overlay mindestens eine sichtbare Segmentlinie.
- Overlay-Labels unterscheiden kompakt zwischen Objekt-Hoehe, Cover, Whole-Tile-LOS und Wandsegment-Kandidaten.
- Objektlayer auf Ground werden im Draw-Node als `object_layer_state = object_on_ground` sichtbar.
- Draw-Node-Metadaten enthalten `blocker_type`, `wall_segment_count`, `object_layer_state`, `truth_label` und `truth_issue_count`.
- Der Overlay-Snapshot bleibt `visual_only` und setzt keinen Gameplay-State.

## Betroffene Dateien
- `docs/tasks/TASK_455_terrain_truth_editor_overlay_visibility.md`
- `docs/dev/terrain_truth_visual_audit_contract.md`
- `scripts/editor/map_editor_tile_property_overlay.gd`
- `scripts/editor/map_editor.gd`
- `scripts/tests/task_455_terrain_truth_editor_overlay_visibility.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_455_terrain_truth_editor_overlay_visibility.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_454_terrain_truth_visual_audit.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_379_mapeditor_tile_property_grid_overlay.gd`
- `git diff --check`

## Risiken / offene Punkte
- Das Overlay ist bewusst kompakt. Fuer volle Tile-Werte braucht es spaeter ein Dev-Panel oder Tooltip-artiges Detailfenster.
- Die Segmentlinien zeigen Kandidaten aus der neuen Auditregel, nicht schon die aktive Runtime-LOS-Entscheidung.
