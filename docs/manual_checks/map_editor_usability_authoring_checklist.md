# Map Editor Usability Authoring Checklist

## Ziel
Manueller Sichtcheck fuer den TASK_229-Authoring-Pass. Der Editor soll beim Bauen einer 32x32-Testkarte klare Werkzeuge, knappe Validierung und einen vorbereiteten Multiplayer-Manifeststatus zeigen.

## Ablauf
1. Map Editor oeffnen und eine 32x32-Karte erstellen.
2. Terrain Brush, Hoehen-Tool, Marker-Tool und Patrol-Tool nacheinander aktivieren.
3. Pruefen, dass `Authoring Status` Tool, Brush und Tile kompakt aktualisiert.
4. Huegel mit `H=1`, `H=2`, `Hang`, `Cliff` und `Keine` bauen.
5. Auf einem Huegel Sand, Mauer und Fels platzieren.
6. Marker `spawn_alpha`, `spawn_bravo` und `objective_point` setzen.
7. Fuer `enemy_delta` mindestens zwei Patrol-Waypoints setzen.
8. Scenario-Felder pruefen: Objective, Spawn, Enemy IDs, Tactic, Security, Facing, Waves.
9. Save, Load und Live Test ausloesen.
10. Multiplayer-Manifeststatus pruefen: nach Save soll `manifest ready` erscheinen; bei ungespeicherten Map-Aenderungen soll `map has unsaved changes` erscheinen.

## Erwartung
- Kein langer Hilfetext blockiert den Arbeitsbereich.
- Aktives Werkzeug, Brushgroesse und selektiertes Tile bleiben jederzeit erkennbar.
- Validierungsdiagnosen nennen fehlende Marker, Scenario-Probleme, Patrol-Probleme und Hoehenkanten knapp.
- Save/Load/Live-Test bleiben erreichbar.
- Das Manifest wird nur aus gespeicherten Mapdaten vorbereitet.
