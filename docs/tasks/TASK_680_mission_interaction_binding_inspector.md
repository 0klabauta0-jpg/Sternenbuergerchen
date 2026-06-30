# TASK_680 - Mission Interaction Binding Inspector

## Ziel / Problem
Der Map-Editor kann Marker setzen und Szenarien koennen Interaction-Points binden, aber beim Authoring ist noch nicht sichtbar, welcher Marker gerade einen Door-/Computer-/Hold-Bezug hat. Das macht Mapbau fehleranfaellig: ein Marker kann gut aussehen, aber im Szenario fehlen, falsch gebunden oder blockiert sein.

## Sinnhaftigkeit / Ursache
TASK_674 bis TASK_679 haben den Runtime-Pfad fuer Interaction-Points stabilisiert. Der Editor blieb dabei hinterher: Marker, Scenario-Panel und Binding-Snapshot waren getrennt. Der naechste kleine Content-Hebel ist ein read-only Inspector, der diese vorhandenen Daten zusammenliest.

## Umfang
- Read-only Editor-Snapshot `get_mission_interaction_binding_inspector_snapshot()`.
- Markerpanel-Label `InteractionBindingInspectorLabel`.
- Anzeige von Binding-Anzahl, fehlenden Markern und selektierter Marker-Bindung.
- Export im bestehenden `get_map_editor_usability_snapshot().interaction_binding_inspector`.

## Nicht-Ziele
- Kein neuer Scenario-Editor fuer Interaction-Points.
- Keine Runtime-Mutation, kein Door-State und keine Animation.
- Kein automatisches Reparieren fehlender Marker.
- Kein Umbau des Mission-Scenario-Panels.

## Relevante Contracts / Dokumente
- `docs/dev/mission_interaction_point_contract.md`
- `docs/tasks/TASK_674_mission_interaction_point_bindings.md`
- `docs/tasks/TASK_679_mission_interaction_progress_readability.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`

## Akzeptanzkriterien
- Der Editor kann den Frontier-Probe-Binding-Snapshot fuer die aktuelle Map lesen.
- Das Markerpanel zeigt eine kompakte Binding-Zeile.
- Auswahl von `objective_point` zeigt die Station-Computer-Bindung.
- Auswahl von `spawn_alpha` zeigt die Cargo-Hold-Bindung.
- Fehlende Marker werden im Snapshot als `missing_marker_ids` sichtbar.
- Der Snapshot ist read-only und setzt keine Gameplay-Wahrheit.

## Betroffene Dateien
- `scripts/editor/map_editor.gd`
- `scripts/tests/task_680_mission_interaction_binding_inspector.gd`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_680_mission_interaction_binding_inspector.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_674_mission_interaction_point_bindings.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Inspector ist zuerst read-only. Echte Bearbeitung von Interaction-Points im Editor bleibt Folgearbeit.
- Door-State-/Animationslogik bleibt bewusst ausserhalb dieses Tasks.
