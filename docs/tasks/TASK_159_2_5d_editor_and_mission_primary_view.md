# TASK_159 - 2.5D Editor and Mission Primary View

## Ziel
Editor und Live-Mission sollen nicht mehr auf der alten 2D-Canvas-Karte als primaere Ansicht haengen. Beide Pfade bekommen eine gemeinsame 2.5D-Primary-View mit `SubViewport`, `Node3D`-Welt und `Camera3D`, damit Kamera-Zoom, WASD-Pan und Rotation die Karte bewegen statt UI- oder Debug-Text zu skalieren.

## Status: IMPLEMENTIERT

## Voraussetzung
- `TASK_157 - Tactical Mission Editor MVP`
- `TASK_158 - Editor-to-Live Mission Validation`
- bestehender `TerrainMapData`-/`TerrainRegistry`-Vertrag

## Kontext
Der alte Editor und die Mission nutzen weiterhin viele `Node2D`-Objekte als Laufzeit-, Registrierungs- und Datenanker. Diese bleiben vorerst erhalten, damit `SimulationRoot`, `UnitRegistry`, `FTLRegistry`, TacticalController und bestehende Tests ihre Autoritaetsgrenzen behalten.

Die sichtbare Kartenoberflaeche und die bedienbare Kamera sollen aber nicht mehr aus `Sprite2D`/`Camera2D` kommen. Der 2D-Renderer bleibt nur als Legacy-/Fallback-Pfad und wird in Editor und Mission ausgeblendet.

## Umfang
1. Gemeinsame 2.5D-View:
   - `TerrainMapData` als 3D-Tile-/Objekt-/Marker-/Patrol-Ansicht rendern.
   - `Camera3D` mit Zoom, WASD-Pan und Rotation.
   - Screen-to-world-Picking fuer Editor und TacticalController anbieten.
2. Editor-Integration:
   - alte `Camera2D` deaktivieren.
   - alte Terrain-/Overlay-Container ausblenden.
   - Klick-, Paint-, Marker- und Patrol-Authoring ueber 3D-Picking weiter nutzbar halten.
3. Live-Mission-Integration:
   - alte Terrain-/Unit-Sprite-Visuals ausblenden, ohne Unit-Node-Registrierung oder Runtime-State zu zerstoeren.
   - Friendlies/Enemies als 3D-Proxies aus den bestehenden runtime-autoritativen `Node2D`-Positionen spiegeln.
   - TacticalController-Picking ueber die 2.5D-View fuehren, damit LZ, Move/Attack/Defend-Areas und Waypoints auf der 3D-Karte landen.
4. Verifier:
   - Editor besitzt eine 3D-Primary-View, 2D-Karte ist ausgeblendet, Kamera ist rotierbar.
   - Live-Mission besitzt dieselbe 3D-Primary-View, 2D-Unit-Sprites sind ausgeblendet, Runtime-Unit-Nodes bleiben sichtbar/registrierbar.

## Nicht-Ziele
- Keine Umschreibung von `SimulationRoot` auf `Node3D`.
- Keine echte 3D-Navigation oder 3D-Physik.
- Keine Entfernung des JSON-/Terrain-Datenvertrags.
- Kein neues Balancing und keine neuen taktischen Regeln.

## Architekturregeln
- Die 2.5D-View ist Darstellung und Eingabeprojektion, nicht Gameplay-Wahrheit.
- Runtime-Positionen bleiben bei den bestehenden autoritativen Pfaden.
- Keine SceneTree-Vollsuche pro Frame fuer Gameplay-Entscheidungen.
- LZ bleibt Spieleraktion und wird weiterhin nicht im Editor-/Szenariodatensatz gespeichert.

## Akzeptanzkriterien
- [x] Editor startet mit sichtbarer 2.5D-Karte und `Camera3D`.
- [x] Kamera laesst sich rotieren; Zoom skaliert nicht mehr die graue Debug-/UI-Schrift.
- [x] Editor-Picking fuer Tile-, Marker- und Patrol-Arbeit nutzt die 2.5D-Karte.
- [x] Live-Mission blendet alte 2D-Terrain-/Unit-Sprites aus und zeigt 3D-Proxies fuer Friendlies/Enemies.
- [x] TacticalController kann LZ und taktische Ziele ueber die 2.5D-Ansicht setzen.
- [x] Boden, Kartenobjekte, Waende, Ecken, Cliffs, Rampen und Felsen nutzen in der 2.5D-View die authored Kenney-Isometric-Texturen und das bestehende Richtungs-Mapping; GLB-/Block-Modelle bleiben nur Fallback.
- [x] Runtime-Units spiegeln die vorhandenen Unit-`Visual`-/Weapon-Sprites als 2.5D-Texturkarten statt generische Astronaut-GLBs zu erzwingen.
- [x] Der Dropship-Marker nutzt die vom TacticalController berechnete Isometric-Speeder-Textur statt Box-/Wing- oder GLB-Platzhaltern.
- [x] Die 2.5D-Bodenkarte nutzt wieder `terrain_SW.png` mit dem bestehenden Tile-Modulate, damit Farbe und Lesbarkeit dem authored 2D-Stand entsprechen.
- [x] Der 2.5D-Live-Pfad baut die versteckte Legacy-2D-Karte nicht mehr zusaetzlich auf.
- [x] Die 3D-Kalibrierungs- und Render-Spike-Szenen besitzen ihre Script-Dependencies und laden die gemeinsame `TerrainMap3DView`.
- [x] Bestehende Authoring-/Live-Verifier bleiben lauffaehig oder dokumentieren bewusst offene GUI-Risiken.

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_159_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_158_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_157_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_155_verifier.gd`

## Dateien (voraussichtlich)
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/editor/map_editor.gd`
- `scripts/tests/mission_test_setup.gd`
- `scripts/tests/mission_map_camera_controller.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/mission_map_3d_calibration.gd`
- `scripts/tests/mission_map_3d_render_spike.gd`
- `scripts/tests/task_159_verifier.gd`
- `scenes/tests/mission_map_3d_calibration.tscn`
- `scenes/tests/mission_map_3d_render_spike.tscn`
- `docs/tasks/TASK_159_2_5d_editor_and_mission_primary_view.md`

## Risiken
- Vollstaendiges Entfernen der 2D-Runtime-Anchor in einem Schritt waere zu riskant, weil viele autoritative Systeme noch `Node2D`-Referenzen verwenden.
- 3D-Visuals duerfen bestehende Tactical-Overlays nicht still ersetzen, bevor ihre Daten explizit gespiegelt werden.
- Headless-Verifier koennen die sichtbare Qualitaet nur strukturell absichern; ein manueller Godot-Run bleibt fuer Kamera-Gefuehl und Lesbarkeit noetig.

## Ergebnis
- `TerrainMap3DView` rendert `TerrainMapData` als gemeinsame 2.5D-Primary-View mit `SubViewport`, `Node3D`, `Camera3D`, Terrain-/Objekt-/Marker-/Patrol-Visuals, Unit-Proxies, LZ-/Dropship-Proxy und taktischen Area-/Contact-Overlays.
- Terrain-Objekte, Waende, Cliffs, Rampen, Felsen und Katalog-Objekte werden in dieser View wieder aus den vorhandenen Kenney-Isometric-PNGs als `Sprite3D`-Texturkarten gerendert; dadurch bleiben Texturen, Farben, Richtungs-Mapping und authored Sprite-Groessen erhalten.
- GLB-Modelle bleiben nur Fallback fuer nicht aufloesbare Texturen. Der fruehere Versuch, GLBs als primaere Map-Assets zu verwenden, war sichtbar falsch, weil dabei Texturen, Wall-/Corner-Richtungen, Objektfarben und Sprite-Groessen verloren gingen.
- `TerrainMapData.load_from_file()` laedt den Terrain-Tile-Katalog nur noch einmal pro Map. Vorher wurde der Katalog fuer jedes Tile neu geladen, was die 32x32-Live-Mission beim Start fuer lange Zeit blockiert hat.
- `TerrainTileData.from_dict()` erzeugt Tiles direkt ueber die bestehende Klasse statt pro Tile das Script erneut zu laden.
- Die sichtbare Bodenkarte der 2.5D-View nutzt wieder `terrain_SW.png` plus das bestehende Modulate-Verhalten statt eines neutralen Farb-Meshes.
- Runtime-Units und Dropship werden als authored Isometric-Texturen gespiegelt; generische Capsule-, Box- und GLB-Proxies bleiben nur Fallbacks.
- `mission_map_3d_calibration.tscn` und `mission_map_3d_render_spike.tscn` laden jetzt ueber kleine Test-Scripts dieselbe 2.5D-Primary-View, sodass Godot sie ohne fehlende Script-Dependencies oeffnen kann.
- Der Map-Editor deaktiviert die alte `Camera2D`, blendet Legacy-2D-Kartencontainer aus und fuehrt WASD, Zoom, Rotation sowie Tile-/Marker-/Patrol-Picking ueber die 3D-View.
- Die Live-Mission blendet alte Terrain-/Unit-Sprites aus, laesst die `Node2D`-Runtime-Anker fuer Simulation/Selection sichtbar und spiegelt Units, LZ, Dropship, Attack Areas und Contacts in die 3D-View; die versteckte 2D-Karte wird im 2.5D-Primary-Pfad nicht mehr parallel gerendert.
- TASK_158 wurde so angepasst, dass die Live-Visual-Bridge jetzt die 3D-Primary-View akzeptiert statt alte 2D-Sprites als sichtbare Wahrheit zu verlangen.
