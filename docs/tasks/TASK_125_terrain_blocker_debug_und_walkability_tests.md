# TASK_125 - Terrain Blocker Debug und Walkability Tests

## Ziel
Das beobachtete Haengenbleiben an Rocks soll reproduzierbar und testbar werden. Units duerfen nicht dauerhaft an nicht-walkable Terrain feststecken und sollen keine zufaelligen Spaet-Durchlaeufe durch Blocker zeigen.

## Status: OFFEN

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
- [ ] Verifier reproduziert ein blockiertes Rock-Ziel.
- [ ] Nicht-walkable Ziel wird stabil auf ein walkable Ersatz-Ziel gemappt.
- [ ] Fireteam-Move in Richtung Blocker bleibt nicht dauerhaft stecken.
- [ ] Units laufen nicht sichtbar durch Rock-Blocker.
- [ ] Debug-Ausgabe benennt Originalziel, Ersatz-Ziel und Blockergrund.

## Dateien (voraussichtlich)
- `scripts/terrain/terrain_registry.gd`
- `scripts/tactical/fireteam_movement_controller.gd`
- `scripts/core/simulation_root.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_125_verifier.gd`

## Risiken
- Wenn der aktuelle Move-Pfad nur Geradlinienbewegung nutzt, muss dieser Task klar zwischen kurzfristigem Ersatz-Ziel und spaeterem echtem Path-Follow trennen.

