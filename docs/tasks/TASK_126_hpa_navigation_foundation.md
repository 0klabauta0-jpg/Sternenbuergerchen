# TASK_126 - HPA Navigation Foundation

## Ziel
Die Terrain-Navigation soll eine hierarchische Grundlage bekommen, damit grosse Karten nicht dauerhaft ueber einen globalen Tile-A*-Suchraum laufen muessen.

Der Task baut noch keine neue Bewegungssemantik. Er erstellt die Datenbasis fuer HPA* auf dem vorhandenen `TerrainRegistry`-/Tile-Grid.

## Status: IMPLEMENTIERT

## Voraussetzung
- `TASK_125 - Terrain Blocker Debug und Walkability Tests`

## Kontext
- Das Projekt nutzt aktuell kein Godot `NavigationMesh`, keine `NavigationRegion` und keinen `NavigationAgent`.
- Die Gameplay-Wahrheit fuer Navigation liegt im eigenen Terrain-Grid:
  - `TerrainRegistry`
  - `TerrainTileData`
  - `TerrainPathfinder`
  - `SimulationRoot`
- Godot-Doku und Community-Hinweise warnen vor zu haeufigen Pfadqueries, besonders bei vielen Agents oder unerreichbaren Zielen.
- HPA* passt zu unserem Grid: Map in Cluster/Zonen teilen, Uebergaenge vorhalten, lokale A*-Suchen begrenzen.

## Umfang
1. Neuen Runtime-/Tactical-geeigneten Navigationsgraphen einfuehren, z.B. `scripts/terrain/hpa_navigation_graph.gd`.
2. Terrain-Tiles in feste Cluster einteilen, z.B. 8x8 oder 12x12 Grid-Tiles.
3. Pro Cluster erfassen:
   - walkable Tiles
   - lokale begehbare Komponenten
   - Cluster-Bounds
   - Nachbar-Cluster
4. Portale/Entrances an Cluster-Grenzen bestimmen:
   - nur zwischen walkable, kompatiblen Nachbar-Tiles
   - keine Diagonal-Corner-Cuts durch Blocker
   - Hoehen-/Slope-Regeln aus `TerrainPathfinder` respektieren
5. Abstract Graph aus Clustern/Portalen bauen.
6. API fuer lesende Abfragen bereitstellen:
   - Cluster zu Grid-Position
   - Portal-Liste
   - gleiche begehbare Komponente?
   - abstrakte Nachbarschaften
7. Headless-Verifier fuer den Graph-Aufbau.

## Nicht-Ziele
- Noch keine Ersetzung der eigentlichen Movement-Pfadfindung.
- Kein Godot NavigationMesh einfuehren.
- Kein Multithreading.
- Keine dynamischen Blocker / keine live aktualisierten Gebaeude.
- Keine Flow Fields.
- Keine Gruppen-Kollisionsvermeidung.

## Architekturregeln
- Terrain-Wahrheit bleibt in `TerrainRegistry` und Tile-Daten.
- HPA-Graph ist abgeleitete Cache-/Indexstruktur, nicht neue Gameplay-Wahrheit.
- Keine UI-Abhaengigkeiten.
- Keine Vollscans pro Frame; Graph-Aufbau passiert beim Terrain-Load oder explizit nach Terrain-Aenderung.

## Akzeptanzkriterien
- [x] Graph kann aus einer `TerrainRegistry` gebaut werden.
- [x] Cluster-Zuordnung ist deterministisch.
- [x] Portale entstehen nur an wirklich begehbaren Cluster-Grenzen.
- [x] Blockierte Tiles trennen lokale Komponenten korrekt.
- [x] Diagonal-Bewegung bleibt moeglich, aber kein Corner-Cutting durch Blocker.
- [x] Headless-Verifier deckt offene Flaeche, Blocker-Wand, getrennte Bereiche und mehrere Cluster ab.

## Erwartetes Ergebnis
- Eine kleine HPA-Datenstruktur existiert als Grundlage fuer spaetere Pfadqueries.
- Bestehende Bewegung nutzt weiterhin den bisherigen `TerrainPathfinder`.
- Der Task ist rein vorbereitend und risikoarm fuer Live-Movement.

## Ergebnis
- `HPANavigationGraph` baut aus der vorhandenen `TerrainRegistry` deterministische Cluster.
- Pro Cluster werden walkable Tiles, lokale Komponenten und Nachbar-Cluster als abgeleitete Navigationsdaten erfasst.
- Portale entstehen nur zwischen begehbaren Grenz-Tiles und nutzen dieselben Step-Regeln wie `TerrainPathfinder`.
- Die Graph-API stellt Cluster-Snapshots, Portale, Komponenten-Keys, Same-Component-Pruefung und abstrakte Nachbarschaften bereit.
- Live-Movement nutzt weiterhin den bestehenden Pfadfinder; HPA wird erst in TASK_127 in den Move-Pfad integriert.

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_126_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_125_verifier.gd`

## Dateien (voraussichtlich)
- `scripts/terrain/hpa_navigation_graph.gd`
- `scripts/terrain/terrain_pathfinder.gd`
- `scripts/tests/task_126_verifier.gd`

## Risiken
- Zu kleine Cluster erzeugen zu viele Portale und sparen wenig CPU.
- Zu grosse Cluster machen lokale A*-Suchen wieder teuer.
- Der erste Task soll deshalb nur den Graphen bauen und testen, bevor er live genutzt wird.
