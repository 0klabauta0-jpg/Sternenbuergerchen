# TASK_1069 - Station Route LZ Evacuation Abort Outcome

## Ziel / Problem

Die Station Route kann starten, deboarden und den ersten Kontakt zeigen.
`Withdraw` ist aber aktuell nur ein Move-Alias und die vorhandene Dropship-
RTB-Aktion schickt lediglich das leere Craft zurueck. Ein Spieler kann damit
keinen nachvollziehbaren Rueckzug beenden; der vorhandene Debrief-Pfad ist nur
an Sieg oder Niederlage angeschlossen.

## Ursache / Sinnhaftigkeit

Der Review-Bestand enthaelt viele read-only Decision-Snapshots fuer
`HOLD / ADV / BACK`, aber keinen autoritativen Abort-Ausgang. Dieser Task
verbindet nur vorhandene Grenzen: LZ-Position und Ground-Fireteam im Tactical
Controller, autoritative Result-Erzeugung im Combat-Driver sowie das bestehende
`combat_resolved -> MetaLayerFlow -> Debrief`-Handoff.

## Umfang

- Einen Public-Authority-Request im Combat-Driver fuer ein abgebrochenes
  Missionsresultat mit `result = aborted`, `mission_outcome = aborted` und
  `win_condition_type = evacuation`.
- Einen Tactical-Controller-Evac-Request fuer ausgewaehlte Ground-Fireteams,
  der nur bei gesetzter LZ und innerhalb des LZ-Radius akzeptiert wird.
- Einen kleinen sichtbaren `EVAC`-Button im bestehenden Mission-Control-
  Action-Row. Ausserhalb der LZ nennt sein Tooltip den fehlenden Schritt.
- Host-only-Mutation: Nicht-Authority-Aufrufe werden abgelehnt und erzeugen
  keinen lokalen MissionResult.
- Einen End-to-End-Trace von Station Route ueber LZ/Deboarding/Evac in den
  vorhandenen Debrief-Screen.

## Nicht-Ziele

- Kein neues Boarding-, Evac-Shuttle- oder Cinematic-System.
- Kein automatischer Rueckzug und kein Auto-GO.
- Kein individuelles Team-Extrahieren in einer laufenden PvP-Mission.
- Kein neuer Combat-, Damage-, Pathfinding- oder Multiplayer-Snapshot-Pfad.

## Relevante Contracts / Dokumente

- `docs/ARCHITECTURE.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/homebase_direct_dropship_flow_contract.md`
- `docs/tasks/TASK_1068_station_route_first_playable_round_trace.md`
- `docs/tasks/TASK_586_debrief_return_homebase_handoff.md`
- `docs/tasks/TASK_966_release_first_decision_loop_two_execution_hook.md`

## Akzeptanzkriterien

- Ohne LZ oder ausserhalb des LZ-Radius bleibt Evac blockiert und die Mission
  aktiv.
- Ein lokaler Host kann mit einem ausgewaehlten Ground-Fireteam im LZ-Radius
  die Mission als `aborted` mit Condition `evacuation` beenden.
- Der vorhandene `combat_resolved`-Pfad oeffnet Debrief und bewahrt das gleiche
  Ergebnis zwischen Combat-Driver, MetaLayerFlow und Debrief.
- Ein Nicht-Authority-Request mutiert weder Combat-Driver noch Debrief.
- Der sichtbare EVAC-Button besitzt keine eigene Missionswahrheit.

## Betroffene Dateien

- `scripts/mission/mission_combat_authority_contract.gd`
- `scripts/tests/mission_combat_loop_driver.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1069_station_route_evac_abort_outcome.gd`
- `docs/dev/mission_evacuation_abort_contract.md`
- diese Task-Datei, Status, Roadmap und aktueller HTML-Bericht

## Lokale Pruefung

- Neuer TASK-1069-Trace.
- TASK_1068, TASK_1063, TASK_813 und TASK_586.
- `git diff --check`.

## Risiken / offene Punkte

Der Slice ist ein Host-kontrollierter Missionsabbruch fuer die aktuelle
Singleplayer-/Host-Route. Eine spaetere echte Mehrparteien-Extraction braucht
eine eigene Server-Command- und Team-Outcome-Regel, statt dieses globale
Missionsresultat still umzudeuten.

## Ergebnis

Implementiert im Arbeitsstand. TASK_1069 ist 28/28 gruen. Vor gesetzter LZ
und ausserhalb des LZ-Radius bleibt EVAC mit einem konkreten Grund blockiert.
Ein ausgewaehltes Ground-Fireteam am gesnappten LZ aktiviert den sichtbaren
EVAC-Button. Der lokale Host erzeugt daraufhin ein einzelnes
`aborted / evacuation`-Resultat; der bestehende Combat-Result-Signalweg
uebergibt es an MetaLayerFlow und Debrief. Ein simulierter Non-Authority-
Aufruf wird ohne lokales Resultat abgelehnt.

Die Anschlussregressionen bleiben gruen: TASK_1068 16/16, TASK_1063 14/14,
TASK_813 43/43 und TASK_586 37/37. TASK_813 meldet beim Headless-Exit weiter
die bekannte ObjectDB-Leak-Warnung, endet aber mit Exit 0 und allen Assertions
gruen.
