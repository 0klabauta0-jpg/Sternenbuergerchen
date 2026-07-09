# TASK_1032 - Release First Decision Loop Two Player Loop Scenario Next Playable Slice Plan

## Ziel / Problem
Nach TASK_1031 ist der kleine FOB/NEXT/GO/FEEDBACK-Griff akzeptiert, aber der naechste sinnvolle spielbare Slice darf nicht wieder im abstrakten Review-Klein-Klein versanden. TASK_1032 legt deshalb fest, welcher konkrete Laufzeitgriff als Naechstes gebaut wird: erster Kontakt mit lesbarer Cover-/LOS-/Fire-Wait-Entscheidung.

## Sinnhaftigkeit / Ursache
Der aktuelle Release-Pfad kann gestartet und als kleiner Griff akzeptiert werden. Damit sich das Spiel danach runder anfuehlt, braucht der Spieler im naechsten Schritt eine echte taktische Frage: Wer sieht wen, warum ist diese Position gefaehrlich, warum schiesst das Fireteam oder wartet es, und was ist danach der naechste Griff?

## Umfang
- TASK_1031-Acceptance als Quelle pruefen.
- Plan-Items fuer den naechsten spielbaren Slice bewerten.
- Bestehende First-Contact-/First-Engagement-/Fire-Cover-/Combat-HUD-Snapshots sichtbar wiederverwenden.
- `MissionTacticalSandboxController` exportiert den TASK_1032-Snapshot im Command-Feedback.
- Bei sauberem Plan zu `TASK_1033 - Release First Decision Loop Two Player Loop Scenario First Contact Runtime Hook` routen.

## Nicht-Ziele
- Kein neuer Combat-Resolver.
- Keine neue UI-Wahrheit.
- Keine Commands, Bewegung, Fire-/Damage-Events oder Multiplayer-Wahrheit.
- Kein Pixel-/Sichttest.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_1031_release_first_decision_loop_two_player_loop_scenario_tester_run_acceptance.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/ARCHITECTURE.md`

## Akzeptanzkriterien
- Snapshot-Schema: `sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_next_playable_slice_plan.v1`.
- Ohne akzeptierten TASK_1031-Stand bleibt TASK_1032 blockiert.
- Ohne Plan bleibt der Status `needs_next_playable_slice_plan`.
- Unvollstaendige Plan-Items bleiben `needs_next_playable_slice_plan_completion`.
- Plan-Issue-Flags routen zu TASK_1032-Polish.
- Sauberer Plan setzt `next_playable_slice_plan_ready` und `ready_for_first_contact_runtime_hook`.
- Die Next-Slice-Line nennt CONTACT, COVER, LOS, FIRE/WAIT und FEEDBACK.
- Der Snapshot bleibt read-only.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_scenario_next_playable_slice_plan.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1032_release_first_decision_loop_two_player_loop_scenario_next_playable_slice_plan.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_1032_release_first_decision_loop_two_player_loop_scenario_next_playable_slice_plan.gd`
- Regression TASK_1031, TASK_1030, TASK_1029
- `git diff --check`

## Risiken / offene Punkte
TASK_1032 baut noch keinen sichtbaren Kampfkontakt. Der eigentliche Laufzeit-Hook kommt bewusst erst mit TASK_1033, damit der Plan stabil auf den bestehenden Kontakt- und Combat-HUD-Vertraegen sitzt.
