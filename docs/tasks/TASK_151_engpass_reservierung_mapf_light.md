# TASK_151 - Engpass-Reservierung und MAPF-Light

## Ziel
Engpaesse sollen deterministisch aufgeloest werden, wenn lokale Avoidance nicht reicht. Statt vollstaendiges CBS/ICBS als Standardpfadfinder einzufuehren, entsteht eine kleine Eskalationsschicht fuer Portale, Korridore und Bottlenecks.

## Status: IMPLEMENTIERT

## Voraussetzung
- `TASK_128 - Navigation Budgeting und Debug`
- `TASK_130 - Lokale Unit-Avoidance mit ORCA/RVO-Light`
- `TASK_131 - Navigation Benchmark Harness`

## Kontext
- ORCA/RVO-Light glaettet offene Bewegungen, entscheidet aber keine Reihenfolge in engen Durchgaengen.
- CBS/ICBS ist deterministisch und stark fuer MAPF, kann aber bei hoher Konfliktdichte exponentiell werden.
- Unser HPA-Graph kennt bereits Cluster und Portale, also sind Engpaesse als kleine lokale Problemraeume greifbar.

## Umfang
1. Engpass-Kandidaten erkennen:
   - HPA-Portale.
   - schmale Korridore.
   - wiederholte `local_avoidance_repath_requested`-/Deadlock-Markierungen.
2. Kleine Reservierungslogik einfuehren:
   - Zeitfenster pro Portal-/Engpasszelle.
   - deterministische Prioritaet nach Command-Prioritaet, Fireteam/Unit-ID und Queue-Reihenfolge.
   - Warte-/Durchlassentscheidung als Command-Metadaten.
3. MAPF-Light statt vollem CBS:
   - V1 nur fuer kleine Agentengruppen und kurze Horizonte.
   - Konfliktarten: gleiche Zelle/Zeit und Gegenverkehr ueber dieselbe Kante.
   - keine optimale globale Loesung erzwingen.
4. Debug:
   - reservierte Portalzellen.
   - wartende Units.
   - Konfliktgrund.
   - Eskalations-/Fallbackgrund.
5. Anbindung:
   - `SimulationRoot` bleibt autoritativ.
   - Avoidance bleibt lokale Korrektur.
   - Reservierung darf nur Bewegung verzögern oder lokale Ziele staffeln.

## Nicht-Ziele
- Kein vollstaendiger CBS/ICBS-Algorithmus fuer alle Units.
- Kein C++/GDExtension-Port in diesem Slice.
- Kein Ersatz fuer HPA/A*.
- Keine Formation-Slot-Swap-Logik.

## Architekturregeln
- Engpass-Entscheidungen laufen nicht in UI/Visualizer.
- Keine SceneTree-Vollscans; Units kommen ueber `UnitRegistry`.
- Debug bleibt lesend und abschaltbar.

## Akzeptanzkriterien
- [x] Zwei Gruppen im Korridor erzeugen eine deterministische Durchlassreihenfolge.
- [x] Deadlock aus lokaler Avoidance wird markiert und in eine Reservierungsentscheidung uebersetzt.
- [x] Units werden nicht auf nicht-walkable Tiles verschoben.
- [x] Debug-Snapshot nennt Portal/Engpass, wartende Units und Konfliktgrund.
- [x] Movement-, HPA- und Avoidance-Tests bleiben gruen.

## Erwartetes Ergebnis
Engpaesse bekommen eine kleine, nachvollziehbare "Ampel", ohne die gesamte Navigation auf teures MAPF umzustellen.

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_151_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_131_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_130_verifier.gd`

## Dateien (voraussichtlich)
- `scripts/tactical/bottleneck_reservation_resolver.gd`
- `scripts/core/simulation_root.gd`
- `scripts/tests/task_151_verifier.gd`

## Risiken
- Zu aggressive Reservierung kann Bewegung steif wirken lassen. Die Schicht muss nur bei echten Engpaessen/Deadlocks greifen.

## Umsetzung
- `BottleneckReservationResolver` erzeugt Kandidaten aus HPA-Portalen, schmalen Korridorzellen oder expliziten Bottleneck-Zellen.
- Der Resolver plant kurze Zeitfenster fuer kleine Agentengruppen, prueft gleiche Zelle/Zeit sowie Gegenverkehr ueber dieselbe Kante und sortiert deterministisch nach Prioritaet, Fireteam-ID, Unit-ID und Queue-Reihenfolge.
- `SimulationRoot` besitzt eine optionale, ausgeschaltete Bottleneck-Reservation-Anbindung fuer Command-Metadaten und Debug-Snapshot. Die Runtime bewegt dadurch keine Unit direkt und ersetzt weder HPA/A* noch lokale Avoidance.
- `scripts/tests/task_151_verifier.gd` deckt Korridorreihenfolge, Gegenverkehr, Deadlock-Metadaten, nicht-walkable Kandidaten, Portal-Kandidaten, Debug und Doku-Status ab.
