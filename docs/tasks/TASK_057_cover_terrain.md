# TASK 057 – Cover aus Terrain-Tiles

## Ziel
Der `cover_score` einer Unit soll jetzt aus dem Terrain-Tile abgeleitet werden, auf dem sie steht, statt nur aus dem Commander-Befehl.

## Pflicht vor Beginn
- Lies `docs/PROJECT_BRIEF.md`
- Lies `docs/ARCHITECTURE.md`
- Lies `docs/CODEX_RULES.md`
- Lies `docs/IMPLEMENTATION_STATUS.md`
- Pruefe den Git-Status

## Abhaengigkeit
- TASK_054 (Terrain-Datenmodell) muss vorher implementiert sein.

## Ist-Zustand (nach TASK_054+)
- `cover_score` wird aktuell aus dem `UnitCommand` abgeleitet: `defend` gibt +20 Basis-Cover, `flank` gibt +0, `move` gibt +0.
- Phasen-System (TASK_039) addiert Phase-Cover-Bonus dazu.
- `SimulationRoot` nutzt `cover_score` fuer Treffer-Modifikation im Damage-Pfad.
- `TerrainTileData` hat `cover_value: int`, wird aber nicht ausgewertet.

## Aufgabe

### 1. Terrain-Cover in SimulationRoot
- Im `SimulationRoot` Damage-Pfad: wenn `TerrainRegistry` verfuegbar ist, wird der `cover_value` des Tiles unter der Ziel-Unit gelesen.
- Der Terrain-Cover wird zum bestehenden `cover_score` (aus Command + Phase) addiert.
- Formel: `effective_cover = command_cover + phase_cover + terrain_cover`.
- Geclamped auf maximal 80 (damit 100% Blockade nicht moeglich ist).

### 2. Cover-Tiles in der Map setzen
- 3–4 Tiles in der Map erhalten `cover_value > 0`:
  - Tiles nahe dem Objective: `cover_value = 20` (leichte Deckung, z.B. "Felsen").
  - 1–2 Tiles an taktischen Positionen: `cover_value = 35` (mittlere Deckung, z.B. "Mauer-Fragment").
- In `MissionTestSetup`: beim Registrieren der Tiles die `cover_value`-Werte fuer diese spezifischen Grid-Positionen setzen.

### 3. Sichtbares Feedback
- `TestUnit` zeigt im Debug-Label den aktuellen effektiven Cover-Wert: `COV:35`.
- Der Wert aktualisiert sich wenn die Unit sich bewegt und auf einem anderen Tile steht.

### 4. Cover-Abfrage-API
- `TerrainRegistry.get_cover_at_world(world_pos: Vector2) -> int` – Convenience-Methode die Welt → Grid → Cover liefert.
- `TestUnit` kann diese Methode nutzen fuer die Label-Anzeige (sofern eine Registry-Referenz vorhanden ist).

## Nicht-Ziele
- keine Richtungsabhaengigkeit (Cover gilt gleichmaessig aus allen Richtungen)
- keine zerstoerbaren Cover-Objekte
- keine visuelle Darstellung der Cover-Tiles (nur Daten)
- keine Deckungssuche-KI

## Akzeptanzkriterien
- Units auf Cover-Tiles erhalten weniger Schaden (hoehere Cover = weniger Treffer)
- Terrain-Cover kombiniert sich mit Command- und Phase-Cover
- Effektiver Cover ist auf 80 geclamped
- Cover-Wert ist im Debug-Label sichtbar
- Bestehende Cover-Logik aus Commands funktioniert weiterhin
- Ohne TerrainRegistry: bisheriges Verhalten als Fallback

## Git-Schritte nach lokaler Pruefung
- `git status`
- `git add` nur relevante Dateien
- `git commit -m "Derive cover score from terrain tiles (TASK_057)"`
- `git push`
- `docs/IMPLEMENTATION_STATUS.md` aktualisieren
