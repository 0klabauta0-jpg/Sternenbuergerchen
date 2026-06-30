# TASK_627 - Host Client Fireteam Eventlog Overlap Polish

## Ziel / Problem
Der frische Host/Client-Fenster-Capture nach TASK_626 zeigt einen klaren HUD-Fund: `#19 EVENT LOG` liegt in der linken Fireteam-Spalte zwischen den Mini-Fireteam-Karten. Das wirkt wie ein ueberlagerter Fremdblock und macht den Host/Client-Spielblick unruhiger.

## Sinnhaftigkeit / Ursache
Der Mission-HUD-Layout-Contract reserviert fuer `fireteam_mini` einen Bereich von `y=128` bis `y=488`, waehrend `event_log` bei `y=244` beginnt. Damit liegt das Eventlog formal innerhalb des Mini-Fireteam-Bereichs. Die Mini-Cards werden absichtlich ueber dem Eventlog gerendert, wodurch der Eventlog-Titel im echten Fenster zwischen den Karten auftaucht.

## Umfang
- Eventlog-Fenster im Mission-HUD-Contract unter die Fireteam-Mini-Cards verschieben.
- Mission-Controller wendet den Eventlog-Rect ebenfalls ueber den Contract an.
- Szenen-Default fuer `TacticalEventLogPanel` an den neuen Contract anpassen.
- Verifier prueft: Fireteam-Mini-Panel und Eventlog schneiden sich nicht mehr, Eventlog liegt darunter, beide bleiben auf dem FullHD-Raster und read-only.

## Nicht-Ziele
- Kein neues Eventlog-System.
- Keine Aenderung an Eventlog-Daten, TacticalCommunication oder Gameplay-State.
- Keine neue Host/Client-Authority-Logik.
- Kein vollstaendiger HUD-Redesign-Slice.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/html_report_workbench_contract.md`
- `docs/tasks/TASK_626_host_client_real_click_review_evidence.md`
- `docs/reports/project_review_status_2026_06_28.html`
- `docs/reports/project_status_handbook_2026_06_29.html`

## Akzeptanzkriterien
- `DropLightLayoutContract.get_mission_hud_layout().event_log` liegt vollstaendig unter `fireteam_mini`.
- `MissionTacticalSandboxController` wendet den Eventlog-Rect aus dem Contract an.
- Die Mission-Testszene startet mit einem passenden Eventlog-Default.
- Der Verifier belegt, dass Fireteam-Mini-Panel und Eventlog nicht ueberlappen.
- Keine UI-Schicht setzt Gameplay-Wahrheit.

## Betroffene Dateien
- `scripts/meta/drop_light_layout_contract.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scenes/tests/mission_reactivity_test.tscn`
- `scripts/tests/task_627_host_client_fireteam_eventlog_overlap_polish.gd`
- Status/Roadmap/Reports

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_627_host_client_fireteam_eventlog_overlap_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_258_fixed_window_clipping_scrollbar_playability_audit.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_626_host_client_real_click_review_evidence.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_620_host_client_badge_recapture_review.gd`
- `powershell -ExecutionPolicy Bypass -File scripts/tools/capture_host_client_two_window_real_run.ps1 -Launch -CloseAfterCapture -WaitSeconds 10`
- `git diff --check`

## Risiken / offene Punkte
- Das verschobene Eventlog kann bei sehr voller Karte weiterhin Weltflaeche verdecken. Das ist kleiner als die aktuelle Fireteam-Karten-Ueberlagerung und sollte spaeter nur mit belegtem Screenshot-Befund weiter poliert werden.
- Der alte `task_180_mission_drop_light_fixed_hud_layout_verifier.gd` faellt aktuell an unrelated Command-Matrix-/Selected-Fireteam-Erwartungen und wird deshalb nicht als TASK_627-Gruenliste gefuehrt.
