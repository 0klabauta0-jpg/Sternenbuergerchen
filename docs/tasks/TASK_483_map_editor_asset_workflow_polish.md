# TASK_483 - Map Editor Asset Workflow Polish

## Ziel / Problem
Der Map Editor ist fuer schoene Maps zu zaeh zu bedienen: Asset-Vorschauen sind zu klein, lange Kit-Listen sind schwer zu scannen, Rotation ist zwar vorhanden, aber nicht prominent genug im Arbeitsfluss, und Asset-Groessen koennen nicht gezielt korrigiert werden.

## Sinnhaftigkeit / Ursache
Der Editor hat bereits Palette-Gruppen, Rotation und 3D-Asset-Mappings. Diese Pfade sind aber noch wie technische Hilfsfunktionen angebunden. Fuer den naechsten spielbaren Szenario-Slice braucht der Editor eine angenehmere Asset-Palette und einen stabil gespeicherten `object_scale`-Wert, ohne dass UI eine zweite Terrain-Wahrheit wird.

## Umfang
- Groessere Palette-Icons und breiteres Palette-Panel.
- Sichtbarer Selected-Asset-Preview-Block mit Displayname, Gruppe und Platzierungs-Scale.
- Alphabetische Sortierung innerhalb der sichtbaren Palette-Gruppe.
- Platzierungs-Scale fuer neue Assets, mindestens bis 1.6.
- Per-Tile-`object_scale` in `TerrainTileData`, Save/Load, Undo, Snapshots und Visuals.
- Property-Panel-Scale-Kontrolle fuer das selektierte Asset.

## Nicht-Ziele
- Kein neues freies Wand-/Cliff-Ziehwerkzeug.
- Keine automatische Wand-Snapping- oder Door-Open-Runtime-Logik.
- Kein Preset-/Korrektur-Speicher fuer Asset-Overrides.
- Keine Map-Editor-Komplettneugestaltung und kein SceneTree-Architekturumbau.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/map_editor_module_split.md`
- `docs/dev/map_editor_asset_workflow_contract.md`
- `docs/dev/terrain_truth_visual_audit_contract.md`

## Akzeptanzkriterien
- Die Palette meldet in Snapshots Preview-Icons mit mindestens 40 px Kantenlaenge.
- Sichtbare Palette-Eintraege sind innerhalb der aktiven Gruppe nach Displayname sortiert.
- Der Editor kann `station_wall` aus der Palette fuer Authoring waehlen und mit Platzierungs-Scale 1.6 pinseln.
- `object_scale` wird pro Tile gespeichert, geladen, in Undo wiederhergestellt und im 3D-Visual angewendet.
- Das Property-Panel kann den Scale eines selektierten Objekts nachtraeglich aendern.
- Rotation bleibt fuer Station-Waende und Floor-Panels funktionsfaehig.

## Betroffene Dateien
- `scripts/editor/map_editor.gd`
- `scripts/terrain/terrain_tile_data.gd`
- `scripts/terrain/terrain_map_data.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/terrain/terrain_map_renderer.gd`
- `scripts/terrain/terrain_truth_audit.gd`
- `docs/dev/terrain_truth_visual_audit_contract.md`
- `scripts/tests/task_483_map_editor_asset_workflow_polish.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_483_map_editor_asset_workflow_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_295_map_editor_paint_toolbar_tools_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_296_map_editor_palette_taxonomy_space_station_assets.gd`
- `godot_console.exe --headless --path . --script scripts/tests/bugfix_map_editor_asset_rotation_context_menu.gd`
- `git diff --check`

## Risiken / offene Punkte
- Das ist ein erster UX-Arbeitsfluss-Slice, kein finaler Editor.
- Grosse Asset-Bibliotheken brauchen spaeter Suche/Favoriten und echte Unterkategorien.
- Door-Open-Logik muss spaeter als Runtime-/Interaction-Contract gebaut werden.
- Wand-/Cliff-Ziehen sollte spaeter auf vorhandener Height-/Edge-/Structure-Wahrheit aufsetzen und nicht als UI-Sonderzustand entstehen.
