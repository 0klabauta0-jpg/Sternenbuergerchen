# TASK_392 - Parallel Boarding Transit Feedback

## Ziel
Homebase-Direct-Dropships sollen mehrere Fireteams parallel boarden koennen, waehrend Mission- und Homebase-Karten klar zeigen, ob ein Dropship nur im Transit unbedienbar ist oder auf der Mission-Map aktiv genutzt werden kann.

## Sinnhaftigkeit
Der Homebase-FOB-Bypass fuehlt sich nur sauber an, wenn jedes Dropship seine eigene Payload-Wahrheit behaelt. Ein globaler Boarding-/Transit-Zustand wuerde Fireteam 2 blockieren, obwohl Dropship 1 noch boardet, und graue Mission-Karten wuerden nicht mehr lesbar zwischen "nicht erreichbar" und "auf der Map unterwegs" unterscheiden.

## Umfang
- Homebase-Direct-Boarding bleibt pro Dropship parallel tickend; ein zweites Fireteam kann sofort in ein zweites Dropship gezogen werden.
- Homebase-Flightdeck rendert Direct-to-Mission-Dropships waehrend des Transit-Timers sichtbar ausgegraut mit Fortschrittsbalken.
- Nach Mission-Ankunft verschwindet das Direct-Dropship aus dem Homebase-Flightdeck und ist in der Mission wieder vollfarbig/zugreifbar.
- Mission-Dropshipkarten sind nur bei unbedienbarem Transfer ausgegraut. LZ-Inbound und Deboarding auf der Map bleiben nicht ausgegraut.
- Die Mission-Dropshipkarte zeigt die embarked Fireteam-Payload als kompakte Fireteamkarte mit Mini-Portraits.
- Touchdown und Trupp-ab-Feedback erscheinen an den Dropship-/Fireteamkarten; Touchdown wird nicht mehr als Bubble auf noch versteckten Units erzeugt.
- Deboarding nutzt den vorhandenen `DROP_UNLOAD_INTERVAL_SECONDS`-Takt und zeigt waehrend des Absetzens Fortschritt.

## Akzeptanz
- Fireteam 1 kann in Dropship 1 boarden, waehrend Fireteam 2 sofort in Dropship 2 startet.
- Beide Dropships behalten ihre Fireteamkarten und Boarding-Progress unabhaengig voneinander.
- Ein gesendetes Direct-Dropship ist in Homebase und Mission waehrend `to_mission` grau und zeigt Transit-Progress.
- Nach `to_mission` ist das Dropship in der Mission nicht grau und in Homebase nicht mehr sichtbar.
- Beim LZ-Anflug ist die Mission-Dropshipkarte nicht grau; beim Deboarding zeigt sie Fortschritt.
- Nach Touchdown steht Feedback auf der Dropshipkarte; nach vollstaendigem Absetzen meldet die Karte `Trupp ab`.

## Betroffene Dateien
- `docs/tasks/TASK_392_parallel_boarding_transit_feedback.md`
- `docs/TASK_ROADMAP.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `scripts/meta/aircraft_manager.gd`
- `scripts/meta/meta_layer_flow.gd`
- `scripts/meta/homebase_screen.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/bugfix_dropship_mission_flow_verifier.gd`
- `scripts/tests/task_392_parallel_boarding_transit_feedback.gd`

## Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_392_parallel_boarding_transit_feedback.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_390_homebase_direct_mission_transit_cards.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_388_homebase_fireteam_roster_shipcard_polish.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_385_homebase_direct_return_isolation.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/bugfix_dropship_mission_flow_verifier.gd`
- [x] `git diff --check`

## Risiken / offene Punkte
- Das Deboarding-Intervall ist ein V1-Spielgefuehlwert aus dem bestehenden `DROP_UNLOAD_INTERVAL_SECONDS`. Eine spaetere Balancing-Runde kann das pro Speed/Disziplin oder Dropship-Typ staffeln.
- Die Karte zeigt `Trupp ab` als Card-Feedback. Falls spaeter echte Sprechblasen an UI-Karten gewuenscht sind, sollte das als eigener UI-Polish-Task geschnitten werden.
