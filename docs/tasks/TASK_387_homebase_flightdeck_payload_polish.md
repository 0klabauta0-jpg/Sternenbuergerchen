# TASK_387 - Homebase Flightdeck Payload Polish

## Ziel
Homebase-Flightdeck und Dropship-Payload-Karten sollen den aktuellen Manual-Test-Fluss sauber abbilden: Boarding muss bis zum letzten Operator sichtbar abschliessen, Fireteams muessen aus dem Dropship wieder per Drag & Drop in `#10 FIRETEAMS` zurueckziehbar sein, Loadout-Dropdowns sollen kleine Waffen-Previews zeigen, und die Dropship-/Payload-Karten sollen keine Editor- oder Debug-Texte mehr anzeigen.

## Sinnhaftigkeit
Der FOB-Bypass ist nur dann gut bedienbar, wenn das Flightdeck nicht wie ein zweiter Editor wirkt. Fireteam, Loadout, Boarding und Zielwahl gehoeren in den Dropship-Kontext, aber die Karten muessen kompakt bleiben und nur den Zustand zeigen, den der Spieler fuer Boarding und Start wirklich braucht.

## Umfang
- Finales Homebase-Direct-Boarding refresht die UI auch dann, wenn der letzte Operator exakt am Ende eines Boarding-Intervals fertig wird.
- Dropship-Payload-Fireteamkarten koennen per Drag & Drop aus dem Dropship zurueck nach `#10 FIRETEAMS` gezogen werden.
- Homebase-Inline-Loadout-Dropdowns zeigen passende kleine Waffen-/Kit-Previews, ohne die Dropdown-Breite aufzublasen.
- Dropship-Payload-Karten blenden unnoetige Labels wie `Lead`, `Members`, `Loadout`, `Loadout Editing`, `Kit Editor Only`, `Launch Payload`, `Top Operator Cards` und `Not Boarded` aus.
- Shipcard-Top-Aktionen `Send` und `Clear` werden aus der sichtbaren Dropship-Karte entfernt; Start-/Transfer-Logik bleibt ueber den bestehenden Direct-Mission-Flow erreichbar.
- Das Direct-Dropship-Staging wird als Teil der jeweiligen Dropship-Karte betrachtet, nicht als separates sichtbares Zusatzfenster im Flightdeck.

## Akzeptanz
- Der letzte Operator einer Payload-Fireteamkarte erreicht `Boarded` / 100 Prozent.
- Ein ins Dropship gezogenes Fireteam verschwindet aus `#10 FIRETEAMS` und erscheint dort wieder, wenn die Payload-Karte zurueck auf `#10` gedroppt wird.
- Loadout-Dropdowns behalten ihre kompakte Groesse und zeigen fuer bekannte Waffen/Kits Icons im Dropdown.
- Dropship-Payload-Karten enthalten keine Editor-/Debug-Labels und keine Loadout-Editor-Controls.
- Sichtbare Dropship-Karten zeigen keine `Send`- oder `Clear`-Buttons mehr.

## Betroffene Dateien
- `docs/tasks/TASK_387_homebase_flightdeck_payload_polish.md`
- `docs/TASK_ROADMAP.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `scripts/meta/homebase_screen.gd`
- `scripts/tests/task_387_homebase_flightdeck_payload_polish.gd`
- `scripts/tests/task_346_homebase_direct_staging_character_popup.gd`
- `scripts/tests/task_349_homebase_direct_staging_real_flightdeck_craft_gate.gd`
- `scripts/tests/task_355_homebase_direct_ux_payload_truth.gd`
- `scripts/tests/task_382_homebase_direct_mission_flightdeck_display.gd`
- `scripts/tests/task_384_homebase_flightdeck_boarding_hotfix.gd`

## Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_387_homebase_flightdeck_payload_polish.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_386_homebase_flightdeck_member_portraits.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_384_homebase_flightdeck_boarding_hotfix.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_383_homebase_flightdeck_fireteam_card_single_owner.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_382_homebase_direct_mission_flightdeck_display.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_381_homebase_fireteam_loadout_flightdeck_polish.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_347_homebase_direct_staging_start_guard.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_346_homebase_direct_staging_character_popup.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_349_homebase_direct_staging_real_flightdeck_craft_gate.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_355_homebase_direct_ux_payload_truth.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_354_homebase_direct_loadout_regression_matrix.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_179_homebase_drop_light_fixed_fullhd_layout_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_258_fixed_window_clipping_scrollbar_playability_audit.gd`
- [x] `git diff --check`

## Risiken / offene Punkte
- Die sichtbare Shipcard-Entfernung der alten `Send`-/`Clear`-Buttons verschiebt Bedienung bewusst auf den bestehenden Homebase-Direct-Startpfad. Falls spaeter pro Dropship ein expliziter lokaler Startbutton gewuenscht ist, sollte er als eigener, klarer Karten-Command wieder eingefuehrt werden.
- Die Icon-Auswahl ist ein UI-Preview-Vertrag und darf keine neue Loadout- oder Combat-Wahrheit werden.
