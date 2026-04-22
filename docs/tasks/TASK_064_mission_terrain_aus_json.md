# TASK_064 – MissionTestSetup: Terrain aus JSON laden

- Phase: 13 – Map Editor
- Status: implementiert
- Abhaengigkeiten: TASK_060 (Terrain-JSON), TASK_063 (Speichern)

## Ziel
Die Missions-Testszene laedt ihre Terrain-Daten aus der JSON-Datei statt aus Hardcode in MissionTestSetup.

## Anforderungen
1. `MissionTestSetup._setup_terrain_registry()` prueft ob eine JSON-Datei existiert (z.B. `res://maps/test_mission.json`)
2. Wenn ja: Terrain-Daten aus JSON laden und in TerrainRegistry registrieren
3. Wenn nein: bisheriger Hardcode-Fallback bleibt bestehen
4. Farbmodulation der Tile-Sprites wird weiterhin aus den geladenen TerrainTileData-Werten abgeleitet
5. Export-Variable am MissionTestSetup fuer den Map-Pfad: `@export var map_file_path: String = "res://maps/test_mission.json"`
6. Der bisherige Hardcode in `_setup_terrain_registry()` wird durch einen Aufruf an `TerrainMapData.load_from_file()` ersetzt

## Akzeptanzkriterien
- Missions-Testszene laeuft identisch mit JSON-Daten wie vorher mit Hardcode
- Aendern der JSON und Neustart zeigt die neuen Werte
- Ohne JSON-Datei laeuft der alte Fallback weiter

## Nicht in diesem Task
- Editor-Integration in die Mission
- Neue Karten
- Multiplayer-Synchronisation der Kartendaten
