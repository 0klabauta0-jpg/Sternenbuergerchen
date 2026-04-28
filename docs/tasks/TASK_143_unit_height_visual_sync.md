# TASK_143 - Unit Height Visual Sync

## Ziel
Units, Selection-Ringe, Zielmarker, Debuglabels und Air-Marker werden visuell an Bodenhoehe, Floor-Kontext und Air-Hoehe ausgerichtet, ohne die autoritative 2D-Simulation umzubauen.

## Status: GEPLANT

## Kontext
- TASK_142 bringt die 2.5D/3D-Kartenvisualisierung in die Live-Mission.
- Die Simulation arbeitet weiterhin auf `Node2D`/Grid-/Terrain-Daten.
- Damit 2.5D spielbar wirkt, muessen Units und taktische Marker sichtbar auf der richtigen Hoehe sitzen.

## Umfang
1. Gemeinsamer Height-Projection-Helper fuer Unit-/Marker-Visuals auf Basis von `TerrainRegistry`, `target_floor_index`, `floor_height` und `movement_layer`.
2. Boden-Units erhalten ihren visuellen Hoehenoffset aus dem aktuellen Tile/Floor.
3. Selection-Ringe, Zielmarker, Path-/Move-Preview und Debuglabels folgen demselben visuellen Offset.
4. Air-Units nutzen `altitude_band` zusaetzlich zu Boden-/Floor-Hoehe fuer Schatten/Marker-Abstand.
5. Verifier prueft Bodenhoehe, Floor-Hoehe und Air-Hoehe getrennt.

## Nicht-Ziele
- Keine echte 3D-Unit-Mesh-Ersetzung.
- Keine Animationen fuer Treppen/Rampen.
- Keine neue Movement-Logik.
- Keine finale UI-Politur.

## Akzeptanzkriterien
- [ ] Ground-Unit-Visuals stehen auf der sichtbaren 2.5D-Bodenhoehe.
- [ ] Multi-Floor-Kontext kann unterschiedliche Visual-Hoehen fuer dieselbe Grid-Zelle darstellen.
- [ ] Selection/Target/Debugmarker driften nicht von der Unit weg.
- [ ] Air-Unit-Schatten und `AIR <band>` Marker bleiben lesbar und hoehenkonsistent.
- [ ] Verifier deckt Ground, Floor und Air-Fall ab.

## Risiken
- Visueller Offset darf nicht versehentlich die autoritative `global_position` veraendern.
- Labels koennen bei hoeheren Floors/Altitudes ueberlappen; V1 darf debugbar sein, muss aber nicht final schoen sein.
