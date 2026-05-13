# TASK_382 - Homebase Direct Mission Flightdeck Display

## Ziel
Homebase Direct Staging soll im Manual Test eindeutig zeigen, welche Fireteams im Dropship sitzen, und der Shipcard-Send soll zwischen direktem Missionsstart und klassischem FOB-Transfer umschaltbar sein.

## Status: IMPLEMENTIERT

## Sinnhaftigkeitscheck
Der Wunsch ist sinnvoll, weil #10 FIRETEAMS seit TASK_381 die Loadout-Bearbeitung enthaelt. Ein eigenes sichtbares #13 LOADOUT-Fenster ist in der Homebase dadurch redundant. Gleichzeitig muss der Flightdeck-Payload auf der Dropship-Karte sichtbar sein, weil der Spieler dort droppt und dort den Start ausloest.

## Problem
- Fireteams konnten auf eine Homebase-Dropship-Karte gezogen werden, wurden dort aber nicht sichtbar.
- #13 LOADOUT nahm weiter Platz ein, obwohl die Loadout-Dropdowns in #10 FIRETEAMS liegen.
- Der Homebase-Shipcard-Button `Send` schickte das Dropship weiter Richtung FOB, obwohl der FOB-Bypass einen direkten Missionsstart braucht.

## Ursache
- Der Direct-Payload wurde global am Homebase-Direct-Staging-State gehalten und nicht an der konkreten Shipcard visualisiert.
- Das alte Homebase-Loadout-Fenster blieb als sichtbares Drop-Light-Fenster erhalten.
- Der Shipcard-Send-Pfad war historisch der Pilot-/Aircraft-Transfer zur FOB und nicht mit dem Homebase-Direct-Missionsstart gekoppelt.

## Umfang
- Homebase-Direct-Payload merkt sich die konkrete Dropship-Craft-ID.
- Dropship-Shipcards zeigen ihre geboardeten Fireteams direkt als Payload-Zeilen.
- #13 LOADOUT ist in der Homebase ein versteckter Legacy-/Kompatibilitaets-Node; die sichtbare Bearbeitung liegt in #10.
- Homebase-Layout gibt den Platz von #13 an #10 FIRETEAMS und #05 FLIGHTDECK.
- Shipcards bekommen eine `Mission`-Checkbox: aktiv = Send startet Mission, aus = Send bleibt FOB-Transfer.

Hinweis: TASK_383 ersetzt die Payload-Zeile durch eine kompakte Fireteam-Karte mit Boarding-/Member-Fortschritt und sorgt dafuer, dass die geboardete Karte nicht mehr parallel in `#10 FIRETEAMS` steht.

## Akzeptanzkriterien
- [x] Ein auf eine Dropship-Shipcard gedropptes Fireteam erscheint auf derselben Shipcard.
- [x] `payload_craft_id` zeigt auf die gedroppte Shipcard.
- [x] #13 LOADOUT ist in der Homebase nicht sichtbar und nicht im Fixed-Layout reserviert.
- [x] Shipcard-Send mit `Mission` aktiv emittiert `mission_start_requested`.
- [x] Shipcard-Send mit `Mission` aus emittiert weiter `aircraft_pilot_transfer_requested`.

## Betroffene Dateien
- `scripts/meta/homebase_screen.gd`
- `scripts/meta/drop_light_layout_contract.gd`
- `scripts/tests/task_382_homebase_direct_mission_flightdeck_display.gd`
- Homebase-Regressionstests fuer Layout/Loadout-Pfad

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_382_homebase_direct_mission_flightdeck_display.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_381_homebase_fireteam_loadout_flightdeck_polish.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_354_homebase_direct_loadout_regression_matrix.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_346_homebase_direct_staging_character_popup.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_179_homebase_drop_light_fixed_fullhd_layout_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_258_fixed_window_clipping_scrollbar_playability_audit.gd`
- [x] `git diff --check`

## Risiken / offene Punkte
- Der Homebase-Direct-Payload bleibt V1 bewusst ein Payload pro Dropship-Auswahl. Mehrere gleichzeitig beladene Homebase-Dropships brauchen spaeter einen per-Craft-Payload-Store.
