# TASK_732 - Station Scenario Route Cue Polish

## Ziel / Problem
Der One-Screen-Stationsdrill zeigt nach TASK_730 die Route im Mission-Identity-Bereich, aber der Spieler muss aus `NEXT AA/DOOR/COM/CARGO` noch zu viel selbst ableiten. Fuer einen angenehmen Playtest braucht der Screen eine kurze, klare "was jetzt?"-Zeile.

## Sinnhaftigkeit / Ursache
Die Route-Line beschreibt den Ablauf, aber nicht die naechste Handlung. Genau diese Luecke ist fuer F6-/Host-Client-Playtests stoerend: AA, Door, Computer und Cargo sollen ohne Debugwissen als naechster Auftrag lesbar sein.

## Umfang
- Neuer read-only Presenter `StationScenarioRouteCuePolish`.
- Cue-Daten aus bestehendem Station-Route-Readout, Objective-Gate, Use-Feedback und Progress-Readability.
- Controller-Export im `get_command_feedback_snapshot()`.
- Mission-HUD-Density nimmt die Cue-Zeile in den vorhandenen ACT-Snapshot auf.
- Verifier fuer direkte Presenter-Faelle und die sichtbare Missionsszene.
- Status-, Roadmap-, Contract- und Handbuch-Update.

## Nicht-Ziele
- Kein automatisches Ausfuellen des TASK_727-Workbench-Exports.
- Keine neuen Scenario-Gates, Door-States, Cargo-States oder Runtime-Mutationen.
- Kein neues grosses Missionssystem.
- Kein visueller FullHD-Abnahmetest in diesem Task.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_727_station_scenario_f6_host_client_playtest_notes.md`
- `docs/tasks/TASK_731_station_scenario_workbench_export_review.md`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Akzeptanzkriterien
- Der Cue-Snapshot bleibt read-only: `read_only = true`, `ui_sets_gameplay_truth = false`.
- Fuer `out_of_range` meldet die Zeile eine Annaeherungs-/Distanzinformation.
- Fuer `usable` meldet die Zeile Aktion plus GO.
- Fuer `in_progress` meldet die Zeile Fortschritt/Halten.
- `get_command_feedback_snapshot()` exportiert `station_scenario_route_cue_line`.
- Der Mission-HUD-Density-Snapshot enthaelt die Cue-Zeile ohne UI-Baum-Neubau oder Gameplay-Mutation.

## Betroffene Dateien
- `scripts/mission/station_scenario_route_cue_polish.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_732_station_scenario_route_cue_polish.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Lokale Pruefung
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_732_station_scenario_route_cue_polish.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_730_station_scenario_targeted_playtest_polish.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_731_station_scenario_workbench_export_review.gd`
- [ ] `git diff --check`

## Risiken / offene Punkte
Der Cue verbessert die Lesbarkeit der naechsten Handlung, ersetzt aber keinen menschlichen TASK_727-F6-/Host-Client-Export. Wenn der echte Fensterlauf danach weiter unklar wirkt, sollten TASK_733/TASK_736 aus echten Notizen folgen.
