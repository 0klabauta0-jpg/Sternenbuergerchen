# TASK_1012 - Release First Decision Loop Two Player Loop Scenario Stitch

## Ziel / Problem
Der akzeptierte Round-Loop aus TASK_1011 ist als Spielergriff lesbar, aber noch kein kleiner Spielmoment. TASK_1012 stitcht ihn in einen minimalen Szenario-Rahmen: FOB-Einstieg, klares Objective, NPC-Druck, zwei Spielerrollen, FEEL/NEXT/GO-Rhythmus, Feedback-zurueck-zu-NEXT und Exit.

## Sinnhaftigkeit / Ursache
Der naechste Schritt zum runden kleinen Spiel ist nicht mehr nur ein weiterer HUD-Snapshot. Der Spieler braucht Kontext: Warum bin ich hier, was soll ich sichern, wer haelt welchen Blickwinkel, und was passiert nach dem Feedback? Dieser Task beschreibt diese Struktur read-only, damit der folgende Runtime-Hook gezielt bauen kann.

## Umfang
- Neuer read-only Service `ReleaseFirstDecisionLoopTwoPlayerLoopScenarioStitch`.
- Bewertung einer TASK_1011-Acceptance-Quelle plus optionalem Szenario-Stitch-Trace.
- Exporte fuer Szenario-Beats, Objective-Zeile, NPC-Druck, zwei Spielerrollen, Stitch-Zeile, Status und empfohlenen naechsten Task.
- Anbindung an `MissionTacticalSandboxController.get_command_feedback_snapshot()`.

## Nicht-Ziele
- Keine neue Mission-Runtime.
- Keine neuen Commands.
- Kein Movement, Combat, Damage oder Multiplayer-State.
- Keine UI-Tree-Erzeugung und keine neue Gameplay-Wahrheit im HUD.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/tasks/TASK_1011_release_first_decision_loop_two_player_loop_micro_objective_round_loop_acceptance_slice.md`

## Akzeptanzkriterien
- Ohne akzeptierte TASK_1011-Quelle blockt der Snapshot mit konkreten Source-Issues.
- Eine akzeptierte Quelle ohne Stitch-Trace bleibt `needs_scenario_stitch_trace`.
- Ein regressiver Trace nennt fehlende Beats, Rollen oder Grenzen und routet zurueck zu TASK_1011.
- Ein guter Trace setzt `scenario_stitch_ready`, nennt FOB/FEEL/GO separat und routet zu `TASK_1013 - Release First Decision Loop Two Player Loop Scenario Runtime Hook`.
- Alle Outputs bleiben read-only und erzeugen keine Commands, kein Movement, keine Fire-/Damage-Events und keine Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_scenario_stitch.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1012_release_first_decision_loop_two_player_loop_scenario_stitch.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_1012_release_first_decision_loop_two_player_loop_scenario_stitch.gd`
- Regression: TASK_1011, TASK_1010, TASK_1009
- `git diff --check`

## Risiken / offene Punkte
TASK_1012 beschreibt den Szenario-Stitch nur als Contract. Der naechste sinnvolle Schritt ist TASK_1013, der diese Struktur als echten Runtime-Hook in den kleinen FOB-Loop bringt.
