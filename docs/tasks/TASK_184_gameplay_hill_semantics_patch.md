# TASK_184 - Gameplay Hill Semantics Patch

## Ziel
Die Spiellogik soll Huegel genauso behandeln, wie sie im Vertrag aus TASK_182 beschrieben sind: Bewegung, HPA/A*, LOS, Cover und Combat lesen dieselben Terrain-Daten und kommen zu denselben Entscheidungen.

Besonders wichtig sind Mauer-auf-Huegel, Klippe vs. Hang, Sand auf Hoehe und diagonale Schritte an harten Kanten.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_182 - Terrain Hill Rules Contract
- TASK_183 - Editor Hill Authoring Patch
- bestehende TerrainRegistry
- bestehendes A*/HPA-Pathfinding
- bestehende LOS- und Combat-Systeme

## Kontext
Aktuell nutzen mehrere Runtime-Systeme Teile der Terrain-Daten. Das ist gut, aber riskant, sobald Huegel echte taktische Bedeutung bekommen:

- A* und HPA duerfen fuer dieselbe Kante nicht verschiedene Walkability-Antworten liefern.
- LOS muss eine Mauer auf H=2 anders behandeln als dieselbe Mauer auf H=0.
- Sand darf auf einem Hang nicht seine Surface-Kosten verlieren.
- Diagonale Bewegung darf nicht an einer Klippe vorbei "durch die Ecke" rutschen, wenn der orthogonale Zugang blockiert ist.

## Umfang
1. Gemeinsame Schrittregel:
   - Zentrale Helper oder klar geteilte Funktionen fuer Terrain-Schritte einbauen.
   - A* und HPA verwenden dieselbe Antwort fuer `walkable`, Hoehendifferenz, `edge_type` und Surface-Kosten.
   - Keine duplizierten Sonderregeln in mehreren Pfaden.
2. Bewegung:
   - `walkable = false` blockiert weiterhin.
   - `edge_type = slope` erlaubt Hoehentransitionen nach TASK_182 und kostet zusaetzlich.
   - `edge_type = cliff` blockiert oder erlaubt nur genau den im Vertrag dokumentierten Fall.
   - `edge_type = none` wird nach TASK_182 behandelt und nicht als stiller Gratis-Hang missbraucht.
   - Surface-Kosten gelten fuer das Ziel-Tile, auch auf Huegeln.
   - Sandhang ist langsamer/teurer als Ground-Hang.
3. Diagonalregeln:
   - Diagonalbewegung prueft die relevanten orthogonalen Nachbarschritte.
   - Harte Klippen, Mauern oder nicht begehbare Tiles koennen nicht diagonal umgangen werden, wenn dadurch eine blockierte Ecke geschnitten wuerde.
4. LOS und Hoehe:
   - Effektive Blockerhoehe wird aus `height_level + object_height` berechnet.
   - Wand auf Huegel blockt hoeher als Wand auf flach.
   - Hoeher stehende Units koennen nur gemaess TASK_182 ueber niedrigere Blocker sehen.
   - Source-/Target-Tiles blockieren sich nicht selbst, ausser der bestehende Combat-Vertrag verlangt das ausdruecklich.
5. Cover und Combat:
   - Cover-Werte bleiben Tile-/Objekt-basiert und werden nicht aus UI oder Renderer gelesen.
   - Hoehen-Accuracy-Bonus/-Penalty bleibt konsistent mit der effektiven Gelaendehoehe.
   - Mauer auf Huegel kombiniert Cover/LOS/Walkability nach Datenvertrag, nicht nach sichtbarem Assetnamen.
6. Fallbacks:
   - Ohne TerrainRegistry bleibt der bestehende Geradlinien-/Distanz-Fallback erhalten.
   - Fehlende oder alte Map-Felder bekommen bewusst dokumentierte Defaults.

## Nicht-Ziele
- Keine Editor-UI-Aenderungen.
- Keine 2.5D-Renderer-Politur.
- Kein neues Balancing fuer Waffen, Units oder Missionsphasen.
- Keine 3D-Physik oder NavMesh-Rewrite.
- Keine UI-State-Mutation als Gameplay-Wahrheit.

## Akzeptanzkriterien
- [x] A* und HPA liefern fuer dieselbe Huegelkarte konsistente Pfade oder konsistente Blockaden.
- [x] Hang-Pfad ist begehbar und teurer als flacher Ground-Pfad.
- [x] Sandhang ist teurer/langsamer als Ground-Hang.
- [x] Klippenkante folgt exakt der Entscheidung aus TASK_182.
- [x] Diagonalbewegung kann harte Klippen-/Mauer-Ecken nicht schneiden.
- [x] Eine Mauer auf H=2 blockt LOS mit effektiver Hoehe `height_level + object_height`.
- [x] Combat-Hoehenbonus nutzt Gelaendehoehe, nicht Objekt- oder Rendererhoehe.
- [x] Ohne TerrainRegistry bleiben bestehende Fallbacks lauffaehig.
- [x] Ein TASK_184-Verifier deckt Bewegung, HPA/A*, LOS, Cover und Combat-Hoehenfaelle ab.

## Erwartete Dateien
- `scripts/terrain/terrain_tile_data.gd`
- `scripts/terrain/terrain_registry.gd`
- `scripts/terrain/terrain_pathfinder.gd`
- `scripts/terrain/hpa_navigation_graph.gd`
- `scripts/terrain/hpa_pathfinder.gd`
- `scripts/core/los_system.gd`
- `scripts/core/simulation_root.gd`
- `scripts/tests/task_184_gameplay_hill_semantics_verifier.gd`
- `docs/tasks/TASK_184_gameplay_hill_semantics_patch.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_184_gameplay_hill_semantics_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_160_tactical_playability_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_096_recovery_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/bugfix_dropship_mission_flow_verifier.gd`
- [x] `git diff --check`

Zusaetzlich:
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_126_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_125_verifier.gd`

## Risiken
- Wenn Klippen von bisher "teilweise begehbar" auf "hart blockiert" wechseln, koennen bestehende Testkarten andere Pfade brauchen. Das muss als bewusste Gameplay-Entscheidung behandelt werden.
- HPA-Caches duerfen keine alten Schrittregeln behalten, wenn sich Terrain-Daten oder Regeln aendern.
- LOS-Regeln koennen Combat-Kontakt deutlich veraendern; der Verifier braucht kleine, eindeutige Karten statt grosse Missionszufaelle.

## Umsetzung
- `TerrainPathfinder` behandelt Hoehendifferenzen jetzt nach TASK_182: nur `edge_type = slope` erlaubt den Wechsel, `cliff` und `none` blockieren.
- Verbotene Schritte liefern `INF` als Kosten; HPA erbt dieselbe Entscheidung ueber Graph-Portale, lokale Pfade und Portal-Kosten.
- Surface-Kosten bleiben Ziel-Tile-basiert; Sandhang ist dadurch teurer als Ground-Hang.
- Die cover-aware Grid-LOS im Pathfinder nutzt dieselbe effektive Blockerhoehe `height_level + object_height` wie `LineOfSightSystem`.
- `scripts/tests/task_184_gameplay_hill_semantics_verifier.gd` prueft Bewegung, A*/HPA, Diagonal-Corner-Cutting, LOS, Cover, Combat-Hoehe und Fallbacks ohne TerrainRegistry.

## Naechster Schritt
TASK_185 kann die sichtbare 2.5D-Darstellung gegen denselben Vertrag ziehen.
