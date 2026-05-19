# TASK_491 - Map Editor Runtime Builder Workbench

## Ziel / Problem
Der aktuelle Map-Builder-Fokus lag zu stark auf Godot-Editor-Dock, GridMap und Plugin-Workflow. Fuer den eigentlichen Spiel-/Tool-Flow soll aber der Sternenbuergerchen-Map-Editor selbst die Bauwerkzeuge anbieten.

`scenes/editor/map_builder_workbench.tscn` bleibt die sichtbare F6-Testszene, soll aber direkt in den Runtime-Map-Editor fuehren.

## Sinnhaftigkeit / Ursache
Der Spieler-/Designer-Workflow braucht dieselben Funktionen in einer eigenen Editor-UI: Asset-Werkzeug, Strassen-Werkzeug, Terrain, Erase, Hoehe, Marker, Patrol und Rotation. Godot-Editor-Docks sind als Recherche-/Compiler-Pfad nuetzlich, aber nicht die Zielbedienung.

## Umfang
- Linke Runtime-Builder-Toolleiste im Map-Editor.
- Quick-Tools fuer Select, Terrain, Road, Asset, Erase, Height, Marker, Patrol und Rotation.
- F6-Start von `map_builder_workbench.tscn` fuehrt in `map_editor.tscn`, solange nicht headless/editor-hint.
- Usability-Snapshot macht den Runtime-Builder pruefbar.
- Doku markiert den Godot-Plugin-Pfad als Legacy/Compiler-Fallback, nicht als Primaerworkflow.

## Nicht-Ziele
- Kein vollstaendiges Auto-Tiling fuer Strassen, Waende oder Cliffs.
- Kein neuer Gameplay-State im UI.
- Kein Entfernen der bestehenden Godot-Plugin-/Compile-Werkzeuge.
- Kein frei gezeichnetes Terrain-Sculpting.

## Relevante Contracts / Dokumente
- `docs/dev/map_editor_asset_workflow_contract.md`
- `docs/dev/map_builder_tooling_spike_contract.md`
- `docs/tasks/TASK_486_map_builder_tooling_spike.md`
- `docs/tasks/TASK_488_map_builder_workbench_meshlibrary_mvp.md`
- `docs/tasks/TASK_490_map_builder_paint_tools_mvp.md`

## Akzeptanzkriterien
- `map_editor.tscn` erzeugt eine linke Runtime-Builder-Toolleiste neben der Palette.
- Die Palette wird neben die Toolleiste verschoben und bleibt breit genug fuer grosse Asset-Vorschauen.
- `activate_runtime_builder_tool("road")` waehlt die Strassenplatte und aktiviert den Brush.
- `activate_runtime_builder_tool("asset")` waehlt ein Gebaeude-Asset und aktiviert den Brush.
- `activate_runtime_builder_tool("erase")`, `"height"`, `"marker"`, `"patrol"` und `"select"` schalten die bestehenden Editor-Werkzeuge um.
- `map_builder_workbench.tscn` startet im sichtbaren F6-Spielmodus den Runtime-Map-Editor.
- Headless-Verifier behalten den alten Workbench-Compile-Pfad.

## Betroffene Dateien
- `scripts/editor/map_editor.gd`
- `scripts/editor/map_builder_workbench.gd`
- `scripts/tests/task_491_map_editor_runtime_builder_workbench.gd`
- `docs/dev/map_editor_asset_workflow_contract.md`
- `docs/dev/map_builder_tooling_spike_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_491_map_editor_runtime_builder_workbench.gd`
- Relevante Map-Builder-/Map-Editor-Regressionen
- `git diff --check`

## Risiken / offene Punkte
- Auto-Snapping/Auto-Rotation fuer Strassen, Waende, Tueren und Cliffs bleibt Folgearbeit.
- Die linke Leiste nutzt noch kompakte Text-/Buchstaben-Buttons; echte Icon-Sprache kann danach als reiner UI-Polish folgen.
- Der Godot-Plugin-Pfad bleibt vorerst erhalten, damit vorhandene Import-/Compile-Tests nicht gebrochen werden.
