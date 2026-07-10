# TASK_1039 - Release First Decision Loop Two Player Loop Scenario First Contact Visual Findings

## Ziel / Problem
TASK_1038 liefert den echten Fenster-/Capture-Rahmen fuer den First-Contact-Griff. TASK_1039 schneidet daraus einen konkreten Sichtbefund: Sieht der Spieler CONTACT, WHY, NEXT, FIRE/WAIT, FEEDBACK und `GO separat` im echten Fenster klar genug, um ohne Raten zu handeln?

## Sinnhaftigkeit / Ursache
Ein akzeptierter Capture beweist, dass das richtige Fenster und die Pflichtflaechen vorhanden sind. Er sagt aber noch nicht, ob die Anordnung, Lesbarkeit und visuelle Prioritaet fuer den ersten taktischen Kontakt wirklich genuegen. Der Sichtbefund trennt deshalb dokumentierte Reibung von einem akzeptablen naechsten Acceptance-Slice.

## Umfang
- Neuer read-only Analyzer `ReleaseFirstDecisionLoopTwoPlayerLoopScenarioFirstContactVisualFindings`.
- Review-Notizen fuer sichtbare CONTACT-, WHY-, NEXT-, FIRE/WAIT-, GO-, FEEDBACK-, HUD- und Multiplayer-Grenzen.
- Routing zu `TASK_1040 - Release First Decision Loop Two Player Loop Scenario First Contact Visual Polish` bei Reibung.
- Routing zu `TASK_1040 - Release First Decision Loop Two Player Loop Scenario First Contact Acceptance Slice` bei sauberem Sichtbefund.
- Export im `MissionTacticalSandboxController` Command-Feedback.

## Nicht-Ziele
- Keine automatische Pixel-/Screenshot-Bewertung.
- Kein neuer HUD-Tree, kein neues Overlay und keine neue Gameplay-Wahrheit.
- Keine Commands, kein Movement, keine Fire-/Damage-Events und keine Multiplayer-Autoritaet.

## Relevante Contracts / Dokumente
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_1038_release_first_decision_loop_two_player_loop_scenario_first_contact_real_window_capture.md`

## Akzeptanzkriterien
- Fehlende oder nicht akzeptierte TASK_1038-Quelle blockiert mit klaren Blocking-Issues.
- Akzeptierte TASK_1038-Quelle ohne Review-Notizen bleibt `needs_first_contact_visual_review`.
- Reibungsnotizen routen zu First-Contact-Visual-Polish.
- Saubere Notizen routen zu First-Contact-Acceptance-Slice.
- Snapshot und Controller-Export bleiben read-only und mutieren keine Runtime-Wahrheit.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_scenario_first_contact_visual_findings.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1039_release_first_decision_loop_two_player_loop_scenario_first_contact_visual_findings.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_1039_release_first_decision_loop_two_player_loop_scenario_first_contact_visual_findings.gd`
- Regressionen: TASK_1038, TASK_1037, TASK_1036
- `git diff --check`

## Risiken / offene Punkte
TASK_1039 ist ein Sichtbefund-Contract. Die eigentliche visuelle Korrektur folgt bei Reibung in `TASK_1040 - Release First Decision Loop Two Player Loop Scenario First Contact Visual Polish`; bei sauberem Befund folgt ein Acceptance-Slice.
