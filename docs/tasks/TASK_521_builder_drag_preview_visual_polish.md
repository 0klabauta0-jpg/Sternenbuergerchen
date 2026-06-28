# TASK_521 - Builder Drag Preview Visual Polish

## Ziel / Problem
Der Runtime-Map-Editor hat seit TASK_492/TASK_516 Netzwerk-Drag-Daten fuer Pipe, Wall und Cliff, aber beim eigentlichen Ziehen fehlt eine sichtbare Linie im 2.5D/3D-Viewport. Dadurch muss man raten, welche Kachelkette beim Loslassen gesetzt wird.

## Sinnhaftigkeit / Ursache
Der Builder soll als Sternenbuergerchen-Map-Editor angenehm bedienbar werden. Dafuer muss der aktive Drag-Stroke sichtbar sein, ohne dass die Preview bereits Tile-, Terrain- oder Gameplay-Wahrheit schreibt.

## Umfang
- Read-only Network-Preview-Snapshot aus dem bestehenden Drag-Pfad an die Primary3DView spiegeln.
- Sichtbare 3D-Linie fuer aktive Pipe-/Wall-/Cliff-/Network-Drag-Pfade zeichnen.
- Start-, Ziel-, Segment- und Pfadzaehler im Render-/Usability-Snapshot ausweisen.
- Preview bei Toolwechsel, Apply, Cancel oder Palette-Auswahl loeschen.
- Kleine Authoring-Preview-Methode fuer Tests und spaetere UI-Hover-Workflows bereitstellen.

## Nicht-Ziele
- Kein neues Auto-Tiling.
- Keine neuen Netzwerk-Asset-Familien.
- Keine Door-/Computer-Interaktion.
- Keine neue Gameplay-Wahrheit im Editor oder Renderer.
- Kein kompletter Editor-UI-Redesign-Slice.

## Relevante Contracts / Dokumente
- `docs/dev/map_editor_asset_workflow_contract.md`
- `docs/tasks/TASK_491_map_editor_runtime_builder_workbench.md`
- `docs/tasks/TASK_492_map_editor_network_drag_snap_tools.md`
- `docs/tasks/TASK_493_map_editor_station_builder_focus.md`
- `docs/tasks/TASK_516_editor_builder_ux_pass.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Akzeptanzkriterien
- `preview_runtime_network_path_for_authoring("pipe", start, end)` baut eine sichtbare Preview, ohne Tiles zu veraendern.
- Der Map-Editor-Snapshot nennt aktive Visual-Preview, Pfadlaenge, Start/Ziel, Segmentzahl und `ui_sets_gameplay_truth = false`.
- Die Primary3DView meldet `editor_network_drag_preview_segment_count > 0`, wenn ein Preview-Pfad mehr als ein Tile enthaelt.
- `apply_runtime_network_path_for_authoring(...)` setzt danach den echten Pfad und loescht die Preview.
- `clear_runtime_network_preview_for_authoring()` loescht die Preview ohne Tile-Aenderung.
- Bestehende TASK_491/TASK_492/TASK_516-Regressionen bleiben gruen.

## Betroffene Dateien
- `scripts/editor/map_editor.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/task_521_builder_drag_preview_visual_polish.gd`
- `docs/dev/map_editor_asset_workflow_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_521_builder_drag_preview_visual_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_516_editor_builder_ux_pass.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_492_map_editor_network_drag_snap_tools.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_491_map_editor_runtime_builder_workbench.gd`
- `git diff --check`

## Risiken / offene Punkte
- Die Preview ist bewusst eine einfache farbige 3D-Linie. Icons/Handles/Segmentnummern koennen spaeter als reiner UI-Polish folgen.
- Der finale FullHD-Sichtcheck bleibt sinnvoll, weil Headless-Tests nur Snapshot und Node-Zaehlung pruefen.
