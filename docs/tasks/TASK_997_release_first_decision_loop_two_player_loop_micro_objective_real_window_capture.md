# TASK_997 - Release First Decision Loop Two Player Loop Micro Objective Real Window Capture

## Ziel / Problem
TASK_996 liefert einen read-only Micro-Objective-Outcome, aber noch keinen echten Fenster-/Capture-Rahmen dafuer.

TASK_997 soll festhalten, ob Outcome-Zeile, Mini-Zielzustand und naechster Griff nach `SICHERN`, `DRUECKEN` oder `SAMMELN` im laufenden Release-Fenster sichtbar geprueft werden koennen.

## Sinnhaftigkeit / Ursache
Ein Snapshot allein macht das Spiel noch nicht angenehm spielbar. Der Spieler muss im echten Fenster lesen koennen, was sein Micro-Objective bewirkt hat und was als naechstes sinnvoll ist.

## Umfang
- Neuer read-only Real-Window-Capture-Service fuer TASK_997.
- Manifest-/Analyzer-Rahmen fuer einen bestandenen TASK_996-Micro-Objective-Outcome-Slice.
- Capture-Tool-Rahmen mit Pflichtchecks fuer Outcome-Zeile, Mini-Zielzustand, naechsten Griff, Spielerlesbarkeit, HUD-read-only und Multiplayer-Grenze.
- Controller-Snapshot und Command-Feedback-Export.
- Status-/Roadmap-/Contract-Update.

## Nicht-Ziele
- Keine automatische manuelle Sichtabnahme.
- Kein neues Objective-State-System.
- Kein Screenshot-Pixelvergleich.
- Kein Movement-, Combat-, Damage- oder Multiplayer-Rewrite.
- Keine Shortcut-Aenderung.

## Relevante Contracts / Dokumente
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_996_release_first_decision_loop_two_player_loop_micro_objective_outcome_slice.md`
- `docs/tasks/TASK_995_release_first_decision_loop_two_player_loop_micro_objective_acceptance_slice.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`

## Akzeptanzkriterien
- TASK_997 blockiert ehrlich, wenn TASK_996 fehlt, nicht ready oder nicht read-only ist.
- Ein bestandener TASK_996-Slice ohne Manifest bleibt `needs_micro_objective_real_window_capture`.
- Ein gueltiges Manifest wird `review_ready`, aber nicht automatisch akzeptiert.
- Manuell vollstaendig erledigte Checks koennen den Capture als `accepted` markieren.
- Tool setzt `manual_review_done = $false`, `updates_shortcuts = $false` und schreibt Manifestdaten mit Screenshotpfaden.
- Snapshot und Controller-Export erzeugen keine UI-, Command-, Movement-, Fire-, Damage- oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_micro_objective_real_window_capture.gd`
- `scripts/tools/capture_release_first_decision_loop_two_player_loop_micro_objective_real_window.ps1`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_997_release_first_decision_loop_two_player_loop_micro_objective_real_window_capture.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_997_release_first_decision_loop_two_player_loop_micro_objective_real_window_capture.gd`
- Regression: TASK_996, TASK_995, TASK_994
- `git diff --check`

## Risiken / offene Punkte
- TASK_997 ist noch kein visueller Befund; er macht nur den Micro-Objective-Outcome-Capture reviewbar.
- Naechster sinnvoller Schritt: `TASK_998 - Release First Decision Loop Two Player Loop Micro Objective Visual Findings`.
