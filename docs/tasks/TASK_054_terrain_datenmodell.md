# TASK 054 – Terrain-Tile-Datenmodell und Registry

## Ziel
Ein datenbasiertes Terrain-System einfuehren, das jedem Tile Metadaten zuweist: walkability, LOS-Blockade, Cover-Wert, Hoehenebene und Oberflaechentyp.

## Pflicht vor Beginn
- Lies `docs/PROJECT_BRIEF.md`
- Lies `docs/ARCHITECTURE.md`
- Lies `docs/CODEX_RULES.md`
- Lies `docs/IMPLEMENTATION_STATUS.md`
- Pruefe den Git-Status

## Ist-Zustand
- Die Map besteht aus 64 isometrischen `Sprite2D`-Tiles unter einem `Terrain`-Node in `iso_map_v2_layout.tscn`.
- Alle Tiles nutzen dieselbe Textur (`terrain_SW.png`) ohne Metadaten.
- `scripts/terrain/` und `scripts/maps/` sind leer.
- Es gibt kein Tile-Grid-System – Units werden an absoluten `Vector2`-Positionen platziert.
- LOS ist rein distanzbasiert, Cover ist ein Zahlenwert am Command, Bewegung ohne Hindernisse.

## Aufgabe

### 1. TerrainTileData (Datenmodell)
- Neues RefCounted `TerrainTileData` unter `res://scripts/terrain/terrain_tile_data.gd`:
  - `tile_id: String` (z.B. `"tile_3_5"` fuer Grid-Koordinate)
  - `grid_position: Vector2i` (Spalte, Zeile im Iso-Grid)
  - `world_position: Vector2` (Mittelpunkt des Tiles in Weltkoordinaten)
  - `walkable: bool` (default: true)
  - `blocks_los: bool` (default: false)
  - `cover_value: int` (0–100, default: 0) – wie viel Deckung das Tile bietet
  - `height_level: int` (0–2, default: 0) – Hoehenstufe
  - `surface_type: String` (default: `"ground"`) – z.B. `"ground"`, `"road"`, `"sand"`, `"rock"`
  - Methoden: `to_dict() -> Dictionary`, statische `from_dict(data: Dictionary) -> TerrainTileData`

### 2. TerrainRegistry
- Neues Node-Script `TerrainRegistry` unter `res://scripts/terrain/terrain_registry.gd`:
  - `register_tile(tile_data: TerrainTileData) -> void`
  - `get_tile_at_grid(grid_pos: Vector2i) -> TerrainTileData`
  - `get_tile_at_world(world_pos: Vector2) -> TerrainTileData` – findet das naechste Tile anhand der Weltposition
  - `get_all_tiles() -> Array[TerrainTileData]`
  - `is_walkable(grid_pos: Vector2i) -> bool`
  - `get_cover_at(grid_pos: Vector2i) -> int`
  - `get_height_at(grid_pos: Vector2i) -> int`
  - Internes Dictionary: `_tiles: Dictionary` (key = `Vector2i`, value = `TerrainTileData`)

### 3. Grid-Konvertierung
- Hilfs-Methoden fuer Iso-Grid ↔ Welt-Koordinaten:
  - `world_to_grid(world_pos: Vector2) -> Vector2i`
  - `grid_to_world(grid_pos: Vector2i) -> Vector2`
- Basierend auf der bestehenden Tile-Groesse und dem Iso-Layout (aus `terrain_SW.png`-Dimensionen und dem Positionsmuster der 64 Tiles).

### 4. Testszene: TerrainRegistry einbinden
- `TerrainRegistry` als Node in die `mission_reactivity_test.tscn` einfuegen.
- `MissionTestSetup` liest die bestehenden 64 Sprite2D-Tiles aus dem Map-Node und registriert sie als `TerrainTileData` mit Default-Werten (alle walkable, kein Cover, Hoehe 0, Typ "ground").

### 5. Keine Gameplay-Wirkung in diesem Task
- Die Daten werden nur registriert und bereitgestellt.
- LOS, Movement und Cover nutzen die Terrain-Daten noch nicht.

## Nicht-Ziele
- keine Tile-Darstellungsaenderung
- keine neuen Texturen oder Assets
- kein Pathfinding
- keine Gameplay-Wirkung der Terrain-Daten
- kein Iso-Editor

## Akzeptanzkriterien
- `TerrainTileData` und `TerrainRegistry` existieren
- Alle 64 Tiles der bestehenden Map sind in der Registry registriert
- Grid ↔ Welt-Konvertierung funktioniert korrekt
- Bestehende Gameplay-Logik laeuft ohne Regression

## Git-Schritte nach lokaler Pruefung
- `git status`
- `git add` nur relevante Dateien
- `git commit -m "Add terrain tile data model and registry (TASK_054)"`
- `git push`
- `docs/IMPLEMENTATION_STATUS.md` aktualisieren
