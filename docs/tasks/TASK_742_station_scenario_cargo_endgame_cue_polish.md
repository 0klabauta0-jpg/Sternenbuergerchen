# TASK_742 - Station Scenario Cargo Endgame Cue Polish

## Ziel / Problem
Der Stationsdrill sagt am Anfang inzwischen gut, was zu tun ist. Der finale Cargo-Schritt ist aber noch zu generisch: `CUE CARGO: halten` oder `erledigt` erklaert nicht klar genug, dass der Spieler die Zone bis zum Abflug decken und danach Richtung Debrief denken soll.

## Sinnhaftigkeit / Ursache
Cargo ist im aktuellen AA -> Door -> Computer -> Cargo-Slice der Missionsabschluss. Gerade dieser Moment muss sich spielerisch nach Ziel, Spannung und Aufloesung anfuehlen. Die bestehende Runtime- und Cargo-Wahrheit ist schon vorhanden; der kleine Polish betrifft nur den read-only Cue-Presenter.

## Umfang
- `StationScenarioRouteCuePolish` bekommt Cargo-spezifische Cue-Sprache fuer Hold, Departing, Complete und Done.
- Der Presenter extrahiert aus vorhandenen Progress-Zeilen kurze Zeit-/Prozent-Hinweise.
- Detailzeilen erklaeren Cargo-Hold und Cargo-Abflug klarer.
- Status, Roadmap, Contract und Handbuchbericht werden auf TASK_742 aktualisiert.
- Neuer Verifier prueft direkte Cargo-Cue-Faelle und bestehende TASK_736-Sprache bleibt kompatibel.

## Nicht-Ziele
- Kein neuer Cargo-Runtime-State.
- Kein neues Missionsende-/Debrief-System.
- Kein automatischer TASK_727-Sichttest.
- Keine Aenderung an Objective-Gates, Door, Computer, Combat oder Multiplayer-Authority.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_736_station_scenario_command_feedback_polish.md`
- `docs/tasks/TASK_741_station_scenario_workbench_recapture_prefill.md`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Akzeptanzkriterien
- Cargo-In-Progress-Cue liest als `halten bis Abflug`.
- Cargo-Departing-Cue liest als `Abflug laeuft`.
- Cargo-Complete- oder Done-Cue liest als `Cargo weg | Debrief`.
- Cue bleibt innerhalb des bestehenden Zeichenbudgets.
- Snapshot bleibt `read_only = true`, `ui_sets_gameplay_truth = false`.
- Bestehender AA-/Door-Command-Feedback-Polish bleibt gruen.

## Betroffene Dateien
- `scripts/mission/station_scenario_route_cue_polish.gd`
- `scripts/tests/task_742_station_scenario_cargo_endgame_cue_polish.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Lokale Pruefung
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_742_station_scenario_cargo_endgame_cue_polish.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_736_station_scenario_command_feedback_polish.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_552_mission_objective_interaction_readability_pass.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_553_mission_cargo_extract_readability_pass.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_554_frontier_probe_integrated_objective_playthrough_smoke.gd`
- [ ] `git diff --check`

## Risiken / offene Punkte
TASK_742 verbessert die finale Handlungszeile, ersetzt aber weiterhin keinen echten TASK_727-Workbench-Export. Ob der Cargo-Endmoment im Fenster gut wirkt, bleibt sichtbar zu pruefen.
