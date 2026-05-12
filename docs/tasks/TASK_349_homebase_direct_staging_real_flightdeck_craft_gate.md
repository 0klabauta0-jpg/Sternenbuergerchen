# TASK_349 - Homebase Direct Staging Real Flightdeck Craft Gate

## Ziel
Homebase-Direct-Staging darf nur mit einem echten Flightdeck-Craft als Dropship-/Boarding-Ziel startbereit werden. Es soll keinen synthetischen `"homebase_dropship"`-Payload geben, wenn kein Craft im Homebase-Flightdeck existiert.

## Status: IMPLEMENTIERT

## Problem
`HomebaseTestScreen.build_homebase_direct_drop_state()` faellt aktuell bei fehlendem Craft auf `"homebase_dropship"` zurueck und setzt trotzdem `drop_ship_staged = true`, wenn Fireteam-Member vorhanden sind.

## Ursache
Der TASK_346-V1-Drop-State wurde als FOB-artiger Snapshot gebaut, aber das Flightdeck-Craft-Gating noch nicht voll an den bestehenden Aircraft-State gekoppelt.

## Umfang
- Direct-Staging nur erlauben, wenn ein sichtbares, boardbares Homebase-Craft existiert.
- Kein `drop_ship_staged = true` fuer synthetische Fallback-Crafts.
- UI-Feedback im Flightdeck anzeigen, wenn Fireteams gestagt sind, aber kein geeignetes Craft vorhanden ist.
- Beruecksichtige bestehende Craft-Zustaende: transit, busy, unavailable, cargo loading, pilot transfer.
- Tests fuer leerer Flightdeck, echtes Dropship, nicht boardbares Craft.

## Akzeptanzkriterien
- [x] Ohne Homebase-Craft bleibt Direct-Drop-State nicht launch-ready.
- [x] Mit geeignetem Dropship exportiert der Direct-Drop-State echte `craft_id`, Textur, Pilot- und Passenger-Daten.
- [x] Nicht boardbare/beschaeftigte/unavailable Crafts blockieren Direct-Launch sichtbar.
- [x] Der Flightdeck-Dropbereich bleibt sichtbar, zeigt aber den korrekten Blockertext.
- [x] Headless-Verifier deckt synthetischen Craft-Fallback ab.

## Erwartete Dateien
- `scripts/meta/homebase_screen.gd`
- `scripts/tests/task_349_homebase_direct_staging_real_flightdeck_craft_gate.gd`
- `scripts/tests/task_346_homebase_direct_staging_character_popup.gd`
- `scripts/tests/task_347_homebase_direct_staging_start_guard.gd`
- `scripts/tests/task_348_homebase_fob_payload_state_isolation.gd`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_349_homebase_direct_staging_real_flightdeck_craft_gate.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_347_homebase_direct_staging_start_guard.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_179_homebase_drop_light_fixed_fullhd_layout_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_346_homebase_direct_staging_character_popup.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_348_homebase_fob_payload_state_isolation.gd`
- [x] `git diff --check`

## Umgesetzt
- `HomebaseTestScreen` prueft Direct-Staging jetzt gegen einen echten ausgewaehlten Homebase-Dropship-Craft.
- Der synthetische `"homebase_dropship"`-Fallback wird nicht mehr als Mission-Drop-Craft exportiert.
- Der Flightdeck-Dropbereich bleibt als Ziel sichtbar und zeigt Blockertexte fuer fehlendes Craft, Cargo-Craft, Transit, laufende Flightdeck-Arbeit und unavailable Air Assets.
- Bestehende Direct-Staging-Regressionen erzeugen nun explizit ein echtes Homebase-Dropship, wenn sie einen launch-ready Direct-Payload erwarten.

## Risiken / offene Punkte
- Direct-Staging verlangt noch keinen Piloten als harte Startbedingung; der Task koppelt zuerst an ein echtes Dropship-Craft. Ein spaeteres Pilot-Gate sollte separat entschieden werden.
- Wenn spaeter ein Default-Dropship automatisch erzeugt werden soll, muss das als eigener Meta-/Economy-Entscheid modelliert werden, nicht als stiller UI-Fallback.
