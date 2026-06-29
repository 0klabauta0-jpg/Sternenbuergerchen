# TASK_613 - Host Client Two Window Visual Polish Findings

## Ziel / Problem
TASK_612 erzeugt ein Review-Board fuer den Host-/Client-Zwei-Fenster-Sichttest. Beim Sichtblick auf das Board war der belegte Befund: Die Flaechen sind technisch vorhanden, aber ohne Labels und Legende zu abstrakt. Dadurch ist das Board als Arbeitsartefakt weniger hilfreich, bevor echte Host-/Client-Screenshots bewertet werden.

Ziel ist ein kleiner Visual-Polish fuer das TASK_612-Board: klare Host-/Client-Labels, Review-Status, Legende und Manifest-Gates fuer menschliche Reviewbarkeit.

## Sinnhaftigkeit / Ursache
Der laufende HTML-Bericht soll zwischendurch Orientierung geben. Wenn das Review-Board selbst nicht erklaert, was Host, Client, Pflichtchecks und naechste Schritte sind, hilft es dem Playtest-Workflow weniger als es koennte.

## Umfang
- TASK_612-Board-Generator um Pixel-Labels und Legende erweitern.
- Manifestfelder fuer `visual_polish_task_id`, `region_legend_present`, `callout_label_count`, `evidence_board_readability_gate` und `visible_followup_candidate`.
- Neuer Verifier `scripts/tests/task_613_host_client_two_window_visual_polish_findings.gd`.
- HTML-Zwischenbericht, Status, Roadmap und Contract auf TASK_613/TASK_614 aktualisieren.

## Nicht-Ziele
- Kein echter Host-/Client-Fensterscreenshot.
- Kein Multiplayer-Transport, keine Authority-Logik, keine Runtime-Mutation.
- Keine Gameplay-Wahrheit im Manifest, Board oder HTML-Bericht.
- Kein UI-Polish am eigentlichen Missions-HUD ohne echten Screenshotbefund.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_612_host_client_two_window_screenshot_review.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/html_report_workbench_contract.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Akzeptanzkriterien
- TASK_612-Board enthaelt sichtbare Labels fuer Host-Fenster, Client-Fenster, Launchplan, Screenshot-Sollpfade, Review offen und naechsten Task.
- Manifest meldet `visual_polish_task_id = TASK_613`, `region_legend_present = true`, `callout_label_count >= 10`, `evidence_board_readability_gate = pass`, `read_only = true` und `ui_sets_gameplay_truth = false`.
- TASK_613-Verifier prueft Task, Contract, Status, Roadmap, HTML-Bericht, Manifest und Board-Pixelbereiche.
- Der HTML-Bericht nennt TASK_614 als naechsten echten Host-/Client-Window-Run-Review.

## Betroffene Dateien
- `docs/tasks/TASK_613_host_client_two_window_visual_polish_findings.md`
- `scripts/tests/task_613_host_client_two_window_visual_polish_findings.gd`
- `scripts/tests/task_612_host_client_two_window_screenshot_review.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`
- Report-Regressionstests unter `scripts/tests/`

## Lokale Pruefung
- `powershell -ExecutionPolicy Bypass -File scripts/tools/launch_host_client_two_window_review.ps1`
- `godot_console.exe --headless --path . --script scripts/tests/task_612_host_client_two_window_screenshot_review.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_613_host_client_two_window_visual_polish_findings.gd`
- Regression: `task_611_host_client_two_window_launch_helper.gd`
- Regression: `task_596_homebase_progression_player_review_notes.gd`
- Regression: `task_598_homebase_progression_evidence_polish_findings.gd`
- `git diff --check`

## Risiken / offene Punkte
- Das Board ist nur ein Arbeitsartefakt. Der echte Host-/Client-Fensterlauf bleibt offen.
- Naechster sinnvoller Schritt: TASK_614 als echter Host-/Client-Window-Run-Review oder manuell ausgefuellter TASK_612-Bericht.
