# TASK_421 - Move Stance Posture Speed Sight

## Ziel / Problem
Das Fireteam-Command `Move` soll die aktuell gewaehlte taktische Haltung klar und pruefbar in Runtime-Verhalten uebersetzen:

- `vorsichtig` / `cautious`: Waffe im Aim, Geschwindigkeit -35%, Sichtweite +20%.
- `normal`: Walk / Reisebewegung, Waffe unten, Geschwindigkeit unveraendert, Sichtweite unveraendert.
- `aggressiv` / `aggressive`: Run, Waffe unten, Geschwindigkeit +20%, Sichtweite -35%.

## Sinnhaftigkeit / Ursache
Die C/N/A-Auswahl ist im Playtest sichtbar, ihre Wirkung muss aber im autoritativen Mission-Tactical-Pfad ankommen. Speed, Waffenhaltung und Sichtweite duerfen nicht in der UI simuliert werden, sondern muessen als `UnitCommand`/Runtime-Status bei den betroffenen Units landen.

## Umfang
- `FireteamMovementController` setzt fuer `Move` die taktische Haltung auf Command-Ebene.
- `UnitCommand` und `UnitRuntimeStatus` tragen einen `sight_range_factor`.
- Fog-of-War liest den Runtime-Sichtfaktor pro Observer.
- Headless-Verifier prueft C/N/A-Command-Dictionaries, Runtime-Status und Doku-Marker.

## Nicht-Ziele
- Kein Umbau des Plan-/GO-/Recovery-Systems.
- Keine neue UI-Wahrheit fuer Sichtweite oder Bewegung.
- Keine Neubalancierung von Bounding/Caterpillar als eigene Bewegungsstile; deren bestehende Deckungs-/Aimed-Postures bleiben erhalten.

## Relevante Contracts / Dokumente
- `docs/dev/fireteam_runtime_execution_path_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_404_fireteam_movement_posture_bridge.md`
- `docs/tasks/TASK_419_go_next_action_and_npc_speed.md`
- `docs/tasks/TASK_420_waypoint_completion_area_followup_hotfix.md`

## Akzeptanzkriterien
- [x] `Move` + `cautious` erzeugt Commands mit `weapon_posture = aimed`, einem Speed-Multiplikator von `0.65` auf den bestehenden Move-Speed und `sight_range_factor = 1.2`.
- [x] `Move` + `normal` erzeugt Commands mit `movement_posture = travel`, `weapon_posture = lowered`, Speed-Multiplikator `1.0` und `sight_range_factor = 1.0`.
- [x] `Move` + `aggressive` erzeugt Commands mit `movement_posture = run`, `weapon_posture = lowered`, Speed-Multiplikator `1.2` und `sight_range_factor = 0.65`.
- [x] `SimulationRoot`-Snapshots und `TestUnit`-Runtime-Status geben `sight_range_factor` weiter.
- [x] Fog-of-War nutzt pro Observer den wirksamen Sichtweitenfaktor.

## Betroffene Dateien
- `scripts/tactical/fireteam_movement_controller.gd`
- `scripts/npc/unit_command.gd`
- `scripts/npc/unit_runtime_status.gd`
- `scripts/npc/test_unit.gd`
- `scripts/core/fog_of_war_system.gd`
- `scripts/core/simulation_root.gd`
- `scripts/tests/mission_test_setup.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/task_421_move_stance_posture_speed_sight.gd`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_421_move_stance_posture_speed_sight.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_404_fireteam_movement_posture_bridge.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_420_waypoint_completion_area_followup_hotfix.gd`
- `git diff --check`

## Risiken / offene Punkte
- `run` ist zunaechst ein Runtime-/Diagnose-Posture. Wenn fuer alle Visuals kein eigener Run-Clip existiert, faellt die Darstellung weiter auf vorhandene Laufanimationen zurueck.
- Sichtweite wirkt erst dort, wo der aktuelle Fog-of-War-Pfad Observer-Visibility berechnet. Combat-Reichweiten oder Waffenwerte bleiben unberuehrt.
