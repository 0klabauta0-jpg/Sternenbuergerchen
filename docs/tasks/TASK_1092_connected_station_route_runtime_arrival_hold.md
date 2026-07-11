# TASK_1092 - Connected Station Route Runtime Arrival Hold

## Ziel / Problem
TASK_1091 repliziert fertige Stationsinteraktionen, schliesst den Host-Fortschritt im Verifier aber direkt ueber den Combat-Driver ab. Ein akzeptierter Client-Interaction-Command muss durch echte autoritative Unit-Ankunft und Hold-Zeit in denselben Progress-Pfad gelangen.

## Ursache / Sinnhaftigkeit
`SimulationRoot` akzeptiert und bewegt Netzwerk-Commands, waehrend der bisherige Interaction-Progress nur Controller-Waypoints mit lokalen Metadaten beobachtet. Dadurch kann ein echter Client zwar zur Door laufen, der Host weiss aber nicht, dass diese Bewegung eine Door-Interaction abschliessen soll.

## Umfang
- Akzeptierte Network-Commands werden auf dem Host als Signal publiziert.
- `MissionCombatLoopDriver` registriert nur sanitisiert akzeptierte Mission-Interaction-Commands.
- Autoritative Unit-Position, Zielradius und Tick-Delta bestimmen Arrival und Hold.
- Fortschritt laeuft weiter ueber `update_mission_interaction_runtime_progress()`.
- Der bestehende TASK-1091-Snapshot repliziert das Ergebnis.

## Nicht-Ziele
- Kein neuer Bewegungspfad, kein Client-Timer und keine UI-Wahrheit.
- Kein Lobby-/Internet-/NAT-Test.
- Kein Umbau lokaler Controller-Waypoints.

## Akzeptanzkriterien
- Ein Client-Door-Command wird per ENet vom Host akzeptiert.
- Vor Ankunft entsteht kein abgeschlossener Interaction-State.
- Autoritative Unit-Ankunft und zwei Sekunden Host-Ticks schliessen Door ab.
- Der Client spiegelt Door-Complete ohne eigenen Command.
- Fremde oder abgewiesene Commands registrieren keinen Pending-Interaction-State.
- TASK_1091, TASK_1083 und TASK_714 bleiben gruen.

## Betroffene Dateien
- `scripts/core/simulation_root.gd`
- `scripts/mission/mission_interaction_door_multiplayer_authority.gd`
- `scripts/tests/mission_combat_loop_driver.gd`
- `scripts/tests/task_1092_connected_station_route_runtime_arrival_hold.gd`
- Interaction-Contract, Status, Roadmap und HTML-Bericht

## Lokale Pruefung
- TASK_1092 Red/Green
- TASK_1091, TASK_1083, TASK_714
- `git diff --check`, HTML-Inline-JavaScript
- Godot-4.6.2-Export und Provenance-Startcheck nach Integration

## Risiken / offene Punkte
Der erste Slice belegt Door-Arrival/Hold. Computer und Cargo brauchen als naechstes eine neutrale Network-Interaction-Projektion und danach einen vollstaendigen verbundenen Route-Trace mit ihren echten 18-/12-Sekunden-Holds.

## Ergebnis
- 15/15: echter Client-Door-Command, Host-Accept, autoritative Ankunft, Hold-Abbruch/Reset, zwei Sekunden Hold und Client-Replikation.
- Vor Ankunft bleibt Door unvollstaendig.
- Der Host rekonstruiert Interaction-Progress nur aus validiertem Command, registrierter Unit, Zielradius und autoritativem Tick-Delta.
- Ein Wrong-Team-Command wird abgewiesen und erzeugt keinen Pending-Interaction-State.
- Der volle lokale Route-Trace deckte einen fruehen `MultiplayerAPI == null`-Zugriff auf; der lokale Team-Resolver faellt waehrend SceneTree-Aufbau nun sicher auf Review-/Friendly-Kontext zurueck.
- Naechster sinnvoller Slice: TASK_1093 - Connected Station Route Full Interaction Trace fuer AA, Door, Computer und Cargo ueber denselben Runtime-Pfad.
