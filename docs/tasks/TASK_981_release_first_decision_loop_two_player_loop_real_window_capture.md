# TASK_981 - Release First Decision Loop Two Player Loop Real Window Capture

## Ziel / Problem
TASK_980 beweist den Choice-Confirm als Smoke, aber noch nicht den echten Fensterblick: Sind `SECURE`, `PUSH`, `FLANK` und `RESET` im laufenden Spiel sichtbar, lesbar und bestaetigbar, bleibt `GO` getrennt, und ist das Feedback nach Confirm sichtbar?

## Sinnhaftigkeit / Ursache
Das Spiel soll sich wie ein kleiner runder Ablauf anfuehlen. Dafuer reicht ein reiner Contract-Smoke nicht; wir brauchen einen reproduzierbaren Capture-Rahmen, der den echten Runtime-Zustand pruefbar macht, ohne selbst Gameplay-State zu erzeugen.

## Umfang
- Neuer read-only Real-Window-Capture-Analyzer fuer TASK_981.
- Capture-Manifest mit Prozess-/Screenshot-/Pflichtcheck-Feldern.
- PowerShell-Capture-Vorbereitung unter `scripts/tools/`.
- Pflichtchecks fuer sichtbare Choice-Buttons, Confirm-Feedback, getrenntes `GO`, Smoke-Zeile, HUD-read-only-Grenze und Multiplayer-Grenze.

## Nicht-Ziele
- Keine automatische manuelle Sichtabnahme.
- Kein neuer Button-Workflow.
- Kein Combat-, Movement- oder Multiplayer-Rewrite.
- Kein automatisches `GO`.
- Keine Shortcut-Aenderung.

## Relevante Contracts / Dokumente
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_980_release_first_decision_loop_two_player_loop_choice_confirm_smoke.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`

## Akzeptanzkriterien
- TASK_981 blockiert ehrlich, wenn TASK_980 nicht bestanden/read-only ist.
- Bestandener TASK_980-Smoke ohne Manifest bleibt `needs_real_window_capture`.
- Gueltiges Manifest wird `review_ready`, aber nicht automatisch akzeptiert.
- Erst abgeschlossene manuelle Pflichtchecks akzeptieren TASK_981.
- Manifest und Analyzer erzeugen keine UI-, Command-, Movement-, Fire-, Damage- oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_real_window_capture.gd`
- `scripts/tools/capture_release_first_decision_loop_two_player_loop_real_window.ps1`
- `scripts/tests/task_981_release_first_decision_loop_two_player_loop_real_window_capture.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_981_release_first_decision_loop_two_player_loop_real_window_capture.gd`
- Regression: TASK_980, TASK_979, TASK_978
- `git diff --check`

## Risiken / offene Punkte
- TASK_981 schafft den Capture- und Review-Rahmen, ersetzt aber keine echte menschliche Sichtabnahme.
- Naechster sinnvoller Schritt: `TASK_982 - Release First Decision Loop Two Player Loop Visual Findings`.
