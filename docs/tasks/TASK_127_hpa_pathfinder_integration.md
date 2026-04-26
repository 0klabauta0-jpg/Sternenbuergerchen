# TASK_127 - HPA Pathfinder Integration

## Ziel
Die eigentliche Pfadfindung soll lange oder teure Routen ueber den HPA-Graphen planen, statt immer direkt globales Tile-A* ueber die gesamte TerrainRegistry zu starten.

## Status: GEPLANT

## Voraussetzung
- `TASK_126 - HPA Navigation Foundation`

## Kontext
- `TASK_126` liefert Cluster, Portale und abstrakte Nachbarschaften.
- `SimulationRoot` baut aktuell in `_build_path_world_points()` direkt Tile-Pfade ueber `TerrainPathfinder`.
- Besonders riskant ist der Fallback bei unerreichbaren Zielen, weil dort viele Kandidaten mit wiederholtem A* getestet werden koennen.

## Umfang
1. Neuen Pathfinder einfuehren, z.B. `scripts/terrain/hpa_pathfinder.gd`.
2. HPA-Pfadquery implementieren:
   - Start-/Zielcluster bestimmen
   - kurze Wege innerhalb desselben Clusters weiterhin direkt mit lokalem A*
   - bei mehreren Clustern abstrakten Portalpfad suchen
   - lokale Teilpfade zwischen Start, Portalen und Ziel zusammensetzen
3. Ergebnis als `path_world_points` kompatibel zum bestehenden `SimulationRoot` liefern.
4. Unerreichbare Ziele frueh erkennen:
   - wenn Start/Ziel nicht verbunden sind, kein globaler Full-Map-Suchlauf
   - stabiler erreichbarer Fallback innerhalb Start-Komponente oder naechster sinnvoller Portalpunkt
5. Bestehende Zielauflosung beibehalten:
   - nicht-walkable Ziel -> `resolve_walkable_target()`
   - walkable Ersatz-Ziel bleibt deterministisch
6. `SimulationRoot` nutzt HPA nur, wenn ein valider HPA-Graph verfuegbar ist.
7. Fallback auf bisherigen `TerrainPathfinder`, falls Graph fehlt oder Query fehlschlaegt.

## Nicht-Ziele
- Keine neue Bewegungsphysik.
- Keine Kollisionsvermeidung zwischen Units.
- Keine Flow-Field-Implementierung.
- Keine dynamischen Kartenupdates.
- Keine Godot NavigationServer-Integration.

## Architekturregeln
- `SimulationRoot` bleibt autoritative Stelle fuer Bewegung.
- HPA liefert nur Pfadpunkte; es committed keinen Unit-State.
- Bestehende Terrain-/Walkability-Regeln muessen identisch bleiben.
- Kein Pfad-Query darf im UI entstehen.

## Akzeptanzkriterien
- [ ] Same-Cluster-Wege funktionieren weiter.
- [ ] Multi-Cluster-Wege liefern gueltige Pfade ueber Portale.
- [ ] Blocker werden nicht betreten.
- [ ] Diagonal-Bewegung bleibt erlaubt, ohne Corner-Cutting.
- [ ] Unerreichbare Ziele erzeugen keinen teuren Full-Map-Fallback.
- [ ] `SimulationRoot` kann HPA-Pfade ausfuehren.
- [ ] Bestehende TASK_125-Rock-/Walkability-Tests bleiben gruen.

## Erwartetes Ergebnis
- Lange Pfade laufen ueber eine hierarchische Route.
- Die Kosten fuer grosse Karten sinken, weil lokale A*-Suchen auf Clusterabschnitte begrenzt werden.
- Bisherige Movement-Kommandos bleiben im Verhalten kompatibel.

## Lokale Pruefung
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_127_verifier.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_125_verifier.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_110_verifier.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/path_recompute_under_fire_verifier.gd`

## Dateien (voraussichtlich)
- `scripts/terrain/hpa_pathfinder.gd`
- `scripts/terrain/hpa_navigation_graph.gd`
- `scripts/core/simulation_root.gd`
- `scripts/tests/task_127_verifier.gd`

## Risiken
- Zusammengesetzte Portalpfade koennen optisch kantig werden, wenn Portalwahl zu grob ist.
- Zu aggressiver Fallback kann Units an schlechten Zwischenzielen parken.
- Deshalb muss der Task bestehende Movement-Tests und Walkability-Tests unveraendert bestehen.
