# Map Editor Module Split

## Zweck
TASK_163 ist ein verhaltensneutraler Schnitt am internen Map-Editor. Der Editor bleibt `scenes/editor/map_editor.tscn` mit `scripts/editor/map_editor.gd`, aber klar abgrenzbare Helfer liegen jetzt unter `scripts/editor/`.

## Umgesetzte Module
- `map_editor_primary_view_adapter.gd`
  - kapselt `Primary3DView`-Lookup/Erzeugung, Legacy-2D-Sichtbarkeit, 2.5D-Refresh, Selektionsspiegelung und Screen-to-World-Picking.
- `map_editor_height_tool.gd`
  - kapselt Height-/Edge-Patch-Building und Hoehenmodus-Regeln.
- `map_editor_patrol_tool.gd`
  - kapselt Patrol-Waypoint-Finden, Hinzufuegen, Verschieben und Entfernen auf `TerrainMapData`.
- `map_editor_marker_tool.gd`
  - kapselt Marker-Hit-Test, Belegungspruefung und Suche nach freier Marker-Position.

## Bewusst im Editor geblieben
- Scenario-Panel und Live-Test-Start bleiben vorerst im Editor-Skript, weil sie direkt an `MissionScenarioData` und bestehende Editor-to-Live-Verifier gekoppelt sind.
- File-Dialog-/Save-Load-Fluss bleibt vorerst im Editor-Skript, weil Dialogpfade und Dirty-State eng mit UI-Signalen verbunden sind.
- Terrain-Brush-Painting bleibt im Editor-Skript, nutzt aber die bestehende `TerrainTileCatalog`-/`TerrainMapData`-Pipeline unveraendert.

## Grenzen
- `TerrainMapData` wurde nicht geaendert.
- `MissionScenarioData` wurde nicht geaendert.
- Die LZ bleibt weiterhin Spielerentscheidung in der Live-Mission und wird nicht im Editor gespeichert.
- Die 2.5D-View bleibt Darstellung und Picking, nicht Gameplay-Wahrheit.
