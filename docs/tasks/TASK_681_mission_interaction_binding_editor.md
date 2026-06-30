# TASK_681 - Mission Interaction Binding Editor

## Ziel / Problem
TASK_680 macht Scenario-Interaction-Bindings im Map-Editor sichtbar. Der naechste Content-Schritt ist, einen ausgewaehlten Marker direkt mit einem Interaction-Point verbinden oder die Bindung wieder entfernen zu koennen.

## Ursache / Sinnhaftigkeit
Ohne kleinen Editor bleibt der Workflow zu indirekt: Marker liegen in der Map, die Bindings aber in `MissionScenarioData.vertical_slice.interaction_points`. Fuer neue Missionen muss diese Verbindung im Editor authorbar sein, ohne Runtime-Gates oder Gameplay-Wahrheit im UI zu erzeugen.

## Umfang
- Kleines Binding-Editor-Panel im bestehenden Markerbereich.
- Apply/Remove fuer den selektierten Marker.
- Schreiben in `vertical_slice.interaction_points` der aktuellen Mission-Scenario-Daten.
- Read-/Write-Snapshot fuer Verifier und Berichte.

## Nicht-Ziele
- Kein Door-State-System.
- Kein Runtime-Interaction-Start aus dem Editor.
- Kein grosses Mission-Scenario-Panel-Redesign.
- Kein automatisches Reparieren fehlender Marker.

## Relevante Contracts / Dokumente
- `docs/dev/mission_interaction_point_contract.md`
- `docs/tasks/TASK_680_mission_interaction_binding_inspector.md`
- `docs/ARCHITECTURE.md`

## Akzeptanzkriterien
- Ein selektierter Marker kann als `door`, `computer` oder `hold_zone` gebunden werden.
- Apply erzeugt oder aktualisiert genau einen Scenario-Interaction-Point fuer den Marker.
- Remove entfernt die selektierte Marker-Bindung aus dem Scenario.
- Der Inspector aktualisiert sich danach und bleibt read-only.
- Snapshot und UI markieren klar: Authoring-Daten, keine Gameplay-Wahrheit.

## Betroffene Dateien
- `scripts/editor/map_editor.gd`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`
- `scripts/tests/task_681_mission_interaction_binding_editor.gd`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_681_mission_interaction_binding_editor.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_680_mission_interaction_binding_inspector.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Editor nimmt fuer neue Bindings konservative Defaults. Ein spaeterer Slice kann bessere Presets je Marker-/Asset-Typ anbieten.
- FullHD-Sicht und Bedienkomfort im rechten Panel bleiben ein separater manueller Pass.
