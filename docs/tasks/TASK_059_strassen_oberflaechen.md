# TASK 059 – Strassen und Oberflaechen

## Ziel
Verschiedene Oberflaechentypen (Strasse, Sand, Fels) beeinflussen die Bewegungsgeschwindigkeit und machen die Karte taktisch vielfaeltiger.

## Pflicht vor Beginn
- Lies `docs/PROJECT_BRIEF.md`
- Lies `docs/ARCHITECTURE.md`
- Lies `docs/CODEX_RULES.md`
- Lies `docs/IMPLEMENTATION_STATUS.md`
- Pruefe den Git-Status

## Abhaengigkeit
- TASK_054 (Terrain-Datenmodell) muss vorher implementiert sein.
- TASK_055 (Pathfinding) muss vorher implementiert sein.

## Ist-Zustand (nach TASK_055+)
- `TerrainTileData` hat `surface_type: String` (default: `"ground"`), aber der Wert hat keine Gameplay-Wirkung.
- Pathfinding (TASK_055) hat vorbereitete Kosten-Modifikatoren fuer Oberflaechentypen.
- Alle 64 Tiles sind `"ground"`.

## Aufgabe

### 1. Oberflaechentypen definieren
- Konstanten in `TerrainTileData` oder als eigene Referenz:
  - `"ground"`: Normaler Boden, Speed-Faktor 1.0, Pfad-Kosten 1.0
  - `"road"`: Strasse, Speed-Faktor 1.4, Pfad-Kosten 0.7
  - `"sand"`: Sand, Speed-Faktor 0.6, Pfad-Kosten 1.5
  - `"rock"`: Fels, Speed-Faktor 0.8, Pfad-Kosten 1.3

### 2. Speed-Modifikator im SimulationRoot
- Im `SimulationRoot._apply_move_command()`: wenn `TerrainRegistry` verfuegbar, wird der Oberflaechentyp des aktuellen Tiles gelesen.
- `effective_speed = base_speed * phase_factor * skill_speed * surface_speed_factor`.
- Der Surface-Speed-Faktor wird pro Bewegungsschritt basierend auf dem Tile gelesen, auf dem die Unit gerade steht.

### 3. Pathfinding-Kosten
- `TerrainPathfinder` nutzt die Surface-Kosten (aus TASK_055 bereits vorbereitet):
  - Units bevorzugen Strassen und meiden Sand, wenn der Pfad aehnlich lang ist.

### 4. Surface-Tiles in der Map setzen
- 4–6 Tiles als `"road"` markieren: ein Strassenstreifen diagonal durch die Map.
- 3–4 Tiles als `"sand"` markieren: ein sandiger Bereich nahe einem Spawn.
- 1–2 Tiles als `"rock"` markieren: felsige Zone nahe dem Objective.
- In `MissionTestSetup`: beim Registrieren die `surface_type`-Werte setzen.

### 5. Visuelle Unterscheidung (minimal)
- Tiles mit `surface_type != "ground"` erhalten eine `modulate`-Farbe:
  - `"road"`: leicht grau/dunkel
  - `"sand"`: leicht gelblich
  - `"rock"`: leicht braun
- Keine neuen Texturen noetig – nur Farbmodulation.

### 6. Sichtbares Feedback
- `TestUnit` zeigt im Debug-Label den aktuellen Oberflaechentyp und Speed-Faktor: `GND:1.0` oder `RD:1.4`.

## Nicht-Ziele
- keine neuen Iso-Texturen oder Asset-Varianten
- keine dynamischen Oberflaechenveraenderungen (Wetter, Zerstoerung)
- keine Auswirkung auf Sound oder Sichtbarkeit
- kein Fahrzeug-spezifisches Terrain

## Akzeptanzkriterien
- Units bewegen sich auf Strassen schneller, auf Sand langsamer
- Pathfinding bevorzugt Strassen bei aehnlicher Pfadlaenge
- Oberflaechentyp ist im Debug-Label sichtbar
- Map hat visuell erkennbare Oberflaechenzonen (Farbmodulation)
- Bestehende Bewegungs- und Kampflogik funktioniert weiterhin
- Ohne TerrainRegistry: bisheriges Verhalten als Fallback

## Git-Schritte nach lokaler Pruefung
- `git status`
- `git add` nur relevante Dateien
- `git commit -m "Add surface types with speed modifiers (TASK_059)"`
- `git push`
- `docs/IMPLEMENTATION_STATUS.md` aktualisieren
