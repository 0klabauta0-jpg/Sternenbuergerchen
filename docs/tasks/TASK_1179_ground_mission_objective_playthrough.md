# TASK_1179 - Ground Mission Objective Playthrough

## Ziel / Problem

`grid_sweep` ist der aktuelle Singleplayer-Standard und verwendet die kleine
Ground Mission mit Patrol- und Defense-NPCs. Bisher pruefen ihre Verifier Map,
Spawns und Visuals, aber nicht den kompletten Spielerweg von Homebase bis zur
autoritativen Objective-Completion.

## Ursache / Sinnhaftigkeit

Die Station Route ist der tiefe Mehrstufen-Slice. Fuer ein rundes kleines Spiel
braucht es daneben eine schnelle, nachvollziehbare Standardmission: Team
stagen, absetzen, ein Objective erreichen und in den vorhandenen Result-/
Debrief-Pfad uebergeben. Ohne diesen Trace kann eine kaputte Missionauswahl,
ein Drop-Handoff oder ein Objective-Gate im Release unbemerkt bleiben.

Der Trace fand drei Content-Blocker: `spawn_alpha` und der versetzte
Drop-Stand lagen auf Felsen, und eine Cliff-/Hoehenkante teilte den von der
Bounding-Formation benoetigten HPA-Korridor. Dadurch blieb `Take` in der
Missionsausfuehrung stehen, obwohl ein einfacher A*-Weg zur Objective-Position
existierte.

## Umfang

- Einen echten Homebase -> Ground Mission -> Dropship -> LZ -> Deboard ->
  Objective-Trace gegen den vorhandenen `grid_sweep`-Katalogeintrag bauen.
- Nur vorhandene Meta-, Mission-, SimulationRoot- und Objective-Pfade nutzen.
- Autoritative Objective-Completion und Meta-Debrief-Handoff pruefen.
- Einen konkreten Bruch mit der kleinsten zustaendigen Aenderung beheben.
- Die Ground-Mission nur an LZ, Stationszugang und zentralem Rampenkorridor
  authoring-seitig reparieren; keine globale Walkability-Aenderung.

## Nicht-Ziele

- Keine Unit-Teleports, keine direkte Objective-/Result-Mutation im Test.
- Kein neues Combat-, Scenario-, Multiplayer- oder UI-State-System.
- Kein Umbau der Station Route und kein Map-/Asset-Polish ohne belegten Fehler.

## Relevante Contracts / Dokumente

- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/dev/homebase_direct_dropship_flow_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_344_ground_mission_default_enemy_visuals.md`
- `docs/tasks/TASK_501_integrated_movement_command_lifecycle_hardening.md`

## Akzeptanzkriterien

- Der Trace startet den bestehenden `grid_sweep`-Eintrag aus Homebase.
- Fireteam- und Dropship-Handoff nutzen den vorhandenen autoritativen Pfad.
- Der Test setzt weder Unit-Position noch Objective-, Combat- oder
  MissionResult-State direkt.
- Nach einem echten Commander-Command erreicht der bestehende Objective-Pfad
  `objective_captured` und der Meta-Layer uebergibt einen Result-/Debrief-
  Snapshot.
- Spawn Alpha ist direkt begehbar; A* und HPA finden von Alpha zur Objective
  sowie durch den zentralen Vormarschkorridor einen legalen Pfad.
- Bei einem echten Blocker nennt der Verifier die fehlerhafte Stage.

## Betroffene Dateien

- `scripts/tests/task_1179_ground_mission_objective_playthrough.gd`
- `maps/Ground_Mission01_32x32.json`
- `scripts/core/simulation_root.gd`
- `docs/tasks/TASK_1179_ground_mission_objective_playthrough.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung

- TASK_1179 (18/18, zweimal hintereinander; maximal 256 beschleunigte
  Missions-Ticks).
- TASK_344 und TASK_501 als Ground-/Movement-Regression.
- TASK_475 und TASK_479 als Pathfinding-/Avoidance-/Hotpath-Regression.
- `git diff --check`.

## Risiken / offene Punkte

Die bestehende 32x32-Mission soll ein kurzer Singleplayer-Loop sein, nicht die
Station Route duplizieren. Der komplette Headless-Trace bleibt wegen des realen
Meta-/3D-Aufbaus bewusst ein langsamer End-to-End-Gate; schnellere
Terrain-/HPA-Regressionen bleiben separat.
