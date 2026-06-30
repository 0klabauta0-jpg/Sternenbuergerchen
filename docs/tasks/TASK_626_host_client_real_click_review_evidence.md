# TASK_626 - Host Client Real Click Review Evidence

## Ziel / Problem
Nach TASK_625 ist der wichtigste Authority-Reject im Mission-Teamchip sichtbar. Der naechste echte Host/Client-Klicklauf braucht aber einen klaren Evidence-Vertrag: Was muss im Fenster sichtbar sein, welche Felder muessen im Manifest stehen, und welche manuellen Checks bleiben offen?

## Sinnhaftigkeit / Ursache
Der bestehende Zwei-Fenster-Capture-Helper erzeugt bereits Host-/Client-Crops und Badge-Evidence. Er kennt den neuen sichtbaren Reject-Hinweis noch nicht als expliziten Pruefpunkt. Dadurch kann ein echter Klicklauf zwar stattfinden, aber der Review verliert schnell die konkrete Frage: Ist `BLOCK P2 wrong team` im Client-/Host-Kontext lesbar, reaktionsschnell und konsistent mit `AUTH OK1/RJ2` und dem Tooltip?

## Umfang
- `capture_host_client_two_window_real_run.ps1` erweitert das read-only Manifest um erwartete Visible-Reject-Felder.
- Der laufende HTML-Zwischenbericht und der Ist-Stand-/Handbuch-Report dokumentieren TASK_626 als aktuellen Review-Anker.
- Ein kleiner Verifier prueft Task, Contract, Reports und Manifestfelder nach Dry-Run-Erzeugung.

## Nicht-Ziele
- Kein neuer Command- oder Authority-Pfad.
- Kein OCR-/Pixel-Erkennungssystem.
- Kein automatisches Klicken in den Godot-Fenstern.
- Kein neues Toast-, Bubble- oder Panel-System.
- Keine Gameplay-Wahrheit im HUD oder im Report.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/html_report_workbench_contract.md`
- `docs/tasks/TASK_625_host_client_visible_reject_feedback_polish.md`
- `docs/reports/project_review_status_2026_06_28.html`
- `docs/reports/project_status_handbook_2026_06_29.html`

## Akzeptanzkriterien
- Das Real-Run-Manifest nennt `TASK_626` als Real-Click-Review-Evidence-Task.
- Erwartete sichtbare Felder sind explizit: `BLOCK P2 wrong team`, `AUTH OK1/RJ2`, `AUTH BLOCKED P2: wrong team`, `peer_team_mismatch`.
- Manuelle Checks fuer Peer-2-Alpha-Reject, Sichtbarkeit, Tooltip-Rohgrund, Input-Latenz, Snapshot-Sync und Fokuswechsel sind exportiert.
- Reports markieren TASK_626 als aktuellen Stand, ohne den echten manuellen Klicklauf als erledigt zu behaupten.
- Alle neuen Daten bleiben `read_only = true` und `ui_sets_gameplay_truth = false`.

## Betroffene Dateien
- `scripts/tools/capture_host_client_two_window_real_run.ps1`
- `scripts/tests/task_626_host_client_real_click_review_evidence.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`
- `docs/reports/project_status_handbook_2026_06_29.html`

## Lokale Pruefung
- `powershell -ExecutionPolicy Bypass -File scripts/tools/launch_host_client_two_window_review.ps1`
- `powershell -ExecutionPolicy Bypass -File scripts/tools/capture_host_client_two_window_real_run.ps1`
- `godot_console.exe --headless --path . --script scripts/tests/task_626_host_client_real_click_review_evidence.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_625_host_client_visible_reject_feedback_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_620_host_client_badge_recapture_review.gd`
- `git diff --check`

## Risiken / offene Punkte
- Das Manifest ist kein erledigter Playtest. Der echte Zwei-Fenster-Klicklauf mit Fokuswechsel, Latenzgefuehl und menschlichem Sichtentscheid bleibt offen.
- Falls der Hinweis im echten Fenster zu leise ist, sollte ein eigener kleiner Follow-up nur belegte UI-Reibung polieren.
