# TASK_381 - Homebase Fireteam Loadout Flightdeck Polish

## Ziel
Homebase Direct Staging soll im Manual Test runder laufen: Fireteam-Mitglieder bekommen ihre Loadout-Auswahl direkt in #10, Fireteams koennen direkt auf Flightdeck-Shipcards gezogen werden, und Character-/Help-Popups werden kompakter und editornah.

## Status: IMPLEMENTIERT

## Sinnhaftigkeitscheck
Der Wunsch ist sinnvoll, weil #10 FIRETEAMS bereits die operative Zuordnung ist. Die wichtigsten Loadout-Entscheidungen dort zu editieren reduziert Panelwechsel, ohne #13 LOADOUT als Detailansicht zu entfernen. Shipcard-Drops nutzen weiterhin denselben Homebase-Direct-Staging-State und fuehren keine zweite Boarding-Wahrheit ein.

## Problem
- #13 LOADOUT enthaelt die Waffen-Dropdowns, #10 FIRETEAMS aber nicht.
- Fireteam-Drops auf die sichtbaren Dropship-Karten im Flightdeck wurden nicht akzeptiert.
- Fireteam-Drag-Preview konnte zu schmal umbrechen.
- Kontext-Hilfen waren fuer NPC-Karten zu breit.
- Das Homebase-Character-Popup nutzte nicht die zweispaltige Editor-Darstellung.

## Umfang
- Kompakte Armor/Primary/Secondary-Dropdowns pro Fireteam-Mitglied in #10.
- #10- und #13-Loadoutauswahl synchronisieren denselben Member-Loadout-State.
- Flightdeck-Shipcards als Fireteam-Drop-Ziele anbinden.
- Fireteam-Drag-Preview mit fester Mindestbreite gegen Ein-Buchstabe-Zeilen absichern.
- Kontext-Hilfe-Breiten auf kompaktere Werte reduzieren.
- Homebase-Character-Popup zweispaltig rendern.

## Akzeptanzkriterien
- [x] #10 zeigt pro zugewiesenem Mitglied drei kompakte Loadout-Dropdowns.
- [x] Aenderungen in #10 erscheinen in #13 und im Homebase-Direct-Export.
- [x] Fireteam-Karten koennen auf Flightdeck-Shipcards gedroppt werden.
- [x] Character-Popup enthaelt `CharacterSheetTwoColumnBody`.
- [x] Kontext-Hilfe-Popups verwenden die neuen schmaleren Breiten.

## Betroffene Dateien
- `scripts/meta/homebase_screen.gd`
- `scripts/meta/homebase_fireteam_drop_target.gd`
- `scripts/meta/fob_fireteam_card.gd`
- `scripts/ui/contextual_help_popup.gd`
- `scripts/ui/contextual_help_service.gd`
- `data/contextual_help_catalog.json`
- `scripts/tests/task_381_homebase_fireteam_loadout_flightdeck_polish.gd`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_381_homebase_fireteam_loadout_flightdeck_polish.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_346_homebase_direct_staging_character_popup.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_355_homebase_direct_ux_payload_truth.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_354_homebase_direct_loadout_regression_matrix.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_179_homebase_drop_light_fixed_fullhd_layout_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_263_contextual_help_popup_ux_contract.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_267_contextual_help_coverage_layout_verifier.gd`
- [x] `git diff --check`

## Risiken / offene Punkte
- Manueller Sichtcheck bleibt sinnvoll, weil die zusaetzlichen #10-Dropdowns die Fireteam-Karten dichter machen.
