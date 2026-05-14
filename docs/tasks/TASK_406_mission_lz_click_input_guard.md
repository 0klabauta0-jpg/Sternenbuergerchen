# TASK 406 - Mission LZ Click Input Guard

## Ziel / Problem

Im manuellen Missionstest laesst sich die Dropship-LZ nicht verlaesslich setzen. Nach dem Aktivieren von `LZ` blinkt Hover-Feedback kurz, aber der Linksklick auf die Karte setzt keine LZ.

## Ursache / Sinn

Der echte Spielerpfad laeuft ueber `_unhandled_input()` im `mission_tactical_sandbox_controller.gd`. Dort blockiert ein pauschaler `gui_get_hovered_control()`-Guard den Linksklick, bevor der LZ-Pick geprueft wird. Wenn Godot noch ein vorheriges UI-Control als Hover-Control meldet oder ein nicht zur Klickposition passendes Control haelt, wird der Kartenklick verworfen.

## Umfang

- Pointer-over-Control-Guard positionsgenau machen.
- LZ- und Target-Pick nur dann blockieren, wenn der Klick wirklich ueber einem UI-Control liegt.
- Regressions-Verifier fuer den echten `_unhandled_input()`-LZ-Klickpfad ergaenzen.

## Nicht-Ziele

- Keine Aenderung an Dropship-State, Boarding, LZ-Accuracy oder Multiplayer-Authority.
- Keine neue UI-Anordnung.
- Keine Aenderung an Terrain-, Cover-, LOS- oder Map-Gameplay.

## Relevante Contracts / Dokumente

- `AGENTS.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/tasks/TASK_311_dropship_lz_target_pick_accuracy_contract.md`
- `docs/tasks/TASK_312_dropship_command_matrix_lz_go_layout.md`
- `docs/tasks/TASK_313_dropship_arrival_visibility_feedback_smoke.md`
- `docs/tasks/TASK_394_per_craft_shipcard_commands.md`
- `docs/tasks/TASK_395_manual_dropship_parallel_flow.md`
- `docs/tasks/TASK_396_mission_dropship_lz_drop_hotfix.md`

## Akzeptanzkriterien

- Ein armer LZ-Pick kann per echtem `_unhandled_input()`-Linksklick auf ein Primary3DView-Tile gesetzt werden.
- Klicks, die wirklich ueber UI-Control liegen, werden weiterhin nicht als Kartenklick behandelt.
- Per-Craft-LZ-State bleibt erhalten.
- Bestehende Dropship-LZ-/Drop-Smokes bleiben gruen.

## Betroffene Dateien

- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_406_mission_lz_click_input_guard.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/tasks/TASK_406_mission_lz_click_input_guard.md`

## Lokale Pruefung

- [x] `godot_console.exe --headless --path . --script scripts/tests/task_406_mission_lz_click_input_guard.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_394_per_craft_shipcard_commands.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_395_manual_dropship_parallel_flow.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_396_mission_dropship_lz_drop_hotfix.gd`
- [x] `git diff --check`

## Risiken / offene Punkte

- Headless-Tests koennen Godots echten Hover-Zustand nur begrenzt nachstellen; der Fix reduziert deshalb den Guard selbst auf die tatsaechliche Klickposition.
