# TASK_746 - Station Scenario Homebase Next Sortie Readiness

## Ziel / Problem
Nach TASK_745 sagt die Homebase nach dem Station-Debrief wieder klar, dass der Station Drill abgeschlossen ist. Der Spieler soll danach aber auch sofort sehen, wie er aus diesem Rueckkehrzustand in die naechste Sortie kommt: Fireteam bereitstellen, Loadout pruefen, Dropship laden und naechsten Einsatz starten.

## Sinnhaftigkeit / Ursache
Der Frontier-Probe-Pfad hat seit TASK_641 eine read-only Next-Sortie-Readiness-Zeile. Die gleiche Spielschleife gilt fuer den Station-Drill, aber `_build_next_sortie_readiness_steps()` war bisher Frontier-only. Dadurch blieb TASK_745 zwar lesbar, aber die Homebase fuehrte den Spieler noch nicht weiter in den naechsten Vorbereitungsschritt.

## Umfang
- Station-Ergebnisse fuer die bestehende Next-Sortie-Readiness-Kette freischalten.
- Read-only Snapshot `get_station_scenario_homebase_next_sortie_readiness_snapshot()` ergaenzen.
- Bestehende Steps wiederverwenden: `review_roster_gains`, `stage_fireteam`, `assign_loadout`, `prepare_transport`, `start_next_sortie`.
- Die sichtbare Zeile im bestehenden `PostDebriefFollowupPanel` fuer Station anzeigen.
- Frontier-Probe-Readiness als Regression stabil halten.
- Verifier, Contract, Status, Roadmap und HTML-Handbuch fortschreiben.

## Nicht-Ziele
- Kein neuer Homebase-Startpfad.
- Keine neue Navigation.
- Keine Progression-/XP-Berechnung.
- Keine MissionResult-Mutation in der UI.
- Kein sichtbarer Host/Client-Fenster-Recapture.
- Kein groesserer Homebase-Layoutumbau.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_745_station_scenario_post_debrief_homebase_readability.md`
- `docs/tasks/TASK_641_frontier_probe_homebase_next_sortie_readiness.md`
- `docs/tasks/TASK_534_pre_mission_readiness_checklist.md`
- `docs/tasks/TASK_594_post_mission_skill_delta_homebase_bridge.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Akzeptanzkriterien
- Die Homebase zeigt nach dem Station-Debrief-Return unter der Summary eine kompakte Zeile wie `Naechste Sortie: Fireteam bereitstellen | danach: Loadout pruefen, Dropship beladen, Start freigeben`.
- Der Snapshot liefert `schema = sternenbuergerchen.station_scenario_homebase_next_sortie_readiness.v1`.
- `route_id = station_route_aa_door_computer_cargo` und `scenario_id = station_route_one_screen_multiplayer_drill` bleiben lesbar.
- `post_debrief_summary_gate = pass`, `station_result_present = true`, `readiness_label_visible = true`.
- Die Readiness-Steps enthalten `review_roster_gains`, `stage_fireteam`, `assign_loadout`, `prepare_transport`, `start_next_sortie`.
- Awards duerfen sichtbar bleiben, blockieren aber nicht die erste echte Vorbereitungsluecke.
- `read_only = true`, `ui_sets_gameplay_truth = false`, `creates_navigation = false`, `creates_command = false`.
- TASK_745 und TASK_641 bleiben gruen.

## Betroffene Dateien
- `scripts/meta/homebase_screen.gd`
- `scripts/tests/task_746_station_scenario_homebase_next_sortie_readiness.gd`
- `docs/tasks/TASK_746_station_scenario_homebase_next_sortie_readiness.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_746_station_scenario_homebase_next_sortie_readiness.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_745_station_scenario_post_debrief_homebase_readability.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_641_frontier_probe_homebase_next_sortie_readiness.gd`
- [x] `git diff --check`

## Risiken / offene Punkte
TASK_746 macht die Station-Homebase-Schleife handlungsfuehrender, ersetzt aber keinen echten sichtbaren Host/Client-Fensterlauf. Der naechste sinnvolle Schritt ist entweder ein Station-Homebase-Visible-Readiness-Review oder ein Host/Client-Recapture des kompletten Station-Abschlusses.
