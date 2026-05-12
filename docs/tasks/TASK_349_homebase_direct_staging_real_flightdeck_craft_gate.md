# TASK_349 - Homebase Direct Staging Real Flightdeck Craft Gate

## Ziel
Homebase-Direct-Staging darf nur mit einem echten Flightdeck-Craft als Dropship-/Boarding-Ziel startbereit werden. Es soll keinen synthetischen `"homebase_dropship"`-Payload geben, wenn kein Craft im Homebase-Flightdeck existiert.

## Status: GEPLANT

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
- [ ] Ohne Homebase-Craft bleibt Direct-Drop-State nicht launch-ready.
- [ ] Mit geeignetem Dropship exportiert der Direct-Drop-State echte `craft_id`, Textur, Pilot- und Passenger-Daten.
- [ ] Nicht boardbare/beschaeftigte/unavailable Crafts blockieren Direct-Launch sichtbar.
- [ ] Der Flightdeck-Dropbereich bleibt sichtbar, zeigt aber den korrekten Blockertext.
- [ ] Headless-Verifier deckt synthetischen Craft-Fallback ab.

## Erwartete Dateien
- `scripts/meta/homebase_screen.gd`
- `scripts/meta/meta_layer_flow.gd`
- `scripts/tests/task_349_homebase_direct_staging_real_flightdeck_craft_gate.gd`

## Lokale Pruefung
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_349_homebase_direct_staging_real_flightdeck_craft_gate.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_347_homebase_direct_staging_start_guard.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_179_homebase_drop_light_fixed_fullhd_layout_verifier.gd`
- [ ] `git diff --check`

## Risiken / offene Punkte
- Muss mit TASK_347 abgestimmt werden: Der Start-Guard darf nur auf echten, gueltigen Direct-Payload reagieren.
- Wenn spaeter ein Default-Dropship automatisch erzeugt werden soll, muss das als eigener Meta-/Economy-Entscheid modelliert werden, nicht als stiller UI-Fallback.
