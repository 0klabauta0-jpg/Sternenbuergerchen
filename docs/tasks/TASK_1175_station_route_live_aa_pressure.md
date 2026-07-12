# TASK_1175 - Station Route Live AA Pressure

## Ziel / Problem

Die Station Route besitzt einen vollstaendigen Victory-Trace, der die
Formation fuer jede Interaction an den Marker setzt. Der echte Spielerweg ist
bisher nur bis zum ersten Guard-Kontakt belegt. Offen ist deshalb, ob Alpha
den ersten realen Zielpunkt unter dem authored NPC-Druck normal erreicht und
die sichtbare AA-Aktion ausfuehren kann.

## Ursache / Sinnhaftigkeit

Ein Victory-Trace mit Positionsbeschleunigung kann einen Fehler zwischen
Movement, Contact-Halt und Interaction-Range verdecken. Gerade dieser Moment
entscheidet, ob die Mission nach dem Drop wie ein spielbarer Auftrag wirkt
oder ob der Spieler ohne sichtbaren Grund vor dem ersten Ziel festhaengt.

## Umfang

- Homebase -> Craft-Arrival -> LZ -> Drop -> Deboarding ueber bestehende
  Pfade starten.
- Die bestehende NPC-AA-Wache am bereits authored `factory_danger_zone`-Marker
  einsetzen; der getrennte PvP-Spawn bleibt unveraendert.
- Einen echten `move`-Befehl zum authored `factory_danger_zone` senden.
- Vorhandene Simulation- und Controller-Ticks nur testseitig beschleunigen.
- Bewegung, Guard-Contact, AA-Context-Button, Interaction-Intent, GO und
  vorhandene `aa_disabled`-Completion pruefen.

## Nicht-Ziele

- Keine Unit-Teleports oder direkte Positionszuweisungen.
- Kein direkter Gate-, Contact-, Combat-, Fire-, Damage- oder Result-State.
- Kein Combat-, NPC-, Multiplayer-, HUD- oder Map-Rewrite.

## Relevante Contracts / Dokumente

- `docs/ARCHITECTURE.md`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_1071_station_route_full_victory_debrief_trace.md`
- `docs/tasks/TASK_1078_station_route_approach_contact_timing.md`
- `docs/tasks/TASK_1079_station_route_real_first_exchange.md`

## Akzeptanzkriterien

- Der Verifier weist nach, dass keine direkte Unit-Position, Gate-, Contact-,
  Fire-, Damage- oder Result-Wahrheit gesetzt wird.
- Nach dem realen Move hat die Formation sich deutlich vom LZ entfernt und
  erreicht die AA-Interaction-Range.
- Ein authored Bravo-Contact tritt vor oder waehrend der AA-Ankunft auf.
- Der bestehende Context-Slot bietet `AA`; Klick erzeugt nur den vorhandenen
  Intent und ein getrenntes GO schliesst den bestehenden AA-Gate-Progress ab.
- Bei einem realen Blocker benennt der Test den konkreten Stage statt ihn zu
  umgehen.

## Betroffene Dateien

- `scripts/tests/task_1175_station_route_live_aa_pressure.gd`
- `docs/tasks/TASK_1175_station_route_live_aa_pressure.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung

- TASK_1175.
- TASK_1078, TASK_1079 und TASK_1071 als bestehende Route-Regressionen.
- `git diff --check`.

## Risiken / offene Punkte

Das Szenario kann den Move unter dem echten Guard-Contact bewusst anhalten.
Dann ist der Test wertvolle Evidenz, aber kein Anlass zum Teleport: Der
Folgetask muss die sichtbare Spielerentscheidung zum Wiederaufnehmen,
Kaempfen oder Rueckzug definieren.

## Ergebnis

Implementiert im Arbeitsstand. Der direkte Alpha-Move zur AA erreichte vorher
den Zielmarker ohne Kontakt, weil die NPC-AA-Wache am entfernten PvP-Spawn
stand. Die Wache startet jetzt am bereits authored `factory_danger_zone`; der
PvP-Spawn `spawn_bravo` bleibt davon getrennt. TASK_1175 ist 16/16 gruen:
Homebase, Drop und Deboarding fuehren ohne Positions- oder State-Overrides zu
normaler Formation-Bewegung, Bravo-Kontakt, sichtbarem AA-Context-Intent,
separatem GO und `aa_disabled` aus dem vorhandenen Runtime-Progress.

Der grosse 192x192-Headless-Harness benoetigt fuer diesen echten Trace rund
266 Sekunden. Das ist ein Test-/Setup-Performancebefund; die beschleunigten
Ticks aendern weder Spieltempo noch Produktionsbalance.
