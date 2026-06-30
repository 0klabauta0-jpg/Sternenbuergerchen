# TASK_662 - Host Client Decision Drill Real Window Capture

## Ziel / Problem
TASK_661 beschreibt den Host/Client-Decision-Drill als konkretes Klickpaket. Der naechste Schritt muss diesen Pfad in den bestehenden Zwei-Fenster-Capture aufnehmen, damit ein echter Host/Client-Fensterlauf gezielt auf `USE BRAVO`, Bravo-Kontext, `NEXT AA`, Preview und GO geprueft werden kann.

## Sinnhaftigkeit / Ursache
Der vorhandene Real-Run-Capture prueft Fenster, Rollen, Team-Badge und sichtbares Reject-Feedback. Fuer den Spielerflow reicht das nicht mehr: Nach dem blockierten Alpha-Klick muss Peer 2 auch die richtige Anschlussentscheidung sehen und ausfuehren koennen. Diese Erwartung soll als Manifest-/Report-Vertrag sichtbar sein, ohne UI-Wahrheit oder automatische Gameplay-Aktionen einzufuehren.

## Umfang
- Bestehenden `capture_host_client_two_window_real_run.ps1` um Decision-Drill-Felder erweitern.
- TASK_661-Packet als Quelle referenzieren.
- Manuelle Pflichtchecks fuer `USE BRAVO`, Bravo-Kontext, `NEXT AA`, Preview und GO erfassen.
- Laufenden HTML-Handbuchbericht mit TASK_662-Stand und Exportfeldern aktualisieren.
- Contract, Status und Roadmap fortschreiben.

## Nicht-Ziele
- Kein automatischer echter Zwei-Fenster-Klickbot.
- Kein neuer Multiplayer-, Movement-, Combat- oder Objective-State.
- Kein Claim, dass der menschliche Sichtreview erledigt ist.
- Kein neues Capture-Werkzeug neben dem bestehenden Host/Client-Real-Run-Pfad.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_661_host_client_decision_drill_click_evidence.md`
- `docs/tasks/TASK_626_host_client_real_click_review_evidence.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`

## Akzeptanzkriterien
- Das Host/Client-Real-Run-Manifest enthaelt `decision_drill_capture_task_id = TASK_662`.
- Das Manifest referenziert `tmp/host_client_decision_drill_click_evidence.json` und erkennt, ob es vorhanden ist.
- Erwartete Spielerhinweise sind im Manifest enthalten: `BLOCK P2 wrong team`, `USE BRAVO`, `AA`, `aa_first_push`, `bravo`, `GO`.
- Pflichtchecks umfassen `use_bravo_visible`, `bravo_context_selected`, `next_aa_visible_after_context_switch`, `move_preview_readable_before_go` und `go_feedback_visible_after_confirm`.
- `manual_review_required = true`, `manual_review_done = false`, `read_only = true` und `ui_sets_gameplay_truth = false` bleiben gesetzt.
- Der HTML-Bericht exportiert TASK_662-Felder und empfiehlt den Folge-Slice fuer belegte Visual-Findings.

## Betroffene Dateien
- `scripts/tools/capture_host_client_two_window_real_run.ps1`
- `scripts/tests/task_662_host_client_decision_drill_real_window_capture.gd`
- `scripts/tests/task_661_host_client_decision_drill_click_evidence.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`

## Lokale Pruefung
- `powershell -ExecutionPolicy Bypass -File scripts/tools/capture_host_client_two_window_real_run.ps1`
- `godot_console.exe --headless --path . --script scripts/tests/task_662_host_client_decision_drill_real_window_capture.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_661_host_client_decision_drill_click_evidence.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_626_host_client_real_click_review_evidence.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_652_current_state_handbook_refresh.gd`
- `git diff --check`

## Risiken / offene Punkte
Der echte menschliche Fensterreview bleibt offen, bis die sichtbaren Host/Client-Fenster tatsaechlich angeschaut und bewertet wurden. TASK_662 macht den Capture dafuer reviewbereit, ersetzt aber keine visuelle Entscheidung.
