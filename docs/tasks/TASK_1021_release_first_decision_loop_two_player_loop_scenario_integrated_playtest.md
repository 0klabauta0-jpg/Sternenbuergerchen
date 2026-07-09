# TASK_1021 - Release First Decision Loop Two Player Loop Scenario Integrated Playtest

## Ziel / Problem
TASK_1020 beweist den kleinen FOB-Szenario-Griff als Acceptance-Slice, aber noch nicht im integrierten Release-/Mission-Kontext. TASK_1021 prueft, ob derselbe Griff im zusammenhaengenden Playtest sichtbar, lesbar, getrennt bestaetigt und performant bleibt.

## Sinnhaftigkeit / Ursache
Der Weg zu "fuehlt sich wie ein rundes kleines Spiel an" braucht einen echten Integrationspunkt zwischen Release-Entry, Command-Feedback, NEXT/CONFIRM/GO, Post-GO-Feedback und Multiplayer-Grenze. Dieser Task macht diese Grenze messbar, ohne neue Gameplay-Wahrheit im HUD zu erzeugen.

## Umfang
- Neuer read-only Scenario-Integrated-Playtest-Service fuer TASK_1021.
- Bewertung eines bestandenen TASK_1020-Slices plus optionalem Integrated-Playtest-Trace.
- Pflichtchecks fuer Release-/Mission-Entry, Command-Feedback, FOB-Entry, Objective, Rollen, NEXT/CONFIRM/GO, GO-Grenze, Post-GO-Feedback, Rueckkehr zu NEXT, HUD-read-only, Multiplayer-Grenze und Performance-Budget.
- Export im `MissionTacticalSandboxController` und Command-Feedback als Snapshot, Zeile, Status und Gate.
- Routing zu `TASK_1022 - Release First Decision Loop Two Player Loop Scenario Player Feel Findings`, wenn der integrierte Playtest besteht.
- Doku in Status, Roadmap und relevanten Contracts.

## Nicht-Ziele
- Kein neues HUD-Layout.
- Kein automatisches `GO`.
- Keine Commands, kein Movement, keine Combat-/Damage-Wirkung.
- Keine Multiplayer-Wahrheit.
- Keine Player-Feel-Politur; das ist TASK_1022.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_1020_release_first_decision_loop_two_player_loop_scenario_acceptance_slice.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Akzeptanzkriterien
- TASK_1021 blockiert ehrlich, wenn TASK_1020 nicht `scenario_acceptance_slice_passed` oder nicht `ready_for_integrated_playtest` ist.
- Ohne Integrated-Trace bleibt der Status `needs_scenario_integrated_playtest_trace`.
- Fehlende Trace-Checks melden konkrete `scenario_integrated_playtest_regression_found`-Issues.
- Ein guter Trace setzt `scenario_integrated_playtest_passed` und `ready_for_player_feel_findings`.
- Die Integrated-Playtest-Zeile nennt ENTRY, FOB, NEXT, GO und FEEDBACK.
- Snapshot bleibt read-only und erzeugt keine Commands, kein Movement, keine Fire-/Damage-Events und keine Multiplayer-Wahrheit.
- Der Controller exportiert TASK_1021 im Command-Feedback als Snapshot, Zeile, Status und Gate.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_scenario_integrated_playtest.gd`
- `scripts/tests/task_1021_release_first_decision_loop_two_player_loop_scenario_integrated_playtest.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_1021_release_first_decision_loop_two_player_loop_scenario_integrated_playtest.gd`
- Regression: TASK_1020, TASK_1019, TASK_1018
- `git diff --check`

## Risiken / offene Punkte
TASK_1021 ist ein integrierter Trace-Vertrag, aber noch kein menschlicher Player-Feel-Befund. Der naechste Schritt sollte aus dem bestandenen Trace konkrete Reibung, Tempo und "rundes Spielgefuehl" schneiden.
