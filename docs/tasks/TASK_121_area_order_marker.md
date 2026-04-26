# TASK_121 - Area Order Marker

## Ziel
Die Missionstaktikkarte soll nicht nur einzelne Wegpunkte, sondern auch Gebiete als spielerseitige Befehlsmarker unterstuetzen. Ein Gebiet besteht in V1 aus mehreren Iso-Grid-Feldern und kann fuer Befehle wie `defend`, `engage`, `take` oder spaeter `recon` verwendet werden.

## Status: IMPLEMENTIERT

## Kontext
- `TASK_115` fuehrte den gemeinsamen Marker-Katalog fuer Editor und Taktikkarte ein.
- Der aktuelle Missionspfad arbeitet mit einzelnen `FireteamWaypoint`-Zielpositionen.
- Das Phasensystem ist fuer das aktuelle Spielgefuehl geparkt; GO fuehrt Fireteams direkt durch die Wegpunktkette.
- Gebietsmarker sollen weiter missionslokaler Tactical-/Planning-State bleiben und nicht in die Karten-JSON zurueckgeschrieben werden.

## Umfang
1. Einen kleinen Datenvertrag fuer Area Orders einfuehren:
   - `area_order_id`
   - `fireteam_id`
   - `command_type`
   - `tile_positions` oder `world_polygon`
   - `center_position`
   - `created_at_order_index`
   - `status`
2. Mission-UI kann ein rechteckiges oder lasso-aehnliches Gebiet aus mehreren Tiles erzeugen.
3. Area Orders werden im Planning-State serialisiert und wieder geladen.
4. `FireteamOrderVisualizer` zeichnet Area Orders separat von normalen Wegpunktlinien.
5. Einzel-Wegpunkte bleiben unveraendert nutzbar.

## Nicht-Ziele
- Keine vollstaendige Polygon-Editor-Komplexitaet.
- Keine Kampagnenpersistenz.
- Keine echte Defend-/Attack-Semantik in diesem Task.
- Keine Gegner-KI-Aenderungen.

## Architekturregeln
- UI erzeugt nur Befehlsdaten, keine Gameplay-Wahrheit.
- Area-Order-State bleibt missionslokal und wird ueber den bestehenden Planning-State-Bridge-Pfad synchronisiert.
- Keine Hotpath-SceneTree-Vollscans.
- Tile-Auswahl nutzt vorhandene Terrain-/Grid-Hilfen, wenn verfuegbar.

## Akzeptanzkriterien
- [x] Spieler kann ein Gebiet aus mehreren Tiles als Area Order markieren.
- [x] Gebiete koennen als `defend`, `engage` oder `take` klassifiziert werden.
- [x] Area Orders werden sichtbar auf der Mission Map gezeichnet.
- [x] Bestehende Einzel-Wegpunkte funktionieren weiter.
- [x] Planning-State-Roundtrip erhaelt Area Orders.
- [x] Headless-Verifier prueft Erzeugen, Serialisieren und Visualizer-Snapshot.

## Ergebnis
- `AreaOrder` ist als kleiner missionslokaler Datenvertrag unter `scripts/command/area_order.gd` eingefuehrt.
- Die Missionstaktikkarte erzeugt Area Orders per `SHIFT+Drag` als einfache Rechteckauswahl aus Terrain-Tiles, mit Polygon-Fallback ohne TerrainRegistry.
- Area Orders werden separat in `area_orders` im Planning-State serialisiert und geladen, nicht in Karten-JSON geschrieben und nicht in die Waypoint-Ausfuehrung eingespeist.
- Das Area-Order-Kontextmenue klassifiziert Gebiete als `defend`, `engage` oder `take`.
- `FireteamOrderVisualizer` zeichnet Area Orders getrennt von normalen Wegpunktlinien und stellt einen eigenen Snapshot bereit.

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_121_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_115_verifier.gd`

## Dateien (voraussichtlich)
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tactical/visuals/fireteam_order_visualizer.gd`
- ggf. `scripts/command/area_order.gd`
- `scripts/tests/task_121_verifier.gd`

## Risiken
- Wenn Gebietsauswahl direkt im UI zu viel Logik bekommt, entsteht Architektur-Drift.
- Rechteck- und Polygon-Auswahl sollten klein gehalten werden; V1 darf bewusst simpel bleiben.
