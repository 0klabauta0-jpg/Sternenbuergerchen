# TASK_1033 - Release First Decision Loop Two Player Loop Scenario First Contact Runtime Hook

## Ziel / Problem
TASK_1032 hat als naechsten spielbaren Slice den ersten Kontakt mit lesbarer CONTACT/COVER/LOS/FIRE-WAIT/FEEDBACK-Entscheidung festgelegt. TASK_1033 macht daraus einen Runtime-Hook-Snapshot, den Controller, HUD, Tests und Reports lesen koennen.

## Sinnhaftigkeit / Ursache
Der Spieler braucht nach dem ersten kleinen FOB/NEXT/GO-Griff einen taktischen Moment, der nicht nur "weiterklicken" ist: Kontakt lesen, Cover/LOS/Risk verstehen, Fire/Wait nachvollziehen, Feedback bekommen und GO separat halten. Die vorhandenen Contact-/Engagement-/Combat-HUD-Snapshots enthalten diese Daten bereits; TASK_1033 verbindet sie ohne neue Gameplay-Wahrheit.

## Umfang
- TASK_1032-Plan als Quelle pruefen.
- Bestehende Snapshots wiederverwenden:
  - `get_mission_first_contact_readability_snapshot()`
  - `get_mission_first_engagement_feedback_snapshot()`
  - `get_mission_fire_cover_visual_polish_snapshot()`
  - `get_mission_combat_feedback_hud_density_snapshot()`
- Eine kompakte Runtime-Zeile fuer CONTACT/COVER/LOS/FIRE-WAIT/FEEDBACK liefern.
- Spielerfragen als lesbare Antworten bereitstellen.
- Command-Matrix-Hook-Metadaten fuer CONTACT, WHY, NEXT und GO liefern.
- `MissionTacticalSandboxController` exportiert Snapshot, Zeile, Status und Gate.

## Nicht-Ziele
- Kein neuer Combat-Resolver.
- Keine Kontakt-, Fire-, Damage- oder Movement-Erzeugung.
- Keine UI-Wahrheit und keine Multiplayer-Wahrheit.
- Kein Sicht-/Pixeltest; der folgt als Smoke.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_1032_release_first_decision_loop_two_player_loop_scenario_next_playable_slice_plan.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/ARCHITECTURE.md`

## Akzeptanzkriterien
- Snapshot-Schema: `sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_hook.v1`.
- Ohne bereiten TASK_1032-Plan bleibt der Hook blockiert.
- Ohne Runtime-Kontext bleibt der Status `needs_first_contact_runtime_hook_context`.
- Fehlende/gruene Contact-/Engagement-/Fire-Cover-/Combat-HUD-Kontexte werden sauber als Review-Issues gemeldet.
- Sauberer Kontext setzt `first_contact_runtime_hook_ready`.
- Die Runtime-Zeile nennt CONTACT, COVER, LOS, FIRE/WAIT, FEEDBACK und `GO separat`.
- Der Snapshot bleibt read-only und erzeugt keine Commands, Bewegung, Fire-/Damage-Events oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_hook.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1033_release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_hook.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_1033_release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_hook.gd`
- Regression TASK_1032, TASK_1031, TASK_1030
- `git diff --check`

## Risiken / offene Punkte
Der Default-Command-Feedback-Pfad gibt TASK_1033 bewusst ohne teure Live-Kontext-Erzeugung aus, um keine rekursive Snapshot-Schleife aus `get_command_feedback_snapshot()` zu erzeugen. Der naechste Schritt ist `TASK_1034 - Release First Decision Loop Two Player Loop Scenario First Contact Runtime Smoke`, der den sichtbaren Runtime-Smoke mit echten Snapshot-Daten pruefen soll.
