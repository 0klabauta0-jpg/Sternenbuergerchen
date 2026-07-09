# TASK_973 - Release First Decision Loop Two Real Window Recapture

## Ziel / Problem
TASK_972 beweist den zweiten Griff als Trace. Jetzt braucht derselbe Ablauf wieder einen echten Fensterblick: `2ND`, getrenntes `GO`, Post-GO-Feedback und die kurze Smoke-Zeile muessen im laufenden Release-Fenster belegbar bleiben.

## Sinnhaftigkeit / Ursache
Der zweite Decision-Loop ist inzwischen technisch angeschlossen und spielbar beschrieben. Ohne Recapture kann aber wieder eine Diskrepanz zwischen Headless-Smoke und sichtbarer Spielerlesbarkeit entstehen.

## Umfang
- Read-only Analyzer fuer TASK_973-Recapture-Manifeste.
- PowerShell-Tool, das ein Recapture-Manifest fuer `--release-singleplayer-lz-drop-preview` schreibt.
- Pflichtchecks fuer Fensterstart, vertrauenswuerdigen Screenshot, `2ND`, getrenntes `GO`, Post-GO-Feedback, Smoke-Zeile, HUD-read-only und Multiplayer-Grenze.
- Doku-Verankerung in Status, Roadmap und Decision-/Command-Contracts.

## Nicht-Ziele
- Kein neuer Command-Pfad.
- Kein automatisches `GO`.
- Keine UI-, Movement-, Combat-, Damage- oder Multiplayer-Mutation.
- Keine automatische manuelle Abnahme und keine Shortcut-Aenderung.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_972_release_first_decision_loop_two_playability_smoke.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `scripts/mission/release_first_decision_loop_two_real_window_recapture.gd`

## Akzeptanzkriterien
- Fehlende TASK_972-Source blockiert.
- Fehlendes Recapture-Manifest bleibt `needs_real_window_recapture`.
- Reviewbares Manifest routet zu `TASK_974 - Release First Decision Loop Two Recapture Visual Findings`.
- Vollstaendig manuell bestaetigte Pflichtchecks koennen den Recapture akzeptieren.
- Der Snapshot bleibt read-only und erzeugt keine Gameplay- oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_real_window_recapture.gd`
- `scripts/tools/capture_release_first_decision_loop_two_real_window_recapture.ps1`
- `scripts/tests/task_973_release_first_decision_loop_two_real_window_recapture.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_973_release_first_decision_loop_two_real_window_recapture.gd`
- Regressionen: TASK_972, TASK_971, TASK_970
- `git diff --check`

## Risiken / offene Punkte
- Das Tool schreibt nur ein Manifest und faket keine Sichtabnahme. TASK_974 sollte aus dem echten Recapture konkrete visuelle Findings schneiden.
