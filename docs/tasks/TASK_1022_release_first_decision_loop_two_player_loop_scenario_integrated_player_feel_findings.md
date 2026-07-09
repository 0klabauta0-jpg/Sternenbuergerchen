# TASK_1022 - Release First Decision Loop Two Player Loop Scenario Player Feel Findings

## Ziel / Problem
TASK_1021 beweist den kleinen FOB-Szenario-Griff im integrierten Release-/Mission-Kontext technisch. TASK_1022 prueft, ob sich dieser Griff fuer einen Spieler auch angenehm, lesbar, schnell und rund anfuehlt.

## Sinnhaftigkeit / Ursache
Ein Spiel kann technisch korrekt sein und sich trotzdem trocken oder hakelig anfuehlen. Fuer das Ziel "fuehlt sich wie ein rundes kleines Spiel an" braucht der integrierte Trace eine menschliche Player-Feel-Auswertung: Einstieg, FOB-Griff, NEXT/CONFIRM/GO, Post-GO-Feedback, HUD-Ruhe, Responsiveness, Zwei-Spieler-Kontext und Multiplayer-Grenze.

## Umfang
- Neuer read-only Player-Feel-Findings-Service fuer TASK_1022.
- Bewertung eines bestandenen TASK_1021 Integrated-Playtest-Snapshots plus optionaler Player-Feel-Notizen.
- Issues fuer unklaren Entry, unrunden FOB-Griff, unklare NEXT/CONFIRM/GO-Grenze, trockenes Post-GO-Feedback, verwirrende Rueckkehr zu NEXT, lautes HUD, traege Performance, unklare Multiplayer-Grenze, unklaren Zwei-Spieler-Kontext und fehlende Rundheit.
- Export im `MissionTacticalSandboxController` und Command-Feedback als Snapshot, Status, Issue-Count und Summary-Zeile.
- Routing zu `TASK_1023 - Release First Decision Loop Two Player Loop Scenario Player Feel Polish` bei Reibung.
- Routing zu `TASK_1023 - Release First Decision Loop Two Player Loop Scenario Small Game Acceptance Slice` bei sauberem Befund.

## Nicht-Ziele
- Kein neues HUD-Layout.
- Keine Politur in diesem Task.
- Kein automatisches `GO`.
- Keine Commands, kein Movement, keine Combat-/Damage-Wirkung.
- Keine Multiplayer-Wahrheit.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_1021_release_first_decision_loop_two_player_loop_scenario_integrated_playtest.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Akzeptanzkriterien
- TASK_1022 blockiert ehrlich, wenn TASK_1021 nicht `scenario_integrated_playtest_passed` oder nicht `ready_for_player_feel_findings` ist.
- Ohne Player-Feel-Notizen bleibt der Status `needs_scenario_integrated_player_feel_review`.
- Reibungsnotizen erzeugen konkrete Issues und routen zu `TASK_1023 - Release First Decision Loop Two Player Loop Scenario Player Feel Polish`.
- Saubere Notizen setzen `accepted_for_small_game_acceptance_slice` und `ready_for_small_game_acceptance_slice`.
- Die Summary-Zeile nennt bei gutem Befund FOB, NEXT und GO.
- Snapshot bleibt read-only und erzeugt keine Commands, kein Movement, keine Fire-/Damage-Events und keine Multiplayer-Wahrheit.
- Der Controller exportiert TASK_1022 im Command-Feedback als Snapshot, Status, Issue-Count und Summary.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_scenario_integrated_player_feel_findings.gd`
- `scripts/tests/task_1022_release_first_decision_loop_two_player_loop_scenario_integrated_player_feel_findings.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_1022_release_first_decision_loop_two_player_loop_scenario_integrated_player_feel_findings.gd`
- Regression: TASK_1021, TASK_1020, TASK_1019
- `git diff --check`

## Risiken / offene Punkte
TASK_1022 sammelt Befunde, baut aber noch keine Politur. Wenn Reibung dokumentiert wird, muss TASK_1023 gezielt die sichtbaren Stellen verbessern. Wenn der Befund sauber ist, sollte TASK_1023 den kleinen Spielmoment als Small-Game-Acceptance-Slice absichern.
