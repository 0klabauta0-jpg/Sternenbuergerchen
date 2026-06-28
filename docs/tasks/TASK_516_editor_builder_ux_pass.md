# TASK_516 - Editor Builder UX Pass

## Ziel / Problem
Der Runtime-Map-Editor ist funktional, fuehlt sich beim Bauen aber noch zu verwaltungslastig an. Assets muessen schneller auffindbar sein, oft genutzte Teile sollen nicht jedes Mal neu gesucht werden, und korrigierende Scale-Werte sollen ohne Spinbox-Gefummel waehlbar sein.

## Sinnhaftigkeit / Ursache
TASK_491 bis TASK_493 haben Builder-Leiste, Netzwerktools und Station-/Outpost-Fokus in den Sternenbuergerchen-Editor gebracht. Der naechste sinnvolle Schritt ist kein neues Gameplay, sondern ein besserer Authoring-Workflow: Suche, Favoriten/Recent und Scale-Presets auf Basis der vorhandenen Palette und `object_scale`-Wahrheit.

## Umfang
- Palette-Suchfeld im bestehenden Palette-Panel.
- Favoriten/Recent-Filter fuer haeufig genutzte Assets.
- Recent-Liste aktualisiert sich bei Palette-Auswahl und Quick-Tools.
- Scale-Preset-Buttons fuer 0.5, 1.0, 1.6 und 2.0.
- Usability-Snapshot erweitert den bestehenden Palette-/Builder-Status.
- Drag-Preview-Snapshot fuer aktive Pipe-/Wall-/Cliff-Netzwerkpfade lesbarer machen.

## Nicht-Ziele
- Kein neuer Map-Datenpfad.
- Keine neue Asset-Datenbank.
- Keine freie Terrain-Sculpting-UI.
- Keine Runtime-Tuer-/Computer-Interaction.
- Keine neue Gameplay-Wahrheit im Editor.

## Relevante Contracts / Dokumente
- `docs/dev/map_editor_asset_workflow_contract.md`
- `docs/tasks/TASK_491_map_editor_runtime_builder_workbench.md`
- `docs/tasks/TASK_492_map_editor_network_drag_snap_tools.md`
- `docs/tasks/TASK_493_map_editor_station_builder_focus.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Akzeptanzkriterien
- `set_palette_search_query_for_authoring("door")` filtert sichtbare Palette-Assets nach Name oder Type-ID.
- `toggle_palette_favorite_for_authoring(type_id)` setzt/entfernt Favoriten ohne Tile-/Gameplay-State zu aendern.
- Der Favoritenfilter zeigt Favoriten plus Recent-Assets, wenn er aktiv ist.
- Recent-Assets werden bei Auswahl und Quick-Tool-Nutzung gepflegt.
- `set_object_placement_scale_preset(1.6)` nutzt den bestehenden Placement-Scale-Pfad.
- Der Palette-Snapshot nennt Suchbegriff, Favoriten, Recent, Trefferzahl, Preview-Icon-Groessen und Scale-Presets.
- Der Runtime-Builder-Snapshot enthaelt eine kompakte Drag-Preview-Zusammenfassung fuer Network-Tools.

## Betroffene Dateien
- `scripts/editor/map_editor.gd`
- `scripts/tests/task_516_editor_builder_ux_pass.gd`
- `docs/dev/map_editor_asset_workflow_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_516_editor_builder_ux_pass.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_493_map_editor_station_builder_focus.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_492_map_editor_network_drag_snap_tools.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_491_map_editor_runtime_builder_workbench.gd`
- `git diff --check`

## Risiken / offene Punkte
- Favoriten/Recent sind vorerst session-lokal im Editor. Persistente User-Presets gehoeren in einen spaeteren kleinen Settings-Task.
- Das verbessert Auswahl und Korrekturwerte, ersetzt aber noch nicht eine echte visuelle Drag-Preview-Linie im 3D-Viewport.
