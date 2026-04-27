# TASK_139 - 2.5D Kamera und Picking

## Ziel
Die 3D-Kamera fuer den Hybridpfad spielbar machen: drehbare Orthokamera, Zoom/Pan und robustes Picking von 3D-Bildschirmpositionen zur autoritativen Grid-/Floor-Position.

## Status: GEPLANT

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
- [ ] Kamera laesst sich drehen, ohne dass Grid-Picking springt.
- [ ] Linksklick/Command-Ziel bleibt auf dem richtigen Terrain-Grid.
- [ ] Zoom/Pan veraendern Picking-Ergebnisse nicht falsch.
- [ ] Optionaler Floor-Hit kann spaeter fuer Multi-Floor genutzt werden.
- [ ] Verifier prueft mindestens zwei Kamerawinkel.

## Risiken
- Falsches Picking wuerde Commands schwer nachvollziehbar machen; Debug-Overlay fuer Grid-Hit ist Pflicht.
- Kamera darf nicht selbst Gameplay-State mutieren.
