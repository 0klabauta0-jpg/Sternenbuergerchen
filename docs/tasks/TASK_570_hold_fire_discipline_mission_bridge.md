# TASK_570 - Hold Fire Discipline Mission Bridge

## Ziel / Problem
Feuerdisziplin soll als spielbarer Missionsbefehl im Live-Pfad ankommen. `hold`, `return`, `free` und `suppress` duerfen nicht nur UI-/Planungstext sein, sondern muessen bis zum `UnitCommand` und zur Combat-Entscheidung nachvollziehbar bleiben.

## Sinnhaftigkeit / Ursache
Nach TASK_567 bis TASK_569 ist die erste Bewegungsentscheidung vor `GO` besser lesbar. Der naechste Taktikhebel ist Feuerdisziplin: Der Spieler muss entscheiden koennen, ob ein Fireteam freiwillig feuert, nur Beschuss beantwortet oder bewusst Feuer frei gibt. Bisher existierten Teile der Regeln, aber der Mission-/Movement-/Combat-Pfad hatte keinen durchgehenden Fire-Rule-Vertrag.

## Umfang
- Fire-Rule pro Fireteam als Mission-Command-Kontext setzen und snapshotten.
- Explizit gesetzte Fire-Rules in Behavior-Metadaten, Movement-State und `UnitCommand` weiterreichen.
- `CombatFireDecisionResolver` unterscheidet `hold`, `return`, `free` und `suppress` ueber das vorhandene Fire-Status-Gate.
- `return` nutzt ein kurzes Incoming-Fire-Fenster im Combat-Driver.
- Contact-Decision-Diagnostik zeigt Fire-Rule, Fire-Status und Return-Fire-Fenster.
- HTML-Zwischenbericht aktualisieren.

## Nicht-Ziele
- Kein neues ROE-Menue mit finaler Bediengestaltung.
- Kein Suppression-/Ammo-/Morale-Rewrite.
- Kein neues Combat-System.
- Keine neue Gameplay-Wahrheit im HUD.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_command_rules_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Akzeptanzkriterien
- `set_fireteams_fire_rule()` kann `hold`, `return`, `free` und `suppress` fuer Fireteams setzen.
- Explizite Fire-Rules landen im `UnitCommand.fire_rule`.
- `hold` blockiert freiwilliges Feuer.
- `return` feuert nur bei aktivem Incoming-Fire-Fenster.
- `free` und `suppress` bleiben feuerbereit.
- Bestehende Commands ohne explizite Fire-Rule behalten ihr bisheriges Verhalten.
- Der HTML-Arbeitsbericht nennt erledigte Arbeit und naechste offene Schritte.

## Betroffene Dateien
- `scripts/npc/unit_command.gd`
- `scripts/tactical/fireteam_movement_controller.gd`
- `scripts/tactical/combat_fire_decision_resolver.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/mission_combat_loop_driver.gd`
- `scripts/tests/task_570_hold_fire_discipline_mission_bridge.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `scripts/tests/task_570_hold_fire_discipline_mission_bridge.gd`
- Relevante Regressionen aus TASK_567 bis TASK_569
- `git diff --check`

## Risiken / offene Punkte
- Final sichtbare Fire-Rule-Bedienung im Command-Panel ist Folgearbeit.
- `suppress` ist im MVP ein Fire-Rule-/Diagnosezustand und noch kein vollstaendiges Unterdrueckungs-/Ammo-System.
