# TASK_492 - Map Editor Network Drag Snap Tools

## Ziel / Problem
Map-Bau bleibt zu langsam, wenn Strassen, Schienen, Pipelines, Waende und Cliffs einzeln aus der Palette gesetzt und manuell gedreht werden muessen.

Der Runtime-Map-Editor braucht ein vorbereitetes Linien-/Netzwerk-Tool, das vorhandene Asset-Sets nutzt und den Grundstrassensatz auf Rails, Pipes, Walls und Cliffs uebertraegt.

## Sinnhaftigkeit / Ursache
TASK_491 hat den Builder in den Sternenbuergerchen-Map-Editor zurueckgeholt. Der naechste Ergonomie-Schritt ist ein Drag-Workflow fuer zusammenhaengende Infrastruktur:

- Grundstrassen als zusammenhaengende Road-Linie.
- Rails fuer spaetere Bahn-/Monorail-Logistik.
- Pipelines fuer Energie, Oel, Rohstoffe und Abwasser.
- Wall-/Cliff-Linien als Basis fuer spaetere Tuer-/Segmentlogik.
- Factory- und Space-/Station-Kit bleiben ueber die Runtime-Palette erreichbar und groessen-korrigierbar.

## Umfang
- Runtime-Builder-Leiste um Linienwerkzeuge fuer Road, Rail, Pipe, Wall und Cliff erweitern.
- Linienpfad aus Start-/End-Tile bauen.
- Netzwerk-Varianten anhand lokaler Verbindungen waehlen: End, Straight, Corner, Split, Cross, soweit im jeweiligen Set vorhanden.
- Bestehende Nachbarsegmente derselben Familie beim Setzen beruecksichtigen.
- Ein gezogener Pfad ist ein Undo-Schritt.
- Linien-Assets nutzen den vorhandenen `object_rotation_degrees`-/`object_scale`-Pfad.
- Factory-/Space-Kit-Groessenkorrektur ueber Platzierungs-Scale fuer relevante Objekt-/Kit-Prefixe vorbereiten.

## Nicht-Ziele
- Keine Bruecken, Rampen, gruene Strassenvarianten oder Hoch-/Runter-Strassen in diesem Task.
- Keine echte Produktions-/Ressourcen-Simulation fuer Oel, Energie oder Abwasser.
- Keine Door-Open- oder Computer-Interaction-Logik.
- Kein neues Gameplay-State-System im UI.

## Relevante Contracts / Dokumente
- `docs/dev/map_editor_asset_workflow_contract.md`
- `docs/tasks/TASK_491_map_editor_runtime_builder_workbench.md`
- `docs/tasks/TASK_485_map_editor_saveas_modular_scale_fix.md`
- `docs/tasks/TASK_483_map_editor_asset_workflow_polish.md`

## Akzeptanzkriterien
- `activate_runtime_builder_tool("road_line")` aktiviert ein Runtime-Netzwerktool fuer Road.
- `apply_runtime_network_path_for_authoring("road", start, end)` setzt Strassen-Enden, -Geraden und -Ecken aus dem Space-Kit-Grundstrassensatz.
- Rail- und Pipe-Linien nutzen `spacekit_rail*` bzw. `spacekit_pipe*` und speichern Rotation/Scale pro Tile.
- Wall- und Cliff-Linien sind ueber dieselbe Toolfamilie vorbereitet.
- Bestehende Road-/Rail-/Pipe-Nachbarn koennen beim naechsten Stroke zu Split/Cross/Corner aktualisiert werden, soweit Varianten existieren.
- Der Usability-Snapshot nennt aktive Network-Art, Path-Preview und verfuegbare Toolfamilien.
- Factory und Space-/Station-/Pipe-/Rail-/Platform-Kit-Assets bleiben ueber Placement-Scale korrigierbar.

## Betroffene Dateien
- `scripts/editor/map_editor.gd`
- `scripts/tests/task_492_map_editor_network_drag_snap_tools.gd`
- `docs/dev/map_editor_asset_workflow_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_492_map_editor_network_drag_snap_tools.gd`
- Relevante TASK_491-/TASK_483-Regressionen
- `git diff --check`

## Risiken / offene Punkte
- Die visuelle Rotation der 2D-Preview-Karten ist weiterhin einfacher als die 3D-Ansicht; der 3D-Pfad liest die gespeicherte Tile-Rotation.
- Bruecken, Rampen, Gruenstrassen und Hoch-/Runter-Strassen brauchen eigene Variantensets.
- Tuer-/Computer-/Pipeline-Interaktionen brauchen spaeter einen eigenen Gameplay-Contract.
