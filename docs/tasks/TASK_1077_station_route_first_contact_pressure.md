# TASK_1077 - Station Route First Contact Pressure

## Ziel / Problem

Station Route beschreibt NPC-Druck, Bravo-Wache und zwei gueltige erste
Entscheidungen. Der bestehende TASK-1068-Trace verschiebt jedoch einen Bravo
NPC manuell an Alpha heran, damit Contact, Ghost und Risiko sichtbar werden.
Im echten Scenario-Start entsteht dieser erste Druck nicht nachweisbar aus
den Scenario-Daten.

## Ursache / Sinnhaftigkeit

`MissionTestSetup` wendet bereits `enemy_groups[].spawn_marker_id` und
`patrol_bindings` auf Runtime-NPCs an. Beide Station-Route-Bravo-Gruppen
werden aber am weit entfernten `spawn_bravo` gestartet. Die vorhandene
Guard-Patrouille erreicht den Alpha-Approach dadurch nicht als erste
Entscheidung. Das Szenario braucht einen datengetriebenen Approach-Guard;
die AA-Wache bleibt bei der eigentlichen AA-Position.

## Umfang

- Einen echten Homebase -> Drop -> Deboard -> First-Contact-Trace ohne
  manuelles Versetzen eines Gegners bauen.
- Die Station-Scenario-Guard-Start-/Patrol-Daten so authoren, dass nach dem
  ersten route-aligned Move ein LOS-Kontakt mit einer Bravo-Wache entsteht.
- Contact, NPC-Taktik, Move-Preview und Evac-Eligibility als bestehende
  Runtime-/Snapshot-Pfade pruefen.
- Den Player-Run weiterhin mit getrenntem `GO` aufbauen; der Test darf keine
  Objectives, Damage- oder MissionResults direkt setzen.

## Nicht-Ziele

- Kein neues Enemy-AI-, Combat-, Contact- oder Movement-System.
- Kein festes Spieler-LZ und kein Auto-GO im Spiel.
- Keine Aenderung an der AA-Wache, Door, Computer, Cargo oder der
  Host-/Client-Autoritaet.

## Relevante Contracts / Dokumente

- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/dev/contact_report_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/homebase_direct_dropship_flow_contract.md`
- TASK_1068, TASK_1069, TASK_1070 und TASK_1071

## Akzeptanzkriterien

- Der Trace veraendert keine Enemy-Position direkt.
- Eine reale Bravo-Wache startet aus den Scenario-Spawn-/Patrol-Daten am
  Alpha-Approach und erzeugt nach dem ersten ausgefuehrten Route-Move einen
  LOS-Kontakt.
- Vor dem Commit bleiben Ghost, Pfad und Risiko sichtbar; nach dem Commit
  wird Contact ohne Test-Teleport sichtbar.
- Ein LZ-Rueckzug bleibt als bestehende, host-autoritative Alternative
  erreichbar; die neue Datenautorenschaft erzeugt keine zweite Wahrheit.

## Betroffene Dateien

- `data/mission_scenarios/station_route_one_screen_multiplayer_drill.json`
- `maps/station_outpost_192x192.json` nur falls ein klar benannter
  Approach-Marker noetig ist
- `scripts/tests/task_1077_station_route_first_contact_pressure.gd`
- Task-/Status-/Roadmap-/Report-Dateien nach bestaetigtem Fix

## Lokale Pruefung

- TASK_1077 First-Contact-Trace.
- TASK_1068, TASK_1069, TASK_1070, TASK_1071 und TASK_607.
- `git diff --check`.

## Risiken / offene Punkte

Der erste Contact soll eine lesbare Bedrohung sein, kein Spawn-Camping. Der
Guard muss deshalb auf der Approach-Route und nicht direkt im LZ stehen. Die
finale menschliche Balance bleibt eine eigene sichtbare Playtest-Abnahme.

Der vollstaendige Headless-Trace baut Homebase, 192x192-Mission, Transfer,
Drop und Deboard real auf und dauert deshalb rund zwei Minuten. Er ist ein
End-to-End-Contract-Gate, kein Framerate-Benchmark; umfangreichere
Stations-Regressionen sollten mit einzelnem, ausreichend hohem Zeitlimit
laufen statt in einem kurzen Sammelbatch zu verschwinden.

## Ergebnis

Implementiert im Arbeitsstand. `approach_guard_post` ist ein benannter,
editor-only Kartenmarker auf der Alpha-Approach-Route. Nur
`bravo_station_guard` startet dort und bindet seine bestehende
`station_loop_route` gegen die Enemy-Group-ID; `bravo_air_defense` bleibt am
AA-Spawn `spawn_bravo`. `MissionScenarioData` akzeptiert die gleiche
Group-ID als Patrol-Ziel, die der bestehende Runtime-Resolver bereits
auflosen konnte. TASK_1077 ist 10/10 gruen, ohne Enemy-Teleport oder
autoritative UI-Mutation.
