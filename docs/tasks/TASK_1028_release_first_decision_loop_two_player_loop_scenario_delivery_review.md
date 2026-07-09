# TASK_1028 - Release First Decision Loop Two Player Loop Scenario Delivery Review

## Ziel / Problem
Nach TASK_1027 ist der kleine Release-Spielmoment sichtbar geprueft. Vor dem naechsten Handoff braucht der Stand aber eine explizite Delivery-Review: Welche EXE/PCK ist gemeint, wie startet man sie, welche Risiken sind akzeptiert, und ist der naechste Task wirklich ein Uebergabepaket statt weiterer Politur?

## Sinnhaftigkeit / Ursache
Der Weg Richtung "fuehlt sich wie ein rundes kleines Spiel an" braucht kleine, harte Uebergabegates. Ohne dieses Gate koennen alte Builds, stale Taskleisten-Verknuepfungen, unklare Startanweisungen oder nicht akzeptierte Restrisiken wieder in die naechste Runde rutschen.

## Umfang
- Read-only Service `ReleaseFirstDecisionLoopTwoPlayerLoopScenarioDeliveryReview.build_snapshot()`.
- Bewertung einer bestandenen TASK_1027-Quelle plus optionaler Delivery-Review-Notizen.
- Pflichtchecks fuer sichtbaren Smoke, Release-Dateien, Startanweisung, Risikoannahme, Shortcut-Warnung, Multiplayer-/HUD-Grenze und naechsten Handoff.
- Export im `MissionTacticalSandboxController` als Snapshot, Line, Status und Gate.

## Nicht-Ziele
- Kein neuer Export und kein automatischer EXE-Start.
- Keine Shortcut-Aenderung.
- Kein Screenshot-/Pixelentscheid.
- Keine UI-, Command-, Movement-, Combat-, Damage- oder Multiplayer-Wahrheit.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_1027_release_first_decision_loop_two_player_loop_scenario_visible_ship_smoke.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `scripts/mission/release_first_decision_loop_two_player_loop_scenario_delivery_review.gd`

## Akzeptanzkriterien
- Fehlende oder unpassende TASK_1027-Quelle blockiert mit `blocked_until_visible_ship_smoke`.
- Bestandener sichtbarer Smoke ohne Review bleibt `needs_delivery_review`.
- Unvollstaendige Review bleibt `needs_delivery_review_completion`.
- Issue-Flags routen nach `TASK_1028 - Release First Decision Loop Two Player Loop Scenario Delivery Polish`.
- Saubere Review setzt `delivery_review_ready` und `ready_for_handoff_packet`.
- Saubere Review empfiehlt `TASK_1029 - Release First Decision Loop Two Player Loop Scenario Handoff Packet`.
- Snapshot bleibt read-only und setzt keine Gameplay-Wahrheit.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_scenario_delivery_review.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1028_release_first_decision_loop_two_player_loop_scenario_delivery_review.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_1028_release_first_decision_loop_two_player_loop_scenario_delivery_review.gd`
- Regression: TASK_1027, TASK_1026, TASK_1025.
- `git diff --check`

## Risiken / offene Punkte
- TASK_1028 bewertet Notizen und Paketklarheit, prueft aber die EXE nicht selbst sichtbar.
- Wenn Delivery-Review Reibung findet, folgt ein gezielter TASK_1028-Polish statt Handoff.
- Der Branch baut bewusst auf dem vorherigen TASK_1027-Arbeitsstand auf.

## Naechster Schritt
TASK_1029 - Release First Decision Loop Two Player Loop Scenario Handoff Packet.
