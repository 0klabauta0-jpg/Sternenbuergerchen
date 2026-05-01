# TASK_147 - 3D Asset Curation and Mapping Expansion

## Ziel
Der 3D-Assetbestand wird kontrolliert erweitert: nicht der komplette Quellordner wird blind ins aktive Spiel gezogen, sondern weitere sinnvolle Modellfamilien werden kuratiert, in den Projektpfad uebernommen und sauber im 3D-Mapping verknuepft.

## Status: GEPLANT

## Voraussetzung
- `TASK_146 - 3D Calibration Workspace`

## Kontext
- Im Projekt liegen bereits viele Kenney-GLBs unter `Assets/kenney_space-kit/Models/GLTF format`.
- Der aktive 3D-Mappingpfad nutzt bisher eine kleinere, kuratierte Auswahl unter `Assets/kenney_space-kit/3d`.
- Fuer eine primaere 3D-Missionsansicht brauchen wir mehr als 13 Modellfamilien, aber weiterhin mit nachvollziehbarer Auswahl und Imports.

## Umfang
1. Asset-Auswahl definieren:
   - zusaetzliche Gebaeude-/Corridor-/Tech-/Cover-/Vehicle-Familien.
   - keine Massenuebernahme ohne sichtbaren Nutzen.
2. Aktiven 3D-Assetordner erweitern:
   - ausgewaehlte `.glb` nach `res://Assets/kenney_space-kit/3d/`.
   - Importstatus ueber Godot pruefen.
3. Mapping erweitern:
   - `model_path`.
   - `layer`.
   - Startwerte fuer `scale`, `y_offset`, `rotation_degrees_offset`.
4. Kalibrierungsszene erweitern:
   - neue Familien in die Vergleichsreihen aufnehmen.
5. Verifier:
   - alle neuen Mappingpfade existieren.
   - neue Familien lassen sich instanziieren.
   - keine fehlenden Modellpfade in der 3D-Bridge fuer Testkarten.

## Nicht-Ziele
- Keine finale Art-Direction.
- Keine Material-Preset-Arbeit fuer Transparenzen.
- Keine 3D-Unit-Visuals.
- Keine automatische Editor-Palette fuer alle 3D-Modelle.

## Architekturregeln
- Aktive 3D-Modelle bleiben kuratiert.
- Gameplay-Terrainwerte bleiben in Katalog/Mapdaten, nicht in GLB-Dateien.
- Neue Assetfamilien duerfen keine SimulationRoot- oder UI-Abhaengigkeiten erzeugen.

## Akzeptanzkriterien
- [ ] Neue kuratierte Modellfamilien liegen im aktiven 3D-Assetordner.
- [ ] Mapping referenziert nur vorhandene Projektpfade.
- [ ] Kalibrierungsszene zeigt neue Familien.
- [ ] Verifier meldet keine fehlenden Modelle.

## Erwartetes Ergebnis
Der 3D-Look bekommt genug visuelle Substanz fuer echte Missionskarten, ohne dass das Repo oder die Map-Palette unkontrolliert anschwillt.

## Lokale Pruefung
- [ ] Godot einmal mit Projektpfad starten, damit neue GLBs importiert werden.
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_147_verifier.gd`
- [ ] Manuelle Sichtpruefung der Kalibrierungsszene.

## Dateien (voraussichtlich)
- `Assets/kenney_space-kit/3d/*.glb`
- `Assets/kenney_space-kit/3d/*.glb.import`
- `data/terrain_3d_asset_mapping.json`
- `scripts/tests/mission_map_3d_calibration.gd`
- `scripts/tests/task_147_verifier.gd`

## Risiken
- Zu viele Assets auf einmal machen Kalibrierung und Git-Historie schwer lesbar. Der Task soll bewusst kuratieren, nicht sammeln.
