# TASK_125 - Terrain Blocker Debug und Walkability Tests

## Ziel
Das beobachtete Haengenbleiben an Rocks soll reproduzierbar und testbar werden. Units duerfen nicht dauerhaft an nicht-walkable Terrain feststecken und sollen keine zufaelligen Spaet-Durchlaeufe durch Blocker zeigen.

## Status: IMPLEMENTIERT

## Kontext
- Die Architektur sieht A*-Navigation ueber Iso-Grid, Walkability, Hoehenunterschiede und Surface-Kosten vor.
- Es gibt bereits TerrainRegistry-/walkable-Replacement-Tests im Fireteam-Dev-Testing.
- Live-Beobachtung: NPCs bleiben erst an Rocks haengen und laufen spaeter teilweise hindurch.

## Umfang
1. Einen gezielten Debug-/Verifier-Fall fuer Rocks und andere Blocker bauen.
2. Pruefen, ob Zielpunkte auf nicht-walkable Tiles korrekt auf nahe walkable Tiles verschoben werden.
3. Pruefen, ob Movement-Kommandos bei Blocker-Kollisionen stabile Ausweichziele erhalten.
4. Sichtbare Debug-Option fuer V1:
   - walkable Zieltile
   - geblocktes Zieltile
   - Ersatz-Ziel
5. Ursache dokumentieren:
   - falsches Tile-Snapping
   - fehlender Path-Follow
   - SimulationRoot-Move laeuft als Gerade
   - TerrainRegistry liefert unstabile Ersatztiles

## Nicht-Ziele
- Kein kompletter neuer Navigation-Stack.
- Keine Physics-basierte Kollisionssimulation.
- Keine grosse Map-Editor-Ueberarbeitung.

## Architekturregeln
- Terrain-Wahrheit liegt bei Terrain-/Registry-Daten, nicht im UI.
- Movement bleibt ueber `SimulationRoot` autoritativ.
- Debug-Overlay ist rein lesend und abschaltbar.

## Akzeptanzkriterien
- [x] Verifier reproduziert ein blockiertes Rock-Ziel.
- [x] Nicht-walkable Ziel wird stabil auf ein walkable Ersatz-Ziel gemappt.
- [x] Fireteam-Move in Richtung Blocker bleibt nicht dauerhaft stecken.
- [x] Units laufen nicht sichtbar durch Rock-Blocker.
- [x] Debug-Ausgabe benennt Originalziel, Ersatz-Ziel und Blockergrund.

## Ergebnis
- `TerrainRegistry.resolve_walkable_target()` liefert jetzt fuer Zielpunkte ein stabiles Ergebnis mit Originalziel, Walkability, geblocktem Tile, Ersatz-Ziel und Blockergrund.
- `get_nearest_walkable_grid()` sortiert Kandidaten deterministisch nach Distanz und Grid-Koordinaten, damit Ersatztiles bei Gleichstand nicht zufaellig wechseln.
- `SimulationRoot` ersetzt nicht-walkable Move-Ziele vor dem Pfadbau durch walkable Ersatz-Ziele und faellt bei nicht erreichbaren Zielen nicht mehr auf eine direkte Gerade durch Blocker zurueck.
- Wenn kein Pfad zum gewuenschten Ziel existiert, wird ein stabiler erreichbarer walkable Fallback gewaehlt; wenn auch das nicht moeglich ist, bleibt der Move ohne Tunnel-Fallback leer.
- Eine abschaltbare Terrain-Move-Debugspur in `SimulationRoot` und ein lesbarer Sandbox-Text nennen Originalziel, Ersatz-Ziel, finales Ziel und Grund.

## Ursache / Befund
- Das beobachtete Verhalten passte zu einer Kombination aus Zielpunkten auf nicht-walkable Tiles, unstabilen Ersatzkandidaten und einem frueheren direkten Move-Fallback, wenn A* keinen Pfad fand.
- Der Fix trennt deshalb Zielauflosung, Pfadfindung und Fallback: TerrainRegistry bestimmt den walkable Zielersatz, SimulationRoot akzeptiert nur Pfade oder stabile erreichbare Ersatzpunkte.

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_125_verifier.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_121_verifier.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_122_verifier.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_123_verifier.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_124_verifier.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_110_verifier.gd`
- `godot_console.exe --headless --path . --script scripts/tests/path_recompute_under_fire_verifier.gd`
- `godot_console.exe --headless --path . --script scripts/tests/fireteam_dev_testing_verifier.gd`

## Dateien (voraussichtlich)
- `scripts/terrain/terrain_registry.gd`
- `scripts/tactical/fireteam_movement_controller.gd`
- `scripts/core/simulation_root.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_125_verifier.gd`

## Risiken
- Wenn der aktuelle Move-Pfad nur Geradlinienbewegung nutzt, muss dieser Task klar zwischen kurzfristigem Ersatz-Ziel und spaeterem echtem Path-Follow trennen.
- V1 bleibt bewusst konservativ: nicht erreichbare Ziele werden nicht erzwungen, sondern auf den naechsten stabil erreichbaren walkable Punkt reduziert.
