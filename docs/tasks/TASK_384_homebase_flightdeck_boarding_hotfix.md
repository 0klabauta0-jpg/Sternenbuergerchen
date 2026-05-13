# TASK_384 - Homebase Flightdeck Boarding Hotfix

## Ziel
Homebase-Flightdeck-Boarding soll im Manual Test wieder lesbar und glaubwuerdig sein: Fireteam-Karten im Dropship zeigen Mini-Portraets, sequentielles Boarding mit Fortschritt, aber keine Loadout-Editor-Flaechen. Die Dropship-Karten sollen kompakt genug sein, dass zwei Karten nebeneinander in `#05 FLIGHTDECK` passen.

## Sinnhaftigkeit
Der Wunsch ist sinnvoll, weil TASK_383 die Fireteam-Karte bereits als einzige sichtbare Payload-Wahrheit ins Dropship verschiebt. Ohne zeitlichen Boarding-Fortschritt wirkt der Status aber instant/unehrlich, und Loadout-Bearbeitung gehoert in `#10 FIRETEAMS`, nicht auf die Dropship-Payload-Karte.

## Umfang
- Homebase-Direct-Boarding bekommt einen eigenen sequentiellen Fortschrittszustand pro Fireteam.
- Boarding laeuft automatisch, aber nur bei stagebarem Homebase-Dropship, mit ca. 4.5 Sekunden pro Operator.
- Mission-Start/Direct-Drop-State werden erst launch-ready, wenn alle Operator des Payload-Fireteams geboardet sind.
- Dropship-Payload-Fireteam-Karten zeigen Mini-Portraets und Member-Fortschritt, aber keine Loadout-Zeile und keine Loadout-Editing-Controls.
- Dropship-Shipcards werden kompakter und im Flightdeck in Zweier-Reihen gerendert.
- Die Dropship-Karte zeigt Payload-/Boarded-Counts direkt oben im Shipcard-Headerbereich.

## Akzeptanz
- Direkt nach dem Drop ist das Fireteam aus `#10 FIRETEAMS` verschwunden, im Dropship sichtbar und noch nicht launch-ready.
- Nach einem Boarding-Intervall ist genau der erste Operator geboardet, der zweite noch nicht.
- Nach dem zweiten Intervall ist das Fireteam launch-ready und der Mission-Send-Button aktiv.
- Die Payload-Karte hat Mini-Portraets und keine Loadout-Editor-UI.
- Zwei Dropship-Karten passen in einer Flightdeck-Zeile nebeneinander.

## Betroffene Dateien
- `scripts/meta/homebase_screen.gd`
- `scripts/tests/task_384_homebase_flightdeck_boarding_hotfix.gd`
- Homebase-Regressionstests fuer TASK_346-355, TASK_381-383 und TASK_179.

## Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_384_homebase_flightdeck_boarding_hotfix.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_383_homebase_flightdeck_fireteam_card_single_owner.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_382_homebase_direct_mission_flightdeck_display.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_381_homebase_fireteam_loadout_flightdeck_polish.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_355_homebase_direct_ux_payload_truth.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_354_homebase_direct_loadout_regression_matrix.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_350_homebase_loadout_contract_export.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_351_homebase_direct_payload_scope_contract.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_352_homebase_loadout_defaults_preserve_unit_profiles.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_349_homebase_direct_staging_real_flightdeck_craft_gate.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_348_homebase_fob_payload_state_isolation.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_347_homebase_direct_staging_start_guard.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_346_homebase_direct_staging_character_popup.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_362_homebase_aircraft_state_manager_extraction.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_179_homebase_drop_light_fixed_fullhd_layout_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_258_fixed_window_clipping_scrollbar_playability_audit.gd`
- [x] `git diff --check`

## Risiken / offene Punkte
- Der Payload-Store bleibt V1 weiterhin auf einen aktiven Homebase-Direct-Payload ausgerichtet. Mehrere parallel beladene Homebase-Dropships brauchen einen eigenen Folge-Task fuer per-Craft-Payload-State.
- Der finale optische Abstand und die genaue Card-Breite sollten im manuellen FullHD-Playtest geprueft werden.
