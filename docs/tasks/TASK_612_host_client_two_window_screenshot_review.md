# TASK_612 - Host Client Two Window Screenshot Review

## Ziel / Problem
TASK_611 macht den lokalen Host-/Client-Fensterlauf reproduzierbar startbar. Offen bleibt der eigentliche Sichtbefund: Host- und Client-Fenster muessen als Review-Artefakte, Pflichtchecks und Folgeentscheidungen im laufenden HTML-Bericht gesichert werden, ohne den manuellen Test vorab als erledigt zu markieren.

Ziel ist ein kleines Screenshot-Review-Paket aus TASK_611-Launchplan, lokalem Board/Manifest und exportierbaren Berichtsfeldern fuer Host-/Client-Screenshotpfade, Lesbarkeit, Authority, Sync, Performance und naechste Findings.

## Sinnhaftigkeit / Ursache
Der echte Multiplayer-Spielblick ist nur dann belastbar, wenn spaeter nachvollziehbar ist, welcher Startplan, welche Fensterrollen und welche Screenshotpfade zum Befund gehoeren. Ein Manifest verhindert lose Dateien und macht sichtbar, dass die echten Screenshots noch menschlich geprueft werden muessen.

## Umfang
- Neuer Verifier `scripts/tests/task_612_host_client_two_window_screenshot_review.gd`.
- Erzeugt `tmp/host_client_two_window_screenshot_review_board.png` als Review-Board aus dem TASK_611-Launchplan.
- Erzeugt `tmp/host_client_two_window_screenshot_review.json` mit Review-Gates, Screenshot-Sollpfaden, offenem manuellen Review und TASK_613-Follow-up.
- HTML-Zwischenbericht erhaelt einen TASK_612-Block mit Host-/Client-Screenshotpfaden, Board-/Manifest-Pfaden, Pflichtchecks, Ratings, naechster Prioritaet und Notizfeld.
- Status/Roadmap/Contract dokumentieren, dass TASK_612 den Sichtreview vorbereitet und nicht automatisch erledigt.

## Nicht-Ziele
- Kein neuer Host-/Client-Transport.
- Kein automatischer LAN-/Steam-/Online-Test.
- Keine Behauptung, dass Host- und Client-Screenshots schon aufgenommen oder bewertet wurden.
- Keine Runtime-, Peer-, Command-, Combat-, Objective-, Cargo- oder UI-Wahrheit im Manifest oder Bericht.
- Kein UI-Polish ohne konkreten Folgefund aus Screenshot, Manifest oder HTML-Export.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_611_host_client_two_window_launch_helper.md`
- `docs/tasks/TASK_610_host_client_two_window_playtest_notes.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/html_report_workbench_contract.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Akzeptanzkriterien
- TASK_612-Verifier liest den TASK_611-Launchplan.
- Verifier erzeugt PNG-Board und JSON-Manifest unter `tmp/`.
- Manifest meldet `task_id = TASK_612`, `source_plan_task_id = TASK_611`, `manual_review_required = true`, `manual_review_done = false`, `read_only = true`, `ui_sets_gameplay_truth = false` und TASK_613 als naechsten Findings-Slice.
- HTML-Bericht exportiert Host-/Client-Screenshotpfade, Board-/Manifest-Pfade, Pflichtchecks, Ratings, Review-Notizen und TASK_613-Folgeprioritaet.
- Host-/Client-Screenshot-Checkboxen bleiben standardmaessig offen.
- TASK_612-Verifier laeuft gruen.

## Betroffene Dateien
- `docs/tasks/TASK_612_host_client_two_window_screenshot_review.md`
- `scripts/tests/task_612_host_client_two_window_screenshot_review.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`
- `scripts/tests/task_596_homebase_progression_player_review_notes.gd`
- `scripts/tests/task_598_homebase_progression_evidence_polish_findings.gd`
- `scripts/tests/task_610_host_client_two_window_playtest_notes.gd`
- `scripts/tests/task_611_host_client_two_window_launch_helper.gd`

## Lokale Pruefung
- `powershell -ExecutionPolicy Bypass -File scripts/tools/launch_host_client_two_window_review.ps1`
- `godot_console.exe --headless --path . --script scripts/tests/task_612_host_client_two_window_screenshot_review.gd`
- Regression: `task_611_host_client_two_window_launch_helper.gd`
- Regression: `task_610_host_client_two_window_playtest_notes.gd`
- Regression: `task_596_homebase_progression_player_review_notes.gd`
- Regression: `task_598_homebase_progression_evidence_polish_findings.gd`
- `git diff --check`

## Risiken / offene Punkte
- TASK_612 erzeugt ein Review-Paket und ein Board, aber keine echten Host-/Client-Fensterscreenshots.
- Der naechste sinnvolle Anschluss ist `TASK_613 - Host Client Two Window Visual Polish Findings`, sobald der sichtbare Lauf echte Reibung zeigt.
