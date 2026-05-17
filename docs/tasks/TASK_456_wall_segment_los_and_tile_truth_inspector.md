# TASK_456 - Wall Segment LOS And Tile Truth Inspector

## Ziel / Problem
Mauern sollen nicht mehr als ganze Tile-LOS-Blocker wirken, wenn die Sichtlinie nur entlang der Wand laeuft oder auf derselben Wandseite bleibt. Gleichzeitig soll ein selektierter Tile-Inspector direkt zeigen, welche Terrain-Wahrheit fuer das ausgewaehlte Tile gilt.

## Sinnhaftigkeit / Ursache
TASK_454 und TASK_455 haben die Segmentregel auditierbar und sichtbar vorbereitet. Solange der aktive `LineOfSightSystem`-Pfad aber weiter ganze Wandtiles blockt, bleiben Combat, FoW, Overwatch und LOS-Debug fachlich ungenau. Der Inspector reduziert zusaetzlich das Rueckfragen-Rauschen beim Map- und Fireteam-Playtest.

## Umfang
- `LineOfSightSystem` nutzt Wand-/Kanten-Segmente fuer gerichtete Wandtypen.
- Mission-/Fire-Sector-LOS-Debug nutzt dieselbe Segmententscheidung fuer sichtbare Blockerlinien.
- Nicht-Wand-LOS-Blocker bleiben Whole-Tile-Blocker.
- Terrain-Truth-Policy meldet explizit, dass Combat-LOS die Segmentregel nutzt.
- MapEditor bekommt einen selektiven Tile-Truth-Inspector fuer das ausgewaehlte Tile.
- Headless-Test fuer Segment-LOS, Inspector-Snapshot, Inspector-Label und Doku-Verankerung.

## Nicht-Ziele
- Kein Umbau von Pathfinding oder Walkability.
- Kein Terrain3D-Prototyp.
- Keine Aenderung an Fireteam-Befehlen, Formationen oder Combat-Treffern.
- Kein vollstaendiger Tooltip-/Popup-Editor fuer alle Tile-Werte.

## Relevante Contracts / Dokumente
- `docs/dev/terrain_truth_visual_audit_contract.md`
- `docs/tasks/TASK_454_terrain_truth_visual_audit.md`
- `docs/tasks/TASK_455_terrain_truth_editor_overlay_visibility.md`
- `docs/tasks/TASK_372_mission_los_debug_overlay_toggle.md`
- `docs/tasks/TASK_379_mapeditor_tile_property_grid_overlay.md`

## Akzeptanzkriterien
- Eine Sichtlinie, die ein Wandsegment wirklich kreuzt, wird durch `LineOfSightSystem` blockiert.
- Eine Sichtlinie entlang derselben Wandseite bleibt frei, obwohl das Wandtile `blocks_los = true` hat.
- Nicht-Wand-LOS-Blocker blocken weiterhin als ganzes Tile.
- `TerrainTruthAudit.build_policy_snapshot()` meldet `combat_los_uses_segment_policy = true`.
- Der MapEditor zeigt fuer das selektierte Tile ein Terrain-Truth-Inspector-Label mit Blocker-Art, Layer-State und Segmentanzahl.
- Der Inspector ist read-only und schreibt keinen Gameplay-State.

## Betroffene Dateien
- `docs/tasks/TASK_456_wall_segment_los_and_tile_truth_inspector.md`
- `docs/dev/terrain_truth_visual_audit_contract.md`
- `scripts/core/los_system.gd`
- `scripts/terrain/terrain_registry.gd`
- `scripts/terrain/terrain_truth_audit.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/editor/map_editor.gd`
- `scripts/tests/task_456_wall_segment_los_and_tile_truth_inspector.gd`
- `scripts/tests/task_454_terrain_truth_visual_audit.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_456_wall_segment_los_and_tile_truth_inspector.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_455_terrain_truth_editor_overlay_visibility.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_454_terrain_truth_visual_audit.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_379_mapeditor_tile_property_grid_overlay.gd`
- `git diff --check`

## Risiken / offene Punkte
- Die Segmentregel nutzt weiterhin die bestehende Grid-Line-Auswahl. Sie wird fachlich genauer fuer Wandkanten, ersetzt aber noch keinen sub-tile Raycaster fuer jede denkbare Geometrie.
- Mission-Visual-LOS-Overlays koennen spaeter noch expliziter Segmentdetails anzeigen; die Gameplay-Entscheidung laeuft aber ueber `LineOfSightSystem`.
