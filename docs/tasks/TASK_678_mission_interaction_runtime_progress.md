# TASK_678 - Mission Interaction Runtime Progress

## Ziel / Problem
TASK_677 erzeugt aus nutzbaren Mission-Interactions geplante Fireteam-Waypoints. Danach fehlt noch der eigentliche Runtime-Fortschritt: Computer-/Hold-Zonen bleiben ohne laufenden `holding`-/`operating`-State und ohne Gate-Abschluss, solange Tests den Step nicht manuell setzen.

## Sinnhaftigkeit / Ursache
Der Spieler soll nicht nur einen Intent planen, sondern nach GO sehen, dass ein Fireteam den Computer bedient oder die Cargo-Zone haelt. Diese Wahrheit darf nicht aus HUD-Text entstehen. Der bestehende Missionspfad hat aber bereits aktive Waypoint-Ausfuehrung, Hold-Zeit und Scenario-Gates. Der kleine Slice verbindet diese vorhandenen Laufzeitdaten.

## Umfang
- Use-Intent-Waypoints uebernehmen `duration_seconds`, `step_id` und `required_state` aus der Interaction.
- Laufende Interaction-Waypoints melden `holding`/`operating`, Hold-Zeit, Progress und Completion an den Combat-/Scenario-Runtime-Driver.
- Der Combat-Driver exportiert `get_mission_interaction_runtime_states()` und `get_mission_interaction_runtime_state_snapshot()`.
- Bei Completion setzt der Runtime-Driver den passenden Scenario-Step-State; Cargo-Hold aktualisiert zusaetzlich den Cargo-Touchdown-State.
- Doku, Roadmap, Status und HTML-Handbuch fortschreiben.

## Nicht-Ziele
- Kein neues Objective-System.
- Kein Door-State-/Animationssystem.
- Kein Computer-Hack-Minispiel.
- Kein direkter Gate-Commit aus UI oder Preview.
- Kein Umbau der Fireteam-Movement-Architektur.

## Relevante Contracts / Dokumente
- `docs/dev/mission_interaction_point_contract.md`
- `docs/tasks/TASK_677_mission_interaction_use_intent.md`
- `docs/tasks/TASK_675_mission_interaction_runtime_use_state.md`
- `docs/dev/runtime_script_layout_contract.md`

## Akzeptanzkriterien
- Station-Computer-Waypoint enthaelt 18 Sekunden Hold-Dauer und meldet `operating` mit Progress.
- Cargo-Hold-Waypoint enthaelt 12 Sekunden Hold-Dauer und meldet `holding` mit Progress.
- Completion setzt den zugehoerigen Scenario-Step-State auf den `required_state`.
- `get_mission_interaction_runtime_use_state_snapshot()` liest den Driver-State und zeigt `in_progress` bzw. `complete`.
- Der Runtime-State bleibt Snapshot-/Driver-Wahrheit; UI setzt keine Gameplay-Wahrheit.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/mission_combat_loop_driver.gd`
- `scripts/mission/mission_interaction_use_feedback.gd`
- `scripts/tests/task_678_mission_interaction_runtime_progress.gd`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/tasks/TASK_678_mission_interaction_runtime_progress.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_678_mission_interaction_runtime_progress.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_677_mission_interaction_use_intent.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_676_mission_interaction_use_feedback.gd`
- `git diff --check`

## Risiken / offene Punkte
- Dieser Slice macht Hold-/Operate-Fortschritt als Runtime-State nutzbar, aber noch keine sichtbare Door-Animation und keinen finalen FullHD-Sichttest der Fortschrittszeile.
