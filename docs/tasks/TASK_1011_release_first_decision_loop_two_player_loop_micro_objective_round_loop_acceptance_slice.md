# TASK_1011 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Acceptance Slice

## Ziel / Problem
TASK_1010 macht den Round-Loop als Player-Feel-Polish lesbar, aber noch nicht als akzeptierten kleinen Spielgriff. TASK_1011 bewertet den Polish mit einem Acceptance-Trace: Sieht der Spieler `FEEL`, `NEXT`, `GO`, versteht den Start, bekommt Feedback und landet wieder bei der naechsten Entscheidung?

## Sinnhaftigkeit / Ursache
Der aktuelle Arbeitsstrang soll weg vom reinen Contract-Stapeln und hin zu einem kleinen, runden Spielgefuehl. Dafuer braucht es ein klares Gate, das den `FEEL -> NEXT -> GO -> FEEDBACK -> NEXT`-Loop als akzeptierten Griff markiert, bevor wir ihn in ein kleines Szenario stitchten.

## Umfang
- Neuer read-only Acceptance-Slice-Service fuer TASK_1011.
- Bewertung eines TASK_1010-Player-Feel-Polish-Snapshots plus optionalem Acceptance-Trace.
- Pflichtchecks:
  - `FEEL/NEXT/GO` sichtbar
  - Start-Kontext klar
  - Round-/Next-/GO-Rhythmus klar
  - Feedback fuehrt zu NEXT zurueck
  - GO-Grenze klar
  - HUD ruhig
  - Performance fuehlt sich responsiv an
  - Multiplayer-Grenze erhalten
  - HUD setzt keine Gameplay-Wahrheit
- Export im `MissionTacticalSandboxController` und Command-Feedback.

## Nicht-Ziele
- Kein neues Szenario selbst.
- Kein neuer Button-Tree.
- Kein Screenshot.
- Kein Combat-, Movement- oder Multiplayer-Resolver.
- Keine Gameplay-Mutation im Snapshot.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_1010_release_first_decision_loop_two_player_loop_micro_objective_round_loop_player_feel_polish.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Akzeptanzkriterien
- TASK_1011 blockiert ehrlich, wenn TASK_1010 nicht acceptance-ready oder nicht read-only ist.
- Ohne Trace bleibt der Slice `needs_round_loop_acceptance_trace`.
- Regressions-Traces routen zurueck zu TASK_1010 Player Feel Polish.
- Gute Traces setzen `round_loop_acceptance_slice_passed`.
- Die Acceptance-Zeile nennt `FEEL`, `NEXT` und `GO separat`.
- Der naechste Follow-up ist `TASK_1012 - Release First Decision Loop Two Player Loop Scenario Stitch`.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_micro_objective_round_loop_acceptance_slice.gd`
- `scripts/tests/task_1011_release_first_decision_loop_two_player_loop_micro_objective_round_loop_acceptance_slice.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_1011_release_first_decision_loop_two_player_loop_micro_objective_round_loop_acceptance_slice.gd`
- Regression: TASK_1010, TASK_1009, TASK_1008
- `git diff --check`

## Risiken / offene Punkte
TASK_1011 ist weiterhin ein Contract-/Trace-Gate. Der naechste echte Spielschritt ist TASK_1012: den akzeptierten Round-Loop in ein kleines Szenario stitchten, damit er nicht nur als Snapshot, sondern als Spielmoment getragen wird.
