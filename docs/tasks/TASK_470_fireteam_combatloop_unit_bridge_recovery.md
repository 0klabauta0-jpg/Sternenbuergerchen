# TASK_470 - Fireteam CombatLoop Unit Bridge Recovery

## Ziel / Problem
Der F6-Drill zeigt sichtbare Fireteam- und Enemy-Units, aber #18 Mission Control meldet weiter `NO_FRIENDLY_UNITS | F0/E0 | DET 0`. Dadurch entstehen keine verlaesslichen Contact-Fire-Entscheidungen, obwohl #17 aktive Engage-/Defend-Befehle sieht.

## Sinnhaftigkeit / Ursache
Die Drill-Scene erbte nur zwei Enemy-Nodes aus der Basisszene und ergaenzte weitere Gegner spaeter ueber das Scenario. Der CombatLoop konnte dadurch zu frueh oder mit veralteten Unit-Pfaden diagnostizieren. Zusaetzlich blieb ein frueher Defeat-/No-Unit-Zustand im Loop haengen, obwohl Units danach registriert wurden.

## Umfang
- CombatLoop-Unit-Resolution ueber konfigurierte NodePaths plus UnitRegistry-Fallback haerten.
- Fruehe Startup-Defeat-Zustaende verhindern bzw. recovern, solange noch nie aktive Friendlies gesehen wurden.
- #18 Contact-Diagnostik beim Lesen gegen aktuelle Presence-Daten auffrischen.
- Overwatch-Fire ebenfalls als `fired`-Diagnose in #18 sichtbar machen.
- F6-Drill-Scene auf vier explizite Enemy-Nodes und vier CombatLoop-Enemy-Pfade normalisieren.

## Nicht-Ziele
- Keine finale Enemy-Taktik oder neue Treffer-/Down-Animation.
- Keine Neugestaltung der Karte ausser der Runtime-Unit-Konfiguration.
- Keine Aenderung der Fireteam-Doctrine fuer Engage/Take/Defend.

## Relevante Contracts / Dokumente
- `docs/ARCHITECTURE.md`
- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/tasks/TASK_469_fireteam_f6_drill_combat_config.md`
- `docs/tasks/TASK_468_fireteam_engage_live_command_conflict_audit.md`

## Akzeptanzkriterien
- Der F6-Drill hat vier explizite Enemy-Nodes und der CombatLoop kennt vier Enemy-Pfade.
- Wenn konfigurierte CombatLoop-Pfade stale sind, kann der Loop aktive Friendlies/Enemies aus der UnitRegistry lesen.
- Ein Startup-Tick ohne je gesehene Friendlies loest keinen dauerhaften Defeat aus.
- Ein vorzeitig resolvter Startup-Defeat kann recovern, sobald aktive Friendlies registriert sind.
- #18 zeigt keine stale `F0/E0`-Diagnose, wenn aktive Units existieren.

## Betroffene Dateien
- `scripts/tests/mission_combat_loop_driver.gd`
- `scenes/tests/fireteam_command_drill_map.tscn`
- `scripts/tests/task_470_fireteam_combatloop_unit_bridge_recovery.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_470_fireteam_combatloop_unit_bridge_recovery.gd`
- relevante Regressionen: TASK_469, TASK_468, TASK_467, TASK_466
- `git diff --check`

## Risiken / offene Punkte
- Wenn danach weiter kein Feuer sichtbar ist, liegt der naechste Befund nicht mehr bei Unit-Presence, sondern bei LOS, Range, Detection-State, FireStatus oder Damage/VFX.
- Die Gegner-Taktik bleibt weiterhin Drill-/Prototype-Logik und muss spaeter separat geglättet werden.
