# TASK_673 - Mission Interaction Point Contract

## Ziel / Problem
Space-Station- und Factory-Maps brauchen bald echte Missionsinteraktionen: Tueren, Computer, Hold-/Capture-Punkte und spaeter Bedienfelder. Bisher gibt es Marker, Objective-Readability und Frontier-Probe-Gates, aber noch keinen kleinen Contract, der Editor-Authoring, Marker und spaetere Runtime sauber verbindet.

## Sinnhaftigkeit / Ursache
Ohne Contract wuerden Door-/Computer-Regeln leicht in UI, Editor-Labels oder Assetnamen rutschen. Das widerspricht der Projektarchitektur: Der Editor darf Anker setzen, aber `SimulationRoot` und Scenario-Gates bleiben fuer Gameplay-Zustand autoritativ.

## Umfang
- Contract `docs/dev/mission_interaction_point_contract.md` anlegen.
- Marker-Typen fuer `interaction_door`, `interaction_computer` und `interaction_hold_zone` im `TerrainMarkerCatalog` vorbereiten.
- Roadmap, Status und HTML-Handbuch fortschreiben.
- Kleinen Verifier fuer Marker-/Contract-/Doku-Konsistenz anlegen.

## Nicht-Ziele
- Keine Door-Animation.
- Keine Computer-Bedienlogik.
- Keine neuen Mission-Commands.
- Kein Objective-/Capture-Rewrite.
- Keine Multiplayer-Authority-Aenderung.

## Relevante Contracts / Dokumente
- `docs/dev/mission_interaction_point_contract.md`
- `docs/dev/map_editor_asset_workflow_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_552_mission_objective_interaction_readability_pass.md`
- `docs/tasks/TASK_637_frontier_probe_playfeel_next_interaction.md`

## Akzeptanzkriterien
- Der neue Contract nennt Autoritaet, Marker-Typen, erwartete Daten, Runtime-Regeln und Nicht-Ziele.
- `TerrainMarkerCatalog` bietet die drei Interaction-Marker als Editor-Authoring-Typen an.
- Die Marker sind nicht single-instance und bleiben `editor_only`.
- Der Verifier `scripts/tests/task_673_mission_interaction_point_contract.gd` laeuft gruen.

## Betroffene Dateien
- `scripts/terrain/terrain_marker_catalog.gd`
- `scripts/tests/task_673_mission_interaction_point_contract.gd`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/dev/map_editor_asset_workflow_contract.md`
- `docs/tasks/TASK_673_mission_interaction_point_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_673_mission_interaction_point_contract.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_672_fullhd_drag_preview_art_direction.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Task macht nur die Authoring-/Contract-Schicht. Die echte Mission-Runtime braucht als Folgearbeit ein Scenario-Binding und einen Runtime-Snapshot fuer nahe, bedienbar, in-progress und complete.
