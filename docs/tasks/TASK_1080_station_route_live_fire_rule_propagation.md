# TASK_1080 - Station Route Live Fire-Rule Propagation

## Ziel / Problem

Die Fire-Rule-Buttons (`HF`, `RF`, `FW`) aktualisieren die sichtbare
Fireteam-Regel und das aktive Behavior-Profil. In einer bereits laufenden
Fireteam-Bewegung muss dieselbe Regel aber auch sofort den aktuellen
`UnitCommand` erreichen. Sonst zeigt der Commander eine neue ROE an, waehrend
der Combat-Resolver noch nach dem vorherigen Command entscheidet.

## Ursache

Der bestehende Setter aktualisiert den Profile-Metadatenwert. Die
`FireteamMovementController`-Ausfuehrung rechnet den Wert erst beim naechsten
Stage-Issue in neue Unit-Commands ein. Ein bereits laufender Stage behaelt
damit potenziell seinen alten Command-Stand.

## Umfang

- Einen realen Station-Route-Trace nach Homebase -> Drop -> Deboard -> GO ->
  Guard-Contact bauen.
- `return` und `free` im laufenden Fireteam-Stage pruefen: Controller-Regel,
  Movement-State und aktuelle Unit-Commands muessen konsistent sein.
- Die bestehende `update_tactical_stance()`-Strategie fuer einen reinen
  Fire-Rule-Refresh wiederverwenden: Command-Revision erhoehen und den
  laufenden Stage ueber `SimulationRoot.enqueue_command()` neu ausgeben.

## Nicht-Ziele

- Kein Trefferzwang, keine Positions- oder Status-Manipulation im Test.
- Kein Combat-, Damage-, LOS- oder Enemy-AI-Umbau.
- Keine neue UI- oder Multiplayer-Wahrheit.

## Relevante Contracts

- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_command_rules_contract.md`
- `docs/tasks/TASK_570_hold_fire_discipline_mission_bridge.md`
- `docs/tasks/TASK_1079_station_route_real_first_exchange.md`

## Akzeptanzkriterien

- Nach einer laufenden `GO`-Ausfuehrung propagiert `return` in Controller,
  Movement-State und alle aktiven Bravo-Unit-Commands inklusive
  `fire_status = hold_fire`.
- `free` propagiert ueber denselben autoritativen Command-Pfad inklusive
  `fire_status = fire_at_will`.
- Alte tokenisierte Move-Commands koennen die neue ROE nicht wieder
  zurueckschreiben.
- Die Regression nutzt den echten Scenario-Guard-Contact ohne Teleport,
  Status-Manipulation oder erzwungenen Treffer.

## Betroffene Dateien

- `scripts/tactical/fireteam_movement_controller.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1080_station_route_live_fire_rule_propagation.gd`
- Task-/Status-/Roadmap-/Report-Dateien nach bestaetigtem Ergebnis

## Lokale Pruefung

- TASK_1080, TASK_1079, TASK_1078, TASK_1077, TASK_570 und TASK_607.
- `git diff --check`.

## Risiken / offene Punkte

`return` feuert im echten Contact nur bei aktivem Incoming-Fire-Fenster. Dieser
Task prueft deshalb die sofortige und korrekte Command-Propagation, nicht
einen kuenstlich erzeugten Trefferwechsel.

## Ergebnis

Implementiert. Der reale Station-Route-Trace ist 17/17 gruen. `return` und
`free` erreichen im laufenden Guard-Contact sofort Controller, Movement-State
und alle aktiven Bravo-Unit-Commands. Jede Aenderung erhoeht die
Command-Revision und gibt den aktuellen Stage ueber den vorhandenen
`SimulationRoot`-Command-Pfad neu aus; alte tokenisierte Move-Commands koennen
die neue ROE dadurch nicht wieder ueberschreiben.
