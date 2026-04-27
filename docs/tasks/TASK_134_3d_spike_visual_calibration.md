# TASK_134 - 3D Spike Visual Calibration

## Ziel
Den TASK_133-3D-Spike so kalibrieren, dass er nicht nur technisch rendert, sondern als visuelle Beurteilungsgrundlage taugt: lesbares Grid, sinnvoll skalierte Props, per-Familie justierbare Transformwerte und eine minimal steuerbare Kamera.

## Status: IMPLEMENTIERT

## Kontext
- TASK_133 hat den parallelen 3D-Darstellungspfad eingefuehrt.
- Die erste brauchbare Ansicht zeigte bereits echte 3D-Modelle auf getrenntem Boden-/Objekt-Layer.
- Sichtbare offene Punkte: Grid ist noch Debug-lastig, Scale/Pivot/Rotation brauchen Familienwerte, Kamera ist noch stark szenengebunden und es gibt noch keine bewusst dichte Kalibrierungsansicht mit vielen Assetfamilien.

## Umfang
1. Per-Modell-Kalibrierung:
   - `scale`, `y_offset`, optional `rotation_degrees_offset` im 3D-Mapping auswerten.
   - Kleine Props wie Fässer sichtbar hochskalieren, grosse Fahrzeuge/Gebäude konservativ halten.
2. Debug-Grid steuerbar machen:
   - 3D-Renderer akzeptiert Render-Option fuer `show_debug_grid`.
   - Debug-Grid bleibt fuer Tests sichtbar, kann aber in Szenen abgeschwaecht/ausgeschaltet werden.
3. Kamera-Steuerung fuer Spike-Szenen:
   - WASD zum horizontalen Schieben.
   - Q/E zum Rotieren um den Fokus.
   - Mausrad oder API-Zoom fuer Orthographic Size.
   - Automatischer Start-Fokus auf Objektgruppe bleibt erhalten.
4. Kalibrierungs-Testszene:
   - Neue Szene unter `scenes/tests`, die eine kleine generierte Map mit mehreren 3D-Objektfamilien rendert.
   - Keine Gameplay- oder Editor-Verdrahtung.
5. Verifier:
   - Prueft Kalibrierungswerte.
   - Prueft Kamera-API/Zoom.
   - Prueft, dass die Kalibrierungs-Szene viele Objektfamilien instanziiert.
   - TASK_133/132/Wall-Verifier bleiben gruen.

## Nicht-Ziele
- Keine finale 3D-Art-Direction.
- Keine 3D-Unit-Darstellung.
- Keine 3D-Editor-Platzierung.
- Keine Umstellung von Navigation, LOS oder Combat auf 3D.
- Keine neuen Assetfamilien ausserhalb der bereits importierten TASK_133-Auswahl.

## Architekturregeln
- 3D bleibt Darstellungsschicht.
- `TerrainMapData` bleibt Quelle.
- Kalibrierungswerte bleiben Daten, nicht hart im Renderer pro Typ verzweigt.
- Szenensteuerung darf nur Test-/Spike-Szenen betreffen.

## Akzeptanzkriterien
- [x] 3D-Mapping unterstuetzt `scale`, `y_offset` und `rotation_degrees_offset`.
- [x] Renderer kann Debug-Grid sichtbar oder nahezu geschlossen rendern.
- [x] Spike-Szene hat minimale Kamera-Steuerung fuer Pan, Zoom und Rotation.
- [x] Eine Kalibrierungs-Szene zeigt mindestens 8 verschiedene Objektfamilien.
- [x] Verifier prueft Kalibrierungswerte, Kamera-API und Objektinstanzen.
- [x] TASK_133-, TASK_132- und Wall-Mapping-Verifier bleiben gruen.

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_134_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_133_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_132_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/wall_direction_mapping_verifier.gd`

## Dateien
- `docs/tasks/TASK_134_3d_spike_visual_calibration.md`
- `data/terrain_3d_asset_mapping.json`
- `scripts/terrain/terrain_map_3d_renderer.gd`
- `scripts/tests/mission_map_3d_render_spike.gd`
- `scripts/tests/mission_map_3d_calibration.gd`
- `scenes/tests/mission_map_3d_calibration.tscn`
- `scripts/tests/task_134_verifier.gd`

## Risiken
- Scale-/Offset-Werte sind optische V1-Schätzungen und ersetzen kein echtes Art-Pass.
- Kamera-Steuerung in Testszene ist bewusst minimal und noch kein finaler Spielkamera-Controller.
- Grosse Modelle koennen trotz Kalibrierung Footprint-/Deckungswerte anders wirken lassen als in 2D.
