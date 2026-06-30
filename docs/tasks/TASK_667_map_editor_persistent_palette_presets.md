# TASK_667 - Map Editor Persistent Palette Presets

## Ziel / Problem
Der Runtime-Map-Editor hat seit TASK_516 Suche, Favoriten, Recent-Assets und Scale-Presets, aber diese Arbeitshelfer gehen beim Editor-Neustart verloren. Dadurch muss man haeufige Station-, Factory-, Pipe-, Wall- oder Door-Teile immer wieder suchen.

## Sinnhaftigkeit / Ursache
Mapbau soll weniger Reibung erzeugen, damit kleine spielbare Szenarien schneller entstehen. Persistente Palette-Hilfen sind ein kleiner UX-Gewinn, ohne den Map-Datenpfad oder die Simulation anzufassen.

## Umfang
- Persistiert Paletten-Favoriten, zuletzt genutzte Assets und Placement-Scale als Editor-Arbeitspräferenz unter `user://map_editor_builder_preferences.json`.
- Laedt diese Praeferenzen beim Start von `map_editor.tscn`.
- Speichert Aenderungen bei Favoriten, Recent-Auswahl und Placement-Scale.
- Erweitert den Usability-Snapshot um Pfad, Schema, Lade-/Speicherstatus und die explizite Grenze `ui_sets_gameplay_truth = false`.

## Nicht-Ziele
- Keine Map-, Terrain-, Tile-, Mission- oder Gameplay-Wahrheit speichern.
- Keine Asset-Override-Presets fuer einzelne Tiles.
- Kein neues Editor-Plugin und kein grosses Paletten-Redesign.

## Relevante Contracts / Dokumente
- `docs/dev/map_editor_asset_workflow_contract.md`
- `docs/tasks/TASK_516_editor_builder_ux_pass.md`
- `docs/tasks/TASK_491_map_editor_runtime_builder_workbench.md`

## Akzeptanzkriterien
- Favoriten, Recent und Placement-Scale ueberleben eine neue Editor-Instanz.
- Der Persistenzpfad liegt unter `user://` und nicht in Map-JSON oder Gameplay-Daten.
- Der Snapshot zeigt, dass die UI keine Gameplay-Wahrheit setzt.
- Bestehende TASK_516-Palettenfunktionen bleiben gruen.

## Betroffene Dateien
- `scripts/editor/map_editor.gd`
- `scripts/tests/task_516_editor_builder_ux_pass.gd`
- `scripts/tests/task_667_map_editor_persistent_palette_presets.gd`
- `docs/dev/map_editor_asset_workflow_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_667_map_editor_persistent_palette_presets.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_516_editor_builder_ux_pass.gd`
- `git diff --check`

## Risiken / offene Punkte
Der Slice speichert nur globale Editor-Hilfen. Asset-Override-Presets pro Asset oder Team-weit teilbare Builder-Profile bleiben Folgearbeit, weil sie einen eigenen Datenvertrag brauchen.
