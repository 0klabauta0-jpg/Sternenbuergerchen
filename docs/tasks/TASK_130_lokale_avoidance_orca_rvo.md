# TASK_130 - Lokale Unit-Avoidance mit ORCA/RVO-Light

## Ziel
Nachdem globale Pfade deckungsbewusster und budgetiert sind, soll eine kleine lokale Avoidance-Schicht Units fluessiger aneinander vorbeifuehren. ORCA/RVO wird dabei nicht als neue Wegfindung eingefuehrt, sondern nur als lokale Geschwindigkeitskorrektur auf Basis des bestehenden autoritativen Move-Pfads.

## Status: IMPLEMENTIERT

## Voraussetzung
- `TASK_128 - Navigation Budgeting und Debug`
- `TASK_129 - Deckungsbewusste Pfade mit HPA und Subgoal-Vorbereitung`

## Kontext
- HPA/A* liefert globale Pfadpunkte.
- `FireteamMovementController` liefert Formation, Stages und taktische Wunschziele.
- `SimulationRoot` setzt Positionen autoritativ um.
- Lokale Avoidance soll nur verhindern, dass aktive Units sich sichtbar stapeln oder ineinander schieben.

## Umfang
1. Einen kleinen lokalen Avoidance-Resolver einfuehren:
   - V1 als deterministisches ORCA/RVO-Light oder Separation-Steering mit klarer Upgrade-Schnittstelle.
   - Nachbarn ueber spatial grid oder begrenzte Registry-Abfrage, keine SceneTree-Vollscans.
   - deterministisch sortierte Agenten/Nachbarn.
2. Integration unterhalb der Pfadfindung:
   - `SimulationRoot` berechnet weiter desired velocity zum naechsten Pathpoint.
   - Avoidance clippt oder verschiebt nur die lokale Velocity.
   - finale Positionsaenderung bleibt autoritativ.
3. Terrain-Sicherheit:
   - Avoidance darf keine Units auf nicht-walkable Tiles druecken.
   - Wenn lokale Korrektur blockiert ist, wird sie reduziert oder verworfen.
4. Deadlock-Waechter:
   - Stuck-Zeit, sehr niedrige Geschwindigkeit und wiederholte Gegenverkehr-Nachbarn erkennen.
   - V1-Eskalation klein halten: kurz stoppen, Prioritaet durchlassen oder Repath-Anfrage markieren.
5. Metriken und Tests:
   - Mindestabstand / Kollisionsrate.
   - mittlere Verzogerung.
   - Formationserror.
   - Stuck-/Deadlock-Zaehler.
   - CPU pro Tick.

## Nicht-Ziele
- Kein Ersatz fuer HPA/A*.
- Kein vollstaendiger RVO2-C++/GDExtension-Port in diesem Task.
- Kein NavigationServer2D-Umbau.
- Keine Physics-Kollisionen als Gameplay-Wahrheit.
- Keine Formation-Slot-Swap-Logik.
- Keine Massenschlacht-Optimierung fuer tausende Units im ersten Slice.

## Architekturregeln
- Lokale Avoidance kommt nach globaler Route und vor autoritativem Positions-Commit.
- Fireteam-Taktik bleibt im `FireteamMovementController`.
- Terrain-/Walkability-Wahrheit bleibt in `TerrainRegistry`.
- Debug ist rein lesend und abschaltbar.
- Keine UI-Callbacks mit Gameplay-State.

## Akzeptanzkriterien
- [x] Zwei kreuzende Fireteams vermeiden sichtbares Stapeln besser als ohne Avoidance.
- [x] Engpass-Test erzeugt keinen dauerhaften Deadlock ohne Debug-Markierung.
- [x] Avoidance bewegt keine Unit auf ein nicht-walkable Tile.
- [x] HPA-/Path-Follow-Verhalten bleibt erhalten.
- [x] Debug-Snapshot nennt Neighbor Count, Avoidance-Velocity, Stuck-Zeit und verworfene Korrekturen.
- [x] Bestehende Movement-, HPA-, Cover-aware- und Area-Tests bleiben gruen.

## Erwartetes Ergebnis
- Fireteam-Bewegung wirkt fluessiger, besonders wenn mehrere Units oder Fireteams kreuzen.
- Globale Routen bleiben taktisch sinnvoll und deckungsbewusst.
- ORCA/RVO bleibt eine lokale Korrekturschicht statt einer zweiten Navigation.

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_130_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_129_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_128_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_127_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_110_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/fireteam_dev_testing_verifier.gd`

## Dateien
- `scripts/core/simulation_root.gd`
- `scripts/tactical/local_avoidance_resolver.gd`
- `scripts/tests/task_130_verifier.gd`

## Ergebnis
- `LocalAvoidanceResolver` baut pro Tick einen deterministischen Spatial-Grid aus registrierten Units und liefert eine ORCA/RVO-Light-nahe lokale Separation-Velocity.
- `SimulationRoot` kann lokale Avoidance optional aktivieren und clippt damit nur die lokale Velocity zum naechsten Pathpoint; globale HPA-/A*-Pfade bleiben Quelle der Route.
- Terrain-Sicherheit verwirft Korrekturen, die auf nicht-walkable Tiles fuehren wuerden.
- Debug-Snapshot pro Unit zeigt Neighbor Count, Avoidance Velocity, Korrektur, Stuck-Zeit, Deadlock-Markierung und verworfene Korrekturen.

## Risiken
- Lokale Avoidance kann taktische Formationen verwischen, wenn sie zu stark eingreift.
- Ein unvollstaendiges ORCA kann in Engpaessen zittern; Deadlock-Metriken sind deshalb Pflicht.
- Ohne TASK_129 koennte Avoidance fluessig schlechte oder exponierte Routen ausfuehren. Deshalb kommt dieser Task nach cover-aware Pfadkosten.
