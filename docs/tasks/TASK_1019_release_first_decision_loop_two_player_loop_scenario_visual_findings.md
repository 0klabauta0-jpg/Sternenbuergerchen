# TASK_1019 - Release First Decision Loop Two Player Loop Scenario Visual Findings

## Ziel / Problem
TASK_1018 liefert den read-only Rahmen fuer einen echten Release-Fensterblick, aber noch keinen geschnittenen Sichtbefund. TASK_1019 bewertet diese Fenster-Evidence plus manuelle Sichtnotizen fuer den kleinen FOB-Szenario-Griff.

## Sinnhaftigkeit / Ursache
Der Weg zum runden kleinen Spiel braucht nicht nur technische Capture-Daten, sondern eine klare Antwort auf die Spielerfrage: sehe ich im Fenster FOB-Einstieg, Objective, Rollen, NEXT/CONFIRM/GO und Feedback gut genug, um ohne Raetseln weiterzuspielen?

## Umfang
- Neuer read-only Visual-Findings-Service fuer TASK_1019.
- Bewertung eines review-ready TASK_1018-Captures.
- Sichtnotizen fuer FOB-Entry, Objective, Alpha/Bravo-Rollen, NEXT/CONFIRM/GO, GO-Grenze, Feedback, HUD-Ruhe, Scenario-Playability-Zeile, Spielerlesbarkeit und Multiplayer-Grenze.
- Routing zu `TASK_1020 - Release First Decision Loop Two Player Loop Scenario Visual Polish` bei belegter Reibung.
- Routing zu `TASK_1020 - Release First Decision Loop Two Player Loop Scenario Acceptance Slice` bei sauberem Befund.
- Export im `MissionTacticalSandboxController` und Command-Feedback.
- Doku in Status, Roadmap und relevanten Contracts.

## Nicht-Ziele
- Kein automatischer Sichttest aus Screenshots.
- Kein neues HUD-Layout.
- Kein automatisches `GO`.
- Keine Movement-, Combat-, Damage- oder Multiplayer-Mutatoren.
- Keine Shortcut-Aenderungen.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_1018_release_first_decision_loop_two_player_loop_scenario_real_window_capture.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Akzeptanzkriterien
- TASK_1019 blockiert ehrlich, wenn TASK_1018 nicht review-ready ist.
- Ohne Review-Notizen meldet TASK_1019 `needs_manual_review`.
- Sichtreibung meldet konkrete Issues und routet zu `TASK_1020 - Release First Decision Loop Two Player Loop Scenario Visual Polish`.
- Ein sauberer Sichtbefund meldet `accepted_for_scenario_acceptance_slice` und routet zu `TASK_1020 - Release First Decision Loop Two Player Loop Scenario Acceptance Slice`.
- Snapshot bleibt read-only und erzeugt keine Commands, kein Movement, keine Fire-/Damage-Events und keine Multiplayer-Wahrheit.
- Der Controller exportiert TASK_1019 im Command-Feedback als Snapshot, Status und Issue-Count.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_scenario_visual_findings.gd`
- `scripts/tests/task_1019_release_first_decision_loop_two_player_loop_scenario_visual_findings.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_1019_release_first_decision_loop_two_player_loop_scenario_visual_findings.gd`
- Regression: TASK_1018, TASK_1017, TASK_1016
- `git diff --check`

## Risiken / offene Punkte
TASK_1019 bewertet Review-Notizen, ersetzt aber keine menschliche Sichtabnahme. Der naechste Task sollte je nach Befund entweder die sichtbaren Szenario-Flaechen polieren oder den Acceptance-Slice fuer den kleinen FOB-Szenario-Griff schneiden.
