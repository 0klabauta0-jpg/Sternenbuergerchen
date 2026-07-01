# TASK_730 - Station Scenario Targeted Playtest Polish

## Ziel / Problem
Der echte Zwei-Fenster-Capture aus TASK_729 startet das richtige Station-Szenario, aber der erste sichtbare HUD-Blick erklaert die Route noch zu schwach. Oben links steht nur der generische Realtime-Feed, waehrend die entscheidende Folge `AA -> Door -> Computer -> Cargo` nur klein auf der Karte und unten im Command-Feedback auftaucht.

## Sinnhaftigkeit / Ursache
Der Spieler muss vor dem ersten Klick verstehen, was in diesem One-Screen-Szenario eigentlich passieren soll. Die Route existiert bereits als read-only `station_route_run_readout`; sie wird nur nicht prominent genug im Mission-Identity-Header gespiegelt.

## Umfang
- Mission-Identity-Body liest den bestehenden `station_route_run_readout`.
- Bei aktiver Station-Route zeigt der Body die kompakte Route plus `NEXT`-Token.
- Host/Client-Badge bleibt erhalten.
- Command-Feedback und Route-Logik bleiben unveraendert.
- Verifier prueft Snapshot, sichtbares Label und Capture-Evidence.

## Nicht-Ziele
- Kein bestandener menschlicher Playtest.
- Kein neues Objective-, Door-, Cargo- oder Multiplayer-System.
- Kein automatisches Ausfuellen der TASK_727-Workbench.
- Kein Balancing der Station-Route.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_729_station_scenario_visible_playtest_run_packet.md`
- `docs/tasks/TASK_727_station_scenario_f6_host_client_playtest_notes.md`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Akzeptanzkriterien
- `MissionTacticalSandboxController.build_station_scenario_identity_body_snapshot()` liefert einen read-only Snapshot.
- Mit aktivem Station-Route-Readout enthaelt der Body `ROUTE`, `AA`, `DOOR`, `COM`, `CARGO` und `NEXT`.
- Im Host/Client-Review bleibt der Badge wie `HOST P1 ALPHA` oder `CLIENT P2 BRAVO` sichtbar.
- UI setzt keine Gameplay-Wahrheit: `read_only = true`, `ui_sets_gameplay_truth = false`.
- Der bestehende TASK_716-Route-Readout bleibt gruen.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_730_station_scenario_targeted_playtest_polish.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Lokale Pruefung
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_730_station_scenario_targeted_playtest_polish.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_716_station_route_run_readout_polish.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_729_station_scenario_visible_playtest_run_packet.gd`
- [ ] `git diff --check`

## Risiken / offene Punkte
TASK_730 verbessert die erste Lesbarkeit aus dem Capture-Befund. Der echte Workbench-Export bleibt offen und muss weiter menschlich bestaetigen, ob der Slice angenehm spielbar ist.
