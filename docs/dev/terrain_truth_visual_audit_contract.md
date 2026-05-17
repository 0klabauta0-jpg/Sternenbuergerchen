# Terrain Truth Visual Audit Contract

## Zweck
Dieser Contract beschreibt die Terrain-Wahrheit, Dev-UI-Diagnose und Mauer-/Kanten-LOS. TASK_454 hat die Regel auditierbar vorbereitet; TASK_456 schaltet sie im zentralen `LineOfSightSystem` als Runtime-LOS-Regel fuer Wandsegmente aktiv.

## Autoritaet
- Gameplay-Wahrheit bleibt bei `TerrainRegistry`, `TerrainTileData`, `LineOfSightSystem`, Pathfinder und Combat Resolver.
- `TerrainMap3DView`, MapEditor-Overlays und HTML-Reports sind Leseschichten.
- Terrain3D darf spaeter als Visual-/Authoring-Prototyp gegen eine Kopie der Drillmap getestet werden, aber nicht als zweite Pathing-/LOS-/Cover-Wahrheit.

## Dauerhafte Dev-UI-Felder
Terrain-Debugansichten sollen diese Werte aus der Tile-Wahrheit anzeigen koennen:

- `tile_id`
- `type_id`
- `object_type_id`
- `surface_type`
- `height_level`
- `object_height`
- `walkable`
- `blocks_los`
- `cover_value`
- `object_rotation_degrees`
- `blocker_type`
- `wall_segment_count`

Die Werte duerfen gelesen, exportiert und in Snapshots angezeigt werden. Sie duerfen im Visual-Overlay keinen Gameplay-State mutieren.

## Boden- und Objektlayer
- Ein Objektlayer-Prop wie Busch/Fels/Technik sitzt auf einem Ground-/Surface-Tile.
- Ein Objektlayer darf Ground nicht unsichtbar zu einer zweiten Terrain-Wahrheit ersetzen.
- Fuer Authoring-Audits ist `type_id = ground_flat` plus nicht-leeres `object_type_id` der gewuenschte Normalfall fuer Props auf Boden.

## Mauer-/Kanten-LOS Zielregel
Vollblocker wie massive Felsen oder hohe Objekte duerfen weiterhin ganze Tiles blocken. Mauern und Zaunsegmente brauchen eine feinere Regel:

- Gerichtete Wandtypen werden als Kanten-/Segment-Blocker interpretiert.
- Sicht entlang einer Wand oder auf derselben Mauerseite bleibt frei.
- Sicht blockt, wenn der Sichtstrahl das Wandsegment wirklich kreuzt.
- Ein reiner Eckpunkt-Touch blockt nicht automatisch.
- Geschlossene Doppel-Ecken oder mehrere Segmente duerfen spaeter blocken, wenn der zusammengesetzte Segment-Schnitt eindeutig ist.

TASK_456 verwendet diese Regel im aktiven `LineOfSightSystem`-Pfad. Nicht-Wand-Blocker bleiben Whole-Tile-Blocker.

## Naechste Slices
1. TASK_455: Terrain-Truth-Visual-Audit im MapEditor-DBG-Overlay sichtbar machen.
2. TASK_456: Wandsegment-LOS in den zentralen Runtime-LOS-Pfad ueberfuehren und selektiven Tile-Truth-Inspector anzeigen.
3. Terrain3D-Visual-Prototyp auf Drillmap-Kopie bauen.
4. Danach erst Sequence-Workbench fuer Fireteam-Raupe/Bounding/Regroup schneiden.

## Sichtbare Overlay-Konvention
Das MapEditor-DBG-Overlay darf kompakte Diagnosekuerzel anzeigen:

- `W1`, `W2`: Wandsegment-Kandidat mit Segmentanzahl.
- `WT`: Wandtyp ohne segmentierbare Kante, aktuell Whole-Tile-Kandidat.
- `OBJ H1`: Objektlayer oder Objekt-Hoehe auf einem Ground-Tile.
- `LOS`: bestehender Whole-Tile-LOS-Blocker.
- `C60`, `H2`: Cover- und Hoehenwert aus der Tile-Wahrheit.

Wandsegmente werden als gelbe Kantenlinie ueber dem Tile gezeichnet. Diese Linie ist Diagnose und ersetzt nicht automatisch den aktiven `LineOfSightSystem`-Pfad.

## Selektiver Tile-Truth-Inspector
Der MapEditor darf fuer das aktuell ausgewaehlte Tile einen read-only Inspector anzeigen. Er soll die kompakten Overlaywerte in Klartext aufloesen:

- Grid, Tile-ID, `type_id`, `object_type_id`
- Boden-/Objektlayer-State
- Walkable, LOS, Cover, Hoehe, Objekt-Hoehe
- Blocker-Art und Wandsegmentanzahl
- aktuelle Runtime-LOS-Policy

Dieser Inspector liest dieselben Helper wie Overlay und LOS-Tests. Er darf keine Gameplay-Wahrheit schreiben.
