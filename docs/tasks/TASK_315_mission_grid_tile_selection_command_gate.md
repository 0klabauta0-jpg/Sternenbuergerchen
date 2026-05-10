# TASK_315 - Mission Grid Tile Selection Command Gate

## Ziel
In der Live-Mission muessen Terrain-Grid und Tile-Auswahl sichtbar sein. Zielbefehle wie Move, Take, Hold/Defend und Flank duerfen erst ueber den UI-Pfad rausgehen, wenn ein konkretes Kartentile ausgewaehlt ist.

## Status: IMPLEMENTIERT

## Kontext
Im Mission-Sichtcheck war das Grid auf dem hellen Terrain kaum erkennbar. Gleichzeitig konnte die Command Matrix Befehle gegen einen alten TargetMarker absetzen, ohne dass die Karte ein aktuell ausgewaehltes Tile zeigte.

## Umfang
1. Grid-Lesbarkeit:
   - Mission-Grid nutzt einen kontrastreicheren Cyan-Highlight-Layer mit dunkler Schattenlinie.
   - Der Grid-Layer bleibt depth-tested und nah an der Tile-Oberflaeche.
2. Tile-Auswahl:
   - Die Mission setzt beim Start ein Default-Tile am Objective.
   - Linksklick auf freie Karte setzt die Tile-Auswahl, ohne die Fireteam-Auswahl wegzuloeschen.
   - Target- und LZ-Picking setzen ebenfalls die aktuelle Tile-Auswahl.
3. Command Gate:
   - Move, Take, Defend und Flank deklarieren `requires_tile_selection`.
   - Ohne Tile sind die Command-Buttons gesperrt und die Hierarchie meldet `select a map tile`.
   - Beim Ausfuehren wird das ausgewaehlte Tile als Command-Ziel verwendet.
4. Verifier:
   - Prueft Grid-Snapshot, Default-Auswahl, Button-Gate und Zielposition eines akzeptierten Move-Befehls.

## Nicht-Ziele
- Keine neue Gameplay-Wahrheit im UI.
- Kein Umbau von SimulationRoot, RuntimeLeader oder TerrainRegistry.
- Kein neues Area-Order-System.

## Akzeptanzkriterien
- [x] Mission-Grid ist im Snapshot kontrastreicher und bleibt depth-tested.
- [x] Beim Missionsstart ist genau ein Tile ausgewaehlt.
- [x] Klick-/Pick-Pfade aktualisieren die sichtbare Tile-Auswahl.
- [x] Move, Take, Defend und Flank verlangen ein ausgewaehltes Tile.
- [x] Ohne Tile wird ein Zielbefehl sichtbar geblockt.
- [x] Mit Tile nutzt der Befehl die ausgewaehlte Tile-Position.

## Erwartete Dateien
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/mission/mission_primary_view_bridge.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/ui/mission_command_hierarchy_contract.gd`
- `scripts/tests/task_315_mission_grid_tile_selection_command_gate.gd`
- `docs/tasks/TASK_315_mission_grid_tile_selection_command_gate.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_315_mission_grid_tile_selection_command_gate.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_292_editor_hill_cliff_grid_depth_repair.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_160_tactical_playability_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_275_command_button_hierarchy_arrangement_overhaul.gd`
- [x] `git diff --check`

## Risiken
- Die Tile-Auswahl ist bewusst Planungs-/UI-State und darf nicht als SimulationRoot-Wahrheit ausgeweitet werden.
- Die staerkeren Grid-Linien sind ein Lesbarkeits-Pass; finale Art-Direction braucht weiter einen manuellen FullHD-Sichtcheck.
