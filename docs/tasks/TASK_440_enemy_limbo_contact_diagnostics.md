# TASK_440 - Enemy Limbo Contact Diagnostics

## Ziel / Problem
Der naechste Fireteam-Build soll sichtbarer machen, warum gegnerische NPCs bei Kontakt halten, Deckung suchen oder patrouillieren. LimboAI bleibt dabei ein Hybrid-Entscheidungsadapter und darf keine zweite Gameplay-Wahrheit erzeugen.

## Sinnhaftigkeit / Ursache
Im Playtest war schwer zu erkennen, ob Gegner Kontakt sehen, warum sie nicht schiessen, ob Limbo ueberhaupt eine Aktion gewaehlt hat und ob ein Command wirklich ueber `SimulationRoot` laeuft. Fuer den naechsten Build brauchen wir daher pro Gegner eine kleine, auslesbare Diagnose: gewaehlte Limbo-Aktion, Grund, Kontextflags und Command-Quelle.

## Umfang
- LimboAI-Adapter gibt zu jeder Entscheidung einen lesbaren Grund aus.
- `MissionCombatLoopDriver` speichert den letzten Limbo-Entscheid pro Gegner als Snapshot.
- Enemy-Limbo-Commands tragen `fire_at_will`, `enemy_bt_action` und `enemy_bt_reason` explizit.
- `MissionTacticalSandboxController.get_command_feedback_snapshot()` reicht den Enemy-Limbo-Snapshot fuer #18/Dev-Diagnose weiter.
- Headless-Verifier fuer Adaptergrund, Driver-Snapshot und Command-Payload.

## Nicht-Ziele
- Kein Full-Limbo-Umstieg.
- Kein editorbares `.tres`-BehaviorTree-Authoring.
- Keine neue Wegfindung, LOS-Regel oder Damage-Logik.
- Kein Skill-, Mut- oder Flanking-System.
- Keine direkte Unit-/Damage-Mutation im Limbo-Task.

## Relevante Contracts / Dokumente
- `docs/dev/fireteam_runtime_execution_path_contract.md`
- `docs/dev/enemy_team_tactics_contract.md`
- `docs/tasks/TASK_434_limboai_enemy_behavior_adapter_smoke.md`
- `docs/tasks/TASK_439_fireteam_runtime_map_flow_limbo_review.md`

## Akzeptanzkriterien
- Limbo-Adapter liefert `reason`, `selected_action` und `source`.
- Contact-Hold-Commands bleiben `hold_position`, sind aber explizit `fire_at_will`.
- Cover-Commands bleiben `move_to_position`, tragen aber `enemy_bt_reason`.
- CombatLoop-Snapshot listet pro Enemy den letzten Limbo-Entscheid inklusive Kontakt-/Patrol-/Cover-Flags.
- Feedback-Snapshot des Tactical Controllers enthaelt `enemy_limbo_behavior`.
- Headless-Test prueft, dass der Hybrid nur Commands erzeugt und keine direkte Gameplay-Wahrheit setzt.

## Betroffene Dateien
- `scripts/tactical/enemy_limbo_behavior_adapter.gd`
- `scripts/tests/mission_combat_loop_driver.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/core/simulation_root.gd`
- `scripts/tests/task_440_enemy_limbo_contact_diagnostics.gd`
- `docs/tasks/TASK_440_enemy_limbo_contact_diagnostics.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_440_enemy_limbo_contact_diagnostics.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_434_limboai_enemy_behavior_adapter_smoke.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Snapshot ist Diagnose, keine Gameplay-Wahrheit.
- Gegner-Schiessen haengt weiterhin an LOS, Reichweite, Waffe, Detection und Combat-Fire-Resolver.
- Blocker- und Pathfinding-Qualitaet werden durch Limbo nicht automatisch geloest.
