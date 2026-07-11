# TASK_1091 - Connected Station Route Two-Player Command Playtest

## Ziel / Problem
TASK_1090 zeigt zwei korrekte Alpha-/Bravo-Perspektiven, der sichtbare Capture startet aber weiterhin zwei unabhaengige Missionen. Door, Computer und Cargo muessen einmal ueber eine echte lokale ENet-Verbindung mit getrenntem Fireteam-Besitz, Host-Commit und Client-Snapshot durchlaufen werden.

## Ursache / Sinnhaftigkeit
TASK_1083 beweist den echten RPC-Rundweg nur fuer ROE. TASK_714 beweist die Station-Route-Autoritaet nur in einer einzelnen SimulationRoot-Instanz. Erst die Verbindung beider Pfade belegt, dass der kleine Multiplayer-Slice nicht nur getrennt aussieht, sondern dieselbe autoritative Missionsfolge spielt.

## Design / Umfang
- Zwei Mission-Instanzen laufen in getrennten lokalen `MultiplayerAPI`-Subtrees ueber ein echtes ENet-Paar.
- Der Host besitzt Station-Route-Runtime, Objective-Gates und Interaction-State.
- Peer-/Team-/Fireteam-Zuordnung bleibt bei `SimulationRoot` und `MultiplayerCommandContract`.
- Der Client sendet bestehende Commander-/Interaction-Commands per RPC und setzt vor Host-Commit keinen Runtime-State.
- Der Verifier setzt autoritativen Arrival-/Hold-Abschluss ueber den vorhandenen Combat-Driver, statt eine zweite Test-Wahrheit einzufuehren.
- Nach dem Host-Commit repliziert der bestehende Snapshot den autoritativen Zustand zum Client.
- Wrong-Team-/Wrong-Fireteam-Grenzen bleiben durch TASK_714 und TASK_1083 regressionsgesichert.

## Nicht-Ziele
- Kein Lobby-, NAT-, Matchmaking- oder Internet-Test.
- Kein neuer Netzwerktransport und keine zweite Interaction- oder Mission-Wahrheit.
- Kein automatischer visueller Spielerentscheid; der Verifier prueft Runtime- und Feedbackvertraege.
- Kein Umbau des kompletten Missionscontrollers.

## Akzeptanzkriterien
- Ein echtes lokales ENet-Paar verbindet Host und Client.
- Der Client-Command erreicht den Host ueber RPC und mutiert vorher weder Client- noch Host-Runtime.
- Own-Fireteam-Door-Command wird ueber echte RPC vom Host akzeptiert; fremde Fireteam-/Team-Commands bleiben in den Authority-Regressionen abgewiesen.
- Door-Open wird erst durch autoritativen Runtime-Progress wirksam und repliziert.
- Computer-Control folgt Door/AA und repliziert, ohne das Cargo-Gate zu ueberspringen.
- Cargo-Departed schliesst die Route autoritativ ab und ist auf dem Client lesbar.
- Snapshot-Apply erzeugt auf dem Client keine Gameplay-Commands.
- TASK_1082, TASK_1083, TASK_714 und TASK_1090 bleiben gruen.

## Betroffene Dateien
- `scripts/tests/task_1091_connected_station_route_two_player_command_playtest.gd`
- bestehende Multiplayer-/Interaction-Pfade nur bei einem im roten Test belegten fehlenden Handoff
- `docs/dev/mission_interaction_point_contract.md`
- Status-, Roadmap- und HTML-Handbuchbericht

## Lokale Pruefung
- TASK_1091 Red/Green
- TASK_1082, TASK_1083, TASK_714, TASK_1090
- HTML-Inline-JavaScript und `git diff --check`
- Godot-4.6.2-Export plus Provenance-Startcheck nach Integration

## Risiken / offene Punkte
Lokales ENet prueft echte RPC-/Snapshot-Grenzen, aber keine Internetlatenz oder NAT. Zwei gleichzeitig geladene 64x64-Station-Renderwelten loesen unter Godot 4.6.1 in Headless-Fog-/Terrain-Callbacks einen Engine-Crash aus; der Contracttest nutzt deshalb die stabile kompakte Missionsfixture und laedt den echten Station-Route-Gate-Contract separat. Die Station-Route-Szenariodaten modellieren Bravo weiterhin als gegnerische Gruppen.

## Ergebnis
- 17/17: Client-Door-Payload erreicht den Host ueber echte ENet-RPC.
- Vor Host-Verarbeitung mutiert weder die Host- noch die Client-Interaction-Runtime.
- `mission_interactions` wird sanitisiert, read-only und deterministisch im Authority-Snapshot transportiert.
- Door, Computer, Cargo und das vollstaendige Objective-Gate werden auf dem Client gespiegelt.
- Snapshot-Apply erzeugt keinen Client-Command.
- Naechster sinnvoller Slice: TASK_1092 - Connected Station Route Runtime Arrival/Hold Integration. Der echte Bewegungs-/Aufenthaltspfad soll die Host-Interaktionen ohne direkte Verifier-Fortschrittsaufrufe abschliessen.
