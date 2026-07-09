# TASK_1020 - Release First Decision Loop Two Player Loop Scenario Acceptance Slice

## Ziel / Problem
TASK_1019 kann einen sauberen Sichtbefund fuer den kleinen FOB-Szenario-Griff liefern, aber der Griff ist damit noch nicht als spielbarer Acceptance-Slice gesichert. TASK_1020 prueft, ob der Ablauf als kleiner, runder Spielmoment traegt.

## Sinnhaftigkeit / Ursache
Der Weg zum angenehmen kleinen Spiel braucht eine klare Akzeptanzgrenze: FOB-Einstieg, Objective, Alpha/Bravo-Rollen, NEXT/CONFIRM/GO, Feedback und Multiplayer-Grenze muessen im selben Ablauf beantwortet werden, ohne dass das HUD Gameplay-Wahrheit erzeugt.

## Umfang
- Neuer read-only Scenario-Acceptance-Service fuer TASK_1020.
- Bewertung akzeptierter TASK_1019-Findings plus optionalem Acceptance-Trace.
- Pflichtchecks fuer FOB-Entry, Objective, Rollen, NEXT/CONFIRM/GO, Feedback-zurueck-zu-NEXT, GO-Grenze, HUD-Ruhe, Responsiveness, Multiplayer-Grenze und keine HUD-Gameplay-Wahrheit.
- Export im `MissionTacticalSandboxController` und Command-Feedback.
- Routing zu `TASK_1021 - Release First Decision Loop Two Player Loop Scenario Integrated Playtest`, wenn der Slice besteht.
- Doku in Status, Roadmap und relevanten Contracts.

## Nicht-Ziele
- Kein neues HUD-Layout.
- Kein automatisches `GO`.
- Keine Commands, kein Movement, keine Combat-/Damage-Wirkung.
- Keine Multiplayer-Wahrheit.
- Kein Ersatz fuer spaetere echte integrierte Playtests.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_1019_release_first_decision_loop_two_player_loop_scenario_visual_findings.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Akzeptanzkriterien
- TASK_1020 blockiert ehrlich, wenn TASK_1019 nicht `accepted_for_scenario_acceptance_slice` ist.
- Ohne Acceptance-Trace bleibt der Status `needs_scenario_acceptance_trace`.
- Fehlende Trace-Checks melden konkrete `scenario_acceptance_regression_found`-Issues.
- Ein guter Trace setzt `scenario_acceptance_slice_passed` und `ready_for_integrated_playtest`.
- Die Acceptance-Zeile nennt FOB, NEXT, GO und FEEDBACK.
- Snapshot bleibt read-only und erzeugt keine Commands, kein Movement, keine Fire-/Damage-Events und keine Multiplayer-Wahrheit.
- Der Controller exportiert TASK_1020 im Command-Feedback als Snapshot, Zeile und Status.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_scenario_acceptance_slice.gd`
- `scripts/tests/task_1020_release_first_decision_loop_two_player_loop_scenario_acceptance_slice.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_1020_release_first_decision_loop_two_player_loop_scenario_acceptance_slice.gd`
- Regression: TASK_1019, TASK_1018, TASK_1017
- `git diff --check`

## Risiken / offene Punkte
TASK_1020 ist ein Acceptance-Slice mit Trace-Evidence, noch kein voll integrierter Playtest. Der naechste Schritt sollte den akzeptierten Slice im echten Release-/Mission-Kontext als integrierten Playtest pruefen.
