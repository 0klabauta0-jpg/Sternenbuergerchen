# TASK_982 - Release First Decision Loop Two Player Loop Visual Findings

## Ziel / Problem
TASK_981 stellt den Real-Window-Capture-Rahmen fuer `SECURE`, `PUSH`, `FLANK` und `RESET` bereit, aber daraus entstehen noch keine konkreten Sichtbefunde.

Wir brauchen eine kleine, nachvollziehbare Auswertung: Ist der neue Spielerloop im echten Fenster lesbar genug, um in den naechsten Acceptance-Slice zu gehen, oder braucht er vorher Visual Polish?

## Sinnhaftigkeit / Ursache
Der Weg Richtung "rundes kleines Spiel" scheitert nicht nur an Logik, sondern an Lesbarkeit. Die vier Choice-Buttons muessen als Spielentscheidung verstanden werden, nicht als Debug-Knoepfe. TASK_982 trennt technische Capture-Evidence von menschlicher Spielbarkeit.

## Umfang
- Neuer read-only Visual-Findings-Service fuer TASK_982.
- Auswertung von TASK_981-Capture-Snapshot plus manuellen Review-Notizen.
- Positive Findings und konkrete Issues fuer:
  - korrektes Fenster
  - vier sichtbare/lesbare Choices
  - beobachteten Choice-Confirm
  - sichtbares/lesbares Confirm-Feedback
  - getrenntes `GO`
  - keine Ausfuehrung vor `GO`
  - HUD-read-only-Grenze
  - Multiplayer-Grenze
  - Gesamtlesbarkeit fuer Spieler

## Nicht-Ziele
- Kein neuer Capture.
- Kein automatischer Sichtbefund.
- Kein UI-Polish in diesem Task.
- Kein neuer Command-, Movement-, Combat- oder Multiplayer-Pfad.

## Relevante Contracts / Dokumente
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_981_release_first_decision_loop_two_player_loop_real_window_capture.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`

## Akzeptanzkriterien
- TASK_982 blockiert ehrlich, wenn TASK_981 nicht review-ready/read-only ist.
- Review-ready Source ohne manuelle Notizen bleibt `needs_manual_review`.
- Manuelle Notizen mit Reibungen routen zu `TASK_983 - Release First Decision Loop Two Player Loop Visual Polish`.
- Saubere manuelle Notizen akzeptieren den Befund fuer `TASK_983 - Release First Decision Loop Two Player Loop Acceptance Slice`.
- Snapshot erzeugt keine UI-, Command-, Movement-, Fire-, Damage- oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_visual_findings.gd`
- `scripts/tests/task_982_release_first_decision_loop_two_player_loop_visual_findings.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_982_release_first_decision_loop_two_player_loop_visual_findings.gd`
- Regression: TASK_981, TASK_980, TASK_979
- `git diff --check`

## Risiken / offene Punkte
- TASK_982 bewertet nur vorhandene Review-Notizen; echte UI-Verbesserung folgt erst bei Reibung.
- Naechster sinnvoller Schritt: je nach Befund `TASK_983 - Release First Decision Loop Two Player Loop Visual Polish` oder `TASK_983 - Release First Decision Loop Two Player Loop Acceptance Slice`.
