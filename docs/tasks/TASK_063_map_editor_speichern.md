# TASK_063 – Map-Editor: Speichern und Laden

- Phase: 13 – Map Editor
- Status: offen
- Abhaengigkeiten: TASK_062 (Property-Editing)

## Ziel
Der Editor kann Karten speichern und laden, sodass editierte Terrain-Daten persistent sind.

## Anforderungen
1. "Speichern"-Button: schreibt den aktuellen Zustand ueber `TerrainMapData.save_to_file()` in die JSON
2. "Laden"-Button: oeffnet einen einfachen Dateiauswahl-Dialog (oder feste Pfade unter `res://maps/`) und laedt die Karte neu
3. "Neue Karte"-Button: erzeugt eine leere 8x8-Karte mit Default-Werten (alle walkable, ground, height 0, cover 0)
4. Ungespeicherte Aenderungen werden durch einen visuellen Hinweis markiert (z.B. Sternchen im Titel)
5. Beim Laden einer neuen Karte: Warnung wenn ungespeicherte Aenderungen vorhanden

## Akzeptanzkriterien
- Karte speichern und neu laden ergibt identische Tile-Eigenschaften
- Neue leere Karte erstellen funktioniert
- Ungespeicherte Aenderungen sind visuell erkennbar

## Nicht in diesem Task
- Variable Kartengroessen (bleibt 8x8)
- Sprite-Auswahl / Tile-Grafik-Editor
- Export fuer andere Formate
