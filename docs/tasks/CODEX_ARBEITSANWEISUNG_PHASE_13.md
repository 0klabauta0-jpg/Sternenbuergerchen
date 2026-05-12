# CODEX-ARBEITSANWEISUNG – Phase 13: Map Editor (TASK_060 bis TASK_064)

## Pflichtlektuere vor Arbeitsbeginn

Lies folgende Dateien vollstaendig, bevor du mit der Arbeit beginnst:

- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/DECISIONS.md`
- `docs/GLOSSARY.md`

Fuer jeden Task zusaetzlich die jeweilige Task-Datei:
- `docs/tasks/TASK_060_terrain_json.md`
- `docs/tasks/TASK_061_map_editor_szene.md`
- `docs/tasks/TASK_062_map_editor_properties.md`
- `docs/tasks/TASK_063_map_editor_speichern.md`
- `docs/tasks/TASK_064_mission_terrain_aus_json.md`

Lies ausserdem die bestehenden Terrain-Dateien, die die Grundlage bilden:
- `scripts/terrain/terrain_tile_data.gd` (TerrainTileData – RefCounted, hat bereits `from_dict()` und `to_dict()`)
- `scripts/terrain/terrain_registry.gd` (TerrainRegistry – Node, Tile-Lookup, Iso-Grid-Konfiguration)
- `scripts/terrain/terrain_pathfinder.gd` (TerrainPathfinder – A* auf Iso-Grid)
- `scripts/tests/mission_test_setup.gd` (MissionTestSetup – aktuelle Hardcode-Terrain-Einrichtung in `_setup_terrain_registry()`)

---

## Projekt und Branch

- Engine: Godot 4.6.2
- Lokales Projekt: `C:\dev\SternenBuergerchen`
- Arbeitsbasis: `batch/multiplayer-prototype-v1`

### Branch-Strategie

```bash
git checkout batch/multiplayer-prototype-v1
git pull
git checkout -b batch/map-editor-phase13
```

Alle 5 Tasks auf diesem einen Branch bearbeiten.
Nach jedem Task einen eigenen Commit machen.
Am Ende pushen.

---

## Reihenfolge und Abhaengigkeiten

Die Tasks muessen in dieser Reihenfolge bearbeitet werden:

```
TASK_060 (JSON-Format)
    |
    v
TASK_061 (Editor-Szene: Anzeige + Auswahl)
    |
    v
TASK_062 (Property-Editing)
    |
    v
TASK_063 (Speichern/Laden)
    |
    v
TASK_064 (MissionTestSetup auf JSON umstellen)
```

---

## TASK_060 – Terrain-Daten als JSON-Datei

### Was zu tun ist

1. Erstelle `scripts/terrain/terrain_map_data.gd` als `class_name TerrainMapData extends RefCounted`
2. JSON-Schema fuer Terrain-Karten:
   ```json
   {
     "map_name": "test_mission",
     "grid_size": { "x": 8, "y": 8 },
     "tile_size": { "half_width": 64, "half_height": 32 },
     "grid_origin": { "x": 512, "y": 64 },
     "tiles": [
       {
         "grid_position": { "x": 0, "y": 0 },
         "walkable": true,
         "blocks_los": false,
         "cover_value": 0,
         "height_level": 0,
         "surface_type": "ground"
       }
     ]
   }
   ```
3. Implementiere:
   - `static func load_from_file(path: String) -> TerrainMapData` – liest JSON, erzeugt TerrainTileData-Objekte
   - `func save_to_file(path: String) -> Error` – serialisiert alle Tiles in JSON
   - `func get_tiles() -> Array` – gibt die geladenen TerrainTileData zurueck
   - `func get_map_name() -> String`
   - `func get_grid_size() -> Vector2i`
   - `func get_tile_size() -> Dictionary` – { half_width, half_height }
   - `func get_grid_origin() -> Vector2`
4. Nutze die bereits bestehenden `TerrainTileData.from_dict()` und `TerrainTileData.to_dict()` Methoden
5. Erstelle `res://maps/test_mission.json` mit den Daten der bestehenden 8x8-Testkarte
   - Lies dafuer die Hardcode-Werte aus `mission_test_setup.gd` → `_setup_terrain_registry()` ab
   - Die meisten Tiles sind Default (walkable, ground, height 0, cover 0); einige haben besondere Werte

### Akzeptanzkriterien
- `TerrainMapData.load_from_file("res://maps/test_mission.json")` gibt valide Daten zurueck
- `save_to_file()` erzeugt identische JSON nach erneutem Laden
- Keine Aenderung an bestehenden Dateien ausser ggf. `.uid`-Dateien

### Commit
```
git add scripts/terrain/terrain_map_data.gd scripts/terrain/terrain_map_data.gd.uid maps/test_mission.json
git commit -m "TASK_060: TerrainMapData JSON load/save + test_mission.json"
```

---

## TASK_061 – Map-Editor-Szene: Tile-Auswahl und Anzeige

### Was zu tun ist

1. Erstelle Szene `scenes/editor/map_editor.tscn` mit Hauptskript `scripts/editor/map_editor.gd`
2. Szenen-Struktur:
   ```
   MapEditor (Node2D)
   ├── Camera2D (Zoom + Pan)
   ├── TileContainer (Node2D) — hier werden die Tile-Sprites erzeugt
   ├── UI (CanvasLayer)
   │   └── PropertyPanel (PanelContainer, rechte Seite)
   │       └── VBoxContainer
   │           ├── Label "Tile: (x, y)"
   │           ├── Label "walkable: ..."
   │           ├── Label "blocks_los: ..."
   │           ├── Label "cover_value: ..."
   │           ├── Label "height_level: ..."
   │           └── Label "surface_type: ..."
   ```
3. Beim Start: lade `test_mission.json` ueber `TerrainMapData.load_from_file()`
4. Erzeuge fuer jedes Tile ein Sprite2D im Iso-Layout (gleiche Berechnung wie `MissionTestSetup`)
5. Farbmodulation der Tiles genauso wie in `MissionTestSetup._apply_tile_modulation()` – uebernimm die bestehende Logik
6. Klick-Erkennung: `_input()` oder `_unhandled_input()` mit Mausposition → `world_to_grid()` → Tile identifizieren
7. Ausgewaehltes Tile visuell hervorheben (z.B. Modulate auf Weiss oder Outline-Sprite)
8. Property-Panel zeigt die Eigenschaften des ausgewaehlten Tiles als Labels (nur Anzeige, kein Editing)
9. Kamera:
   - Zoom: Mausrad, Bereich z.B. 0.5 bis 3.0
   - Pan: Mittlere Maustaste oder Rechtsklick + Drag

### Akzeptanzkriterien
- Szene laesst sich in Godot starten (F5 oder direkt)
- 8x8-Karte wird korrekt als Iso-Grid angezeigt
- Klick auf Tile markiert es und zeigt Eigenschaften im Panel
- Kamera Zoom und Pan funktionieren

### Nicht aendern
- Keine Aenderung an `MissionTestSetup`, `SimulationRoot` oder anderen bestehenden Dateien
- Die Editor-Szene ist komplett eigenstaendig

### Commit
```
git add scenes/editor/ scripts/editor/
git commit -m "TASK_061: Map-Editor-Szene mit Tile-Anzeige und Auswahl"
```

---

## TASK_062 – Map-Editor: Tile-Properties bearbeiten

### Was zu tun ist

1. Ersetze die Labels im PropertyPanel durch editierbare Controls:
   - `walkable` → CheckBox
   - `blocks_los` → CheckBox
   - `cover_value` → SpinBox (min 0, max 100, step 1)
   - `height_level` → SpinBox (min 0, max 3, step 1)
   - `surface_type` → OptionButton mit Eintraegen: ground, road, sand, rock
2. Bei Wertaenderung:
   - Aktualisiere das `TerrainTileData`-Objekt in der lokalen `TerrainMapData`
   - Aktualisiere die Farbmodulation des betroffenen Tile-Sprites sofort
3. Pinsel-Modus:
   - Toggle-Button "Pinsel" im UI
   - Wenn aktiv: der aktuell im Panel eingestellte Wert wird auf jedes angeklickte Tile angewandt
   - Mindestens fuer `surface_type` und `walkable`
4. Einfacher Ein-Schritt-Undo:
   - Speichere vor jeder Aenderung den vorherigen Zustand des Tiles
   - Strg+Z oder Undo-Button stellt den letzten Zustand wieder her

### Akzeptanzkriterien
- Jede Eigenschaft laesst sich aendern und ist sofort visuell sichtbar
- Pinsel-Modus funktioniert fuer `surface_type` und `walkable`
- Undo stellt die letzte Aenderung wieder her

### Commit
```
git add scripts/editor/ scenes/editor/
git commit -m "TASK_062: Property-Editing, Pinsel-Modus und Undo im Map-Editor"
```

---

## TASK_063 – Map-Editor: Speichern und Laden

### Was zu tun ist

1. Toolbar im Editor-UI mit drei Buttons:
   - **Speichern** → ruft `TerrainMapData.save_to_file()` auf den aktuellen Pfad auf
   - **Laden** → zeigt eine einfache Auswahl der JSON-Dateien unter `res://maps/` (z.B. ItemList oder FileDialog eingeschraenkt auf `res://maps/*.json`)
   - **Neue Karte** → erzeugt eine leere 8x8-Karte mit Defaults (walkable=true, ground, height=0, cover=0, blocks_los=false)
2. Dirty-State:
   - Setze ein `_dirty`-Flag bei jeder Tile-Aenderung
   - Zeige visuellen Hinweis (z.B. `*` im Fenstertitel oder Label) wenn ungespeichert
   - Beim Laden oder Neue-Karte: Warnung wenn `_dirty == true` (ConfirmationDialog)
3. Nach Speichern: `_dirty = false`, visueller Hinweis entfernen

### Akzeptanzkriterien
- Speichern und erneutes Laden ergibt identische Tile-Daten
- Neue leere Karte funktioniert und kann gespeichert werden
- Ungespeicherte Aenderungen werden visuell angezeigt
- Warnung vor Datenverlust beim Laden/Neu funktioniert

### Commit
```
git add scripts/editor/ scenes/editor/ maps/
git commit -m "TASK_063: Speichern, Laden und Neue-Karte im Map-Editor"
```

---

## TASK_064 – MissionTestSetup: Terrain aus JSON laden

### Was zu tun ist

1. Oeffne `scripts/tests/mission_test_setup.gd`
2. Fuege Export-Variable hinzu:
   ```gdscript
   @export var map_file_path: String = "res://maps/test_mission.json"
   ```
3. Aendere `_setup_terrain_registry()`:
   - Pruefe ob `FileAccess.file_exists(map_file_path)`
   - Wenn ja: lade ueber `TerrainMapData.load_from_file(map_file_path)` und registriere alle Tiles in der TerrainRegistry
   - Wenn nein: bisheriger Hardcode bleibt als Fallback bestehen (in einer eigenen Methode wie `_setup_terrain_hardcoded()`)
4. Die Farbmodulation der Tile-Sprites muss weiterhin funktionieren – aus den geladenen TerrainTileData-Werten
5. Iso-Grid-Konfiguration (`configure_iso_grid()`) aus den JSON-Metadaten uebernehmen

### Akzeptanzkriterien
- Missions-Testszene laeuft identisch mit JSON wie vorher mit Hardcode
- Aendern eines Wertes in der JSON und Neustart der Szene zeigt die Aenderung
- Loeschen der JSON-Datei → Fallback auf Hardcode, Szene laeuft weiter
- Kein Verhaltensunterschied zum bisherigen Stand

### Commit
```
git add scripts/tests/mission_test_setup.gd
git commit -m "TASK_064: MissionTestSetup laedt Terrain aus JSON mit Hardcode-Fallback"
```

---

## Nach allen Tasks

### IMPLEMENTATION_STATUS.md aktualisieren
Ergaenze in `docs/IMPLEMENTATION_STATUS.md` die Eintraege fuer TASK_060 bis TASK_064 im gleichen Format wie die bestehenden Eintraege. Markiere sie als implementiert.

### Abschluss-Commit und Push
```bash
git add docs/IMPLEMENTATION_STATUS.md
git commit -m "docs: IMPLEMENTATION_STATUS fuer Phase 13 aktualisiert"
git push origin batch/map-editor-phase13
```

### Lieferformat pro Task
Fuer jeden abgeschlossenen Task dokumentiere kurz:
1. Aenderung
2. Betroffene Dateien
3. Risiken / offene Punkte
4. Git-Status / Commit

---

## Verbindliche Regeln (aus AGENTS.md und CODEX_RULES.md)

- **Nur betroffene Dateien aendern** – keine Refactors, keine "Verbesserungen" ausserhalb des Tasks
- **Bestehende Patterns wiederverwenden** – die Farbmodulation, Iso-Grid-Berechnung und TerrainTileData-API existieren bereits
- **UI ist Anzeige, nicht Wahrheit** – der Map-Editor aendert TerrainMapData, nicht direkt die Sprites
- **Keine neuen Systeme einfuehren** wenn bestehende Strukturen reichen
- **Keine per-frame Vollscans** – die Editor-Szene ist kein Spiel-Loop
- **Keine stillen Scope-Erweiterungen** – wenn ein Task "Nicht in diesem Task" auflistet, gilt das
- **Kleine, kontrollierte Aenderungen** – lieber einen Task sauber als alle auf einmal
- **Godot 4.6.2 GDScript** – keine C#, keine GDExtension, keine Plugins
