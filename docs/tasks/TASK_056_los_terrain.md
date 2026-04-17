# TASK 056 – LOS ueber Terrain-Tiles

## Ziel
Die Sichtlinien-Pruefung (`LineOfSightSystem`) soll jetzt Terrain-Daten beruecksichtigen: Mauern und Cliffs blockieren LOS, statt nur die Distanz zu pruefen.

## Pflicht vor Beginn
- Lies `docs/PROJECT_BRIEF.md`
- Lies `docs/ARCHITECTURE.md`
- Lies `docs/CODEX_RULES.md`
- Lies `docs/IMPLEMENTATION_STATUS.md`
- Pruefe den Git-Status

## Abhaengigkeit
- TASK_054 (Terrain-Datenmodell) muss vorher implementiert sein.

## Ist-Zustand (nach TASK_054)
- `LineOfSightSystem` prueft nur Distanz: `source.distance_to(target) <= max_range`.
- `TerrainTileData` hat `blocks_los: bool`, aber der Wert wird nirgends ausgewertet.
- Mauern und Cliffs blockieren keine Sicht.

## Aufgabe

### 1. Tile-basierte LOS-Pruefung
- `LineOfSightSystem` erhaelt eine optionale `TerrainRegistry`-Referenz.
- Neue Methode: `has_line_of_sight_with_terrain(source_pos: Vector2, target_pos: Vector2, registry: TerrainRegistry, max_range: float) -> bool`.
- Algorithmus:
  1. Distanzpruefung wie bisher (early exit bei zu grosser Entfernung).
  2. Bresenham-Linie oder einfaches Tile-Stepping von Source-Grid zu Target-Grid.
  3. Wenn ein Tile auf dem Pfad `blocks_los == true` hat: return false.
  4. Sonst: return true.

### 2. Hoehen-Einfluss auf LOS (Vorbereitung)
- Wenn Source und Target auf unterschiedlichen Hoehenstufen sind:
  - Unit auf hoeherer Stufe kann ueber niedrige Hindernisse (Hoehe < eigene Hoehe) hinwegsehen.
  - Unit auf niedrigerer Stufe wird von Hindernissen auf gleicher oder hoeherer Stufe blockiert.
- Einfache Regel: ein Tile blockiert LOS nur, wenn seine Hoehe >= Source-Hoehe UND >= Target-Hoehe.

### 3. Bestehende Methoden erweitern
- `has_line_of_sight_between_nodes()` und `has_line_of_sight_to_position()` sollen optional eine `TerrainRegistry` akzeptieren.
- Wenn keine Registry uebergeben: bisheriges Distanz-Verhalten als Fallback.

### 4. CombatLoopDriver anpassen
- `MissionCombatLoopDriver` soll die `TerrainRegistry`-Referenz an `LineOfSightSystem`-Aufrufe weitergeben, sofern verfuegbar.

### 5. Test-Tiles setzen
- In der bestehenden Map 1–2 Tiles als `blocks_los = true` markieren (z.B. eine "Mauer" zwischen den Spawns).
- Sichtbar: Units verlieren LOS-Kontakt wenn die Mauer dazwischen liegt.

## Nicht-Ziele
- keine Raycasts oder Physik-basierte LOS
- keine partielle Sicht (Tile blockiert komplett oder gar nicht)
- keine dynamische LOS-Blockade (zerstoerbare Mauern etc.)
- kein Fog-of-War-Rework

## Akzeptanzkriterien
- Tiles mit `blocks_los = true` unterbrechen die Sichtlinie
- Units verlieren Kontakt wenn ein LOS-blockierendes Tile dazwischen liegt
- Hoehenvorteil erlaubt Sicht ueber niedrigere Hindernisse
- Ohne TerrainRegistry: bisheriges Verhalten als Fallback
- Bestehende Kampflogik und FoW funktionieren weiterhin

## Git-Schritte nach lokaler Pruefung
- `git status`
- `git add` nur relevante Dateien
- `git commit -m "Add terrain-based line of sight blocking (TASK_056)"`
- `git push`
- `docs/IMPLEMENTATION_STATUS.md` aktualisieren
