# TASK_411 Large Map Scale Profile Report

Stand: 2026-05-14

## Ziel

Dieser Bericht bewertet 128x128- und 256x256-Karten als naechste Skalierungsziele. Die Profilkarten werden in-memory erzeugt und mischen Ground/Sand/Rock/Road, Hoeheninseln, Slopes/Cliffs, Nature-Props, Station-/Modular-Zonen, FoW und eine kleine Runtime-Unit-Navigation.

## Lokaler Headless-Befund

| Profil | Tiles | HPA-Cluster | HPA-Build | HPA-Portale | FoW-Scan | Fixture-Build | Ergebnis |
|---|---:|---:|---:|---:|---:|---:|---|
| 128x128 | 16384 | 256 | 649 ms | 10506 | 90 ms | 174 ms | Logik gruen |
| 256x256 | 65536 | 1024 | 3964 ms | 43308 | 628 ms | 899 ms | Logik gruen |

Die Werte stammen aus einem lokalen Headless-Lauf und sind maschinenabhaengig. Sie sind Startwerte fuer Skalierungsentscheidungen, keine finalen Produktionsbudgets.

## HPA-Fix

Der erste 128/256-Profilversuch hat einen HPA-Hotspot sichtbar gemacht: Portale wurden bei jedem Insert neu sortiert. TASK_411 verschiebt diese Sortierung ans Build-Ende und sortiert anschliessend die Portal-Buckets. Danach laeuft der 128/256-Logikprofil-Smoke in Sekunden statt in den Headless-Timeout.

## Render-Grenze

Der 256x256-Full-Render-Probe wurde nicht in das automatisierte Gate aufgenommen. Ein erster headless Full-Render-Lauf blockierte den Test bis zum 10-Minuten-Timeout. Deshalb gilt:

- 64x64 bleibt der automatisiert voll gerenderte sichere Bereich.
- 128x128 und 256x256 sind fuer Terrain-Logik, HPA, FoW und kurze Runtime-Navigation strukturell gruen.
- Grosse Full-Render-Maps brauchen als naechsten Schritt echtes Viewport-Profiling, Chunk-Sichtbarkeit oder Streaming/Regionen.

## TASK_412 Nachtrag - Visual Streaming

TASK_412 schliesst den ersten Render-Engpass strukturell: `TerrainMap3DView` aktiviert oberhalb von 4096 Tiles automatisches Visual-Streaming. Die Datenkarte bleibt vollstaendig, aber der 3D-View rendert nur aktive 8x8-Chunk-Fenster um den Kamerafokus. Der neue Snapshot unterscheidet `total_tile_count` und `rendered_tile_count` und meldet aktive Chunks, uebersprungene Tiles und Streaming-Refreshes.

Der lokale Headless-Gate rendert eine 128x128-Karte mit Streaming, ohne in den frueheren Full-Render-Timeout zu laufen. Kamerafokus-Wechsel ueber Chunk-Grenzen erzeugen einen gezielten Visual-Refresh. Damit ist 128x128 als naechste echte Playtest-Groesse deutlich realistischer; 256x256 bleibt fuer die Logik gruen, braucht als voll sichtbare Missionskarte aber weiterhin einen echten Godot-Fenster-/Visual-Profiler-Lauf.

## TASK_412 Nachtrag - HPA Dirty Cluster

`TerrainRegistry` trackt Dirty-Grids, und `HPANavigationGraph` kann geaenderte Cluster plus angrenzende Portal-Cluster inkrementell rebuilden. `SimulationRoot` ersetzt bei gleicher Registry und gleicher Tile-Anzahl den HPA-Graphen nicht mehr pauschal, sondern repariert den vorhandenen Graphen und markiert die Runtime-Diagnose mit `runtime_rebuild_mode = incremental`.

## Interpretation

256x256 ist als logische Missionskarte nach TASK_411/TASK_412 erreichbar. Als voll aktive, komplett sichtbare Karte ist 256x256 noch nicht freigegeben. Die naechste harte Grenze liegt jetzt weniger im HPA-Graphen und mehr in echter Viewport-/Editor-Interaktion, Materials, Draw Calls, Labels und Overlay-Dichte.

## TASK_1193 Release-Kandidatengrenze

Die groesste automatisiert unterstuetzte Release-Kandidatenkarte ist `128x128`.
Diese Entscheidung stuetzt sich auf die vorhandene Logik-/Streaming-Evidenz,
ist aber keine automatische Fensterfreigabe: Ein echter FullHD-Spieltest muss
LZ, ersten Move, ersten Contact, ersten Fire-Event und Kamera-/Overlay-Wechsel
auf demselben Git-SHA belegen. `256x256` bleibt bis zu einem separaten
Viewport-/Visual-Profiler- und Spielercheck von der Release-Freigabe
ausgeschlossen.

## Naechster Schritt

Vor echten 256x256-Content-Maps:

1. 128x128 als erste grosse Playtest-Zielkarte im echten Godot-Fenster nutzen.
2. Editor-Overlays und Labels fuer grosse Karten hart cappen oder on-demand zeichnen, falls der Sichtcheck stockt.
3. 256x256 mit aktivem Streaming und Visual Profiler gegen Draw Calls, Materials und Interaktion messen.
4. 256x256 erst nach Viewport-/Profiler-Sichtcheck als voll spielbare Karte freigeben.
