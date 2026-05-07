# TASK_183 - Editor Hill Authoring Patch

## Ziel
Der Map-Editor soll Huegel, Haenge, Klippen, Sand und Waende auf Huegeln sauber authoren koennen, ohne bestehende Terrain-Daten beim Malen, Platzieren oder Speichern zu verlieren.

Der Patch stellt sicher, dass das Hoehenwerkzeug, Surface-Authoring und Objekt-/Wandplatzierung nach dem Vertrag aus TASK_182 zusammenarbeiten.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_182 - Terrain Hill Rules Contract
- TASK_159 - 2.5D Editor and Mission Primary View
- bestehender `TerrainMapData`-/`TerrainTileData`-Roundtrip
- bestehender Map-Editor mit Hoehenwerkzeug

## Kontext
Der Editor kann Hoehenstufen und `edge_type` bereits ueber das Hoehenwerkzeug schreiben. Andere Authoring-Pfade setzen aber ebenfalls Tile-Daten, besonders Surface-Typen und Katalogobjekte wie Waende, Klippen, Rampen oder Felsen.

Der Task verhindert, dass ein Arbeitsschritt den anderen still ueberschreibt. Eine Mauer auf einem Huegel muss danach weiterhin Huegel bleiben; Sand auf einem Hang muss Sand bleiben; eine Klippenkante darf beim Save/Load nicht verschwinden.

## Umfang
1. Hoehenwerkzeug pruefen und patchen:
   - H=0/H=1/H=2, Raise, Lower und Brushgroessen weiter unterstuetzen.
   - `edge_type` nach TASK_182 anwenden.
   - H=0 darf keine ungueltige sichtbare Hoehenkante behalten.
   - H>0 muss eine nachvollziehbare Kantenentscheidung tragen.
2. Surface-Authoring pruefen:
   - Sand, Road, Rock und Ground duerfen `height_level`, `edge_type` und `object_height` nicht zuruecksetzen.
   - Surface-Wechsel auf einem Hang oder Plateau bleibt im JSON erhalten.
3. Objekt-/Wandplatzierung pruefen:
   - Wand/Fels/Cliff-/Slope-Objekte duerfen die Gelaendehoehe nicht still veraendern.
   - Objektfelder wie `object_height`, `blocks_los`, `cover_value`, `walkable` und `type_id` werden gesetzt, ohne `height_level`, `surface_type` und `edge_type` zu verlieren.
   - Mauer auf Huegel ist ein expliziter Testfall.
4. Save/Load-Roundtrip:
   - Testkarte mit Huegel, Sandhang, Klippe, Plateau-Innenbereich und Mauer auf Huegel speichern und neu laden.
   - Alle relevanten Felder muessen byte-nah bzw. semantisch gleich bleiben.
5. Editor-/Live-Trennung:
   - Der Editor schreibt nur `TerrainMapData`.
   - Keine Runtime- oder `SimulationRoot`-State-Mutation im Authoring-Pfad.

## Nicht-Ziele
- Keine neuen Gameplay-Regeln.
- Keine 2.5D-Renderer-Politur ausser noetiger Editor-Refresh nach Datenpatch.
- Kein neues grosses Editor-UI.
- Keine umfassende Undo-Rewrite.

## Akzeptanzkriterien
- [x] H=0/H=1/H=2, Raise und Lower schreiben konsistent `height_level` und `edge_type`.
- [x] Surface-Painting auf Huegeln erhaelt Hoehe, Kante und Objektfelder.
- [x] Wandplatzierung auf Huegeln erhaelt `height_level` und setzt nur die objektbezogenen Felder nach Katalogregel.
- [x] Sandhang, Klippe, Plateau und Mauer-auf-Huegel ueberstehen Save/Load-Roundtrip.
- [x] Der Editor-Refresh zeigt die geaenderten Daten, ohne Gameplay-State als Wahrheit zu verwenden.
- [x] Ein TASK_183-Verifier deckt die Datenpatch- und Roundtrip-Faelle ab.

## Erwartete Dateien
- `scripts/editor/map_editor_height_tool.gd`
- `scripts/editor/map_editor.gd`
- `scripts/terrain/terrain_map_data.gd`
- `scripts/terrain/terrain_tile_data.gd`
- `scripts/tests/task_183_editor_hill_authoring_verifier.gd`
- optional eine kleine Test-Map unter `maps/`, falls ein fixture-basierter Roundtrip noetig ist
- `docs/tasks/TASK_183_editor_hill_authoring_patch.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_183_editor_hill_authoring_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_159_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_158_verifier.gd`
- [ ] Manueller Editor-Sichtcheck: Huegel malen, Sand setzen, Mauer platzieren, speichern, laden.
- [x] `git diff --check`

## Risiken
- Objektkataloge koennen versehentlich komplette Tile-Zustaende ueberschreiben. Der Patch muss zwischen Gelaende- und Objektfeldern sauber trennen.
- Eine zu strenge `edge_type`-Validierung kann existierende Karten brechen. Migration oder Warnung ist besser als stilles Umdeuten.

## Naechster Schritt
Nach TASK_183 sind Huegel authorbar und roundtrip-sicher. Die Runtime-Regeln folgen in TASK_184.

## Ergebnis
- `TerrainTileCatalog` markiert Waende, Felsen, Cliffs, Rampen und bestehende Objekt-Layer als hill-preserving, damit Palette-Platzierung `height_level`, `surface_type` und `edge_type` nicht mehr still ueberschreibt.
- Der Map-Editor malt Katalogtypen auch bei Brushgroessen ueber denselben Katalogpfad und benutzt keinen Sonderpfad mehr, der umgebende Cliff-/Slope-Tiles als Hoehenpatch uminterpretiert.
- Surface-Patches im Editor erhalten Strukturtypen wie `wall_*`, `rock_*`, `cliff_*` und `slope_*`; stale Ground-Base-Types unter `object_type_id` werden weiter geloescht, damit die Surface-Farbe sichtbar bleibt.
- `scripts/tests/task_183_editor_hill_authoring_verifier.gd` deckt Hoehenwerkzeug, hill-preserving Katalogplatzierung, Sandhang/Klippe/Plateau/Wand-/Fels-auf-Huegel-Roundtrip und Editor-Refresh ohne `SimulationRoot` ab.
