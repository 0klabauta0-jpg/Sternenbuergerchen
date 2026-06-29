# TASK_610 - Host Client Two Window Playtest Notes

## Ziel / Problem
TASK_607 bis TASK_609 pruefen und visualisieren den Host/Client-Pfad headless. Offen bleibt der echte Spielerblick: zwei Fenster, Host und Client nebeneinander, sichtbare Team-/Authority-Grenzen, F6-Lesbarkeit, Snapshot-Sync und Bediengefuehl.

Ziel ist eine exportierbare Playtest-Notizflaeche im laufenden HTML-Bericht, damit ein echter Zwei-Fenster-Lauf nicht als Chat-Notiz verloren geht.

## Sinnhaftigkeit / Ursache
Multiplayer-Faehigkeit ist nicht nur ein gruener Runtime-Smoke. Der Spieler muss sehen koennen, wer Host ist, welcher Client welches Fireteam steuert, ob verbotene Commands sauber abgewiesen werden, ob der Client nur Server-State anzeigt und ob beide Fenster in FullHD noch lesbar wirken.

## Umfang
- Neuer TASK_610-Block im HTML-Zwischenbericht.
- Exportfelder fuer Host- und Client-Screenshotpfad.
- Pflichtchecks fuer zwei sichtbare Fenster, lokale Verbindung, Host-Authority, Client-Read-only, Peer-Command-Grenzen, Snapshot-Sync, F6-Lesbarkeit und Performance-Eindruck.
- Ratings fuer Verbindung, Authority, Sync, Lesbarkeit, Performance und Folgeprioritaet.
- Freitextnotiz unter `notes.host_client_two_window_manual_review`.
- Neuer Verifier `scripts/tests/task_610_host_client_two_window_playtest_notes.gd`.

## Nicht-Ziele
- Kein automatischer Zwei-Prozess-Launcher.
- Kein echter LAN-/Steam-/Matchmaking-Test.
- Keine Runtime-, Peer-, Command-, Combat-, Objective-, Cargo- oder UI-Wahrheit im HTML-Bericht.
- Kein Layout-Fix aus unbewiesenen Annahmen.
- Keine Behauptung, dass der menschliche Zwei-Fenster-Test schon erledigt ist.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/html_report_workbench_contract.md`
- `docs/tasks/TASK_607_two_instance_host_client_runtime_smoke.md`
- `docs/tasks/TASK_608_host_client_runtime_visual_capture.md`
- `docs/tasks/TASK_609_host_client_runtime_visual_polish_findings.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Akzeptanzkriterien
- Der Bericht enthaelt einen sichtbaren TASK_610-Block.
- Der Block exportiert Host- und Client-Screenshotpfade.
- Der Block exportiert Pflichtchecks fuer Verbindung, Authority, Client-Read-only, Peer-Grenzen, Snapshot-Sync, F6-Lesbarkeit und Performance.
- Der Block exportiert Ratings und eine konkrete naechste Prioritaet.
- Der Block enthaelt keine vorab als erledigt markierten Screenshot-Checkboxen.
- Der JSON-Export nennt TASK_610 als erledigt und TASK_611 als naechsten Anschluss.
- TASK_610-Verifier laeuft gruen.

## Betroffene Dateien
- `docs/tasks/TASK_610_host_client_two_window_playtest_notes.md`
- `scripts/tests/task_610_host_client_two_window_playtest_notes.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`
- `scripts/tests/task_596_homebase_progression_player_review_notes.gd`
- `scripts/tests/task_598_homebase_progression_evidence_polish_findings.gd`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_610_host_client_two_window_playtest_notes.gd`
- Regression: `task_609_host_client_runtime_visual_polish_findings.gd`
- Regression: `task_596_homebase_progression_player_review_notes.gd`
- Regression: `task_598_homebase_progression_evidence_polish_findings.gd`
- `git diff --check`

## Risiken / offene Punkte
- TASK_610 schafft die Review-Flaeche, fuehrt aber keinen echten Zwei-Fenster-Test aus.
- Der naechste sinnvolle Anschluss ist ein kleiner Launch-/Run-Helper oder ein echter exportierter Screenshot-Review.
