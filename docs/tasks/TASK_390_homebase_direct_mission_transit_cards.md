# TASK_390 - Homebase Direct Mission Transit Cards

## Ziel
Homebase-Direct-Dropships sollen beim Klick auf `Send` nicht sofort als an der Mission angekommen gelten. Die Mission soll zuerst eine ausgegraute Dropship-Karte mit ETA-/Fortschrittsbalken und dem geboardeten Fireteam anzeigen. Erst nach Abschluss des Transit-Timers wechselt das Dropship auf `waiting`; erst nach dem realen Drop steigen die Fireteams aus dem Dropship-Payload heraus und werden als aktive Infanterie behandelt.

## Sinnhaftigkeit
Der FOB-Bypass braucht dieselbe Transportwahrheit wie der klassische FOB-Pfad. Wenn Homebase-Direct direkt `waiting` schreibt, wirkt das Dropship teleportiert, Fireteams koennen zu frueh als missionsbereit erscheinen und die bestehende Mission-UI kann ihren Transit-Zustand nicht zeigen. Die Aenderung bleibt im Meta-/Planning-Bridge-Vertrag; die Mission-UI liest weiter nur den gelieferten Dropship-State.

## Umfang
- Homebase-Direct-Mission-Start erzeugt fuer das gewaehlte Dropship einen `to_mission`-Transfer mit ETA/Fortschritt.
- Mission-Planning-State und `mission_drop_cards` werden waehrend des Timers aus dem Direct-Transfer aktualisiert.
- Die laufende Mission erhaelt ohne erneutes Navigieren aktualisierte Progress-/ETA-Werte.
- Nach Abschluss des Timers wechselt Direct-Payload auf `waiting`, Passagiere bleiben bis zum Drop im Dropship.
- FOB bleibt beim Direct-Transit isoliert; Direct-Dropships und Direct-Fireteams erscheinen nicht in FOB-Transportkarten oder FOB `#10`.

## Akzeptanz
- Homebase-Direct `Send` startet die Mission mit `mission_drop_source = homebase_direct` und `mission_drop_state = to_mission`.
- Die Mission-Dropship-Karte ist waehrend `to_mission` transit/disabled, zeigt ETA/Progress und listet die Payload-Fireteam-Passagiere.
- Timer-Fortschritt aktualisiert die aktive Mission, ohne dass der Spieler die Ansicht wechseln muss.
- Nach Transit-Ende ist der Dropship-State `waiting`, der Passenger-Count bleibt erhalten.
- Nach dem LZ-Drop werden `embarked_unit_ids` und die Dropship-Passagiere geleert; die Fireteam-Mini-Karten bleiben bis dahin nur als inaktive/embarked Karten sichtbar.
- Homebase-Direct schreibt weiterhin keine Direct-Fireteams in die FOB.

## Betroffene Dateien
- `docs/tasks/TASK_390_homebase_direct_mission_transit_cards.md`
- `docs/TASK_ROADMAP.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `scripts/meta/meta_layer_flow.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_390_homebase_direct_mission_transit_cards.gd`
- `scripts/tests/task_385_homebase_direct_return_isolation.gd`

## Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_390_homebase_direct_mission_transit_cards.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_385_homebase_direct_return_isolation.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/bugfix_dropship_mission_flow_verifier.gd`
- [x] `git diff --check`

## Risiken / offene Punkte
- Homebase-Shipcards selbst bekommen in diesem Slice noch keine eigene Mission-Transit-Progressanzeige; der Fokus liegt auf dem autoritativen Mission-Planning-State und der laufenden Mission.
- Die Fensternummern-Kollision um Eventlog/Dropship bleibt ein separater Benennungs-/Layout-Task, sobald die finale Window-Liste feststeht.
