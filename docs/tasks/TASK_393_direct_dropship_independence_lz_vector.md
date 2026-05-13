# TASK_393 - Direct Dropship Independence LZ Vector

## Ziel
Homebase-Direct-Dropships muessen im Live-Test vollstaendig pro Craft unabhaengig bleiben: mehrere gesendete Dropships duerfen sich nicht gegenseitig aus Mission oder Countdown-State verdraengen, Payload-Aenderungen an Fireteams im Dropship muessen sichtbar auf der Dropship-Fireteamkarte landen, und LZ-Anfluege brauchen eine groessere, klare Markierung samt Anflugvektor.

## Sinnhaftigkeit
Der FOB-Bypass ist nur spielbar, wenn jedes Dropship eine eigene Wahrheit fuer Payload, Boarding, Transit, Mission-Card und LZ-Plan behaelt. Sobald ein zweites Dropship den Planning-State global ueberschreibt, verschwinden Karten, ETAs bleiben scheinbar stehen oder Fireteams landen wieder am falschen Ort. Die LZ-Visuals sind dabei kein Extra-Polish, sondern helfen dem Spieler zu verstehen, wohin ein Dropship fliegt und wann eine LZ bereits verbraucht wurde.

## Umfang
- Homebase-Direct-Drop-State kann fuer ein konkretes Craft exportiert werden, ohne andere Dropships zu leeren.
- Mission-Planning merge't Homebase-Direct-`mission_drop_cards` pro Craft statt die komplette Kartenliste beim naechsten Send zu ersetzen.
- Direct-to-Mission-Transferfelder und ETA-/Progresswerte werden fuer alle aktiven Direct-Dropship-Transfers synchronisiert, nicht nur fuer das zuletzt gesendete Craft.
- Operator-Drops auf eine bereits im Dropship sichtbare Fireteamkarte fuegen den Operator diesem Fireteam hinzu und aktualisieren die sichtbare Payload-/Boarding-Karte im Dropship.
- Mission-LZ-Marker werden groesser und nur angezeigt, solange die LZ noch geplant oder im Anflug ist; nach Touchdown/Benutzung verschwindet der LZ-Marker.
- Die Mission zeigt einen halbtransparenten Anflugvektor vom Dropship zur LZ.

## Akzeptanz
- Wenn Fireteam 1 in Dropship 1 liegt, kann ein Operator aus `Available Operators` direkt auf diese Dropship-Fireteamkarte gedroppt werden; die Karte zeigt danach den neuen Member und der Drop-State enthaelt ihn.
- Dropship 1 bleibt in der Mission sichtbar und sein Transit-Fortschritt laeuft weiter, wenn Dropship 2 spaeter ebenfalls zur Mission gesendet wird.
- Zwei Direct-Dropships koennen parallel `to_mission`-Cards mit eigenen ETA-/Progresswerten halten.
- Ein LZ-Marker ist im geplanten/wartenden und im Anflugzustand sichtbar groesser markiert.
- Nach Touchdown bzw. waehrend Deboarding ist der benutzte LZ-Marker verschwunden.
- Der Anflugvektor fuehrt sichtbar von der aktuellen Dropship-Position zur LZ und bleibt pro Dropship getrennt.

## Betroffene Dateien
- `docs/tasks/TASK_393_direct_dropship_independence_lz_vector.md`
- `docs/TASK_ROADMAP.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `scripts/meta/homebase_screen.gd`
- `scripts/meta/meta_layer_flow.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/task_393_direct_dropship_independence_lz_vector.gd`

## Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_393_direct_dropship_independence_lz_vector.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_392_parallel_boarding_transit_feedback.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_390_homebase_direct_mission_transit_cards.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_388_homebase_fireteam_roster_shipcard_polish.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/bugfix_mission_multi_dropship_cards.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/bugfix_mission_dropship_plans_and_facing.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_385_homebase_direct_return_isolation.gd`
- [x] `git diff --check`

## Risiken / offene Punkte
- Der Anflugvektor ist in diesem Task ein klarer, halbtransparenter Missions-Visual-Hinweis. Eine spaetere gestrichelte Material-/Shader-Variante kann als eigener Visual-Polish folgen, falls die breite Linie im Live-Test nicht reicht.
- Der Fireteam-in-Dropship-Operator-Drop bleibt UI-Glue: Fireteam-Mitgliedschaft und Boarding-Wahrheit liegen weiter im bestehenden Homebase-State.
