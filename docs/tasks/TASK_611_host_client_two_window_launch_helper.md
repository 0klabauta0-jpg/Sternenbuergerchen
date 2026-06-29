# TASK_611 - Host Client Two Window Launch Helper

## Ziel / Problem
TASK_610 sammelt manuelle Host-/Client-Zwei-Fenster-Notizen im laufenden HTML-Bericht. Offen bleibt der praktische Start: Host und Client muessen reproduzierbar mit derselben Szene, Rollenannahme und Fensteranordnung vorbereitet werden koennen, ohne dass jeder Playtest neu improvisiert.

Ziel ist ein kleiner Launch-Helper, der standardmaessig nur einen JSON-Startplan schreibt und erst mit explizitem `-Launch` zwei sichtbare Godot-Fenster startet.

## Sinnhaftigkeit / Ursache
Der Mehrspielerpfad ist headless und als Evidence-Board abgesichert, aber der echte Spielerblick braucht einen wiederholbaren lokalen Startpunkt. Ein Startplan macht die Testannahmen sichtbar: Szene, Rolle, Peer, Team, Fensterposition, Read-only-Grenze und naechster Screenshot-Review.

## Umfang
- Neuer PowerShell-Helper unter `scripts/tools/launch_host_client_two_window_review.ps1`.
- Dry-Run als Default: schreibt `tmp/host_client_two_window_launch_plan.json`, startet aber keine Fenster.
- Explizites `-Launch` startet zwei sichtbare Godot-Prozesse fuer Host und Client.
- Plan enthaelt Host-/Client-Rolle, Fensterlayout, Szene, Godot-Pfadstatus, Read-only-Grenze und TASK_612-Follow-up.
- Neuer Verifier `scripts/tests/task_611_host_client_two_window_launch_helper.gd`.
- Laufender HTML-Zwischenbericht zeigt den Launch-Helper und die offenen Screenshot-/Review-Folgefelder.

## Nicht-Ziele
- Kein neuer Multiplayer-Transport.
- Kein Matchmaking, kein Steam-/LAN-Autotest.
- Keine Behauptung, dass der echte Zwei-Fenster-Sichttest erledigt ist.
- Keine Runtime-, Peer-, Command-, Combat-, Objective-, Cargo- oder UI-Wahrheit im Helper oder Bericht.
- Kein Fensterstart in automatischen Godot-Verifiern.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_610_host_client_two_window_playtest_notes.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/html_report_workbench_contract.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Akzeptanzkriterien
- Der Helper schreibt im Dry-Run einen JSON-Plan unter `tmp/host_client_two_window_launch_plan.json`.
- Der Plan nennt `task_id = TASK_611`, `launch_mode = dry_run`, Host und Client, `read_only = true`, `ui_sets_gameplay_truth = false` und TASK_612 als naechsten Review.
- `-Launch` ist explizit noetig, bevor sichtbare Godot-Fenster gestartet werden.
- Der HTML-Bericht exportiert Helper-Pfad, Plan-Pfad, Szene, Fensterlayout, Launch-Command, Read-only-Flag und TASK_612-Folgeprioritaet.
- Bestehende TASK_610-Notizfelder bleiben offen und werden nicht als erledigter Sichttest markiert.
- TASK_611-Verifier laeuft gruen.

## Betroffene Dateien
- `docs/tasks/TASK_611_host_client_two_window_launch_helper.md`
- `scripts/tools/launch_host_client_two_window_review.ps1`
- `scripts/tests/task_611_host_client_two_window_launch_helper.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`
- `scripts/tests/task_596_homebase_progression_player_review_notes.gd`
- `scripts/tests/task_598_homebase_progression_evidence_polish_findings.gd`
- `scripts/tests/task_610_host_client_two_window_playtest_notes.gd`

## Lokale Pruefung
- `powershell -ExecutionPolicy Bypass -File scripts/tools/launch_host_client_two_window_review.ps1`
- `godot_console.exe --headless --path . --script scripts/tests/task_611_host_client_two_window_launch_helper.gd`
- Regression: `task_610_host_client_two_window_playtest_notes.gd`
- Regression: `task_609_host_client_runtime_visual_polish_findings.gd`
- Regression: `task_596_homebase_progression_player_review_notes.gd`
- Regression: `task_598_homebase_progression_evidence_polish_findings.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Helper erleichtert den echten Lauf, ersetzt ihn aber nicht.
- Falls lokale Godot-Pfade abweichen, muss `-GodotBin` oder `GODOT_BIN` gesetzt werden.
- TASK_612 sollte den echten Host-/Client-Fenster-Screenshot-Review aus dem Plan heraus dokumentieren.
