# TASK_137 - 2.5D Height-Aware Navigation

## Ziel
Navigation um kontrollierte Hoehenwechsel erweitern: Units duerfen erhoehte Flaechen, Rampen, Treppen oder Stege nutzen, aber keine vertikalen Spruenge durch reine Nachbarschaft im Grid machen.

## Status: IMPLEMENTIERT

## Kontext
- HPA/A* ist bereits autoritativ im Move-Pfad integriert.
- Hoehenstufen existierten frueher als einfache Terrain-Regel; 2.5D braucht jetzt explizite Transition-Daten statt impliziter Spruenge.

## Umfang
1. Terrain-Datenvertrag um `height_transition_type` oder explizite `height_links` vorbereiten.
2. `TerrainPathfinder`-Step-Pruefung um Hoehenwechselregeln erweitern:
   - gleiche Ebene frei
   - kleine Stufe nur bei erlaubter Slope/Transition
   - grosse Stufe blockiert
3. HPA-Graph und Portalbildung mit denselben Regeln betreiben.
4. Pfadkosten fuer Rampen/Treppen leicht erhoehen.
5. Debug-Snapshot fuer geblockte Hoehenschritte und genutzte Transitions.

## Nicht-Ziele
- Keine mehrstoeckigen Innenraeume.
- Keine Flugnavigation.
- Keine animierten Treppen-/Leitersequenzen.
- Keine Full-3D-Navmesh-Umstellung.

## Akzeptanzkriterien
- [x] Pfade bleiben auf gleicher Hoehe unveraendert stabil.
- [x] Unerlaubte Hoehenspruenge werden blockiert.
- [x] Erlaubte Rampen-/Treppenverbindungen werden genutzt.
- [x] HPA und direkter Pathfinder liefern konsistente Traversal-Regeln.
- [x] Verifier deckt gleiche Ebene, erlaubte Transition und blockierten Sprung ab.

## Umsetzung
- `TerrainTileData` und Map-/Catalog-Serialisierung fuehren `height_transition_type` mit den Werten `none`, `ramp` und `stairs`.
- `TerrainPathfinder` prueft Hoehenwechsel zentral ueber einen Traversal-Snapshot: gleiche Hoehe ist frei, kleine Hoehenschritte brauchen Rampen/Treppen, grosse Schritte bleiben blockiert.
- `HPANavigationGraph` nutzt dieselbe `can_traverse_step`-Logik automatisch fuer Komponenten und Portale.
- `SimulationRoot` bleibt unveraendert auf dem HPA-/TerrainPathfinder-Pfad und bekommt damit dieselben Hoehenregeln.

## Lokale Checks
- `godot_console.exe --headless --path . --script scripts/tests/task_137_verifier.gd`

## Risiken
- Zu strikte Regeln koennen alte Karten unpassierbar machen; Legacy-Defaults muessen flache Karten unveraendert halten.
- HPA-Portale koennen bei Hoehenkanten zu duenn werden; Debugdaten muessen das sichtbar machen.
