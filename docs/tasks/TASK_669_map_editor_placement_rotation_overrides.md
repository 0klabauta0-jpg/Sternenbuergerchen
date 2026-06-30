# TASK_669 - Map Editor Placement Rotation Overrides

## Ziel / Problem
Assets lassen sich zwar nachtraeglich drehen, aber neue Pinselstriche hatten keinen eigenen Placement-Rotationsdefault. Fuer Wall-, Door-, Factory- und Station-Teile bedeutet das zu viel Nacharbeit pro Tile.

## Sinnhaftigkeit / Ursache
Der Editor soll beim Mapbau schneller und angenehmer werden. Nach Scale-Overrides aus TASK_668 ist Rotation der naechste wiederkehrende Authoring-Schritt.

## Umfang
- Fuehrt einen lokalen Placement-Rotationsdefault in 90-Grad-Schritten ein.
- Speichert pro Palette-`type_id` optionale `asset_rotation_overrides` in den lokalen `user://`-Authoring-Praeferenzen.
- Wendet gespeicherte Rotation beim erneuten Auswaehlen eines Assets an.
- Neue Brush-Platzierungen schreiben den aktuellen Placement-Rotationsdefault nach `object_rotation_degrees`.
- Der Usability-Snapshot nennt Placement-Rotation, Rotation-Overrides und weiter `ui_sets_gameplay_truth = false`.

## Nicht-Ziele
- Keine Auto-Rotation fuer Wand-/Door-/Cliff-Ketten.
- Keine geteilten Team-/Projektprofile.
- Keine Aenderung an bereits platzierten Tiles, ausser der User pinselt oder rotiert sie bewusst.

## Relevante Contracts / Dokumente
- `docs/dev/map_editor_asset_workflow_contract.md`
- `docs/tasks/TASK_668_map_editor_asset_scale_override_presets.md`
- `docs/tasks/TASK_667_map_editor_persistent_palette_presets.md`

## Akzeptanzkriterien
- Placement-Rotation kann in 90-Grad-Schritten gesetzt werden.
- Ein Asset kann die aktuelle Placement-Rotation lokal speichern und wieder loeschen.
- Beim erneuten Auswaehlen desselben Assets wird die gespeicherte Rotation angewendet.
- Ein Brush-Stroke schreibt die Placement-Rotation ins Tile.
- Bestehende Palette-Persistenz und Scale-Override-Regressionen bleiben gruen.

## Betroffene Dateien
- `scripts/editor/map_editor.gd`
- `scripts/tests/task_669_map_editor_placement_rotation_overrides.gd`
- `docs/dev/map_editor_asset_workflow_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_669_map_editor_placement_rotation_overrides.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_668_map_editor_asset_scale_override_presets.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_667_map_editor_persistent_palette_presets.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_516_editor_builder_ux_pass.gd`
- `git diff --check`

## Risiken / offene Punkte
Auto-Rotation/Snapping fuer Drag-Ketten bleibt Folgearbeit. Rotation-Overrides sind lokale Editor-Hilfen und werden nicht mit Maps oder Teamprofilen verteilt.
