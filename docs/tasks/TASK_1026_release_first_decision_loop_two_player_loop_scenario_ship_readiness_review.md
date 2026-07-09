# TASK_1026 - Release First Decision Loop Two Player Loop Scenario Ship Readiness Review

## Ziel / Problem
TASK_1025 kann den kleinen FOB/NEXT/GO/FEEDBACK-Spielmoment als Release Candidate akzeptieren. TASK_1026 prueft danach, ob die Uebergabe fuer einen sichtbaren EXE-/Ship-Smoke wirklich bereit ist: Build-Pfade, Testerhinweise, offene Risiken und die Grenzen zu HUD-/Multiplayer-Wahrheit muessen vorliegen.

## Sinnhaftigkeit / Ursache
Nach einer Acceptance-Entscheidung darf der naechste Schritt nicht lose im Chat oder in einem Screenshot haengen bleiben. Vor `TASK_1027 - Release First Decision Loop Two Player Loop Scenario Visible Ship Smoke` braucht der Arbeitsstand ein kleines, maschinenlesbares Readiness-Paket, damit klar ist, was gestartet, geprueft und beobachtet werden soll.

## Umfang
- Neuer read-only Ship-Readiness-Review-Service fuer TASK_1026.
- Bewertung eines akzeptierten TASK_1025-Snapshots plus optionalem Ship-Readiness-Paket.
- Pflichtdaten fuer Release-EXE, PCK, Szenario-ID, Testerhinweise, Operator-Ziel, bekannte Risiken, Uebergabe-Items, Multiplayer-Grenze, HUD-Wahrheit und Review-Abschluss.
- Export im `MissionTacticalSandboxController` und Command-Feedback als Snapshot, Line, Status und Gate.
- Routing zu `TASK_1026 - Release First Decision Loop Two Player Loop Scenario Ship Readiness Polish` bei unvollstaendigem Paket.
- Routing zu `TASK_1027 - Release First Decision Loop Two Player Loop Scenario Visible Ship Smoke` bei sauberer Ship-Readiness.

## Nicht-Ziele
- Kein neuer Release-Export.
- Kein automatischer Sichttest.
- Keine neue UI-Politur.
- Keine Commands, kein Movement, keine Combat-/Damage-Wirkung.
- Keine Multiplayer-Wahrheit.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_1025_release_first_decision_loop_two_player_loop_scenario_release_candidate_acceptance.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Akzeptanzkriterien
- TASK_1026 blockiert ehrlich, wenn TASK_1025 nicht `release_candidate_accepted` oder nicht `ready_for_ship_readiness_review` ist.
- Ohne Ship-Readiness-Paket bleibt der Status `needs_ship_readiness_packet`.
- Fehlende Paketdaten melden `ship_readiness_incomplete` mit konkreten Missing-Items und Issues.
- Ein sauberes Paket setzt `ship_readiness_ready` und `ready_for_visible_ship_smoke`.
- Die Ship-Readiness-Line nennt `SHIP READY`, FOB, NEXT, GO und FEEDBACK.
- Snapshot bleibt read-only und erzeugt keine Commands, kein Movement, keine Fire-/Damage-Events und keine Multiplayer-Wahrheit.
- Der Controller exportiert TASK_1026 im Command-Feedback als Snapshot, Line, Status und Gate.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_scenario_ship_readiness_review.gd`
- `scripts/tests/task_1026_release_first_decision_loop_two_player_loop_scenario_ship_readiness_review.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_1026_release_first_decision_loop_two_player_loop_scenario_ship_readiness_review.gd`
- Regression: TASK_1025, TASK_1024, TASK_1023
- `git diff --check`

## Risiken / offene Punkte
TASK_1026 baut noch keinen neuen sichtbaren Spielmoment. Es ist der kurze Uebergabe-Gate, bevor TASK_1027 die frische EXE bzw. den sichtbaren Ship-Smoke wirklich ausfuehrt. Wenn das Paket unvollstaendig ist, sollte gezielt poliert werden statt weitere Gates aufeinanderzustapeln.
