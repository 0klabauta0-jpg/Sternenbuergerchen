# TASK_668 - Map Editor Asset Scale Override Presets

## Ziel / Problem
Einige Kit-Teile sind im Editor zu gross oder zu klein und brauchen wiederholt denselben Placement-Scale. TASK_667 speichert globale Palette-Hilfen, aber noch keine Asset-spezifischen Korrekturen.

## Sinnhaftigkeit / Ursache
Der User soll beim Mapbau nicht jedes Mal neu daran denken muessen, dass ein bestimmtes Factory-, Station-, Wall- oder Space-Kit-Teil z. B. Scale `1.6` braucht. Solche Korrekturen sind Authoring-Komfort, nicht Map- oder Gameplay-Wahrheit.

## Umfang
- Speichert pro Palette-`type_id` einen lokalen `asset_scale_override`.
- Ausgewaehlte Assets mit Override setzen den Placement-Scale automatisch beim erneuten Auswaehlen.
- Palette bekommt kleine Save-/Clear-Buttons fuer den aktuellen Asset-Scale.
- Der Usability-Snapshot nennt Overrides, Count, Selected-Override und weiter `ui_sets_gameplay_truth = false`.

## Nicht-Ziele
- Keine Rotation-Overrides in diesem Slice.
- Keine Team- oder Projekt-Sync-Profile.
- Keine Aenderung an gespeicherten Maps; Tiles speichern weiterhin nur ihren konkreten `object_scale`.

## Relevante Contracts / Dokumente
- `docs/dev/map_editor_asset_workflow_contract.md`
- `docs/tasks/TASK_667_map_editor_persistent_palette_presets.md`
- `docs/tasks/TASK_516_editor_builder_ux_pass.md`

## Akzeptanzkriterien
- Ein Asset kann den aktuellen Placement-Scale als lokalen Override speichern.
- Beim erneuten Auswaehlen desselben Assets wird der Override angewendet.
- Der Override ueberlebt eine neue Editor-Instanz.
- Bestehende globale Palette-Persistenz aus TASK_667 bleibt gruen.

## Betroffene Dateien
- `scripts/editor/map_editor.gd`
- `scripts/tests/task_668_map_editor_asset_scale_override_presets.gd`
- `docs/dev/map_editor_asset_workflow_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_668_map_editor_asset_scale_override_presets.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_667_map_editor_persistent_palette_presets.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_516_editor_builder_ux_pass.gd`
- `git diff --check`

## Risiken / offene Punkte
Rotation-Defaults, geteilte Projektprofile und visuelle FullHD-Politur der neuen Buttons bleiben Folgearbeit. Der Override ist lokal unter `user://` und wird nicht mit Maps verteilt.
