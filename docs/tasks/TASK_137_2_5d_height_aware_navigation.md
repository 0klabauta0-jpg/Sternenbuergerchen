# TASK_137 - 2.5D Height-Aware Navigation

## Ziel
Navigation um kontrollierte Hoehenwechsel erweitern: Units duerfen erhoehte Flaechen, Rampen, Treppen oder Stege nutzen, aber keine vertikalen Spruenge durch reine Nachbarschaft im Grid machen.

## Status: GEPLANT

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
- [ ] Pfade bleiben auf gleicher Hoehe unveraendert stabil.
- [ ] Unerlaubte Hoehenspruenge werden blockiert.
- [ ] Erlaubte Rampen-/Treppenverbindungen werden genutzt.
- [ ] HPA und direkter Pathfinder liefern konsistente Traversal-Regeln.
- [ ] Verifier deckt gleiche Ebene, erlaubte Transition und blockierten Sprung ab.

## Risiken
- Zu strikte Regeln koennen alte Karten unpassierbar machen; Legacy-Defaults muessen flache Karten unveraendert halten.
- HPA-Portale koennen bei Hoehenkanten zu duenn werden; Debugdaten muessen das sichtbar machen.
