# TASK_1189 - FOW Dirty Region Fan-out

## Ziel

Die taktische Sicht aktualisiert bei einer Observer-Bewegung nur die betroffene
Region. Sichtzustand wird in begrenzten Arbeitsscheiben berechnet und erst nach
vollstaendiger Berechnung atomar publiziert. Die 3D-Map konsumiert die
publizierte Sichtrevision als Visual-Delta, ohne Orders, Drops oder Unit-Proxies
bei einem reinen Sichtwechsel neu zu erzeugen.

## Architekturgrenzen

- `FogOfWarSystem` bleibt die einzige Quelle fuer Terrain-Sichtwissen.
- Noch nicht vollstaendig berechnete Sicht wird weder an Gameplay noch an die
  Visualisierung publiziert.
- `TerrainMap3DView` bleibt eine Leseschicht; sie verwaltet nur Mesh- und
  Sichtbarkeitsinstanzen, keine Sicht- oder Contact-Wahrheit.
- Ein Full-Scan bleibt als deterministischer Oracle-Pfad erhalten und wird bei
  Erstaufbau, Terrainrevision oder explizitem Force genutzt.

## Akzeptanz

- Eine Bewegung um eine Grid-Zelle verarbeitet weniger Kandidaten als die ganze
  128x128-Karte und arbeitet in begrenzten Scheiben.
- Die vorangehende Sichtrevision bleibt sichtbar, bis die neue Revision komplett
  ist; danach entspricht sie dem Full-Scan-Oracle bitgenau.
- Sichtdelta dokumentiert Revision, geaenderte Tiles, Dirty-Chunks, LOS-Paare
  und verarbeitete Tiles.
- Reine FOW-Deltas erzeugen keine Unit-Proxies, Orders oder Drops neu.
- 128x128 bleibt pro Dirty-Anfrage unter 16,7 ms, 256x256 unter 33,3 ms;
  mit dem 100-ms-Updateintervall ist die atomare Sicht innerhalb von 350 ms
  publiziert.
- Der taktische Missionsharness haelt `terrain.fow_work_usec` bei p99 <= 2 ms.

## Verifikation

```powershell
godot_console.exe --headless --path . --script scripts/tests/task_1189_fow_dirty_region_fanout.gd
godot_console.exe --headless --path . --script scripts/tests/task_224_fog_of_war_tile_visibility_height_cover_runtime.gd
godot_console.exe --headless --path . --script scripts/tests/task_225_fog_of_war_2_5d_visual_overlay_and_contacts.gd
godot_console.exe --headless --path . --script scripts/tests/task_1187_tactical_map_frame_budget.gd -- --task1187-fast
git diff --check
```

## Umsetzung

- Der Dirty-Pfad plant Candidate-Regionen nur noch konstant und durchlaeuft
  Lookup sowie Sichtauswertung in getrennten, begrenzten Scheiben. Er sortiert
  weder die gesamte Karte noch die gesammelten Kandidaten; die Reihenfolge ist
  durch Observer-ID, alten/neuen Bereich und Grid-Lauf stabil.
- `FogOfWarSystem` publiziert `visibility_revision` und `visibility_delta`
  ausserhalb der normalisierten Gameplay-Contract-Felder. Das Delta bleibt
  damit Render-Metadaten und keine zweite Sichtwahrheit.
- `TerrainMap3DView` reserviert einen festen, farbigen MultiMesh-Slot pro
  gerendertem Tile. Deltas aendern nur die betroffenen Instanzen. Ein
  Full-Aufbau laeuft in 512-Instanz-Scheiben hinter einer schwarzen
  Sicherheitsabdeckung, bis der neue Zustand vollstaendig ist.
- Der reine FOW-Pfad aktualisiert die Sichtbarkeit vorhandener Unit-Proxies
  gezielt und laeuft nicht durch deren Visual-/Animations-Synchronisation.

## Lokale Ergebnisse

- TASK_1189: 25/25. Der 128x128-Fall misst 1,85 ms fuer die Dirty-Anfrage und
  5,83 ms pro Slice; 256x256 misst 4,16 ms und 5,58 ms. Beide Faelle
  publizieren nach 350 ms oder frueher.
- TASK_224: 25/25; TASK_225: 34/34; TASK_1188: 31/31.
- TASK_1187-Schnellvertrag: 0 Fehler, `terrain.fow_work_usec` p99 1,816 ms
  gegen 2 ms Budget. Weitere bereits bekannte Harness-Budgets bleiben als
  Messwerte markiert und sind nicht Teil dieses FOW-Slices.
