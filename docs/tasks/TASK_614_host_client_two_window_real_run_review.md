# TASK_614 - Host Client Two Window Real Run Review

## Ziel / Problem
TASK_611 bis TASK_613 machen Startplan, Screenshot-Review-Workbench und Board-Labels reproduzierbar. Offen bleibt der echte lokale Zwei-Fenster-Lauf: Host und Client sollen aus demselben Plan gestartet, als Desktop-/Fensterbefund erfasst und wieder sauber geschlossen werden koennen.

Ziel ist ein expliziter Real-Run-Capture-Helper, der aus `tmp/host_client_two_window_launch_plan.json` arbeitet und ein Manifest fuer den echten Fensterlauf schreibt.

## Sinnhaftigkeit / Ursache
Multiplayer-Faehigkeit wird erst glaubwuerdig, wenn der sichtbare Host-/Client-Lauf nicht nur als Headless-Smoke oder Board existiert. Gleichzeitig darf kein Testlauf ungefragt Fenster oeffnen oder Gameplay-Wahrheit in HTML/Tools schreiben.

## Umfang
- Neuer PowerShell-Helper `scripts/tools/capture_host_client_two_window_real_run.ps1`.
- Default ist Dry-Run: liest den Launchplan und schreibt ein Manifest ohne Fensterstart.
- Explizites `-Launch` startet Host und Client sichtbar, wartet, erzeugt einen Desktop-Screenshot und kann mit `-CloseAfterCapture` die gestarteten Prozesse schliessen.
- Manifest unter `tmp/host_client_two_window_real_run_review.json` mit Screenshotpfad, Run-Modus, Prozess-IDs, offenen Review-Flags und read-only-Grenze.
- Neuer Verifier `scripts/tests/task_614_host_client_two_window_real_run_review.gd`.
- HTML-Zwischenbericht zeigt Tool, Manifest, Screenshotpfad, echten Launch-Befehl und offene manuelle Bewertung.

## Nicht-Ziele
- Kein neuer Multiplayer-Transport.
- Kein automatisches Matchmaking.
- Kein stiller Fensterstart in Headless-/Verifier-Laeufen.
- Keine Behauptung, dass der echte sichtbare Run bereits bestanden ist.
- Keine Runtime-, Peer-, Command-, Combat-, Objective-, Cargo- oder UI-Wahrheit im Tool, Manifest oder Bericht.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_613_host_client_two_window_visual_polish_findings.md`
- `docs/tasks/TASK_612_host_client_two_window_screenshot_review.md`
- `docs/tasks/TASK_611_host_client_two_window_launch_helper.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/html_report_workbench_contract.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Akzeptanzkriterien
- Dry-Run schreibt `tmp/host_client_two_window_real_run_review.json`.
- Manifest meldet `task_id = TASK_614`, `launch_requested = false`, `real_run_done = false`, `manual_review_required = true`, `manual_review_done = false`, `read_only = true` und `ui_sets_gameplay_truth = false`.
- Tool enthaelt einen expliziten `-Launch`-Pfad fuer sichtbare Host-/Client-Fenster und einen `-CloseAfterCapture`-Pfad.
- HTML-Bericht exportiert Toolpfad, Manifestpfad, Screenshotpfad, Launch-Befehl, Pflichtchecks, Ratings und Folgeprioritaet.
- Bestehende TASK_612-/TASK_613-Artefakte bleiben reviewbar.
- TASK_614-Verifier laeuft gruen, ohne Fenster zu starten.

## Betroffene Dateien
- `docs/tasks/TASK_614_host_client_two_window_real_run_review.md`
- `scripts/tools/capture_host_client_two_window_real_run.ps1`
- `scripts/tests/task_614_host_client_two_window_real_run_review.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`
- Report-Regressionstests unter `scripts/tests/`

## Lokale Pruefung
- `powershell -ExecutionPolicy Bypass -File scripts/tools/launch_host_client_two_window_review.ps1`
- `powershell -ExecutionPolicy Bypass -File scripts/tools/capture_host_client_two_window_real_run.ps1`
- `godot_console.exe --headless --path . --script scripts/tests/task_614_host_client_two_window_real_run_review.gd`
- Regression: `task_613_host_client_two_window_visual_polish_findings.gd`
- Regression: `task_612_host_client_two_window_screenshot_review.gd`
- Regression: `task_596_homebase_progression_player_review_notes.gd`
- Regression: `task_598_homebase_progression_evidence_polish_findings.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der automatische Verifier prueft den Dry-Run-Pfad. Der echte sichtbare Run muss lokal explizit mit `-Launch -CloseAfterCapture` ausgefuehrt und danach im Bericht bewertet werden.
- Wenn Godot auf einem anderen Pfad liegt, muss zuerst TASK_611-Launchplan mit passendem `-GodotBin` neu geschrieben werden.
