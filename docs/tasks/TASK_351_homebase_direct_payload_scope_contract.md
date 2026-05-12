# TASK_351 - Homebase Direct Payload Scope Contract

## Ziel
Homebase-Direct darf beim Missionsstart nur die Units und Fireteams in die Mission uebergeben, die wirklich im Homebase-Flightdeck-Dropship gestaged sind.

## Status: GEPLANT

## Problem
`build_homebase_direct_drop_state()` baut zwar `payload_unit_ids` aus den Fireteams im Flightdeck, exportiert aber fuer `selected_unit_ids`, `selected_fireteam_ids` und `selected_team_unit_configs` weiterhin die komplette Homebase-Auswahl. `MetaLayerFlow` uebernimmt diese Liste und `MissionTestSetup` aktiviert Friendly-Slots anhand von `selected_team_unit_ids`.

## Ursache
TASK_346 bis TASK_350 haben Direct-Staging schrittweise an FOB-/Mission-Vertraege angeschlossen, aber der Payload-Scope ist noch nicht hart genug vom allgemeinen Homebase-Team-Scope getrennt.

## Umfang
- Direct-Drop-State auf klare Payload-Felder begrenzen:
  - `selected_unit_ids` = wirklich embarkte `payload_unit_ids`
  - `selected_fireteam_ids` = nur Fireteams, die im Flightdeck gestaged sind
  - `selected_team_unit_configs` = nur Configs fuer embarkte Units
  - `selected_fireteam_definitions` = nur payload-relevante Fireteam-Definitionen
- Falls die komplette Homebase-Team-Auswahl weiterhin fuer UI/Debug gebraucht wird, separat als `homebase_team_unit_ids` / `homebase_team_fireteam_ids` exportieren.
- MetaLayerFlow darf bei `homebase_direct` keine nicht-embarkten Homebase-Units in `_selected_unit_ids` oder `MissionSetup.selected_team_unit_ids` uebernehmen.
- Bestehende FOB- und Homebase-Fallback-Pfade unveraendert lassen.

## Akzeptanzkriterien
- [ ] Wenn zwei Fireteams in Homebase ausgewaehlt sind, aber nur eins im Flightdeck liegt, startet die Mission nur mit dem Flightdeck-Fireteam.
- [ ] `embarked_unit_ids`, `selected_unit_ids`, `selected_team_unit_configs` und `member_loadouts` sind fuer Homebase-Direct konsistent.
- [ ] Nicht-embarkte Homebase-Units bleiben in der Homebase-/Team-Auswahl nachvollziehbar, werden aber nicht als Missionsteilnehmer aktiviert.
- [ ] FOB-Payload-Scope bleibt unveraendert.
- [ ] Headless-Verifier deckt mindestens den Zwei-Fireteam-eins-im-Dropship-Fall ab.

## Erwartete Dateien
- `scripts/meta/homebase_screen.gd`
- `scripts/meta/meta_layer_flow.gd`
- `scripts/tests/task_351_homebase_direct_payload_scope_contract.gd`
- ggf. `scripts/tests/task_348_homebase_fob_payload_state_isolation.gd`
- ggf. `scripts/tests/task_350_homebase_loadout_contract_export.gd`

## Lokale Pruefung
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_351_homebase_direct_payload_scope_contract.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_350_homebase_loadout_contract_export.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_348_homebase_fob_payload_state_isolation.gd`
- [ ] `git diff --check`

## Risiken / offene Punkte
- Einige UI-Snapshots koennten bisher `selected_unit_ids` als gesamte Homebase-Auswahl verstanden haben. Falls das noetig ist, muss dieser UI-Scope explizit als eigenes Feld erhalten bleiben.
- Die Mission braucht weiter eine stabile Slot-Reihenfolge; Payload-Filterung darf Fireteam- und Unit-Indexing nicht auseinanderziehen.
