# TASK_493 - Map Editor Station Builder Focus

## Ziel / Problem
Der Runtime-Builder war nach TASK_492 zu breit fuer den naechsten Space-Station-/Outpost-Workflow: Rails sind fuer diese Map kein Ziel, Road-Line wirkt irrefuehrend, waehrend Waende, Cliffs, Tueren und Pipelines wirklich gebraucht werden.

## Sinnhaftigkeit / Ursache
Der Editor soll als spielbarer Sternenbuergerchen-Map-Editor funktionieren. Die linke Builder-Leiste muss deshalb die aktuell sinnvollen Bauwerkzeuge zeigen und nicht jede vorbereitete technische Netzwerkfamilie gleich prominent machen.

## Umfang
- Runtime-Builder-Leiste auf sichtbare Kernwerkzeuge fuer Station/Outpost fokussieren.
- Road-/Rail-Line nicht als sichtbare Hauptbuttons fuehren; die bestehenden Backend-Pfade bleiben als vorbereitete/Legacy-Authoring-API verfuegbar.
- Pipe-, Wall- und Cliff-Line als sichtbare Linienwerkzeuge behalten.
- Space-Station-Tuer-Quick-Brushes fuer Door Wall, Door Closed, Door Half und Door Open ergaenzen.
- Kleinen Door-State-Authoring-Snapshot vorbereiten, damit spaeter Closed/Half/Open-Animationen auf denselben Asset-Familien aufbauen koennen.

## Nicht-Ziele
- Keine Runtime-Tuerinteraktion, Naeheabfrage oder Animation.
- Keine neue Gameplay-Wahrheit im Editor.
- Keine Entfernung der Road-/Rail-Katalogdaten.
- Keine Pipeline-/Ressourcen-Simulation.

## Relevante Contracts / Dokumente
- `docs/dev/map_editor_asset_workflow_contract.md`
- `docs/tasks/TASK_492_map_editor_network_drag_snap_tools.md`
- `docs/tasks/TASK_491_map_editor_runtime_builder_workbench.md`

## Akzeptanzkriterien
- Die sichtbare Runtime-Builder-Leiste zeigt Pipe-, Wall- und Cliff-Line, aber nicht mehr Rail-Line oder Road-Line als Hauptbuttons.
- Door-Wall, Door-Closed, Door-Half und Door-Open sind als Quick-Brushes waehlbar.
- Die Tuer-Quick-Brushes nutzen vorhandene Katalog-IDs aus dem Space-Station-Set.
- Der Usability-Snapshot enthaelt einen Authoring-Contract fuer Station-Door-Zustaende.
- TASK_492-Backend-Pfade fuer Road/Rail bleiben testbar, ohne als aktueller Designfokus in der Leiste zu erscheinen.

## Betroffene Dateien
- `scripts/editor/map_editor.gd`
- `scripts/tests/task_492_map_editor_network_drag_snap_tools.gd`
- `scripts/tests/task_493_map_editor_station_builder_focus.gd`
- `docs/dev/map_editor_asset_workflow_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_493_map_editor_station_builder_focus.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_492_map_editor_network_drag_snap_tools.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_491_map_editor_runtime_builder_workbench.gd`
- `git diff --check`

## Risiken / offene Punkte
- Door-Closed/Half/Open sind vorerst Authoring-States, keine animierte Runtime-Tuer.
- Double-Doors bleiben im Door-State-Contract sichtbar, aber nicht als eigene Quick-Buttons in der ersten Leiste.
- Road-/Rail-Code bleibt vorhanden, falls spaetere Karten ihn wieder brauchen; sichtbar priorisiert ist er hier nicht.
