# TASK_683 - Map Editor Interaction FullHD Sight Pass

## Ziel / Problem
Nach TASK_682 sind Interaction-Bindings im Map-Editor per Preset authorbar. Offen ist, ob der rechte Editorbereich bei FullHD noch lesbar und bedienbar bleibt, wenn Marker-Inspector, Binding-Editor, Presets und Scenario-Felder zusammen sichtbar sind.

## Ursache / Sinnhaftigkeit
Der Spieler-/Autor-Workflow ist jetzt funktional, aber die Felddichte ist im rechten Panel gestiegen. Ohne sichtbares FullHD-Evidenzpaket koennen Presets technisch korrekt sein und sich trotzdem im echten Mapbau zaeh anfuehlen.

## Umfang
- Headless-FullHD-Evidenzlauf fuer den Map-Editor bei `1920 x 1080`.
- Selektierter Interaction-Marker mit Preset-Vorschau und Apply-/Remove-Bedienpfad.
- PNG- und JSON-Artefakt unter `tmp/`.
- Report-, Contract-, Status- und Roadmap-Update.

## Nicht-Ziele
- Kein Layout-Redesign des Map-Editors.
- Kein neues Runtime-Interaction-System.
- Kein automatischer Ersatz fuer einen menschlichen Sichtentscheid.
- Keine neue Gameplay-Wahrheit im Editor.

## Relevante Contracts / Dokumente
- `docs/dev/mission_interaction_point_contract.md`
- `docs/tasks/TASK_682_mission_interaction_binding_presets.md`
- `docs/dev/html_report_workbench_contract.md`
- `docs/ARCHITECTURE.md`

## Akzeptanzkriterien
- Der Verifier erzeugt `tmp/map_editor_interaction_fullhd_sight_pass.png`.
- Der Verifier erzeugt `tmp/map_editor_interaction_fullhd_sight_pass.json`.
- Das Manifest nennt Viewport `1920 x 1080`, aktiven Marker, Presetliste, Preset-Vorschau, Inspector-/Editor-Snapshots und sichtbare UI-Pfade.
- Property-Panel, Markerpanel, Binding-Inspector, Binding-Editor, Preset-Option, Apply-Button und Remove-Button bleiben im FullHD-Arbeitsbereich sichtbar oder scrollbar erreichbar.
- Manifest und Snapshots halten `ui_sets_gameplay_truth = false` ein.
- Der Bericht markiert den echten manuellen Sichtentscheid weiter als offen.

## Betroffene Dateien
- `docs/tasks/TASK_683_map_editor_interaction_fullhd_sight_pass.md`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`
- `scripts/tests/task_683_map_editor_interaction_fullhd_sight_pass.gd`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_683_map_editor_interaction_fullhd_sight_pass.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_682_mission_interaction_binding_presets.gd`
- `git diff --check`

## Risiken / offene Punkte
- Das PNG kann im Headless-Lauf ein generiertes Review-Board sein, wenn kein echter Viewport-Readback verfuegbar ist.
- Der echte menschliche FullHD-Sichtlauf bleibt offen: Lesbarkeit, Mauswege, Scroll-Gefuehl und Panel-Dichte muessen im sichtbaren Fenster beurteilt werden.
