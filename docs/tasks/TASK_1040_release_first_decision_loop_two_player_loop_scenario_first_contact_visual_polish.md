# TASK_1040 - Release First Decision Loop Two Player Loop Scenario First Contact Visual Polish

## Ziel / Problem
TASK_1039 trennt den echten Fensterblick in akzeptierten Befund oder sichtbare Reibung. TASK_1040 macht daraus konkrete, ruhige Surface-Specs fuer den ersten Kontakt, damit CONTACT, WHY, NEXT, FIRE/WAIT, FEEDBACK und `GO separat` im naechsten Slice als klare Spielerflaechen auftauchen koennen.

## Sinnhaftigkeit / Ursache
Der Sichtbefund benennt Probleme, aber er gestaltet noch keine Leseflaechen. Fuer ein angenehmes kleines Spielgefuehl braucht der erste Kontakt eine konsistente visuelle Sprache: wenige starke Tokens, kurze Texte, stabile Flaechenhoehen und keine zweite Gameplay-Wahrheit im HUD.

## Umfang
- Neuer read-only Analyzer `ReleaseFirstDecisionLoopTwoPlayerLoopScenarioFirstContactVisualPolish`.
- Surface-Specs fuer CONTACT, WHY, NEXT, FIRE/WAIT, FEEDBACK, GO und HUD/MP.
- Kompakte Polish-Line, NEXT-Line, FIRE/WAIT-Microcopy und GO-Microcopy.
- Export im `MissionTacticalSandboxController` Command-Feedback.
- Folgtask: `TASK_1041 - Release First Decision Loop Two Player Loop Scenario First Contact Acceptance Slice`.

## Nicht-Ziele
- Kein neuer HUD-Control-Tree und kein Layout-Rewrite.
- Keine automatische Pixelbewertung.
- Keine Commands, kein Movement, keine Fire-/Damage-Events und keine Multiplayer-Autoritaet.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_1039_release_first_decision_loop_two_player_loop_scenario_first_contact_visual_findings.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`

## Akzeptanzkriterien
- Fehlende oder nicht polishbare TASK_1039-Quelle blockiert mit klaren Issues.
- Reibungsquelle und akzeptierte Quelle erzeugen stabile First-Contact-Surface-Specs.
- Specs bleiben read-only, haben feste Textbudgets und erzeugen keine Commands.
- Controller exportiert Snapshot, Polish-Line, Surface-Specs und Status.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_scenario_first_contact_visual_polish.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1040_release_first_decision_loop_two_player_loop_scenario_first_contact_visual_polish.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_1040_release_first_decision_loop_two_player_loop_scenario_first_contact_visual_polish.gd`
- Regressionen: TASK_1039, TASK_1038, TASK_1037
- `git diff --check`

## Risiken / offene Punkte
TASK_1040 beschreibt die sichtbare Sprache als Contract. Der naechste Schritt muss sie in einem Acceptance-Slice gegen den echten First-Contact-Griff pruefen.
