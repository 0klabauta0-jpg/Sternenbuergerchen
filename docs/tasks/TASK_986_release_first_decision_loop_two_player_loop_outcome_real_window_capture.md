# TASK_986 - Release First Decision Loop Two Player Loop Outcome Real Window Capture

## Ziel / Problem
TASK_985 liefert ein kleines Szenario-Outcome als read-only Contract, aber es gibt noch keinen echten Fenster-/Capture-Rahmen dafuer.

Der naechste Schritt soll festhalten, ob Outcome-Zeile, Mini-Zielzustand und naechster Griff im laufenden Release-Fenster sichtbar geprueft werden koennen.

## Sinnhaftigkeit / Ursache
Ein Outcome im Snapshot reicht nicht. Fuer ein angenehmes, spielbares Gefuehl muss der sichtbare Fensterzustand reproduzierbar eingefangen und danach manuell bewertet werden koennen.

## Umfang
- Neuer read-only Real-Window-Capture-Service fuer TASK_986.
- Manifest-/Analyzer-Rahmen fuer einen bestandenen TASK_985-Outcome-Slice.
- Capture-Tool-Rahmen mit Pflichtchecks fuer Outcome-Zeile, Mini-Zielzustand, naechsten Griff, HUD-read-only und Multiplayer-Grenze.
- Controller-Snapshot und Command-Feedback-Export.
- Status-/Roadmap-/Contract-Update.

## Nicht-Ziele
- Keine automatische manuelle Sichtabnahme.
- Kein neues Missionszielsystem.
- Kein Screenshot-Pixelvergleich.
- Kein Combat-, Movement- oder Multiplayer-Rewrite.
- Keine Shortcut-Aenderung.

## Relevante Contracts / Dokumente
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_985_release_first_decision_loop_two_player_loop_scenario_outcome_slice.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`

## Akzeptanzkriterien
- TASK_986 blockiert ehrlich, wenn TASK_985 fehlt, nicht ready oder nicht read-only ist.
- Ein bestandener TASK_985-Slice ohne Manifest bleibt `needs_outcome_real_window_capture`.
- Ein gueltiges Manifest wird `review_ready`, aber nicht automatisch akzeptiert.
- Manuell vollstaendig erledigte Checks koennen den Capture als `accepted` markieren.
- Tool setzt `manual_review_done = $false`, `updates_shortcuts = $false` und schreibt Manifestdaten mit Screenshotpfaden.
- Snapshot und Controller-Export erzeugen keine UI-, Command-, Movement-, Fire-, Damage- oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_outcome_real_window_capture.gd`
- `scripts/tools/capture_release_first_decision_loop_two_player_loop_outcome_real_window.ps1`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_986_release_first_decision_loop_two_player_loop_outcome_real_window_capture.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_986_release_first_decision_loop_two_player_loop_outcome_real_window_capture.gd`
- Regression: TASK_985, TASK_984, TASK_983
- `git diff --check`

## Risiken / offene Punkte
- TASK_986 ist noch kein visueller Befund; er macht nur den Capture reviewbar.
- Naechster sinnvoller Schritt: `TASK_987 - Release First Decision Loop Two Player Loop Outcome Visual Findings`.
