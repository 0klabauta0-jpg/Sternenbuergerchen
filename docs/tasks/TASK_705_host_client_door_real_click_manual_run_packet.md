# TASK_705 - Host/Client Door Real Click Manual Run Packet

## Ziel / Problem
TASK_704 trennt technische Door-Evidence und offene menschliche Host/Client-Klickbeobachtung. Fuer den naechsten echten Zwei-Fenster-Lauf fehlt noch ein Door-spezifisches Manual-Run-Paket im vorhandenen Capture-Manifest: Welche Door-Schritte sind zu pruefen, welche Workbench soll ausgefuellt werden, und welche Artefakte gehoeren zusammen?

## Sinnhaftigkeit / Ursache
Die vorhandenen Host/Client-Tools koennen Fenster starten und Screenshots/Crops erzeugen, enthalten aber noch keine kompakte Door-Run-Checkliste fuer Button, Shortcut `B`, GO-Pflicht, Wrong-Team-Reject, Door-Open und HUD-Lesbarkeit. Ohne diese Felder muss der Mensch aus mehreren Tasks zusammensuchen, was genau im Door-Lauf zu beurteilen ist.

## Umfang
- `capture_host_client_two_window_real_run.ps1` erweitert das read-only Manifest um Door-Real-Click-Manual-Run-Felder.
- Neuer Verifier prueft Tool-Vertrag und Manifestfelder.
- Status, Roadmap, Contract und aktueller HTML-Bericht werden aktualisiert.
- Der Dry-Run des Capture-Tools schreibt die Felder ohne Fensterstart.

## Nicht-Ziele
- Kein Klickbot.
- Kein automatisches Setzen von `manual_review_done`.
- Kein neues Multiplayer-, Door-, Terrain- oder SimulationRoot-Verhalten.
- Kein UI-Layout-/Visual-Polish.
- Kein Behaupten eines bestandenen echten Host/Client-Playtests.

## Relevante Contracts / Dokumente
- `docs/dev/mission_interaction_point_contract.md`
- `docs/tasks/TASK_704_host_client_door_real_click_findings.md`
- `docs/tasks/TASK_700_host_client_door_real_click_workbench.md`
- `docs/reports/host_client_door_real_click_workbench_2026_06_30.html`
- `docs/reports/project_current_state_handbook_2026_06_30.html`

## Akzeptanzkriterien
- Das Real-Run-Manifest enthaelt `door_real_click_manual_run_task_id = TASK_705`.
- Das Manifest referenziert Workbench, Findings-Manifest und erwartete Door-Artefakte.
- Das Manifest nennt Door-Manual-Checks fuer Host-Fenster, Client-Fenster, Door-Button, Shortcut `B`, GO-Pflicht, Wrong-Team-Reject, Door-Open Host/Client und HUD-Lesbarkeit.
- Das Manifest meldet `door_real_click_manual_review_required = true`, `door_real_click_manual_review_done = false` und `door_real_click_manual_run_gate` als `manual_open` oder `review_ready`.
- Das Manifest bleibt `read_only = true` und `ui_sets_gameplay_truth = false`.
- Der aktuelle HTML-Bericht exportiert TASK_705-Pfad, Manifestpfad und offene Manual-Run-Checks.

## Betroffene Dateien
- `scripts/tools/capture_host_client_two_window_real_run.ps1`
- `scripts/tests/task_705_host_client_door_real_click_manual_run_packet.gd`
- `docs/tasks/TASK_705_host_client_door_real_click_manual_run_packet.md`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`

## Lokale Pruefung
- `powershell -ExecutionPolicy Bypass -File scripts/tools/launch_host_client_two_window_review.ps1`
- `powershell -ExecutionPolicy Bypass -File scripts/tools/capture_host_client_two_window_real_run.ps1`
- `godot_console.exe --headless --path . --script scripts/tests/task_705_host_client_door_real_click_manual_run_packet.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_704_host_client_door_real_click_findings.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_705 macht den echten Door-Host/Client-Run besser ausfuehrbar und auswertbar, ersetzt ihn aber nicht. Der menschliche Klick- und Sichtentscheid bleibt offen, bis die Workbench bewusst ausgefuellt wird.
