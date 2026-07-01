# TASK_735 - Station Scenario Current Report Sync Guard

## Ziel / Problem
Die technischen Station-Route-Guards TASK_707 und TASK_714 liefen gruen, prueften aber noch gegen den alten `project_current_state_handbook_refresh_2026_06_30.html` statt gegen den aktuellen Iststand-/Handbuch-Report.

## Sinnhaftigkeit / Ursache
Das ist kein Runtime-Gameplay-Fehler, aber ein Review-Fallstrick: Der aktuelle Report kann TASK_707-/TASK_714-Anker verlieren, ohne dass die alten Guards es merken. Fuer Multiplayer-Faehigkeit und Playtest-Abnahme soll die technische Door/Computer/Cargo- und Host/Client-Sync-Evidence an den aktuellen Bericht gekoppelt bleiben.

## Umfang
- TASK_707- und TASK_714-Verifier auf `project_current_state_handbook_2026_07_01.html` rebasen.
- Neuer kleiner Guard `task_735_station_scenario_current_report_sync_guard.gd`.
- Aktuellen Report, Status, Roadmap und Interaction-Contract aktualisieren.

## Nicht-Ziele
- Kein echter sichtbarer Host/Client-Playtest.
- Kein neues Sync-System.
- Kein Door-, Computer-, Cargo- oder Combat-Rewrite.
- Keine Aenderung an Gameplay-State oder UI-Wahrheit.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_707_mission_door_computer_cargo_smoke.md`
- `docs/tasks/TASK_714_station_route_multiplayer_scenario_guard.md`
- `docs/tasks/TASK_734_station_scenario_performance_feel_pass.md`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Akzeptanzkriterien
- TASK_707 und TASK_714 referenzieren den aktuellen 2026-07-01-Handbuch-Report.
- Der aktuelle Report enthaelt die TASK_707- und TASK_714-Exportanker.
- Der neue TASK_735-Guard schreibt ein read-only Manifest.
- Die technischen Door/Computer/Cargo- und Host/Client-Sync-Guards bleiben gruen.

## Betroffene Dateien
- `scripts/tests/task_707_mission_door_computer_cargo_smoke.gd`
- `scripts/tests/task_714_station_route_multiplayer_scenario_guard.gd`
- `scripts/tests/task_735_station_scenario_current_report_sync_guard.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Lokale Pruefung
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_735_station_scenario_current_report_sync_guard.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_714_station_route_multiplayer_scenario_guard.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_707_mission_door_computer_cargo_smoke.gd`
- [ ] `git diff --check`

## Risiken / offene Punkte
TASK_735 bestaetigt, dass die technischen Guards am aktuellen Bericht haengen. Er ersetzt weiter keinen menschlichen TASK_727-Fensterlauf und keine echte Host/Client-Spielgefuehl-Abnahme.
