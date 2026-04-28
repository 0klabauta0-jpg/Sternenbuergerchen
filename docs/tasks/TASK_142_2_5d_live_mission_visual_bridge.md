# TASK_142 - 2.5D Live Mission Visual Bridge

## Ziel
Die echte Missions-Testszene rendert dieselbe autoritative Missionskarte zusaetzlich mit 2.5D/3D-Visuals, ohne `SimulationRoot`, Navigation, Combat oder den bestehenden 2D-Spielpfad umzubauen.

## Status: IMPLEMENTIERT

## Kontext
- TASK_133/134 haben den 3D-Renderer als Spike bewiesen.
- TASK_135-141 haben Hoehen, Floor-Kontext, Picking und Air-Layer als Daten-/Simulationsgrundlage eingefuehrt.
- Der alte 2D-Iso-Pfad ist noch der praktisch spielbare Stand. Dieser Task soll die 2.5D-Darstellung in die Live-Missions-Testszene bringen, aber noch nicht zur einzigen Wahrheit machen.

## Umfang
1. `mission_fireteam_dev_test.tscn` oder eine klar benannte Live-Testvariante erhaelt eine optionale 2.5D/3D-Visual-Schicht.
2. Die 2.5D-Schicht rendert dieselbe `TerrainMapData`/Registry-Basis wie die 2D-Mission.
3. Der bestehende 2D-Renderer bleibt als Fallback oder Vergleich aktivierbar.
4. Kamera/Lighting/Render-Root werden so verdrahtet, dass die Szene direkt visuell pruefbar ist.
5. Ein Verifier prueft, dass die Live-Mission 2.5D-Terrain und Objekt-Instanzen aus derselben Karte erzeugt.

## Nicht-Ziele
- Keine Umstellung der Simulation auf 3D-Koordinaten.
- Keine Unit-Height-Synchronisierung; das ist TASK_143.
- Keine Editor-Smoke-Test-Kette; das ist TASK_144.
- Keine neue Gameplay-Logik.

## Umsetzung
- `MissionLive25DVisualBridge` rendert als rein lesende Node3D-Schicht die geladene Live-Missionskarte ueber `TerrainMap3DRenderer`.
- `mission_reactivity_test.tscn` enthaelt die Bridge direkt; `mission_fireteam_dev_test.tscn` erbt sie ueber seine Instanz.
- Die Bridge liest `TerrainMapData` aus `MissionTestSetup`, vergleicht Tile-Anzahl mit `TerrainRegistry` und stellt einen Snapshot fuer Verifier/Debug bereit.
- Die 2D-Map bleibt standardmaessig sichtbar; sie kann ueber `hide_2d_map_when_visible` als Fallback/Compare-Pfad umgeschaltet werden.
- Kamera, Licht, `MapRoot3D/Terrain3D` und `MapRoot3D/Object3D` werden automatisch erzeugt.

## Akzeptanzkriterien
- [x] Live-Missions-Testszene kann mit 2.5D/3D-Visual-Layer gestartet werden.
- [x] 2.5D-Layer nutzt dieselbe Kartenquelle wie die Missionssimulation.
- [x] Boden- und Objektlayer bleiben visuell getrennt.
- [x] Bestehende Simulation/Command-Verarbeitung bleibt unveraendert lauffaehig.
- [x] Verifier prueft Live-Bridge ohne manuelle Editor-Schritte.

## Risiken
- Doppelte Darstellung kann verwirren, wenn 2D und 2.5D gleichzeitig sichtbar sind. Deshalb braucht der Task klare Toggle-/Fallback-Regeln.
- Wenn die Live-Mission eigene Setup-Glue-Pfade hat, darf die 2.5D-Schicht diese nicht zur neuen Gameplay-Wahrheit machen.
