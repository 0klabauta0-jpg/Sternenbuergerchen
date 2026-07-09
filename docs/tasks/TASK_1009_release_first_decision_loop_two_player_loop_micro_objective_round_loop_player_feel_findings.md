# TASK_1009 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Player Feel Findings

## Ziel / Problem
TASK_1008 prueft den integrierten Round-Loop technisch als Trace-Gate, sagt aber noch nicht, ob sich der Ablauf fuer den Spieler angenehm, rund und lesbar anfuehlt. TASK_1009 schneidet daraus Player-Feel-Findings: Was wirkt gut, was reibt, und ob der naechste Schritt ein enger Feel-Polish oder ein Acceptance-Slice sein soll.

## Sinnhaftigkeit / Ursache
Das Spiel soll nicht nur korrekt sein, sondern angenehm spielbar und huebsch lesbar wirken. Nach dem integrierten Gate braucht es einen strukturierten Befund zu Einstieg, Command-Feedback, `ROUND`, `NEXT`, `GO`, Feedback, Loop-Rhythmus, HUD-Ruhe, Multiplayer-Grenze und Performance-Gefuehl.

## Umfang
- Neuer read-only Player-Feel-Findings-Service fuer TASK_1009.
- Bewertung eines bestandenen TASK_1008-Integrated-Playtest-Snapshots plus optionaler Player-Feel-Notizen.
- Positive Findings fuer gelungene Lesbarkeit.
- Issues fuer belegte Reibung:
  - Entry/Start unklar
  - `ROUND`/`NEXT`/`GO` nicht als Rhythmus lesbar
  - Feedback zu trocken oder ohne naechsten Griff
  - Confirm-/GO-Grenze nicht spuerbar
  - HUD zu laut oder instabil
  - Performance fuehlt sich zaeh an
  - Multiplayer-Grenze unklar
- Export im `MissionTacticalSandboxController` und Command-Feedback.
- Doku in Status, Roadmap und relevanten Contracts.

## Nicht-Ziele
- Kein Visual-Polish selbst.
- Kein Screenshot.
- Kein neuer Combat-, Movement- oder Multiplayer-Resolver.
- Keine Gameplay-Mutation im Snapshot.
- Kein Control-Tree-Rebuild im Hotpath.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_1008_release_first_decision_loop_two_player_loop_micro_objective_round_loop_integrated_playtest.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Akzeptanzkriterien
- TASK_1009 blockiert ehrlich, wenn TASK_1008 nicht `round_loop_integrated_playtest_passed` oder nicht `ready_for_player_feel_findings` ist.
- Ohne Player-Feel-Notizen bleibt der Slice `needs_player_feel_review`.
- Reibung erzeugt konkrete Issues und routet zu `TASK_1010 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Player Feel Polish`.
- Saubere Notizen erzeugen positive Findings und routen zu `TASK_1010 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Acceptance Slice`.
- Der Controller exportiert TASK_1009 im Command-Feedback.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_micro_objective_round_loop_player_feel_findings.gd`
- `scripts/tests/task_1009_release_first_decision_loop_two_player_loop_micro_objective_round_loop_player_feel_findings.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_1009_release_first_decision_loop_two_player_loop_micro_objective_round_loop_player_feel_findings.gd`
- Regression: TASK_1008, TASK_1007, TASK_1006
- `git diff --check`

## Risiken / offene Punkte
TASK_1009 verbessert noch nicht die UI selbst. Er trennt sauber zwischen belegter Reibung und akzeptiertem Spielerblick, damit der naechste Task gezielt polishen oder akzeptieren kann.
