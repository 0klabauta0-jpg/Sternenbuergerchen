# TASK_1078 - Station Route Approach Contact Timing

## Ziel / Problem

TASK_1077 macht den Station-Route-Guard aus Szenario-Spawn- und Patrol-Daten
sichtbar. Sein eigener Trace bestaetigt aber Kontakt bereits direkt nach
Deboard. Das widerspricht dem beabsichtigten ersten Commander-Griff: Eine
kleine LZ-Readiness-Phase, ein bewusstes `GO` in die Approach-Zone, danach
Kontakt und Feuer-/Evac-Entscheidung.

## Ursache / Sinnhaftigkeit

Der `approach_guard_post` liegt innerhalb der aktuellen Kontakt-/LOS-Reichweite
des normalen Deboard-Standorts. Der Guard wird deshalb vor der ersten
Spielerbewegung contact-locked und seine Patrol kann die Anmarschphase nicht
mehr als lesbaren Druck aufbauen.

## Umfang

- Einen echten Homebase -> Drop -> Deboard -> GO -> Approach-Contact-Trace
  ohne NPC-Teleport oder direkte Unit-Positionen bauen.
- Die Startdistanz der Bravo-Guard-Gruppe ausschliesslich ueber vorhandene
  Karten-/Szenariodaten so abstimmen, dass Deboard kontaktfrei bleibt und ein
  bestaetigter Move in die Approach-Zone Kontakt erzeugt.
- Die bestehende Guard-Patrol, AA-Position, Evac-Alternative und
  SimulationRoot-Command-Autoritaet beibehalten.

## Nicht-Ziele

- Kein neuer Contact-, Combat-, Enemy-AI- oder Movement-Algorithmus.
- Kein Auto-GO, kein festes LZ und keine UI-Gameplay-Wahrheit.
- Kein Umbau der AA -> Door -> Computer -> Cargo-Route.

## Relevante Contracts / Dokumente

- `docs/dev/contact_report_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/homebase_direct_dropship_flow_contract.md`
- TASK_1068, TASK_1069, TASK_1070, TASK_1071 und TASK_1077

## Akzeptanzkriterien

- Direkt nach echtem Deboard hat das ausgewaehlte Ground-Fireteam keinen
  bestaetigten Bravo-Contact.
- Ein vorhandener `move`-Intent bleibt vor `GO` Preview-only.
- Das bestaetigte `GO` bewegt das Fireteam in die benannte Approach-Zone und
  erzeugt dort aus Scenario-Guard-Daten einen Kontakt.
- Evac bleibt als host-autoritative LZ-Alternative erreichbar; keine
  Enemy-Position und kein Contact wird vom Test direkt gesetzt.

## Betroffene Dateien

- `maps/station_outpost_192x192.json`
- `scripts/tests/task_1078_station_route_approach_contact_timing.gd`
- Task-/Status-/Roadmap-/Report-Dateien nach bestaetigtem Fix

## Lokale Pruefung

- TASK_1078, TASK_1077, TASK_1068, TASK_1069, TASK_1070, TASK_1071 und
  TASK_607.
- `git diff --check`.

## Risiken / offene Punkte

Der Guard darf weder auf dem Spawn warten noch so weit weg liegen, dass der
erste Advance ins Leere fuehrt. Der Test prueft den konkreten
Scenario-/Runtime-Handshake; der menschliche Look-and-feel-Check bleibt
separate Balance-Arbeit.

Der End-to-End-Trace baut die reale 192x192-Map, Homebase, Transfer und
Mission auf. Er dauert deshalb rund drei Minuten und ist ein
Contract-/Lifecycle-Gate, kein Framerate-Benchmark.

## Ergebnis

Implementiert im Arbeitsstand. Der bestehende `approach_guard_post` steht
jetzt bei `x = 2304`, `y = 5056`. Nach Deboard bleibt die ausgewaehlte Alpha
Gruppe kontaktfrei. Der bestehende Move-Intent zu `2432, 5056` bleibt vor
`GO` Preview-only und erzeugt nach `GO` ohne Enemy-Teleport einen
Scenario-Guard-Contact. Evac und alle Snapshots bleiben read-only. TASK_1078
ist 11/11 gruen; TASK_1077 sichert den vorherigen ruhigen Planungszustand mit
10/10.
