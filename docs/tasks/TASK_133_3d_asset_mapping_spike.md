# TASK_133 - 3D Asset Mapping Spike

## Ziel
Pruefen, ob die vorhandenen Kenney-Space-Kit-3D-Assets als alternative Darstellungsschicht fuer die bestehende 2D-Iso-Simulation taugen, ohne Navigation, Combat, Area-Orders oder `SimulationRoot` auf 3D umzubauen.

## Status: IMPLEMENTIERT

## Asset-Quelle
- Lokaler Quellordner: `C:\Users\bjoer\Pictures\Sternenbürger\3d\Space Kit`
- Der Ordner enthaelt je 153 Modelle in mehreren Formaten, darunter `.glb`, `.fbx`, `.obj`, `.dae`, `.stl`.
- Fuer Godot V1 bevorzugt: `Models/GLTF format/*.glb`
- Assets werden nicht blind importiert; nur eine kleine kuratierte Spike-Auswahl wird ins Projekt kopiert.

## Kontext
- Die aktuelle Runtime ist bewusst 2D-Iso-gridbasiert: `Vector2i`, `Vector2`, `TerrainRegistry`, HPA/A*, Area-Orders und Combat lesen Tile-Daten.
- TASK_132 hat bereits einen sauberen Objekt-Layer (`object_type_id`) fuer 2D-Assets eingefuehrt.
- Die 3D-Assets tragen groesstenteils dieselben Familiennamen wie die 2D-Sprites, z. B. `barrel.glb`, `barrels.glb`, `machine_generator.glb`, `hangar_smallB.glb`, `craft_speederB.glb`, `crater.glb`, `corridor_wall.glb`.
- Der Spike soll beweisen, ob wir dieselben Katalog-IDs visuell in 3D rendern koennen, waehrend die Gameplay-Wahrheit unveraendert im bestehenden 2D-Datenmodell bleibt.

## Grundsatz
Keine Full-3D-Migration in diesem Task.

Die Simulation bleibt:
- 2D-Grid
- bestehende `TerrainMapData`
- bestehende `TerrainRegistry`
- bestehende HPA-/Pathfinder-Logik
- bestehende Combat-/LOS-/Cover-Felder

Nur die Darstellung bekommt einen parallelen 3D-Prototyp.

## Umfang
1. 3D-Asset-Audit:
   - GLB-Dateien aus dem lokalen Quellordner finden und nach Familiennamen gruppieren.
   - Pruefen, welche TASK_132-Typen direkt auf GLB-Familien gemappt werden koennen.
   - Ergebnis als kleine Summary im Verifier ausgeben.
2. Kuratierte V1-Auswahl kopieren:
   - Maximal 10-15 GLB-Dateien ins Projekt uebernehmen.
   - Zielpfad z. B. `res://Assets/kenney_space-kit/3d/`.
   - Startauswahl bevorzugt: `barrel`, `barrels`, `machine_generator`, `satelliteDish_large`, `structure_closed`, `hangar_smallB`, `platform_center`, `pipe_straight`, `rail`, `crater`, `craft_speederB`, plus falls passend `terrain`/`corridor_wall`.
3. Katalog-Mapping vorbereiten:
   - `terrain_tile_catalog.json` oder ein separater kleiner 3D-Mapping-Katalog erhaelt fuer die kuratierte Auswahl einen `model_path`/`scene_path`.
   - 2D-`texture_path` bleibt unveraendert.
   - Objekt-Layer-Typen (`object_type_id`) sollen dasselbe Mapping nutzen koennen.
4. `TerrainMap3DRenderer` als Spike:
   - Laedt dieselbe `TerrainMapData`.
   - Uebersetzt `Vector2i`/Gridpositionen deterministisch nach `Vector3`.
   - Rendert Boden als einfache 3D-Tiles oder Platzhalter-Prismen.
   - Rendert Objekt-Layer als GLB-Instanzen ueber den jeweiligen Tiles.
   - Richtungen koennen in V1 ueber Rotation gemappt werden; wenn ein GLB keine Richtungssuffixe hat, wird die Richtung aus dem Type-ID-Suffix (`_ne`, `_nw`, `_se`, `_sw`) rotiert.
5. 3D-Testszene:
   - Neue isolierte Szene unter `res://scenes/tests/`, z. B. `mission_map_3d_render_spike.tscn`.
   - Laedt `maps/test_mission_32x32_slots8.json`.
   - Enthält feste isometrische 3D-Kamera und Licht.
   - Kein Gameplay-Input, keine Missionsausfuehrung.
6. Verifier:
   - Prueft, dass die erwarteten GLB-Dateien existieren.
   - Prueft, dass mindestens ein Boden- und mehrere Objekt-Mappings instanziierbar sind.
   - Prueft, dass die 3D-Testszene headless laedt.
   - Prueft, dass 2D-Renderer-/TASK_132-Verhalten nicht gebrochen wird.

## Nicht-Ziele
- Keine Umstellung von `SimulationRoot` auf `Vector3`.
- Keine NavMesh-/NavigationServer-3D-Migration.
- Keine 3D-LOS- oder Physik-Raycast-Combat-Logik.
- Keine komplette Asset-Massenuebernahme.
- Keine neue Editor-Bedienlogik fuer 3D-Platzierung.
- Keine finalen Materialien, Schatten-Optimierungen oder LOD-Systeme.

## Architekturregeln
- 3D ist in diesem Task eine alternative Darstellungsschicht, nicht die neue Gameplay-Wahrheit.
- `TerrainMapData` bleibt die gemeinsame Quelle.
- Katalog-/Mapping-Daten muessen optional sein; fehlt ein 3D-Modell, bleibt der 2D-Pfad unveraendert.
- Keine SceneTree-Vollscans im Runtime-Pfad.
- Der Spike darf unter `scripts/tests`/`scenes/tests` isoliert bleiben, solange er keine Live-Mission verdrahtet.

## Akzeptanzkriterien
- [x] Der lokale 3D-Asset-Ordner wurde auditiert und die GLB-Verfuegbarkeit dokumentiert.
- [x] Mindestens 8 kuratierte 3D-Modelle sind im Projekt unter einem klaren Asset-Pfad verfuegbar.
- [x] Mindestens 6 bestehende TASK_132-Asset-Typen haben ein 3D-Mapping.
- [x] Eine 3D-Testszene rendert dieselbe Map-Datenbasis ohne Gameplay-Umbau.
- [x] Boden und Objekt-Layer sind auch in 3D getrennt: `type_id` fuer Boden, `object_type_id` fuer Objekt.
- [x] Der Verifier laedt die 3D-Testszene headless und prueft Modellpfade/Instanzen.
- [x] TASK_132-Verifier und Wall-Mapping-Verifier bleiben gruen.

## Erwartetes Ergebnis
Nach TASK_133 wissen wir, ob eine 3D-Darstellung mit den vorhandenen Assets praktikabel ist, welche Scale-/Pivot-/Rotationsprobleme auftreten und ob sich ein groesserer 2.5D-Renderpfad lohnt. Die laufende 2D-Simulation bleibt dabei unangetastet.

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_133_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_132_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/wall_direction_mapping_verifier.gd`

## Dateien
- `docs/tasks/TASK_133_3d_asset_mapping_spike.md`
- `data/terrain_3d_asset_mapping.json`
- `scripts/terrain/terrain_map_3d_renderer.gd`
- `scenes/tests/mission_map_3d_render_spike.tscn`
- `scripts/tests/mission_map_3d_render_spike.gd`
- `scripts/tests/task_133_verifier.gd`
- `Assets/kenney_space-kit/3d/...`

## Risiken
- GLB-Pivots, Scale und Vorwaertsrichtung koennen von den 2D-Iso-Sprites abweichen.
- 3D-Objekte koennen deutlich andere Footprints haben als die bisherigen Tile-/Cover-Werte.
- Importierte GLB-Dateien koennen Repo-Groesse und Importzeiten erhoehen; deshalb nur kleine Auswahl.
- Wenn die 3D-Optik gut wirkt, braucht der naechste Schritt trotzdem eigene Tasks fuer Auswahl, Kamera, Units und eventuell 3D-Editor-Preview.
