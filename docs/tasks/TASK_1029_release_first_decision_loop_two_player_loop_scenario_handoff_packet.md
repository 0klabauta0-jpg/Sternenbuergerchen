# TASK_1029 - Release First Decision Loop Two Player Loop Scenario Handoff Packet

## Ziel / Problem
Nach dem Delivery Review soll der kleine FOB/NEXT/GO/FEEDBACK-Spielmoment als greifbares Handoff-Paket vorliegen: Welche EXE/PCK ist gemeint, wie startet ein Tester, welche Warnungen gelten, welche Risiken bleiben offen, und welcher naechste Testlauf ist vorgesehen?

## Sinnhaftigkeit / Ursache
Die letzten Gates beweisen, dass der kleine Moment grundsaetzlich bereit ist. Ohne Handoff-Paket bleibt aber zu viel im Chat- oder Task-Kontext haengen. Das erhoeht das Risiko, dass ein Tester eine alte Verknuepfung startet, nicht weiss was zu pruefen ist oder die Multiplayer-/HUD-Grenzen versehentlich als Gameplay-Wahrheit missversteht.

## Umfang
- Read-only Service `ReleaseFirstDecisionLoopTwoPlayerLoopScenarioHandoffPacket.build_snapshot()`.
- Bewertung einer bereiten TASK_1028-Delivery-Review plus optionaler Handoff-Packet-Notizen.
- Pflichtitems fuer Delivery-Ready, Release-Dateien, Startanweisung, Shortcut-Warnung, Risiko-Zusammenfassung, naechste Tester-Aktion, Multiplayer-Grenze und HUD-Wahrheit.
- Export im `MissionTacticalSandboxController` als Snapshot, Line, Status und Gate.
- Tester-Schritte werden als read-only `test_steps` mitgegeben.

## Nicht-Ziele
- Kein neuer Export und kein automatischer EXE-Start.
- Keine Shortcut-Aenderung.
- Kein Tester-Run und keine Sicht-/Pixelbewertung.
- Keine UI-, Command-, Movement-, Combat-, Damage- oder Multiplayer-Wahrheit.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_1028_release_first_decision_loop_two_player_loop_scenario_delivery_review.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `scripts/mission/release_first_decision_loop_two_player_loop_scenario_handoff_packet.gd`

## Akzeptanzkriterien
- Fehlende oder unpassende TASK_1028-Quelle blockiert mit `blocked_until_delivery_review`.
- Bereite Delivery-Review ohne Handoff-Notizen bleibt `needs_handoff_packet`.
- Unvollstaendige Handoff-Items bleiben `needs_handoff_packet_completion`.
- Issue-Flags routen nach `TASK_1029 - Release First Decision Loop Two Player Loop Scenario Handoff Polish`.
- Sauberes Paket setzt `handoff_packet_ready` und `ready_for_tester_run`.
- Sauberes Paket empfiehlt `TASK_1030 - Release First Decision Loop Two Player Loop Scenario Tester Run`.
- Snapshot bleibt read-only und setzt keine Gameplay-Wahrheit.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_scenario_handoff_packet.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1029_release_first_decision_loop_two_player_loop_scenario_handoff_packet.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_1029_release_first_decision_loop_two_player_loop_scenario_handoff_packet.gd`
- Regression: TASK_1028, TASK_1027, TASK_1026.
- `git diff --check`

## Risiken / offene Punkte
- TASK_1029 baut das Handoff-Paket, prueft es aber noch nicht in der EXE.
- Wenn Handoff-Notizen stale oder unklar sind, folgt gezielte Handoff-Politur.
- Der Branch baut bewusst auf dem TASK_1028-Arbeitsstand auf.

## Naechster Schritt
TASK_1030 - Release First Decision Loop Two Player Loop Scenario Tester Run.
