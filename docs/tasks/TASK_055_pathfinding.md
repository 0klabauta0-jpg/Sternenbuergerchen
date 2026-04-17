# TASK 055 – Walkability und einfaches A*-Pathfinding

## Ziel
Units sollen nicht mehr in gerader Linie zum Ziel laufen, sondern ein einfaches Tile-basiertes Pathfinding nutzen, das nicht-begehbare Tiles (Mauern, Cliffs) umgeht.

## Pflicht vor Beginn
- Lies `docs/PROJECT_BRIEF.md`
- Lies `docs/ARCHITECTURE.md`
- Lies `docs/CODEX_RULES.md`
- Lies `docs/IMPLEMENTATION_STATUS.md`
- Pruefe den Git-Status

## Abhaengigkeit
- TASK_054 (Terrain-Datenmodell) muss vorher implementiert sein.

## Ist-Zustand (nach TASK_054)
- `TerrainRegistry` hat Daten fuer alle 64 Tiles (alle walkable, Hoehe 0).
- `SimulationRoot._apply_move_command()` bewegt Units in gerader Linie (`position + direction.normalized() * step`).
- Kein Pathfinding, keine Kollisionserkennung, keine Hindernisumgehung.

## Aufgabe

### 1. Pathfinder
- Neues RefCounted `TerrainPathfinder` unter `res://scripts/terrain/terrain_pathfinder.gd`:
  - Nutzt A*-Algorithmus auf dem Iso-Grid.
  - Eingabe: `find_path(from_grid: Vector2i, to_grid: Vector2i, registry: TerrainRegistry) -> Array[Vector2i]`
  - Beruecksichtigt `walkable`-Flag aus `TerrainTileData`.
  - Nachbar-Tiles: 4-direktional (N, S, E, W im Iso-Grid) oder 8-direktional (mit Diagonalen).
  - Rueckgabe: Array von Grid-Positionen als Pfad, leeres Array wenn kein Pfad existiert.

### 2. Pfad-Kosten
- Basis-Kosten: 1.0 pro Tile.
- Hoehenunterschied: +0.5 pro Hoehenstufe Unterschied (Vorbereitung fuer TASK_058).
- Oberflaechentyp: `"road"` = 0.7, `"sand"` = 1.5, `"ground"` = 1.0 (Vorbereitung fuer TASK_059).

### 3. SimulationRoot: Pathfinding integrieren
- `SimulationRoot` erhaelt eine optionale Referenz auf `TerrainRegistry` und `TerrainPathfinder`.
- Wenn vorhanden: `_apply_move_command()` berechnet beim ersten Aufruf den Pfad und speichert ihn am Command (`"path": Array[Vector2]` in Weltkoordinaten).
- Unit bewegt sich Wegpunkt fuer Wegpunkt statt in gerader Linie.
- Wenn kein Pfad gefunden: Unit bleibt stehen, `push_warning()`.

### 4. Fallback
- Wenn keine `TerrainRegistry` vorhanden: bisheriges Geradlinien-Movement als Fallback.

### 5. Test-Tiles setzen
- In der bestehenden Map 2–3 Tiles als `walkable = false` markieren (z.B. am Rand oder zwischen den Spawns), damit der Pfad sichtbar um sie herumfuehrt.
- Kein visueller Unterschied noetig (nur Daten-Aenderung in `MissionTestSetup`).

## Nicht-Ziele
- keine dynamische Pathfinding-Aktualisierung bei Kartenveraenderungen
- keine lokale Kollisionsvermeidung zwischen Units
- keine Formation
- keine Performance-Optimierung (NavMesh, hierarchisches A* etc.)

## Akzeptanzkriterien
- Units laufen um nicht-begehbare Tiles herum statt hindurch
- Der Pfad wird einmal bei Command-Erstellung berechnet
- Wenn kein Pfad existiert: Unit bleibt stehen
- Ohne TerrainRegistry: bisheriges Verhalten als Fallback
- Bestehende Kampf- und Respawn-Logik funktioniert weiterhin

## Git-Schritte nach lokaler Pruefung
- `git status`
- `git add` nur relevante Dateien
- `git commit -m "Add tile-based A* pathfinding (TASK_055)"`
- `git push`
- `docs/IMPLEMENTATION_STATUS.md` aktualisieren
