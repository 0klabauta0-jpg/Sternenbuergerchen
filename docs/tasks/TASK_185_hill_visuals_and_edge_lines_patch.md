# TASK_185 - Hill Visuals and Edge Lines Patch

## Ziel
Die sichtbare 2.5D- und Legacy-Darstellung soll Huegel, Huegellinien, Klippen, Haenge, Sand und Waende auf Huegeln so zeigen, wie Editor und Spiellogik sie nach TASK_182 bis TASK_184 verwenden.

Die Karte soll nicht nur huebscher wirken, sondern taktisch lesbar bleiben: Spieler muessen erkennen, wo ein Hang begehbar ist, wo eine Klippe hart ist und ob eine Mauer auf dem Huegel oder im Tal steht.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_182 - Terrain Hill Rules Contract
- TASK_183 - Editor Hill Authoring Patch
- TASK_184 - Gameplay Hill Semantics Patch
- bestehende `TerrainMap3DView`
- bestehende `TerrainMapRenderer`
- bestehende `data/terrain_3d_asset_mapping.json`

## Kontext
Der 2.5D-Pfad nutzt bereits Kenney-GLBs fuer Boden, Waende, Klippen, Rampen, Felsen und Units. Gleichzeitig existieren Legacy-2D-Overlays fuer Cliff-/Slope-Texturen. Bei Huegeln mit Sand, Klippenlinien und Objekten auf erhoehtem Terrain muessen beide Pfade dieselbe Datenwahrheit visualisieren.

Besonders kritische Faelle:

- Sand auf H=1/H=2 muss als Sand lesbar bleiben.
- Hang und Klippe muessen visuell unterscheidbar sein.
- Plateau-Innenbereiche duerfen keine falschen Huegellinien erzeugen.
- Eine Mauer auf dem Huegel muss auf der Huegeloberseite stehen, nicht im Sockel oder halb im Rand.
- Fehlende 3D-Mappings duerfen nicht still in falsche PNG-/Box-Fallbacks rutschen.

## Umfang
1. Huegellinien-Regel im Renderer:
   - Linien/Edges entstehen nur dort, wo Nachbarhoehen unterschiedlich sind.
   - Die hoehere Kachel bestimmt `edge_type`, Richtung und Visual.
   - `edge_type = slope` nutzt Hang/Rampen-Visuals.
   - `edge_type = cliff` nutzt Klippen-Visuals.
   - `edge_type = none` unterdrueckt Visuals nur gemaess TASK_182.
   - Plateau-Innenbereiche bleiben sauber.
2. 2.5D-Objektanker:
   - Bodenoberseite nutzt `height_level * height_step`.
   - Wand, Fels, Marker, Selection und Objekt-Fallbacks sitzen auf der Bodenoberseite.
   - `object_height` beeinflusst Objektvolumen/LOS-Visualisierung, aber nicht die Gelaendehoehe.
3. Sand und Surface-Lesbarkeit:
   - Surface-Material/Tint bleibt auch auf H=1/H=2 sichtbar.
   - Klippen-/Hangseiten duerfen die Top-Surface nicht uebermalen.
   - Road/Rock/Ground bleiben auf Hoehen unterscheidbar.
4. Asset-Mapping:
   - `wall_*`, `cliff_*`, `slope_*`, `rock_*` und Boden-Mapping pruefen.
   - Fehlende Mappings erzeugen weiter sichtbare Missing-Asset-Zaehler statt stillen falschen Fallback.
   - Richtung und Y-Offset fuer Klippen, Haenge und Waende auf Huegeln pruefen.
5. Legacy-2D-Kompatibilitaet:
   - Der alte `TerrainMapRenderer` bleibt datenkompatibel.
   - 2D-Fallbacks duerfen keine andere Huegellinienlogik als die 2.5D-View verwenden.
6. Sicht- und Strukturverifier:
   - Kleine Testkarte mit Plateau, Sandhang, Klippe, Mauer-auf-Huegel und Fels-auf-Huegel bauen.
   - Verifier prueft Node-/Snapshot-Struktur, Hoehenanker, Edge-Zaehler und fehlende Mapping-Zaehler.
   - Manueller Godot-Sichtcheck bleibt Pflicht fuer Lesbarkeit.

## Nicht-Ziele
- Keine neuen Pathfinding- oder LOS-Regeln.
- Keine Editor-Datenpatches.
- Keine neuen Projektassets, solange bestehende Kenney-Assets reichen.
- Kein Wechsel auf echte 3D-Gameplay-Physik.
- Kein UI-HUD-Rework.

## Akzeptanzkriterien
- [x] Hang, Klippe und `none` werden in 2.5D und Legacy-2D nach derselben Kantenregel dargestellt.
- [x] Sand auf Huegeln bleibt als Sand erkennbar.
- [x] Plateau-Innenbereiche erzeugen keine falschen Huegellinien.
- [x] Waende und Felsen auf Huegeln sitzen sichtbar auf der Huegeloberseite.
- [x] Selection, Marker und taktische Overlays snappen auf die passende Hoehe.
- [x] Fehlende 3D-Mappings bleiben sichtbar und zaehlbar.
- [x] Ein TASK_185-Verifier prueft die strukturellen Visual-Regressionsfaelle.
- [ ] Ein manueller 2.5D-Sichtcheck bestaetigt Lesbarkeit bei Rotation, Zoom und Pitch.

## Erwartete Dateien
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/terrain/terrain_map_renderer.gd`
- `data/terrain_3d_asset_mapping.json`
- `scripts/tests/task_185_hill_visuals_edge_lines_verifier.gd`
- optional eine kleine visuelle Fixture-Map unter `maps/`
- `docs/tasks/TASK_185_hill_visuals_and_edge_lines_patch.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_185_hill_visuals_edge_lines_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_159_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_160_tactical_playability_verifier.gd`
- [ ] Manueller 2.5D-Sichtcheck mit Rotation, Zoom und Pitch auf der Huegel-Testkarte.
- [x] `git diff --check`

Zusaetzlich ausgefuehrt:
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_170_performance_warning_gate_verifier.gd` (60 passed, 2 failed: Live-Dropship-GLB-/Mission-Result-Spiegelcheck)

## Umsetzung
- `TerrainMap3DView` rendert Hoehenkanten im strikten 3D-Pfad jetzt als GLB-Modelle aus Hoehendifferenzen: `slope` als Hang, `cliff` als Klippe, `none` ohne Kantenvisual.
- Nicht-Ground-Surfaces erhalten im 3D-Pfad eine eigene Top-Surface-Tint-Schicht, damit Sand/Rock/Road auf H=1/H=2 sichtbar bleiben, ohne Ground-Model-Materialien zu ueberschreiben.
- Marker, Patrol-/Waypoint-Linien, Contact-/Objective-/Dropship-Overlays, Unit-Proxies und Missing-Asset-Marker nutzen jetzt die Tile-Oberseite als visuellen Anker.
- `TerrainMapRenderer` nutzt dieselbe Hoehenkantenregel ohne Objekt-Tile-Ausnahmen und erkennt Objektplatzierung ueber `object_type_id`, damit Wand/Fels auf Huegeln im Legacy-Pfad sichtbar bleiben.
- `scripts/tests/task_185_hill_visuals_edge_lines_verifier.gd` prueft eine kleine Plateau-/Sandhang-/Klippen-/Wand-/Fels-Fixture fuer 3D und Legacy-2D.

## Risiken
- Optische Korrekturen duerfen nicht die Terrain-Daten oder Gameplay-Wahrheit veraendern.
- Ein visueller Fix fuer 2.5D darf den Legacy-2D-Fallback nicht widerspruechlich machen.
- Zu viele dekorative Linien koennen taktische Lesbarkeit verschlechtern. Edge-Visuals muessen aus Datenregeln kommen, nicht aus Deko.

## Naechster Schritt
Manuellen 2.5D-Sichtcheck mit Rotation, Zoom und Pitch auf einer kleinen Huegelkarte ausfuehren. Danach koennen TASK_186ff. wieder auf Mission-Map-Verhalten gehen.
