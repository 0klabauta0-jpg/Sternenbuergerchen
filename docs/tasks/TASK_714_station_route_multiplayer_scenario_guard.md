# TASK_714 - Station Route Multiplayer Scenario Guard

## Ziel / Problem
Die Station-Route Door -> Computer -> Cargo ist als Single-Mission-Smoke und als Host/Client-Acceptance-Paket vorbereitet. Es fehlt aber noch ein integrierter technischer Guard, der die Route mit Multiplayer-Authority und Snapshot-Sync in einem reproduzierbaren Headless-Szenario prueft.

## Sinnhaftigkeit / Ursache
Der echte Zwei-Fenster-Sichtlauf bleibt menschlich. Trotzdem soll die technische Multiplayer-Grundlage vorher belastbar sein: Own-Team-Command akzeptiert, Wrong-Team-Command abgewiesen, Door-Runtime nur ueber den Producer geoeffnet, Computer/Cargo-Gates bleiben in Reihenfolge und ein Client kann den Server-Snapshot uebernehmen.

## Umfang
- Neuer Verifier `task_714_station_route_multiplayer_scenario_guard.gd`.
- Temporare Station-Route-Szenario-Variante mit Door am Stationsmarker.
- Kombination aus Door-Authority, Door-Runtime-Collision/LOS, Computer-Gate, Cargo-Gate und Multiplayer-Snapshot-Sync.
- JSON-Manifest unter `tmp/station_route_multiplayer_scenario_guard.json`.
- Contract, Status, Roadmap und aktueller HTML-Handbuch-Refresh werden aktualisiert.

## Nicht-Ziele
- Kein echter Fenster-/Sichttest.
- Kein Klickbot.
- Kein neues Objective-, Door-, Computer-, Cargo- oder Multiplayer-System.
- Kein UI-State und keine neue Gameplay-Wahrheit.

## Relevante Contracts / Dokumente
- `docs/dev/mission_interaction_point_contract.md`
- `docs/tasks/TASK_707_mission_door_computer_cargo_smoke.md`
- `docs/tasks/TASK_697_door_interaction_multiplayer_authority_check.md`
- `docs/tasks/TASK_712_station_route_host_client_acceptance_packet.md`
- `docs/tasks/TASK_713_station_route_host_client_findings.md`

## Akzeptanzkriterien
- Der Guard instanziiert die Mission-Testszene mit der Station-Outpost-Map.
- Peer 1/Team Alpha darf den Door-Command absenden.
- Peer 2/Team Bravo wird fuer denselben Alpha-Door-Command abgewiesen.
- Client-seitige Runtime-State-Mutation wird abgewiesen.
- Door-Runtime-Collision/LOS oeffnet Walkability und LOS nur ueber den Producer.
- Door-Open ueberspringt nicht den Computer-Gate.
- Computer-Control schaltet den Cargo-Gate frei.
- Cargo-Departed setzt `all_gates_complete`.
- Server-Snapshot wird gebaut und vom Client akzeptiert.
- Manifest bleibt `read_only = true` und `ui_sets_gameplay_truth = false`.

## Betroffene Dateien
- `docs/tasks/TASK_714_station_route_multiplayer_scenario_guard.md`
- `scripts/tests/task_714_station_route_multiplayer_scenario_guard.gd`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_refresh_2026_06_30.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_714_station_route_multiplayer_scenario_guard.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_713_station_route_host_client_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_707_mission_door_computer_cargo_smoke.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_714 beweist technische Konsistenz, nicht Sichtbarkeit oder Bediengefuehl. Der echte Zwei-Fenster-Run bleibt danach weiter noetig, aber mit weniger technischem Risiko.
