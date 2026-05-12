# TASK_350 - Homebase Loadout Contract Export

## Ziel
`#13 LOADOUT` in der Homebase darf nicht nur lokal sichtbar sein. Loadout-Aenderungen muessen in denselben Staging-/Mission-Vertrag gelangen wie im FOB oder sichtbar als nicht-persistente V1-Einschraenkung blockiert werden.

## Status: GEPLANT

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
- [ ] Homebase-Loadout-Aenderungen erscheinen im exportierten Direct-Drop-/Mission-Setup-State.
- [ ] Fireteam- und Member-Loadout folgen demselben Contract wie FOB-Loadout.
- [ ] Kein rein UI-lokaler Loadout-State bleibt als alleinige Wahrheit bestehen.
- [ ] FOB-Loadout-Regressionen bleiben gruen.
- [ ] Headless-Verifier deckt mindestens eine geaenderte Member-Loadout-Auswahl ab.

## Erwartete Dateien
- `scripts/meta/homebase_screen.gd`
- `scripts/meta/meta_layer_flow.gd`
- ggf. `scripts/meta/fob_screen.gd`, falls ein gemeinsamer Helper extrahiert wird
- `scripts/tests/task_350_homebase_loadout_contract_export.gd`

## Lokale Pruefung
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_350_homebase_loadout_contract_export.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_346_homebase_direct_staging_character_popup.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_316_fob_fireteam_staging_migration.gd`
- [ ] `git diff --check`

## Risiken / offene Punkte
- Falls der bestehende FOB-Loadout-State selbst noch UI-nah ist, muss zuerst ein kleiner gemeinsamer Contract-Helper extrahiert werden.
- Keine Loadout-Werte still in Mission-Setup-Fallbacks duplizieren; die Gameplay-Wahrheit muss nachvollziehbar bleiben.
