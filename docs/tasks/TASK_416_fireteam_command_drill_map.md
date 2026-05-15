# TASK_416 - Fireteam Command Drill Map

## Ziel / Problem

Fuer den naechsten Fireteam-Playtest braucht es eine kleine Karte, auf der Bewegung, Waypoints, AreaOrders, Flankieren, Take/Engage und Kontakt gegen genau ein gegnerisches Fireteam nachvollziehbar geprueft werden koennen.

## Sinn / Ursache

TASK_415 hat den Mission-Tactical-Pfad als aktiven sichtbaren Fireteam-Ausfuehrungspfad festgelegt. Fuer weitere Arbeit am Fireteam braucht dieser Pfad eine kleine, wiederholbare Testumgebung mit klaren Markern statt einer grossen Content-Karte.

## Umfang

- 24x24 Fireteam-Command-Drill-Karte mit Spawn, Move-Lane, Defend-Zone, Flank-Alternativen und Objective.
- Ein Friendly-Fireteam mit vier Slots ueber eine abgeleitete Testszene.
- Ein gegnerisches Fireteam mit vier Gegnern im MissionScenarioData-Vertrag.
- HTML-Entscheidungshilfe fuer Move/Rush, Bounding, Caterpillar, Defend, Flank, Take/Engage und Alternativen.
- Kleine Meta-Mission-Catalog-Anbindung, damit die Karte im Mission-Flow auffindbar ist.
- Headless-Verifier fuer Map, Scenario, Testszene und HTML-Marker.

## Nicht-Ziele

- Kein neues Movement-, Combat- oder Gegner-KI-System.
- Keine gespeicherten Spielerbefehle in der Karten- oder Szenario-JSON.
- Keine neue UI-Wahrheit.
- Kein Ersatz fuer den grossen Ground-Mission-Playtest.

## Relevante Contracts / Dokumente

- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/fireteam_runtime_execution_path_contract.md`
- `docs/dev/commander_fireteam_delegation_contract.md`
- `docs/dev/multi_fireteam_plan_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_404_fireteam_movement_posture_bridge.md`
- `docs/tasks/TASK_415_fireteam_runtime_execution_path_switch.md`

## Akzeptanzkriterien

- [x] Karte `fireteam_command_drill_24x24` laedt als 24x24 Terrain mit vier Missionsslots.
- [x] Marker fuer Spawn, Move-Lane, Defend-Zone, Flank-Nord, Flank-Sued, Contact-Line und Objective existieren.
- [x] Szenario validiert mit genau einem gegnerischen Fireteam zu vier Units.
- [x] Testszene startet mit genau einem Friendly-Fireteam `drill`.
- [x] HTML erklaert, wann Move/Rush, Bounding, Caterpillar, Defend, Flank und Take/Engage sinnvoll sind.
- [x] Verifier prueft Map, Szenario, Szene, Meta-Catalog-Anbindung und HTML.

## Betroffene Dateien

- `docs/tasks/TASK_416_fireteam_command_drill_map.md`
- `docs/reports/fireteam_command_drill_decision_guide.html`
- `docs/TASK_ROADMAP.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `maps/fireteam_command_drill_24x24.json`
- `data/mission_scenarios/fireteam_command_drill_24x24.json`
- `scripts/tools/generate_fireteam_command_drill_24x24.gd`
- `scenes/tests/fireteam_command_drill_map.tscn`
- `scripts/meta/meta_layer_flow.gd`
- `scripts/tests/task_416_fireteam_command_drill_map.gd`

## Lokale Pruefung

- [x] `godot_console.exe --headless --path . --script scripts/tools/generate_fireteam_command_drill_24x24.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_416_fireteam_command_drill_map.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_415_fireteam_runtime_path_switch.gd`
- [x] `git diff --check`

## Risiken / offene Punkte

- Die Szene ist ein Headless- und manueller Drill-Anker, kein Balancing-Nachweis.
- Die Gegnergruppe ist bewusst einfach gehalten. Feineres Gegner-Teamverhalten gehoert in spaetere Tactics-/Combat-Tasks.
