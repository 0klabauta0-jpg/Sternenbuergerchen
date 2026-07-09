# TASK_1017 - Release First Decision Loop Two Player Loop Scenario Playability Slice

## Ziel / Problem
TASK_1016 macht den kleinen FOB-Szenario-Griff textlich ruhiger, beweist aber noch nicht, dass der Ablauf als Spielerentscheidung rund genug ist. TASK_1017 bewertet deshalb einen Playability-Trace: Der Spieler erkennt FOB-Start, Objective, Alpha/Bravo-Rollen, NEXT/CONFIRM/GO, Feedback und die read-only Multiplayer-Grenze.

## Sinnhaftigkeit / Ursache
Der Release-Pfad braucht jetzt einen winzigen, verstandenen Spielgriff statt weiterer Rohfunktionen. Wenn `FOB -> NEXT -> CONFIRM -> GO -> FEEDBACK -> NEXT` als Szenario-Slice tragfaehig ist, kann danach ein echter Fensterbeweis und spaeter mehr KI-/Multiplayer-/Szenarioinhalt folgen, ohne HUD-State zur Gameplay-Wahrheit zu machen.

## Umfang
- Neuer read-only Playability-Slice-Service fuer TASK_1017.
- Bewertung eines bereiten TASK_1016-Scenario-Player-Feel-Polish-Snapshots plus Playability-Trace.
- Pflichtchecks fuer FOB-Entry, Objective, zwei Rollen, NEXT/CONFIRM/GO, GO-Grenze, Feedback-zurueck-zu-NEXT, HUD-Ruhe, Responsiveness, Multiplayer-Grenze und keine Gameplay-Wahrheitsmutation.
- Export im `MissionTacticalSandboxController` und Command-Feedback.
- Doku in Status, Roadmap und relevanten Contracts.

## Nicht-Ziele
- Kein neuer Combat-Resolver.
- Kein echter Screenshot.
- Kein neues UI-Layout.
- Kein automatisches `GO`.
- Keine Movement-, Combat-, Damage- oder Multiplayer-Mutatoren.
- Kein Control-Tree-Rebuild im Hotpath.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_1016_release_first_decision_loop_two_player_loop_scenario_player_feel_polish.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Akzeptanzkriterien
- TASK_1017 blockiert ehrlich, wenn TASK_1016 nicht `scenario_player_feel_polish_ready` ist.
- Ohne Trace bleibt der Slice `needs_scenario_playability_trace`.
- Ein unvollstaendiger Trace meldet konkrete Regressionen.
- Ein guter Trace setzt `scenario_playability_slice_passed = true`.
- Die Playability-Zeile nennt `FOB`, `NEXT`, `GO` und `FEEDBACK`.
- Der Controller exportiert TASK_1017 im Command-Feedback.
- Der naechste sinnvolle Schritt ist `TASK_1018 - Release First Decision Loop Two Player Loop Scenario Real Window Capture`.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_scenario_playability_slice.gd`
- `scripts/tests/task_1017_release_first_decision_loop_two_player_loop_scenario_playability_slice.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_1017_release_first_decision_loop_two_player_loop_scenario_playability_slice.gd`
- Regression: TASK_1016, TASK_1015, TASK_1014
- `git diff --check`

## Risiken / offene Punkte
TASK_1017 ist ein Trace-/Contract-Gate, noch kein echter Fensterplaytest. Er sagt nur, ob die kleinste Szenario-Entscheidung rund genug ist, um danach im Fenster sichtbar bewiesen zu werden.
