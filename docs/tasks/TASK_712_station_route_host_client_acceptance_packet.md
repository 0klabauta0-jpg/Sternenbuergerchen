# TASK_712 - Station Route Host/Client Acceptance Packet

## Ziel / Problem
Door -> Computer -> Cargo ist technisch und visuell als Single-Route belegt, aber der naechste echte Multiplayer-Schritt ist noch nicht sauber als Host/Client-Acceptance-Run beschrieben. Der vorhandene Zwei-Fenster-Capture kennt Door-Checks, aber nicht die komplette Station-Route.

## Sinnhaftigkeit / Ursache
Damit die Station-Route multiplayerfaehig wird, muss der echte Zwei-Fenster-Lauf nicht aus mehreren Tasks zusammengesucht werden. Der Run braucht eine kompakte Checkliste fuer Host/Client-Fenster, Door-Open, Computer-Control, Cargo-Departed, Wrong-Team-Reject, Snapshot-Sync und Workbench-Export.

## Umfang
- `capture_host_client_two_window_real_run.ps1` erweitert das read-only Manifest um Station-Route-Acceptance-Felder.
- Neuer Verifier prueft Tool-Vertrag und Manifestfelder.
- Status, Roadmap, Contract und aktueller HTML-Bericht werden aktualisiert.
- Der Dry-Run des Capture-Tools schreibt die Felder ohne Fensterstart.

## Nicht-Ziele
- Kein Klickbot.
- Kein automatisches Setzen von `manual_review_done`.
- Kein neues Multiplayer-, Objective-, Door-, Computer-, Cargo- oder SimulationRoot-Verhalten.
- Kein Behaupten eines bestandenen echten Host/Client-Playtests.

## Relevante Contracts / Dokumente
- `docs/dev/mission_interaction_point_contract.md`
- `docs/tasks/TASK_705_host_client_door_real_click_manual_run_packet.md`
- `docs/tasks/TASK_707_mission_door_computer_cargo_smoke.md`
- `docs/tasks/TASK_708_station_route_visual_evidence.md`
- `docs/tasks/TASK_709_station_route_window_playtest_notes.md`
- `docs/tasks/TASK_710_station_route_polish_readiness_findings.md`

## Akzeptanzkriterien
- Das Real-Run-Manifest enthaelt `station_route_host_client_acceptance_task_id = TASK_712`.
- Das Manifest referenziert TASK_708/709/710-Artefakte und erwartete Station-Route-Schritte.
- Das Manifest nennt Manual-Checks fuer Host-/Client-Fenster, Door-Open Host/Client, Computer-Control, Cargo-Departed, Wrong-Team-Reject, Snapshot-Sync, HUD-Lesbarkeit und Workbench-Export.
- Das Manifest meldet `station_route_host_client_acceptance_review_required = true`, `station_route_host_client_acceptance_review_done = false` und ein Gate `manual_open` oder `review_ready`.
- Das Manifest bleibt `read_only = true` und `ui_sets_gameplay_truth = false`.

## Betroffene Dateien
- `scripts/tools/capture_host_client_two_window_real_run.ps1`
- `scripts/tests/task_712_station_route_host_client_acceptance_packet.gd`
- `docs/tasks/TASK_712_station_route_host_client_acceptance_packet.md`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_refresh_2026_06_30.html`

## Lokale Pruefung
- `powershell -ExecutionPolicy Bypass -File scripts/tools/launch_host_client_two_window_review.ps1`
- `powershell -ExecutionPolicy Bypass -File scripts/tools/capture_host_client_two_window_real_run.ps1`
- `godot_console.exe --headless --path . --script scripts/tests/task_712_station_route_host_client_acceptance_packet.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_705_host_client_door_real_click_manual_run_packet.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_712 macht den echten Station-Route-Host/Client-Lauf ausfuehrbar und auswertbar, ersetzt ihn aber nicht. Der menschliche Klick-, Sicht- und Performanceentscheid bleibt offen, bis der Zwei-Fenster-Lauf bewusst geprueft wird.
