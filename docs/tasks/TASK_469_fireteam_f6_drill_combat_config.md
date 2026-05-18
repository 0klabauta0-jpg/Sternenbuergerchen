# TASK_469 - Fireteam F6 Drill Combat Config

## Ziel / Problem
Der direkte Godot-Start per F6 der Fireteam-Drill-Szene darf nicht mit einem geerbten Objective-Capture-Ziel oder ohne aktive Combat-Units laufen. Im Playtest zeigte #18 zeitweise `NO_FRIENDLY_UNITS | F0/E0`, obwohl 3D-Units sichtbar waren.

## Sinnhaftigkeit / Ursache
Die Drill-Szene erbt von `mission_reactivity_test.tscn`. Dadurch koennen Basiswerte wie `objective_capture` und nur zwei statische Enemy-Paths im F6-Pfad sichtbar werden, wenn das Szenario seine Laufzeitdaten nicht explizit bis zum CombatLoop durchreicht. Fuer Fireteam-Behavior-Tests muss die Combat-Wahrheit direkt aus dem Drill-Szenario kommen.

## Umfang
- Szenario-Daten duerfen eine `win_condition` definieren.
- `MissionTestSetup` uebertraegt die Szenario-Wincondition auf `CombatLoopDriver`.
- Der Meta-Missionskatalog uebertraegt fuer den Drill ebenfalls `elimination`.
- Ein Verifier prueft den direkten Drill-/F6-Start und den Basis-Szenenstart mit injiziertem Drill-Szenario.

## Nicht-Ziele
- Kein neues Feuer-/Trefferbalancing.
- Kein alternativer Fake-Muzzleflash ohne Combat-Fire-Event.
- Keine finale Engage-/Take-/Defend-Doctrine.

## Relevante Contracts / Dokumente
- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/tasks/TASK_468_fireteam_engage_live_command_conflict_audit.md`
- `docs/tasks/TASK_466_fireteam_live_defend_contact_fire_damage.md`

## Akzeptanzkriterien
- `fireteam_command_drill_24x24.json` setzt `win_condition = elimination`.
- Direkter F6-Start der Drill-Szene hat nach Initialisierung aktive Friendlies und aktive Enemies im CombatLoop.
- Ein geerbtes `objective_capture` wird durch die Drill-Szenario-Konfiguration ersetzt.
- CombatLoop loest nicht vor der Drill-Initialisierung wegen fehlender Units auf.

## Betroffene Dateien
- `scripts/mission/mission_scenario_data.gd`
- `scripts/tests/mission_test_setup.gd`
- `scripts/meta/meta_layer_flow.gd`
- `data/mission_scenarios/fireteam_command_drill_24x24.json`
- `scripts/tests/task_469_fireteam_f6_drill_combat_config.gd`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_469_fireteam_f6_drill_combat_config.gd`
- Relevante Fireteam-Regressionen TASK_468/TASK_467/TASK_466.
- `git diff --check`

## Risiken / offene Punkte
- Wenn im Fenster danach weiter nicht geschossen wird, ist der naechste Diagnosepunkt nicht mehr F0/E0, sondern LOS/Range/Detection/FireStatus aus #18.
- Gegner-Patrouille, Trefferanimation und finale Area-Doctrine bleiben eigene Folgeschritte.
