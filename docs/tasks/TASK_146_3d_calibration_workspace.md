# TASK_146 - 3D Calibration Workspace

## Ziel
Die vorhandene 3D-Kalibrierungsszene wird zu einem brauchbaren Arbeitsraum, mit dem Scale, Pivot, Y-Offset, Rotation und Footprint der kuratierten 3D-Objektfamilien sichtbar beurteilt und kontrolliert nachgezogen werden koennen.

## Status: ERLEDIGT

## Voraussetzung
- `TASK_133 - 3D Asset Mapping Spike`
- `TASK_134 - 3D Spike Visual Calibration`
- `TASK_145 - 2.5D Tactical Debug Overlay`

## Kontext
- `res://scenes/tests/mission_map_3d_calibration.tscn` zeigt bereits mehrere Objektfamilien, ist aber noch eher technischer Spike als praktisches Art-/Kalibrierwerkzeug.
- Die 3D-Richtung gefaellt als Ziel-Look besser als die alte 2D-Missionsdarstellung.
- Bevor 3D primaer wird, muessen Groesse, Drehung, Bodenhoehe und Footprints nachvollziehbar sein.

## Umfang
1. Kalibrierungsszene lesbarer machen:
   - Objektlabels mit `type_id`/Modellfamilie.
   - sichtbarer Tile-Footprint pro Objekt.
   - Umschaltung zwischen Debug-Grid und nahezu geschlossenem Boden.
   - klare Vergleichspositionen fuer kleine Props, grosse Gebaeude, Plattformen, Fahrzeuge und flache Decals.
2. Mapping-Werte gezielt nachziehen:
   - `scale`.
   - `y_offset`.
   - `rotation_degrees_offset`.
   - keine hart codierten Sonderfaelle im Renderer.
3. Optionaler Vergleichspfad:
   - 2D-Sprite/Objektfamilie nur als visuelle Referenz, nicht als Gameplay-Wahrheit.
4. Verifier:
   - Szene rendert die erwarteten Objektfamilien.
   - Labels/Footprint-Helfer existieren.
   - Mapping bleibt valide und alle referenzierten GLBs existieren.

## Nicht-Ziele
- Keine Gameplay-Regelaenderung.
- Keine Umstellung der Live-Mission auf 3D als Primaeransicht.
- Keine neuen Unit-Modelle.
- Kein automatischer Vollimport aller Kenney-GLBs.

## Architekturregeln
- 3D bleibt Darstellungsschicht.
- `TerrainMapData` und Mapping-Daten bleiben Quelle der Darstellung.
- Kalibrierungswerte sind Daten in `data/terrain_3d_asset_mapping.json`, keine Renderer-Verzweigungen pro Modell.

## Akzeptanzkriterien
- [x] Kalibrierungsszene kann im Editor/Playmode sinnvoll als Sichtpruefung genutzt werden.
- [x] Jedes Kalibrierobjekt hat ein lesbares Label.
- [x] Footprint/Grid-Bezug ist sichtbar.
- [x] Mindestens die bisher gemappten Objektfamilien haben dokumentiert plausible V1-Werte.
- [x] Verifier prueft Szene, Mapping und fehlende Modellpfade.

## Umsetzung
- `mission_map_3d_calibration.tscn` zeigt jetzt 12 kuratierte Objektfamilien inklusive `wall_straight`.
- Die Szene erzeugt rein visuelle Helper unter `MapRoot/CalibrationHelpers3D`:
  - `Labels3D` mit `type_id`, Modellfamilie, `scale`, `y_offset` und Gesamtdrehung.
  - `Footprints3D` als farbige Tile-Footprint-Flaechen.
  - `PivotMarkers3D` als kleine gelbe Pivot-/Ankerpunkte.
- Die Szene liefert `get_calibration_snapshot()` fuer Verifier und Debug.
- `TerrainMap3DRenderer` zentriert GLB-Instanzen jetzt horizontal anhand ihrer Mesh-Bounds auf den Tile-Anker. Dadurch werden importierte Modelle mit seitlich versetztem GLB-Origin nicht mehr neben dem Footprint platziert. Pro Mapping-Eintrag kann das bei Bedarf mit `center_horizontal: false` abgeschaltet werden.
- Die Szene fuegt eine `astronautA.glb`-NPC-Referenz mit normalisierter Hoehe als Groessenvergleich ein.
- Erste grobe Scale-Korrektur im Mapping:
  - einzelnes Fass deutlich kleiner.
  - Fassgruppe, Plattform, Pipe, Rail und Crater konservativer skaliert.
  - Gebaeude, Speeder, Wall, Generator und Satellite bleiben als naechste visuelle Vergleichsgruppe erstmal bewusst vorsichtig.
- Tastatur im Playmode:
  - `G`: Debug-Grid an/aus.
  - `L`: Labels an/aus.
  - `F`: Footprints und Pivot-Marker an/aus.
- `scripts/tests/task_146_verifier.gd` prueft Mapping, fehlende GLB-Pfade, Labels, Footprints, Pivot-Marker und Toggles.
- Der Verifier prueft zusaetzlich, dass die gerenderten Modell-Bounds horizontal auf ihren Tile-Ankern liegen.
- Der Verifier prueft, dass die NPC-Referenz im Workspace vorhanden ist.

## Bedienung fuer visuelle Kalibrierung
1. In Godot `res://scenes/tests/mission_map_3d_calibration.tscn` oeffnen und starten.
2. Mit `WASD` die Kamera schieben, mit `Q/E` drehen und mit dem Mausrad zoomen.
3. Mit `G` zwischen Debug-Grid und geschlossenerer Bodenansicht wechseln.
4. Pro Objekt pruefen:
   - Wirkt das Objekt neben dem NPC plausibel?
   - Ist die farbige Footprint-Flaeche plausibel zum Tile?
   - Sitzt der gelbe Pivot-Punkt sinnvoll auf dem Tile?
   - Schwebt das Modell oder steckt es im Boden?
   - Wirkt `scale` im Vergleich zu Nachbarobjekten passend?
   - Zeigt das Objekt in die erwartete Richtung?
5. Wenn etwas nicht passt, Werte in `data/terrain_3d_asset_mapping.json` anpassen:
   - `scale` fuer Groesse.
   - `y_offset` fuer Hoehe.
   - `rotation_degrees_offset` fuer Korrekturdrehung.
   - `center_horizontal: false` nur als Ausnahme, wenn ein Modell bewusst nicht auf seine visuelle Mitte gesetzt werden soll.
6. Szene neu starten oder `G`/anderes Rerendern ausloesen und erneut vergleichen.

## Erwartetes Ergebnis
Wir koennen konkret sagen, welche 3D-Objekte optisch passen und welche Werte noch nachgezogen werden muessen, statt nur grob zu raten.

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_146_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_134_verifier.gd`
- [ ] Manuell `res://scenes/tests/mission_map_3d_calibration.tscn` starten und Kamera/Labels/Footprints pruefen.

## Dateien
- `scenes/tests/mission_map_3d_calibration.tscn`
- `data/terrain_3d_asset_mapping.json`
- `scripts/terrain/terrain_map_3d_renderer.gd`
- `scripts/tests/mission_map_3d_calibration.gd`
- `scripts/tests/task_146_verifier.gd`

## Risiken
- Kalibrierungswerte sind optische V1-Entscheidungen. Sie duerfen Gameplay-Werte wie Cover, LOS und Walkability nicht still veraendern.
