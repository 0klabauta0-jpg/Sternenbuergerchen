# TASK_082 – Gemeinsamer Terrain-Renderer fuer Editor und Mission

- Phase: 16 – Charakterbogen-Kampfwirkung
- Status: implementiert
- Abhaengigkeiten: TASK_064 (MissionTestSetup: Terrain aus JSON laden), TASK_069 (Map-Editor: Auswahl, Save As und Workflow-Polish), TASK_078 (Meta-Layer: Navigation und Map-Ansicht)

## Ziel
Editor, Missions-Testszene und Meta-Map sollen auf denselben kleinen JSON-/Renderpfad fuer Terrain- und Missionskarten aufsetzen, statt mehrere voneinander driftende Kartenpfade zu pflegen.

## Anforderungen
1. Fuehre einen gemeinsamen Renderer fuer `TerrainMapData` ein, den Editor und Mission teilen koennen.
2. Die Missions-Testszene soll dieselbe JSON-Karte ueber diesen Pfad sichtbar aufbauen statt ueber einen separaten Hardcode-/Sprite-Mix.
3. `TerrainMapData` soll einen kleinen Marker-Datenvertrag fuer feste Missionsmarker tragen, mindestens `spawn_alpha`, `spawn_bravo`, `objective_point`, `flank_anchor_left` und `flank_anchor_right`.
4. Die zentrale Testmap soll diese Marker direkt in derselben JSON-Datei speichern.
5. `MissionTestSetup` soll Marker aus der JSON in die vorhandenen Szenen-Marker spiegeln, damit bestehende NodePath-Pfade weiter funktionieren.
6. Die read-only Meta-Map soll dieselben Markerkoordinaten aus derselben Map-Datei lesen.
7. `TerrainMapData` soll zusaetzlich `mission_slot_count` speichern koennen, damit Slot-Kapazitaet direkt an der Map haengt.
8. Der Map-Editor soll ein kleines Map-Settings-Panel fuer `mission_slot_count` und die festen Marker-Zuweisungen besitzen.
9. `MetaLayerFlow` soll bei Bedarf die Missions-Slot-Kapazitaet direkt aus der Map-Datei aufloesen koennen, statt nur an statischen Missionsdefinitionen zu haengen.

## Akzeptanzkriterien
- Editor und Mission rendern dieselbe JSON-Karte ueber denselben kleinen Renderer-Pfad.
- Marker werden in der Map-Datei gespeichert und in Mission sowie Meta-Map konsistent gelesen.
- `mission_slot_count` bleibt beim Save/Load-Roundtrip erhalten.
- Der Map-Editor kann Slot-Zahl und feste Missionsmarker aus dem bestehenden UI-Workflow heraus pflegen.
- Die Mission bleibt mit den bestehenden Szenen-Marker-NodePaths kompatibel.

## Nicht in diesem Task
- frei definierbare Marker-Typen
- graphische Handle-basierte Marker-Platzierung direkt auf der Karte
- komplexe Missionsplanung oder Kampagnenpersistenz
- mehrere voneinander unabhaengige Runtime-Renderer fuer dieselbe Kartenlogik

## Folgepfad
- Der verbliebene Marker-Restpunkt wurde als [TASK_115 - Gemeinsames Markersystem fuer Editor und Taktikkarte](docs/tasks/TASK_115_gemeinsames_markersystem_fuer_editor_und_taktikkarte.md) ausgelagert und dort umgesetzt.
