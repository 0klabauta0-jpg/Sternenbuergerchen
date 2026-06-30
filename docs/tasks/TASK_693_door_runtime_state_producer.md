# TASK_693 - Door Runtime State Producer

## Ziel / Problem
TASK_692 hat den effektiven Door-Collision-/LOS-Contract gebaut. Es fehlte aber noch der Producer, der den vorhandenen Mission-Interaction-Runtime-State wirklich in diese TerrainRegistry-Overrides schreibt.

## Sinnhaftigkeit / Ursache
Spielerisch ist es widerspruechlich, wenn eine Door-Reaktion visuell offen ist, Pathfinding und LOS aber keinen Runtime-State anwenden. Gleichzeitig darf die UI keine Door-Wahrheit setzen. Der Producer muss deshalb am bestehenden Mission-Interaction-Snapshot-Pfad haengen und die `TerrainRegistry` nur mit effektiven Runtime-Overrides aktualisieren.

## Umfang
- `MissionTacticalSandboxController` exportiert `get_mission_interaction_door_runtime_collision_los_snapshot()`.
- `MissionTacticalSandboxController.apply_mission_interaction_door_runtime_collision_los_snapshot()` wendet Door-Overrides auf die `TerrainRegistry` an.
- Der Apply-Pfad nutzt einen Override-Fingerprint und setzt gleiche Overrides nicht erneut.
- Der 3D-Mission-Status-Sync exportiert Door-Override-Diagnosewerte fuer Render-/Verifier-Snapshots.
- Neuer Verifier erzeugt eine temporaere Door-Interaction im Missionsszenario und prueft half/closed vs. open gegen die echte Registry.

## Nicht-Ziele
- Kein neues Door-State-System.
- Kein neuer UI-Button.
- Kein Asset-Swap-/Animationssystem.
- Kein Mission-Flow-Rewrite.
- Kein per-frame Vollscan.

## Relevante Contracts / Dokumente
- `docs/dev/mission_interaction_point_contract.md`
- `docs/tasks/TASK_692_door_runtime_collision_los_contract.md`
- `docs/tasks/TASK_678_mission_interaction_runtime_progress.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`

## Akzeptanzkriterien
- In-progress/half Door-State wird als blockierender Runtime-Override angewendet.
- Complete/open Door-State wird als walkable und LOS-clear Runtime-Override angewendet.
- Statische `TerrainTileData` und `TerrainMapData` werden nicht mutiert.
- Wiederholtes Apply ohne Aenderung wird per Fingerprint uebersprungen.
- Snapshot/Manifest melden `ui_sets_gameplay_truth = false`.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_693_door_runtime_state_producer.gd`
- `docs/tasks/TASK_693_door_runtime_state_producer.md`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_693_door_runtime_state_producer.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_692_door_runtime_collision_los_contract.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Producer nutzt vorhandene Mission-Interaction-Stati. Ein sichtbarer Bedienbutton oder echte Breach-Animation bleibt Folgearbeit.
- Der echte FullHD-Sichtlauf bleibt weiterhin separat offen.
