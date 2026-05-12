# TASK_350 - Homebase Loadout Contract Export

## Ziel
`#13 LOADOUT` in der Homebase darf nicht nur lokal sichtbar sein. Loadout-Aenderungen muessen in denselben Staging-/Mission-Vertrag gelangen wie im FOB oder sichtbar als nicht-persistente V1-Einschraenkung blockiert werden.

## Status: IMPLEMENTIERT

## Problem
Homebase speichert Loadout-Auswahl aktuell nur in `_member_loadout_by_unit_id`. `build_homebase_direct_drop_state()` exportiert diese Daten nicht. Damit kann die UI Loadout-Bedienung suggerieren, ohne Gameplay-Wirkung zu haben.

## Ursache
TASK_346 hat die kompakte Loadout-UI in die Homebase geholt, aber den Datenvertrag fuer Member-/Fireteam-Loadouts noch nicht an den bestehenden FOB-/Mission-State angeschlossen.

## Umfang
- Bestehenden FOB-Loadout-Vertrag identifizieren und wiederverwenden.
- Homebase-Loadout-Aenderungen an Fireteam-/Member-State koppeln, ohne eine zweite Gameplay-Wahrheit in der UI zu erzeugen.
- Direct-Drop-State muss die relevanten Loadout-Felder exportieren oder MetaLayerFlow muss sie vor Missionsstart in den bestehenden Mission-Setup-State uebernehmen.
- UI soll nur Optionen zeigen, die in den exportierten Vertrag passen.
- Tests fuer geaenderte Kit/Primary/Sidearm-Werte im Homebase-Direct-Missionsstate.

## Akzeptanzkriterien
- [x] Homebase-Loadout-Aenderungen erscheinen im exportierten Direct-Drop-/Mission-Setup-State.
- [x] Fireteam- und Member-Loadout folgen demselben Contract wie FOB-Loadout.
- [x] Kein rein UI-lokaler Loadout-State bleibt als alleinige Wahrheit bestehen.
- [x] FOB-Loadout-Regressionen bleiben gruen.
- [x] Headless-Verifier deckt mindestens eine geaenderte Member-Loadout-Auswahl ab.

## Erwartete Dateien
- `scripts/meta/homebase_screen.gd`
- `scripts/meta/meta_layer_flow.gd`
- ggf. `scripts/meta/fob_screen.gd`, falls ein gemeinsamer Helper extrahiert wird
- `scripts/tests/task_350_homebase_loadout_contract_export.gd`
- `scripts/tests/medic_support_verifier.gd`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_350_homebase_loadout_contract_export.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_349_homebase_direct_staging_real_flightdeck_craft_gate.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_348_homebase_fob_payload_state_isolation.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_347_homebase_direct_staging_start_guard.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_346_homebase_direct_staging_character_popup.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_316_fob_fireteam_staging_migration.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/bugfix_mission_fireteam_fob_payload_and_bubbles.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/medic_support_verifier.gd`
- [x] `git diff --check`

## Umgesetzt
- Homebase-Loadout verwendet fuer Member jetzt den FOB-kompatiblen Contract `armor`, `weapon_1`, `weapon_2` statt UI-naher Alias-Felder.
- `build_homebase_direct_drop_state()` exportiert `member_loadouts`, `selected_fireteam_definitions` und `selected_team_unit_configs` fuer Homebase-Direct.
- `MetaLayerFlow` uebergibt bei Homebase-Direct den exportierten Planning-State an `MissionSetup`; FOB bleibt der Fallback und nutzt denselben `member_loadouts`-Builder.
- Die Homebase-Loadout-Dropdowns zeigen nur Werte, die vom bestehenden FOB-/Mission-Contract verstanden werden.
- Der neue Verifier prueft eine geaenderte Homebase-Member-Auswahl bis in den Direct-Drop-State und `MissionSetup`.

## Risiken / offene Punkte
- Der Contract-Helper ist noch nicht in eine gemeinsame Datei extrahiert; Homebase und FOB normalisieren aktuell lokal auf denselben Wertebereich.
- `task_316_fob_fireteam_staging_migration.gd` meldet beim Headless-Exit bestehende Godot-RID-Leak-Warnungen, aber alle Assertions laufen gruen.
