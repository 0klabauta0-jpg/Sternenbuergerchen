# TASK_454 - Terrain Truth Visual Audit

## Ziel / Problem
Der Fireteam-Playtest leidet unter schwer lesbaren Terrain-Signalen: Bodenplatten, Buesche, Hoehen, LOS-Blocker und Mauerverhalten muessen gegen die Runtime-Wahrheit pruefbar sein, bevor weitere Behavior-Feinheiten bewertet werden.

## Sinnhaftigkeit / Ursache
TASK_453 hat festgelegt, dass `TerrainRegistry`, Tile-Daten, LOS-System, Pathfinder und Combat Resolver die Gameplay-Wahrheit bleiben. Terrain3D darf spaeter als Visual-Prototyp getestet werden, aber nicht still zur zweiten Autoritaet werden.

Gleichzeitig reichen ganze Tile-Blocker fuer Mauern fachlich nicht aus: Sicht entlang einer Mauer soll moeglich sein, waehrend echte Segment-Schnitte blocken sollen.

## Umfang
- Kleiner Terrain-Truth-Audit-Helfer fuer Tile-/Map-Diagnose.
- Pruefbare Mauer-/Kanten-LOS-Segmentregel als Contract-Helfer, noch ohne Combat-LOS-Umschaltung.
- MapEditor-Tile-Property-Overlay bekommt die dauerhaft gewuenschten Dev-UI-Werte im Debug-Snapshot.
- Headless-Test fuer Audit-Helfer, Wandsegment-Regel, Overlay-Felder und Doku-Verankerung.

## Nicht-Ziele
- Keine Umstellung von `LineOfSightSystem` auf Segment-LOS.
- Keine Terrain3D-Runtime-Integration.
- Kein Umbau der Drillmap.
- Keine neue Sequence-Workbench.
- Keine Aenderung an Combat, Pathfinding oder Unit-Verhalten.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_453_fireteam_terrain_los_sequence_direction_audit.md`
- `docs/dev/terrain_truth_visual_audit_contract.md`
- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/tasks/TASK_372_mission_los_debug_overlay_toggle.md`
- `docs/tasks/TASK_379_mapeditor_tile_property_grid_overlay.md`

## Akzeptanzkriterien
- Ein Helper kann pro Tile die relevanten Dev-UI-Felder liefern: Tile-ID/Typ, Objekt-Typ, Surface, Hoehe, Objekt-Hoehe, Walkable, LOS-Block, Cover, Rotation und Blocker-Art.
- Ein Helper kann pro Map zaehlen, wie viele Objektlayer, LOS-Blocker, Wandsegment-Kandidaten und Objekt-auf-Ground-Faelle vorhanden sind.
- Wand-/Zaun-Linie wird als Kanten-/Segment-Blocker modelliert: paralleles Entlangsehen blockt nicht, echter Segment-Schnitt blockt, ein reiner Eckpunkt-Touch blockt nicht automatisch.
- MapEditor-Overlay-Snapshots liefern die Dev-UI-Felder, ohne Gameplay-State zu schreiben.
- Doku haelt fest, dass der Segment-Helfer noch nicht den aktiven Combat-LOS-Pfad ersetzt.

## Betroffene Dateien
- `docs/tasks/TASK_454_terrain_truth_visual_audit.md`
- `docs/dev/terrain_truth_visual_audit_contract.md`
- `scripts/terrain/terrain_truth_audit.gd`
- `scripts/editor/map_editor_tile_property_overlay.gd`
- `scripts/tests/task_454_terrain_truth_visual_audit.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_454_terrain_truth_visual_audit.gd`
- `git diff --check`

## Risiken / offene Punkte
- Aktiver Combat-LOS nutzt weiterhin den bestehenden Tile-Blocker-Pfad. Die Segmentregel ist bewusst nur auditierbar vorbereitet.
- Die genaue Mapping-Konvention fuer weitere importierte Wand-Assets muss spaeter pro Asset-Familie ergaenzt werden.
- Die spaetere Visual-Prototyp-Kopie mit Terrain3D bleibt offen.
