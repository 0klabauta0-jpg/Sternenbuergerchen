# TASK_060 – Terrain-Daten als JSON-Datei

- Phase: 13 – Map Editor
- Status: offen
- Abhaengigkeiten: TASK_054 (TerrainTileData), TASK_055 (TerrainRegistry)

## Ziel
Terrain-Konfiguration (walkable, blocks_los, cover_value, height_level, surface_type) aus einer JSON-Datei laden und speichern, statt im Code zu hardcoden.

## Anforderungen
1. JSON-Schema definieren: Array von Tile-Eintraegen mit `grid_position`, `walkable`, `blocks_los`, `cover_value`, `height_level`, `surface_type`
2. `TerrainMapData`-Klasse (RefCounted) zum Laden und Speichern einer JSON-Datei unter `res://maps/`
3. Speichern: alle registrierten Tiles der TerrainRegistry in JSON serialisieren
4. Laden: JSON lesen und TerrainTileData-Objekte erzeugen
5. Karten-Metadaten im JSON: `map_name`, `grid_size` (Vector2i), `tile_size` (half_width, half_height), `grid_origin`
6. Fallback: wenn keine JSON existiert, bleibt der bisherige Hardcode-Pfad in MissionTestSetup bestehen

## Akzeptanzkriterien
- Eine Beispiel-JSON fuer die bestehende 8x8-Testkarte existiert unter `res://maps/test_mission.json`
- `TerrainMapData.load_from_file()` und `TerrainMapData.save_to_file()` funktionieren
- Die bestehende Testkarte laesst sich aus der JSON laden und ergibt dasselbe Spielverhalten

## Nicht in diesem Task
- Editor-UI
- Neue Tiles oder Karten
- Aenderung am Sprite-Layout
