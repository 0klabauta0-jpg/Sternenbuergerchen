# TASK_745 - Station Scenario Post Debrief Homebase Readability

## Ziel / Problem
Nach TASK_744 ist der technische Weg `Station Scenario -> Debrief -> Homebase` gruen. Auf der Homebase soll der Spieler nach dem Return aber auch sofort lesen koennen, dass der Station-Debrief abgeschlossen ist, welche Route zurueckgetragen wurde und was als naechstes sinnvoll ist.

## Sinnhaftigkeit / Ursache
Der Core Loop endet nicht beim Debrief, sondern beim erneuten Verstehen der Homebase-Lage. Bisher war diese Homebase-Rueckkehr-Lesbarkeit fuer Frontier Probe vorhanden, aber nicht fuer den neuen Station-Drill `AA > DOOR > COM > CARGO`. Dadurch war der Stationsabschluss technisch korrekt, aber spielerisch noch ein wenig stumpf.

## Umfang
- Homebase-Post-Debrief-Summary fuer Station-Ergebnisse erweitern.
- Station-Route und Scenario-ID aus dem letzten MissionResult erkennen.
- Read-only Snapshot `get_station_scenario_post_debrief_homebase_readability_snapshot()` ergaenzen.
- Bestehende Frontier-Probe-Post-Debrief-Funktionalitaet stabil halten.
- Verifier, Contract, Status, Roadmap und HTML-Handbuch fortschreiben.

## Nicht-Ziele
- Keine neue Homebase-Navigation.
- Keine neue XP-/Skill-/Roster-Berechnung.
- Keine neue MissionResult-Wahrheit in der UI.
- Kein groesserer Homebase-Layoutumbau.
- Kein neuer Debrief-Screen-Polish.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_744_station_scenario_meta_debrief_route_smoke.md`
- `docs/tasks/TASK_640_frontier_probe_post_debrief_homebase_readability.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Akzeptanzkriterien
- Die Homebase zeigt nach dem Station-Debrief-Return eine kompakte Zeile wie `Debrief complete -> Homebase | Station Drill / VICTORY / ... | Next: prep next sortie`.
- Der Snapshot liefert `schema = sternenbuergerchen.station_scenario_post_debrief_homebase_readability.v1`.
- `route_id = station_route_aa_door_computer_cargo` und `scenario_id = station_route_one_screen_multiplayer_drill` bleiben lesbar.
- `summary_label_visible = true`, `station_result_present = true`, `mission_result_preserved = true`.
- `read_only = true`, `ui_sets_gameplay_truth = false`, `creates_navigation = false`, `creates_command = false`.
- Die Summary bleibt kompakt und einzeilig.
- TASK_640 Frontier-Probe-Regression bleibt gruen.

## Betroffene Dateien
- `scripts/meta/homebase_screen.gd`
- `scripts/tests/task_745_station_scenario_post_debrief_homebase_readability.gd`
- `docs/tasks/TASK_745_station_scenario_post_debrief_homebase_readability.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_745_station_scenario_post_debrief_homebase_readability.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_744_station_scenario_meta_debrief_route_smoke.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_640_frontier_probe_post_debrief_homebase_readability.gd`
- [x] `git diff --check`

## Risiken / offene Punkte
TASK_745 verbessert nur die Homebase-Rueckkehrlesbarkeit. Der naechste spielerisch sinnvolle Schritt bleibt entweder eine Station-Next-Sortie-Readiness-Zeile oder ein echter Host/Client-Fenster-Recapture nach dem neuen Debrief/Homebase-Abschluss.
