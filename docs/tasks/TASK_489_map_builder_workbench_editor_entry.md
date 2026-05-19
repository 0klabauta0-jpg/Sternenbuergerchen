# TASK_489 - Map Builder Workbench Editor Entry

## Status: IMPLEMENTIERT

## Ziel / Problem
- Der erste Sichttest der `MapBuilderWorkbench` war unklar: F6 startet nur eine Runtime-Vorschau ohne echte Editor-Werkzeuge.
- Der Workbench-Pfad braucht einen sichtbaren Godot-Editor-Einstieg, damit man GridMap, Asset-Placer-Root und Compile-Schritt findet.

## Sinnhaftigkeit / Ursache
- TASK_488 hat die Daten- und Compile-Wahrheit angelegt, aber keine Bedienflaeche im Godot-Editor.
- Godot-GridMap-Werkzeuge erscheinen erst sinnvoll, wenn der `GridMap`-Node ausgewaehlt ist; das war fuer den Nutzer nicht offensichtlich.
- Die Workbench darf trotzdem keine zweite Gameplay-Wahrheit einfuehren: Das Dock soll nur Editor-Aktionen ausloesen und den bestehenden Compile-Pfad nutzen.

## Umfang
- Ein kleines Editor-Plugin `Map Builder Workbench` als Dock ergaenzen und aktivieren.
- Dock-Aktionen als linke Icon-Leiste nach DCC-/Blender-Muster anbieten: Workbench oeffnen, MeshLibrary konfigurieren, `GridMap` auswaehlen, `AssetPlacerProps` auswaehlen und JSON kompilieren.
- In F6-/Runtime-Vorschau einen klaren Hinweis anzeigen, dass die Scene kein Spielmodus ist.
- Headless-Import stabil halten.

## Nicht-Ziele
- Kein vollstaendiger Custom-Map-Editor.
- Keine Runtime-Gameplay-Mutation aus dem Dock.
- Kein Ersatz fuer Godots GridMap-/Asset-Placer-Bedienung.
- Keine neue Persistenz neben `TerrainMapData` / Mission-JSON.

## Relevante Contracts / Dokumente
- `docs/dev/map_builder_tooling_spike_contract.md`
- `docs/tasks/TASK_488_map_builder_workbench_meshlibrary_mvp.md`
- `docs/tasks/TASK_487_install_godot_asset_placer.md`

## Akzeptanzkriterien
- Das Projekt aktiviert ein `Map Builder Workbench`-Editor-Plugin.
- Headless-Import ueberspringt Dock-Aufbau.
- Das Dock sitzt links und bietet eine Icon-Werkzeugleiste fuer Workbench, `GridMap`, `AssetPlacerProps` und Compile.
- F6 zeigt einen Hinweis, dass die Workbench im Editor-Dock bedient wird.
- Der bestehende TASK_488-Compile-Verifier bleibt gruen.

## Betroffene Dateien
- `addons/map_builder_workbench/plugin.cfg`
- `addons/map_builder_workbench/map_builder_workbench_plugin.gd`
- `scripts/editor/map_builder_workbench.gd`
- `scripts/tests/task_489_map_builder_workbench_editor_entry.gd`
- `project.godot`
- `docs/dev/map_builder_tooling_spike_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_489_map_builder_workbench_editor_entry.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_488_map_builder_workbench_meshlibrary_mvp.gd`
- `godot_console.exe --headless --path . --import`
- `git diff --check`

## Risiken / offene Punkte
- Der sichtbare Editor-Test bleibt offen: Godot neu starten, Dock `Map Builder` ansehen, `GridMap`-Auswahl pruefen und einmal nach JSON kompilieren.
- Das Dock ist bewusst nur ein Einstieg und keine eigene Paletten-/Placement-Engine.
