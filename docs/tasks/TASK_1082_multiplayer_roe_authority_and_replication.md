# TASK_1082 - Multiplayer ROE Authority And Replication

## Status: IMPLEMENTIERT

## Ziel / Problem

Die in TASK_1080/1081 wirksame und lesbare Feuerregel muss im Multiplayer denselben autoritativen Weg wie andere Gameplay-Befehle nehmen. Ein Client darf nur die ihm zugewiesenen Fireteams aendern; der Host committed die Regel und repliziert Regel, Revision und lesbare Konsequenz.

## Ursache / Sinnhaftigkeit

`MissionTacticalSandboxController.set_fireteams_fire_rule()` aktualisiert derzeit unmittelbar lokalen Controller-, Bewegungs- und UnitCommand-State. Der allgemeine Multiplayer-Command-Contract kennt Peer-/Team-/Fireteam-Rechte, aber noch keinen eigenen ROE-Command. Dadurch ist der lokale Buttonpfad nicht als echter Host-Commit belegt.

## Umfang

- Whitelisted `tactical_rule / set_fire_rule`-Command mit Team-, Fireteam- und Regelvalidierung.
- Autoritativer ROE-State inklusive monotoner Revision in `SimulationRoot`.
- Aufnahme des autoritativen ROE-State in den vorhandenen `tactical_rules`-Snapshot.
- Controller-Handoff: lokal nur nach akzeptiertem Authority-Commit anwenden; Client-Snapshot read-only uebernehmen.
- Regressionen fuer getrennte Peer-/Fireteam-Zuordnung und Snapshot-Replikation.

## Nicht-Ziele

- Kein Lobby- oder Rollen-Redesign.
- Kein Combat- oder ROE-Regel-Rewrite.
- Kein neuer paralleler Netzwerkkanal neben `SimulationRoot`.
- Keine UI als Gameplay-Wahrheit.

## Relevante Contracts

- `docs/ARCHITECTURE.md`
- `docs/dev/mission_command_feedback_contract.md`
- `scripts/multiplayer/multiplayer_command_contract.gd`
- `scripts/multiplayer/multiplayer_snapshot_contract.gd`
- `scripts/core/simulation_root.gd`

## Akzeptanzkriterien

- Ein Fireteam-Peer kann `set_fire_rule` fuer sein zugewiesenes Fireteam einreichen.
- Derselbe Peer kann kein anderes Fireteam desselben Teams aendern.
- Ungueltige Fire Rules und direkte Runtime-State-Felder werden abgewiesen.
- Erst die autoritative Command-Verarbeitung erhoeht die Revision und aendert den ROE-State.
- Der Client erhaelt den autoritativen State ueber `tactical_rules`, ohne Commands oder Effects einzureihen.
- Singleplayer behaelt ohne aktiven Netzwerk-Peer den vorhandenen unmittelbaren Runtime-Pfad.

## Betroffene Dateien

- `scripts/multiplayer/multiplayer_command_contract.gd`
- `scripts/core/simulation_root.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1082_multiplayer_roe_authority_replication.gd`
- Status-, Roadmap-, Contract- und HTML-Berichtsdokumentation

## Lokale Pruefung

- `task_1082_multiplayer_roe_authority_replication.gd`
- `task_1081_station_route_roe_consequence_readability.gd`
- `task_1080_station_route_live_fire_rule_propagation.gd`
- `task_607_two_instance_host_client_runtime_smoke.gd`
- `git diff --check`

## Risiken / offene Punkte

- Der Controller lebt historisch unter `scripts/tests/`; dieser Task verschiebt ihn nicht, sondern haertet nur seinen bestehenden Runtime-Handoff.
- Echte ENet-Button-Interaktion kann nach dem Contract-/Fixture-Nachweis als separater sichtbarer Zwei-Fenster-Playtest folgen.
- Der zusaetzliche TASK_284-Architektur-Audit bleibt 63/64: alte Release-Deep-Link-Helfer in `meta_layer_flow.gd` setzen fuer TASK_832/868 Runtime-Status direkt. Das ist nicht Teil des normalen ROE-Pfads, braucht aber nach dem Playtest einen eigenen Authority-Repair.

## Ergebnis

- `tactical_rule / set_fire_rule` ist ein eigener whitelisted Multiplayer-Command.
- Auch ein Commander-Peer mit expliziter Fireteam-Zuweisung kann diese Zuweisung fuer ROE nicht umgehen; nur der Host bleibt teamweit autorisiert.
- `SimulationRoot` committed Fire Rule und Revision erst bei Command-Verarbeitung und publiziert den State im vorhandenen `tactical_rules`-Snapshot.
- Host-Commit aktualisiert aktive UnitCommands; ein Client-Snapshot aktualisiert nur revisionsgeschuetzte Lesedaten und erzeugt keine lokalen Gameplay-Commands.
- TASK_1082 ist 21/21, TASK_281 33/33, TASK_1081 33/33, TASK_1080 22/22, TASK_570 46/46 und TASK_607 41/41 gruen.
