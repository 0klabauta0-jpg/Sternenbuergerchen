# TASK_420 - Waypoint Completion Area Followup Hotfix

## Ziel / Problem

Im Playtest bleiben Abschlussfaelle im Fireteam-Plan noch haengen:

- Der letzte Waypoint wird nach Abschluss nicht konsequent aus der internen Planliste entfernt.
- Eine Sequenz `Move -> Defend Area` startet nach dem Move nicht automatisch die wartende Defend-Area.

## Sinn / Ursache

TASK_417 hat Waypoints beim Abschluss aus `FireteamOrderPlan.waypoints` entfernt, aber leere Plaene blieben als Registry-Eintrag erhalten und der Abschluss-Fallback wechselte direkt auf Default-Hold. Dadurch konnte ein nachfolgender AreaOrder-Fall im sichtbaren Playtest uebersprungen werden.

## Umfang

- Leere abgeschlossene Plaene werden aus `_order_plans_by_key` entfernt.
- Nach dem letzten Waypoint prueft der Controller zuerst pending Defend-/Attack-AreaOrders.
- Erst wenn kein AreaOrder wartet, greift Default-Hold.
- Regressionstest fuer letzten Waypoint und `Move -> Defend Area`.

## Nicht-Ziele

- Kein Umbau der AreaOrder-Semantik.
- Kein neues UI fuer Waypoint- oder AreaOrder-Reihenfolgen.
- Keine Aenderung an Movement-Styles oder NPC-Geschwindigkeit.
- Keine Gegner-KI-Aenderung.

## Relevante Contracts / Dokumente

- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/fireteam_runtime_execution_path_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_417_fireteam_waypoint_completion_cleanup.md`
- `docs/tasks/TASK_419_go_next_action_and_npc_speed.md`

## Akzeptanzkriterien

- [x] Der letzte abgeschlossene Waypoint entfernt den leeren Plan aus `_order_plans_by_key`.
- [x] Serialisierte Order-Visuals enthalten nach dem letzten Waypoint keinen leeren Altplan.
- [x] Nach einem abgeschlossenen Move startet eine pending Defend-Area automatisch.
- [x] Default-Hold wird nur genutzt, wenn kein Waypoint und kein AreaOrder wartet.
- [x] Ein Verifier deckt beide gemeldeten Playtest-Faelle ab.

## Betroffene Dateien

- `docs/tasks/TASK_420_waypoint_completion_area_followup_hotfix.md`
- `docs/TASK_ROADMAP.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_420_waypoint_completion_area_followup_hotfix.gd`

## Lokale Pruefung

- [x] `godot_console.exe --headless --path . --script scripts/tests/task_420_waypoint_completion_area_followup_hotfix.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_417_fireteam_waypoint_completion_cleanup.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_419_go_next_action_and_npc_speed.gd`
- [x] `git diff --check`

## Risiken / offene Punkte

- Die Reihenfolge bleibt aktuell getrennt nach Plan-Waypoints und AreaOrders. Ein spaeterer UI-Task kann daraus eine explizite gemischte Queue machen, fuer diesen Hotfix bleibt es beim bestehenden Datenmodell.
