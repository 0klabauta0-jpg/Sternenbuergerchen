# TASK_716 - Station Route Run Readout Polish

## Ziel / Problem
Nach TASK_715 ist der initiale Host/Client-Fensterblick ruhiger, aber der Spieler muss die kleine Stationsroute weiterhin aus getrennten HUD-Fragmenten zusammensetzen. Door, Computer und Cargo sind technisch vorhanden, aber der naechste sinnvolle Handlungspfad soll als kurze Route-Line im Mission-HUD lesbar sein.

## Sinnhaftigkeit / Ursache
Die Multiplayer- und Scenario-Guards pruefen die Station-Route technisch. Fuer ein angenehmes Spielgefuehl braucht der Commander aber vor und nach jedem Schritt eine kompakte Antwort auf: Was ist erledigt, was ist als naechstes dran, und wo endet die Kette?

## Umfang
- Neuer read-only `station_route_run_readout` im Command-Feedback-Snapshot.
- Kompakte Route-Line wie `ROUTE AA OK > DOOR OPEN > COM READY > CARGO WAIT | NEXT COM`.
- Route-Line erscheint im Command-Feedback und in der bestehenden Mission-Control-Density-Line.
- Die Line liest nur Objective-Gate- und Object-Reaction-Snapshots.
- Verifier fuer Door -> Computer -> Cargo inklusive Label-Text und Snapshot-Felder.
- Status, Roadmap, Contract und HTML-Handbuch-Refresh werden aktualisiert.

## Nicht-Ziele
- Kein neuer Door-, Computer- oder Cargo-State.
- Kein neuer Klick-/Command-Pfad.
- Kein Completion-Bypass fuer Computer oder Cargo.
- Kein grosses HUD-Redesign.
- Kein Ersatz fuer den echten Host/Client-Klicklauf.

## Relevante Contracts / Dokumente
- `docs/dev/mission_interaction_point_contract.md`
- `docs/tasks/TASK_712_station_route_host_client_acceptance_packet.md`
- `docs/tasks/TASK_714_station_route_multiplayer_scenario_guard.md`
- `docs/tasks/TASK_715_station_route_empty_eventlog_polish.md`

## Akzeptanzkriterien
- `get_command_feedback_snapshot()` exportiert `station_route_run_readout` read-only mit `ui_sets_gameplay_truth = false`.
- Die Route-Line nennt AA, Door, Computer, Cargo und ein `NEXT`-Token.
- Nach Door-Open zeigt die Line `DOOR OPEN` und `NEXT COM`.
- Nach Computer-Control zeigt die Line `COM CTRL` und `NEXT CARGO`.
- Nach Cargo-Departed zeigt die Line `CARGO DEPARTED` und `NEXT DONE`.
- Die Route-Line bleibt innerhalb des festgelegten Zeichenlimits.
- Der sichtbare Command-Feedback-Labeltext enthaelt die Route-Line.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_716_station_route_run_readout_polish.gd`
- `docs/tasks/TASK_716_station_route_run_readout_polish.md`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_refresh_2026_06_30.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_716_station_route_run_readout_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_714_station_route_multiplayer_scenario_guard.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_715_station_route_empty_eventlog_polish.gd`
- `git diff --check`

## Risiken / offene Punkte
Die Route-Line macht die Stationsroute lesbarer, ersetzt aber keinen echten Klicklauf. Der naechste Spielerblick muss weiterhin pruefen, ob DoorBreachButton, GO-Pflicht, Wrong-Team-Reject und Client-Sync im Fenster angenehm erkennbar sind.
