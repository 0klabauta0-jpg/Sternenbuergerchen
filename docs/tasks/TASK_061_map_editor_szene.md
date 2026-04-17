# TASK_061 – Map-Editor-Szene: Tile-Auswahl und Anzeige

- Phase: 13 – Map Editor
- Status: offen
- Abhaengigkeiten: TASK_060 (Terrain-JSON)

## Ziel
Eine Runtime-Szene, in der die geladene Karte sichtbar ist und einzelne Tiles per Klick ausgewaehlt werden koennen.

## Anforderungen
1. Neue Szene `res://scenes/editor/map_editor.tscn` als eigenstaendige Szene
2. Karte aus `TerrainMapData` (JSON) laden und als Iso-Grid anzeigen
3. Tile-Sprites mit Farbmodulation wie in MissionTestSetup (walkable, height, surface, cover, LOS)
4. Klick auf ein Tile markiert es visuell (Highlight/Rahmen)
5. Ausgewaehltes Tile zeigt seine Eigenschaften in einem seitlichen Panel (Labels)
6. Kamera-Steuerung: Zoom und Pan fuer die Kartenansicht
7. Kein Editieren in diesem Task – nur Anzeige und Auswahl

## Akzeptanzkriterien
- Editor-Szene laesst sich starten und zeigt die 8x8-Testkarte korrekt an
- Tiles sind anklickbar und zeigen ihre Eigenschaften
- Kamera laesst sich bewegen und zoomen
- Farbmodulation entspricht der bestehenden Logik

## Nicht in diesem Task
- Property-Editing
- Speichern
- Neue Tiles oder Kartengroessen
