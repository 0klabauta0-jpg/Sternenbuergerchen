# TASK_692 - Door Runtime Collision/LOS Contract

## Ziel / Problem
Door- und Computer-Reaktionen besitzen seit TASK_691 Runtime-Visualstates. Offene Tueren koennen dadurch sichtbar offen sein, aber Pathfinding und LOS lesen bisher weiterhin nur die statischen `TerrainTileData`-Werte.

TASK_692 legt den kleinen Contract und Runtime-Pfad an, mit dem Door-State als effektive, read-only Terrain-Uebersteuerung gelesen werden kann, ohne `TerrainMapData` zu mutieren.

## Sinnhaftigkeit / Ursache
Wenn ein Door-Proxy optisch offen ist, Bewegung und Sicht aber weiter blockieren, entsteht ein direkter Widerspruch im Spielerflow. Gleichzeitig darf die UI keine zweite Gameplay-Wahrheit erzeugen. Der State muss aus dem Runtime-/Interaction-Pfad kommen und von Registry, Pathfinder und LOS als effektiver Zustand gelesen werden.

## Umfang
- Neuer Service `MissionInteractionDoorRuntimeCollisionLOS`.
- Door-Reaction-Eintraege werden in effektive Runtime-Tile-Overrides uebersetzt.
- `TerrainRegistry` speichert Runtime-Overrides getrennt von `TerrainTileData`.
- Pathfinder und `LineOfSightSystem` lesen effektive Walkability/LOS/Object-Height ueber die Registry.
- Verifier prueft offen/geschlossen fuer Pathfinding, LOS und Nicht-Mutation der statischen Tile-Daten.

## Nicht-Ziele
- Kein neues Door-State-System.
- Kein Asset-Swap-System.
- Kein automatisches Oeffnen/Schliessen aus UI-Klicks.
- Keine Mutation von `TerrainMapData`.
- Kein Mission-Flow-Rewrite.

## Relevante Contracts / Dokumente
- `docs/dev/mission_interaction_point_contract.md`
- `docs/tasks/TASK_691_mission_interaction_runtime_visual_assets.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`

## Akzeptanzkriterien
- Offene Door liefert `walkable_override = true`, `blocks_los_override = false`, `object_height_override = 0`.
- Halbe/geschlossene Door bleibt fuer Bewegung und LOS blockierend.
- `TerrainRegistry.is_walkable()`, `blocks_los_at_grid()` und `get_object_height_at_grid()` liefern effektive Werte.
- `TerrainPathfinder` und `LineOfSightSystem` nutzen diese effektiven Werte.
- Statische Tile-Werte bleiben unveraendert.
- Snapshot und Manifest markieren `read_only = true`, `ui_sets_gameplay_truth = false` und `terrain_map_data_mutated = false`.

## Betroffene Dateien
- `scripts/mission/mission_interaction_door_runtime_collision_los.gd`
- `scripts/mission/mission_interaction_object_reaction.gd`
- `scripts/terrain/terrain_registry.gd`
- `scripts/terrain/terrain_pathfinder.gd`
- `scripts/core/los_system.gd`
- `scripts/tests/task_692_door_runtime_collision_los_contract.gd`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_692_door_runtime_collision_los_contract.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_691_mission_interaction_runtime_visual_assets.gd`
- `git diff --check`

## Risiken / offene Punkte
- TASK_692 erzeugt den effektiven Runtime-Pfad, bindet aber noch keinen echten Door-Use-Command an das Oeffnen/Schliessen.
- Wenn Door-Overrides spaeter pro Frame neu gesetzt werden, muss der Aufrufer dirty-/statebasiert arbeiten.
- Der echte Fenster-Sichtlauf bleibt weiter offen.
