# TASK_726 - One-Screen Multiplayer Station Scenario Drill

## Ziel / Problem
Nach TASK_725 ist der kleine Station-Route-Multiplayer-Slice eng akzeptiert. Jetzt soll daraus wieder ein spielbares Stueck werden: ein kompakter One-Screen-Drill mit Alpha-Angriff, Bravo-Verteidigung/NPCs, AA-Abschaltung, Door, Computer und Cargo-Abflug.

## Sinnhaftigkeit / Ursache
Die letzten Tasks haben Sichtbarkeit, HUD-Polish und Host/Client-Akzeptanz abgesichert. Ohne einen konkreten Scenario-Drill bleibt der Fortschritt aber abnahme-lastig. TASK_726 macht die Interaktionskette als Daten-/Runtime-Vertrag spielbar pruefbar.

## Umfang
- Neues Szenario `station_route_one_screen_multiplayer_drill.json` mit expliziter Route: AA -> Door -> Computer -> Cargo.
- Read-only Analyzer `StationRouteOneScreenScenarioDrill` fuer One-Screen-, Team-, Objective- und Multiplayer-Drill-Checks.
- Verifier laedt das Szenario in die Mission-Testszene, laeuft die Runtime-Gates durch und schreibt ein Manifest.
- Report, Status, Roadmap und Interaction-Contract nennen TASK_726 als aktuellen Spielbarkeitsgriff.

## Nicht-Ziele
- Kein neues Combat-System.
- Kein neues HUD-Layout.
- Kein neues Netcode-System.
- Kein Balancing der Gegnerwerte.
- Kein Ersatz fuer einen spaeteren echten F6/Host/Client-Playtest.

## Relevante Contracts / Dokumente
- `docs/dev/mission_interaction_point_contract.md`
- `docs/tasks/TASK_725_station_route_host_client_recapture_acceptance_review.md`
- `docs/tasks/TASK_714_station_route_multiplayer_scenario_guard.md`
- `docs/tasks/TASK_707_mission_door_computer_cargo_smoke.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Akzeptanzkriterien
- Das Szenario enthaelt Singleplayer-, Coop- und PvP-Modusannahmen.
- Alpha und Bravo sind als Team-Slots vorhanden; Bravo kann NPC-owned bleiben und PvP-ready sein.
- Die Interaktionsroute ist in Reihenfolge `disable_air_defense`, `open_station_door`, `occupy_station_computer`, `cargo_touchdown_extract` pruefbar.
- Der Verifier bestaetigt, dass AA -> Door -> Computer -> Cargo in der Mission-Runtime nicht uebersprungen wird.
- Snapshot und Manifest bleiben `read_only = true` und `ui_sets_gameplay_truth = false`.

## Betroffene Dateien
- `data/mission_scenarios/station_route_one_screen_multiplayer_drill.json`
- `scripts/mission/station_route_one_screen_scenario_drill.gd`
- `scripts/tests/task_726_one_screen_multiplayer_station_scenario_drill.gd`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Lokale Pruefung
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_726_one_screen_multiplayer_station_scenario_drill.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_725_station_route_host_client_recapture_acceptance_review.gd`
- [ ] `git diff --check`

## Risiken / offene Punkte
TASK_726 beweist die Daten-/Runtime-Kette, aber noch nicht das echte Balancing oder Spielgefuehl gegen Menschen. Der naechste sinnvolle Schritt ist ein sichtbarer F6/Host-Client-Playtest dieses Drill-Szenarios mit Performance- und Lesbarkeitsnotizen.

Beim Gegencheck alter Harnesses fiel auf, dass Szenario-Dateien, die vor dem Szenenboot direkt in `MissionSetup.scenario_file_path` gesetzt werden, weiterhin empfindlich sind. TASK_726 nutzt deshalb bewusst den stabileren Ablauf: Szene booten, danach Runtime-Gates aus dem Szenario laden. Die alten TASK_707/TASK_714-Harnesses sollten separat modernisiert werden, ohne ihre Controller-Bindings zu verlieren.
