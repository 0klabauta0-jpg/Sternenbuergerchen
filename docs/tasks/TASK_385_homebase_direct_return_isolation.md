# TASK_385 - Homebase Direct Return Isolation

## Ziel
Homebase-Direct-Missionen duerfen die FOB nicht als Rueckkehr- oder Zwischenzustand benutzen. Wenn ein Dropship direkt aus der Homebase in die Mission startet und den Fireteam-Payload absetzt, kehrt das Dropship zur Homebase zurueck. Die abgesetzten Fireteams bleiben Missionspayload und tauchen nicht in der FOB `#10 FIRETEAMS` auf.

## Sinnhaftigkeit
Der FOB-Bypass ist nur spielbar, wenn es genau eine Wahrheit fuer Ort und Zustand gibt: Homebase-Direct gehoert zur Homebase/Mission-Schleife, der klassische FOB-Pfad bleibt separat. Andernfalls erscheinen Dropship- und Fireteam-Karten am falschen Ort und suggerieren, dass die FOB am Direct-Flow beteiligt war.

## Umfang
- Homebase-Start bevorzugt Direct-Payloads und faellt nur dann auf den alten FOB-Launch-Ready-Pfad zurueck, wenn kein Direct-Payload existiert.
- Queued, aber noch nicht fertig geboardete Homebase-Direct-Payloads blockieren den FOB-Fallback.
- Mission-Return-Events aus `homebase_direct` erzeugen `to_homebase`-Transfers statt `to_fob`.
- FOB-Screen-Refreshs werden waehrend aktiver Homebase-Direct-Missionen isoliert, damit keine Direct-Fireteams oder Direct-Dropships in FOB-Fenstern landen.
- Homebase-Direct-Boardingdauer wird pro Operator aus Speed und Discipline abgeleitet; durchschnittliche Werte ergeben ca. 4 Sekunden.

## Akzeptanz
- Direct-Start schreibt `mission_drop_source = homebase_direct`.
- Direct-Return legt einen `to_homebase`-Transfer an und macht das Dropship nach Abschluss wieder in der Homebase sichtbar.
- FOB `#10 FIRETEAMS` enthaelt keine Direct-Mission-Fireteams.
- FOB-Transportkarten zeigen den Direct-Return nicht.
- Durchschnittliche Speed/Discipline-Operator boarden in ca. 4 Sekunden; bessere Werte sind schneller, schlechtere langsamer.
- Der alte FOB-Launch-Ready-Pfad bleibt funktionsfaehig, wenn kein Direct-Payload existiert.

## Betroffene Dateien
- `scripts/meta/meta_layer_flow.gd`
- `scripts/meta/homebase_screen.gd`
- `scripts/tests/task_385_homebase_direct_return_isolation.gd`
- `scripts/tests/task_348_homebase_fob_payload_state_isolation.gd`
- `scripts/tests/task_384_homebase_flightdeck_boarding_hotfix.gd`

## Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_385_homebase_direct_return_isolation.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_348_homebase_fob_payload_state_isolation.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_384_homebase_flightdeck_boarding_hotfix.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_383_homebase_flightdeck_fireteam_card_single_owner.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_382_homebase_direct_mission_flightdeck_display.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_381_homebase_fireteam_loadout_flightdeck_polish.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_362_homebase_aircraft_state_manager_extraction.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/bugfix_dropship_mission_flow_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_179_homebase_drop_light_fixed_fullhd_layout_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_258_fixed_window_clipping_scrollbar_playability_audit.gd`
- [x] `git diff --check`

## Risiken / offene Punkte
- Der Homebase-Direct-Payload-Store ist weiterhin V1 und auf einen aktiven Direct-Payload ausgerichtet. Mehrere parallel beladene Homebase-Dropships bleiben ein separater Folge-Task.
- Die genaue Boardingkurve ist ein Gameplay-Tuningwert; die aktuelle Ableitung ist bewusst konservativ und kann spaeter durch weitere Operatorwerte wie Ausruestungsgewicht erweitert werden.
