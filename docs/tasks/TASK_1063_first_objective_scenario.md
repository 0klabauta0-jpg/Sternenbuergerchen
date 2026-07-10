# TASK_1063 - First Objective Scenario

## Ziel / Problem

Die Station-Route mit AA-Abschaltung, Tuer, Computer und Cargo-Abflug besitzt
bereits Szenario-Daten, Runtime-Gates, HUD-Readout und Debriefing-Handoff.
Sie fehlt jedoch im echten Homebase-Missionskatalog. Dadurch kann ein Spieler
sie nicht als zusammenhaengende Spielrunde auswaehlen und starten.

## Ursache

`station_route_one_screen_multiplayer_drill.json` wird von TASK_726 direkt in
einer Testmission geladen. `MetaLayerFlow.HOMEBASE_MISSION_CATALOG` kennt nur
die Frontier-Probe-Variante und reicht die Station-Route daher nie durch
`MissionSetup.scenario_file_path` in die echte Mission weiter.

## Umfang

- Einen Homebase-Katalogeintrag fuer die vorhandene Station-Route hinzufuegen.
- Den echten Meta-Startpfad pruefen: Missionswahl -> Homebase-Handoff ->
  MissionSetup-Szenario -> Runtime-Gates -> Missionsergebnis -> Debriefing.
- Den bestehenden `station_route_aa_door_computer_cargo`-Pfad und die
  vorhandene Debriefing-Datenbruecke wiederverwenden.
- Einen read-only End-to-End-Snapshot fuer diesen Player-Flow bereitstellen,
  falls der vorhandene Handoff-Snapshot nicht alle notwendigen Kanten abdeckt.

## Nicht-Ziele

- Kein zweites Objective-, Combat-, Door- oder Cargo-System.
- Kein neuer Multiplayer-Transportzustand; Team-Ownership bleibt in den
  vorhandenen Scenario- und Runtime-Contracts.
- Keine neue HUD-Wahrheit und kein automatisches Ausfuehren eines Spielerplans.
- Kein manueller Sichttest als Blocker.

## Relevante Contracts / Dokumente

- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/dev/mission_briefing_contract.md`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/tasks/TASK_517_mission_scenario_vertical_slice.md`
- `docs/tasks/TASK_726_one_screen_multiplayer_station_scenario_drill.md`
- `docs/tasks/TASK_586_debrief_return_homebase_handoff.md`

## Akzeptanzkriterien

- Homebase listet `station_route_one_screen_multiplayer_drill` als waehlbare
  Mission mit `station_outpost_192x192.json` und der vorhandenen Scenario-Datei.
- Die Wahl reicht Scenario-Pfad und 8-Slot-Contract in `MissionSetup` weiter.
- Die echte Mission konfiguriert ihre vorhandenen AA -> Door -> Computer ->
  Cargo-Runtime-Gates aus diesem Szenario.
- Nach vollstaendiger Gate-Route erzeugt der Combat-Driver einen Sieg, der
  `scenario_id`, Route und Runtime-Gate-Snapshot bis ins Debriefing behaelt.
- Alle neuen Diagnose-Snapshots bleiben read-only und mutieren keine
  Gameplay-, Command- oder Multiplayer-Wahrheit.

## Betroffene Dateien

- `scripts/meta/meta_layer_flow.gd`
- `scripts/tests/task_1063_first_objective_scenario.gd`
- `docs/superpowers/plans/2026-07-10-first-objective-scenario.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_task1057_1058_2026_07_10.html`

## Lokale Pruefung

- TASK_1063-End-to-End-Verifier.
- TASK_726-Scenario-Drill.
- TASK_586-Debrief-Return-Handoff.
- TASK_1062 und TASK_1061 als aktuelle Multi-Fireteam-/HUD-Regression.
- `git diff --check`.

## Risiken / offene Punkte

- Die Route ist technisch verifizierbar, aber ihr Balancing gegen Menschen
  und ein echter F6-Sichtbefund bleiben getrennte Folgearbeit.
- Der Startpfad muss den vorhandenen Direct-Dropship-Flow behalten; der Task
  darf keine Sonderroute um Homebase, FOB oder SimulationRoot herum bauen.
