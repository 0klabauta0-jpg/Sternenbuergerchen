# TASK_139 - 2.5D Kamera und Picking

## Ziel
Die 3D-Kamera fuer den Hybridpfad spielbar machen: drehbare Orthokamera, Zoom/Pan und robustes Picking von 3D-Bildschirmpositionen zur autoritativen Grid-/Floor-Position.

## Status: IMPLEMENTIERT

## Kontext
- TASK_134 hat eine Spike-Kamera fuer 3D-Testansichten eingefuehrt.
- Fuer 2.5D muss Kamera-Drehung moeglich sein, ohne Commands, Auswahl und Marker vom autoritativen Terrain-Grid zu entkoppeln.

## Umfang
1. Gemeinsamen 2.5D-Kamera-Controller fuer Test-/Mission-Szenen schneiden.
2. Rotation, Pan und Zoom als kontrollierte API anbieten.
3. Screen-Ray auf Ground-/Floor-Ebene in Grid-Position umrechnen.
4. Picking muss Kamera-Rotation, Orthographic Size und optionalen `floor_index` beruecksichtigen.
5. Kleine Testszene oder Verifier fuer Command-Zielpunkte unter gedrehter Kamera.

## Nicht-Ziele
- Keine finale Spielkamera-Politur.
- Keine Full-3D-Unit-Auswahl.
- Keine neue Tactical-UI-Struktur.
- Keine Umstellung der Simulation auf Vector3.

## Akzeptanzkriterien
- [x] Kamera laesst sich drehen, ohne dass Grid-Picking springt.
- [x] Linksklick/Command-Ziel bleibt auf dem richtigen Terrain-Grid.
- [x] Zoom/Pan veraendern Picking-Ergebnisse nicht falsch.
- [x] Optionaler Floor-Hit kann spaeter fuer Multi-Floor genutzt werden.
- [x] Verifier prueft mindestens zwei Kamerawinkel.

## Umsetzung
- `Terrain25DCameraController` kapselt die bisherige Spike-Kamera als wiederverwendbare Orthokamera mit Fokus, Rotation, Pan und Zoom.
- `Terrain25DPicker` rechnet Camera-Screen-Rays auf 2.5D-Floor-Ebenen zurueck und liefert einen Snapshot mit `grid_position`, `target_position` und `target_floor_index`.
- `TerrainMap3DRenderer` nutzt fuer Boden/Objekte die 2.5D-`floor_height` und bietet Grid/3D-Konvertierung fuer Picking-Schichten an.
- `mission_map_3d_render_spike.gd` nutzt Controller und Picker, speichert den letzten Pick-Snapshot und zeigt einen kleinen Debug-Marker auf dem Grid-Hit.
- `scripts/tests/task_139_verifier.gd` prueft Kamera-API, Ground-/Floor-Picking, Command-Zielvertragsdaten und Picking nach Rotation/Zoom.

## Risiken
- Falsches Picking wuerde Commands schwer nachvollziehbar machen; Debug-Overlay fuer Grid-Hit ist Pflicht.
- Kamera darf nicht selbst Gameplay-State mutieren.
