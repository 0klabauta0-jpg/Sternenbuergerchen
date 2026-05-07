# TASK_182 - Terrain Hill Rules Contract

## Ziel
Huegel, Hoehenkanten, Oberflaechen und Objekte bekommen einen gemeinsamen Regelvertrag, bevor Editor, Spiellogik und 2.5D-Renderer weiter gepatcht werden.

Der Task ist zuerst eine Bestandsaufnahme und Vertragsklaerung. Er soll die bestehenden Regeln aus Code und Doku zusammenziehen und die offenen Widersprueche sichtbar entscheiden.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_054 - Terrain-Tile-Datenmodell und Registry
- TASK_055 - Walkability und einfaches A*-Pathfinding
- TASK_056 - LOS ueber Terrain-Tiles
- TASK_057 - Cover ueber Terrain
- TASK_058 - Hoehenstufen
- TASK_059 - Oberflaechentypen
- TASK_082 - Gemeinsamer Terrain-Renderer fuer Editor und Mission
- TASK_159 - 2.5D Editor and Mission Primary View

## Kontext
Die Hoehenlogik existiert bereits, ist aber auf mehrere Stellen verteilt:

- `TerrainTileData` speichert `height_level`, `object_height`, `surface_type`, `walkable`, `blocks_los`, `cover_value` und `edge_type`.
- `TerrainPathfinder` nutzt Hoehen, Oberflaechenkosten und `edge_type` fuer Schrittregeln.
- `LineOfSightSystem` und Combat verwenden Hoehen fuer Sicht- und Accuracy-Regeln.
- `TerrainMapRenderer` und `TerrainMap3DView` leiten Huegellinien, Klippen, Haenge und Objektpositionen aus denselben Tile-Daten ab.
- Der Map-Editor schreibt Hoehe und Kante ueber das Hoehenwerkzeug, Objekt-/Wandplatzierung kommt aber aus anderen Authoring-Pfaden.

Gerade fuer "Mauer auf Huegel", Sand auf Hang, Klippe vs. Hang und Huegellinien muss ein einzelner Vertrag gelten. Sonst sieht die Karte richtig aus, waehrend Pathfinding, LOS oder Save/Load etwas anderes glauben.

## Zielregeln, die zu klaeren sind
Der Task soll die folgenden Regeln entweder bestaetigen oder begruendet abweichend dokumentieren:

1. `height_level` ist reine Gelaendehoehe von `0` bis `2`.
2. `object_height` wird auf die Gelaendehoehe addiert und beschreibt Hoehe von Mauern, Felsen oder anderen Blockern.
3. Ein LOS-Blocker auf einem Huegel hat effektive Blockerhoehe `height_level + object_height`.
4. Eine Mauer auf einem Huegel veraendert nicht die Gelaendehoehe, sitzt visuell aber auf der Huegeloberseite.
5. `surface_type` gilt auf jeder Hoehe. Sand bleibt langsam, Road bleibt guenstig, Rock bleibt teurer, egal ob das Tile flach oder erhoeht ist.
6. `edge_type = slope` ist die begehbare Hang-/Rampen-Kante. Sie erlaubt Hoehentransitionen, solange Ziel-Tile und Schrittregel begehbar sind, und kostet zusaetzlich.
7. `edge_type = cliff` ist die harte Klippenkante. Wenn die bisherige `height_diff <= 1`-Ausnahme behalten werden soll, muss der Task explizit dokumentieren, warum Klippen spielerisch doch begehbar bleiben.
8. `edge_type = none` bedeutet keine sichtbare Hoehenkante. Fuer echte Hoehendifferenzen muss geklaert werden, ob das nur fuer Plateau-Innenbereiche erlaubt ist oder als eigener Gameplay-Fall gilt.
9. Huegellinien entstehen aus Nachbar-Tiles mit unterschiedlicher Hoehe. Die hoehere Kachel bestimmt Kantenart und Richtung.
10. Diagonale Bewegung darf harte Klippen- oder Mauer-Ecken nicht einfach umgehen, wenn die betroffenen orthogonalen Schritte blockiert waeren.

## Umfang
1. Doku- und Code-Audit:
   - `docs/tasks/TASK_054_terrain_datenmodell.md`
   - `docs/tasks/TASK_055_pathfinding.md`
   - `docs/tasks/TASK_056_los_terrain.md`
   - `docs/tasks/TASK_057_cover_terrain.md`
   - `docs/tasks/TASK_058_hoehenstufen.md`
   - `docs/tasks/TASK_059_strassen_oberflaechen.md`
   - `docs/tasks/TASK_082_gemeinsamer_terrain_renderer_editor_und_mission.md`
   - `docs/tasks/TASK_159_2_5d_editor_and_mission_primary_view.md`
   - `scripts/terrain/terrain_tile_data.gd`
   - `scripts/terrain/terrain_registry.gd`
   - `scripts/terrain/terrain_pathfinder.gd`
   - `scripts/terrain/hpa_pathfinder.gd`
   - `scripts/terrain/hpa_navigation_graph.gd`
   - `scripts/terrain/terrain_map_renderer.gd`
   - `scripts/terrain/terrain_map_3d_view.gd`
   - `scripts/editor/map_editor_height_tool.gd`
   - `data/terrain_3d_asset_mapping.json`
2. Neues Regel-Dokument:
   - `docs/dev/terrain_height_hill_rules.md`
   - Enthalten sein muessen Datenfelder, Bewegung, LOS, Cover, Combat, Visuals, Editor-Authoring, Save/Load und Verifier-Strategie.
3. Regelmatrix:
   - Flach zu flach.
   - Flach zu Hang.
   - Flach zu Klippe.
   - Hang mit Sand.
   - Klippe mit Sand.
   - Plateau-Innenbereich.
   - Wand auf flach.
   - Wand auf Huegel.
   - Fels auf Huegel.
4. Bestandskonflikte benennen:
   - Abweichungen zwischen Doku und aktuellem Code nicht still patchen.
   - Pro Konflikt eine klare Folgeaufgabe oder bewusste Zielregel festhalten.
5. Verifier:
   - Ein kleiner Contract-Verifier soll pruefen, dass die zentralen Konstanten/Felder existieren und das neue Regel-Dokument die Pflichtabschnitte enthaelt.
   - Der Verifier ist keine Gameplay-Regression; Gameplay-Faelle folgen in TASK_184.

## Nicht-Ziele
- Keine grossen Pathfinding- oder LOS-Umbauten in diesem Task.
- Keine Renderer-Politur.
- Keine neuen Terrain-Assets.
- Kein neues Balancing jenseits der dokumentierten Zielregeln.
- Keine UI-Wahrheit im Editor oder in der 2.5D-View.

## Akzeptanzkriterien
- [x] `docs/dev/terrain_height_hill_rules.md` beschreibt die gemeinsame Huegelregel fuer Editor, Runtime und Renderer.
- [x] Klippe, Hang, Keine, Sand, Road, Rock, Wand auf Huegel, Fels auf Huegel und Plateau-Innenbereiche sind eindeutig beschrieben.
- [x] Der Vertrag sagt explizit, ob Klippen begehbar oder harte Blocker sind.
- [x] Der Vertrag sagt explizit, wie `height_level + object_height` fuer LOS und sichtbare Objektpositionen verwendet wird.
- [x] Der Vertrag sagt explizit, wie Huegellinien aus Nachbarhoehen und `edge_type` entstehen.
- [x] Bestehende Widersprueche zwischen Doku und Code sind als Folgepatches markiert.
- [x] Ein TASK_182-Verifier prueft die Existenz der Pflichtfelder, Konstanten und Dokumentabschnitte.

## Erwartete Dateien
- `docs/dev/terrain_height_hill_rules.md`
- `scripts/tests/task_182_terrain_hill_rules_contract_verifier.gd`
- `docs/tasks/TASK_182_terrain_hill_rules_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_182_terrain_hill_rules_contract_verifier.gd`
- [x] `git diff --check`

## Risiken
- Wenn dieser Task zu viel implementiert, werden die Folgepatches unscharf. Der Wert liegt hier in der gemeinsamen Entscheidung, nicht in schnellen Code-Aenderungen.
- Wenn Klippe/Hang/None nicht sauber entschieden werden, entstehen spaeter wieder Unterschiede zwischen sichtbarer Karte und Spiellogik.

## Naechster Schritt
Nach TASK_182 koennen Editor-Authoring, Gameplay-Semantik und 2.5D-Darstellung in getrennten Patchtasks umgesetzt werden.

## Ergebnis
- `docs/dev/terrain_height_hill_rules.md` definiert `cliff` als harte Hoehenblockade, `slope` als begehbare Transition und `none` als Same-Height-/Plateau-Innenfall.
- Der Vertrag beschreibt `height_level + object_height` fuer LOS und sichtbare Objektpositionen sowie die Ableitung von Huegellinien aus Nachbarhoehen und `edge_type`.
- Bestehende Abweichungen sind bewusst als Folgepatches markiert: TASK_183 fuer Editor-Authoring, TASK_184 fuer Gameplay-Semantik und TASK_185 fuer Visuals.
- `scripts/tests/task_182_terrain_hill_rules_contract_verifier.gd` prueft Dokumentabschnitte, Pflichtfaelle, Terrain-Konstanten, Clamp-Grenzen, Surface-Werte und zentrale Codeanker.
