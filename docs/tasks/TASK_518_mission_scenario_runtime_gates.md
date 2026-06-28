# TASK_518 - Mission Scenario Runtime Gates

## Status: IMPLEMENTIERT

## Ziel / Problem
`frontier_probe_vertical_slice` beschreibt AA-Shutdown, Computer-Hold und Cargo-Touchdown/Extract bisher nur als Datenvertrag. Fuer einen angenehmen Playtest braucht der Missionspfad einen lesbaren Runtime-Gate-Status, der aus autoritativen Mission-/Combat-Snapshots abgeleitet wird und spaeter Victory/Progress treiben kann.

## Sinnhaftigkeit / Ursache
Ohne Runtime-Gates bleibt das Szenario eine Briefing-Idee. Der Spieler kann zwar auf der Map landen und kaempfen, aber das Spiel weiss noch nicht, ob die Luftabwehr wirklich aus ist, ob der Computer lange genug gehalten wurde oder ob der Frachter erst nach AA-Shutdown starten darf.

## Umfang
- Kleiner Mission-Service fuer `vertical_slice.flow_steps`.
- Gate-Status fuer `pending`, `active`, `blocked`, `complete`.
- AA-Shutdown-Gate aus Enemy-Group-Fitcount oder explizitem Runtime-State ableiten.
- Computer-Hold-Gate aus `ObjectiveStatus`-Ownership plus Hold-Timer ableiten.
- Cargo-Gate erst nach AA-Shutdown freigeben und aus Cargo-Runtime-State ableiten.
- Combat-Driver-Anbindung fuer Snapshot, Countdown und Victory-Bedingung, ohne UI-Wahrheit einzufuehren.

## Nicht-Ziele
- Kein neues komplexes Objective-System.
- Kein Dropship-/Cargo-Flight-Rewrite.
- Kein neues UI-Panel.
- Kein Multiplayer-Lobby-Ownership.
- Keine SceneTree-Vollscans im Gate-Service.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/tasks/TASK_517_mission_scenario_vertical_slice.md`
- `docs/dev/mission_briefing_contract.md`
- `docs/dev/air_asset_threat_damage_contract.md`
- `docs/dev/combat_loop_authority_contract.md`

## Akzeptanzkriterien
- `MissionScenarioRuntimeGates` arbeitet ohne SceneTree-Abhaengigkeit und mutiert keinen Gameplay-State.
- Das Gate-Snapshot enthaelt alle drei Flow-Steps mit Status, Progress, Hold-Zeit, Target-Marker und Blocker-Hinweisen.
- Computer-Hold laeuft nur, wenn das Objective von `operator_team_id` gehalten wird; bei Verlust pausiert/resetet der Hold-Fortschritt.
- Cargo bleibt blockiert, bis der AA-Step abgeschlossen ist.
- Der Combat-Driver kann den Slice laden, Gate-Snapshot liefern und Victory erst melden, wenn alle Gates abgeschlossen sind.
- Bestehende `frontier_probe`- und Objective-Capture-Smokes bleiben unveraendert gruen.

## Betroffene Dateien
- `scripts/mission/mission_scenario_runtime_gates.gd`
- `scripts/tests/mission_combat_loop_driver.gd`
- `scripts/tests/mission_test_setup.gd`
- `scripts/tests/task_518_mission_scenario_runtime_gates.gd`
- `docs/tasks/TASK_518_mission_scenario_runtime_gates.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_518_mission_scenario_runtime_gates.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_517_mission_scenario_vertical_slice.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_500_gameflow_spine_hardening.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_505_frontier_probe_large_map_playtest_hotfix.gd`
- `git diff --check`

## Risiken / offene Punkte
- Cargo-Runtime-State ist in diesem Slice noch ein Contract-Input; die echte Frachter-Lande-/Abfluganimation bleibt ein separater Dropship-/Cargo-Task.
- AA-Shutdown ist vorerst an Enemy-Group-Fitcount oder expliziten Runtime-State gekoppelt. Feineres Interaktionsdesign fuer Computer/AA-Terminals kann spaeter aus dem Map-Editor kommen.
