# TASK_744 - Station Scenario Meta Debrief Route Smoke

## Ziel / Problem
TASK_743 macht im Missions-HUD sichtbar, dass die fertige Station-Route in den Debrief und danach zur Homebase fuehrt. Der echte Meta-Weg muss nun fuer das Station-Szenario belegbar sein: Station-Ergebnis im Debrief anzeigen, Return-to-Homebase ausloesen und das Ergebnis auf dem Rueckweg erhalten.

## Sinnhaftigkeit / Ursache
Der Debrief-/Homebase-Rueckweg existiert bereits und wurde fuer Frontier Probe abgesichert. Der aktuelle spielbare Stationsdrill nutzt aber die Route `AA > DOOR > COM > CARGO` und ein eigenes Szenario. Damit der Core Loop nicht nur als HUD-Zeile endet, braucht dieser Pfad einen eigenen Smoke auf dem vorhandenen Meta-Layer.

## Umfang
- `MetaLayerFlow` um einen read-only Station-Szenario-Meta-Debrief-Route-Smoke-Snapshot erweitern.
- Den bestehenden Debrief-Return-Homebase-Handoff wiederverwenden.
- Vor und nach dem Return pruefen: Debrief sichtbar, Return verfuegbar, Homebase sichtbar nach Return, MissionResult erhalten.
- Lokales Manifest fuer den Smoke schreiben.
- Aktuellen Status, Roadmap, Contract und Handbuchbericht fortschreiben.

## Nicht-Ziele
- Kein neuer Debrief-Screen.
- Kein neuer Meta-Navigationspfad.
- Keine neue MissionResult-, XP-, Skill-, Ammo-, Combat-, Movement- oder UI-Wahrheit.
- Kein visueller Debrief-Polish und keine Homebase-Progression-Aenderung.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_743_station_scenario_debrief_handoff_cue.md`
- `docs/tasks/TASK_639_frontier_probe_meta_debrief_route_smoke.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Akzeptanzkriterien
- `get_station_scenario_meta_debrief_route_smoke_snapshot()` liefert `schema = sternenbuergerchen.station_scenario_meta_debrief_route_smoke.v1`.
- Der Snapshot erkennt `route_id = station_route_aa_door_computer_cargo` oder `scenario_id = station_route_one_screen_multiplayer_drill`.
- Vor Return gilt: Debrief sichtbar, Homebase verborgen, Return-to-Homebase verfuegbar.
- Nach Return gilt: Homebase sichtbar, Debrief verborgen, Navigation sichtbar.
- `mission_result_preserved = true`, `active_mission_released = true`, `read_only = true` und `ui_sets_gameplay_truth = false`.
- Der Testhelper nutzt weiterhin nur den bestehenden Debrief-Return-Handler.

## Betroffene Dateien
- `scripts/meta/meta_layer_flow.gd`
- `scripts/tests/task_744_station_scenario_meta_debrief_route_smoke.gd`
- `docs/tasks/TASK_744_station_scenario_meta_debrief_route_smoke.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Lokale Pruefung
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_744_station_scenario_meta_debrief_route_smoke.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_743_station_scenario_debrief_handoff_cue.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_639_frontier_probe_meta_debrief_route_smoke.gd`
- [ ] `git diff --check`

## Risiken / offene Punkte
TASK_744 ist ein Headless-Meta-Smoke, kein finaler sichtbarer Debrief-/Homebase-Polish. Danach bleibt sinnvoll, die Station-spezifische Homebase-Rueckkehr lesbarer zu machen oder den echten Host/Client-Fensterlauf mit dem neuen Abschluss zu recapturen.
