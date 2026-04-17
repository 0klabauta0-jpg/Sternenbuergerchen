# TASK 058 – Hoehenstufen

## Ziel
Die Map unterstuetzt 2–3 Hoehenstufen; Hoehenvorteil gibt einen Accuracy-Bonus, und Cliffs (grosse Hoehenunterschiede) sind nicht begehbar.

## Pflicht vor Beginn
- Lies `docs/PROJECT_BRIEF.md`
- Lies `docs/ARCHITECTURE.md`
- Lies `docs/CODEX_RULES.md`
- Lies `docs/IMPLEMENTATION_STATUS.md`
- Pruefe den Git-Status

## Abhaengigkeit
- TASK_054 (Terrain-Datenmodell) muss vorher implementiert sein.
- TASK_055 (Pathfinding) muss vorher implementiert sein.
- TASK_056 (LOS ueber Terrain) muss vorher implementiert sein.

## Ist-Zustand (nach TASK_056)
- `TerrainTileData` hat `height_level: int` (0–2), alle Tiles sind auf Hoehe 0.
- Pathfinding (TASK_055) beruecksichtigt Hoehenunterschied als Kosten-Modifikator.
- LOS (TASK_056) beruecksichtigt Hoehe bei Blockade-Pruefung.
- Aber: es gibt keine Tiles mit Hoehe > 0 und keinen Accuracy-Bonus bei Hoehenvorteil.

## Aufgabe

### 1. Hoehen-Tiles in der Map
- 5–8 Tiles in der Map erhalten `height_level = 1` (erhoehte Position, z.B. ein Huegel).
- 2–3 Tiles erhalten `height_level = 2` (hohe Position, z.B. eine Klippe).
- In `MissionTestSetup`: beim Registrieren die Height-Werte setzen.

### 2. Walkability bei Hoehe
- Pathfinding-Regel: eine Unit kann nur Tiles betreten, deren Hoehenunterschied zum aktuellen Tile maximal 1 betraegt.
- `height_level 0 → 1`: erlaubt (Anstieg).
- `height_level 0 → 2`: blockiert (Cliff, zu steil).
- `height_level 2 → 1`: erlaubt (Abstieg).
- `height_level 2 → 0`: blockiert (Cliff).
- `TerrainPathfinder` prueft dies zusaetzlich zur `walkable`-Flag.

### 3. Hoehenvorteil im Combat
- Im `SimulationRoot` Damage-Pfad: wenn der Angreifer auf einer hoeheren Stufe steht als das Ziel:
  - `accuracy_bonus = +0.1 * height_difference` (z.B. +0.1 bei 1 Stufe Unterschied).
- Wenn der Angreifer tiefer steht:
  - `accuracy_penalty = -0.05 * height_difference`.
- Bonus/Penalty wird auf die effektive `hit_chance` addiert.

### 4. Sichtbares Feedback
- `TestUnit` zeigt im Debug-Label die aktuelle Hoehe: `H:1`.
- Optional: Tiles mit Hoehe > 0 erhalten einen leichten Farboffset (z.B. `modulate` heller fuer hoehere Tiles) – nur wenn einfach umsetzbar.

### 5. Visuelle Unterscheidung (minimal)
- In der `.tscn`: Tiles mit `height_level > 0` erhalten eine leicht andere `modulate`-Farbe, damit die Hoehenstufen in der Szene erkennbar sind.
- Keine neuen Texturen noetig.

## Nicht-Ziele
- keine echte 3D-Darstellung oder Iso-Stacking
- keine Rampen oder Treppen
- keine dynamischen Hoehenveraenderungen
- keine Hoehen-basierte Schadensphysik (Fallschaden etc.)

## Akzeptanzkriterien
- Units koennen nicht ueber Cliffs (Hoehenunterschied > 1) laufen
- Pfad fuehrt um Cliffs herum
- Hoehenvorteil gibt messbaren Accuracy-Bonus
- Hoehennachteil gibt kleine Accuracy-Penalty
- Hoehe ist im Debug-Label sichtbar
- Map hat erkennbare Hoehenzonen

## Git-Schritte nach lokaler Pruefung
- `git status`
- `git add` nur relevante Dateien
- `git commit -m "Add height levels with cliff blocking and accuracy bonus (TASK_058)"`
- `git push`
- `docs/IMPLEMENTATION_STATUS.md` aktualisieren
