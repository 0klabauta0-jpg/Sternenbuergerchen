# TASK_348 - Homebase FOB Payload State Isolation

## Ziel
Homebase-Direct-Staging und FOB-Dropship-Staging duerfen sich nicht gegenseitig ueberschreiben. Der FOB-Start muss immer den FOB-Payload verwenden; der Homebase-Start muss den Homebase-Payload verwenden.

## Status: GEPLANT

## Problem
`MetaLayerFlow._sync_fob_dropship_state_into_mission_planning()` liest aktuell zuerst `_get_homebase_direct_drop_state()`. Dadurch kann ein alter Homebase-Direct-Payload einen spaeteren FOB-Missionsstart ueberschreiben.

## Ursache
Der Sync-Helper ist durch den Namen und alten Vertrag FOB-zentriert, bekommt aber inzwischen beide Quellen gemischt. Es fehlt eine explizite Quellenwahl fuer `homebase_direct` vs. `fob`.

## Umfang
- Sync-Pfad in `MetaLayerFlow` nach Payload-Quelle trennen oder explizit parametrieren.
- `_on_homebase_mission_start_requested()` darf Homebase-Direct-State bevorzugen.
- `_on_fob_mission_start_requested()` darf Homebase-Direct-State nicht automatisch lesen.
- Map-/Preview-Sync muss weiterhin den aktuell gueltigen Planungszustand aktualisieren, ohne versteckte Quellenwechsel.
- Regressionstest fuer: Homebase-Payload vorhanden, danach FOB-Payload starten.

## Akzeptanzkriterien
- [ ] FOB-Missionsstart nutzt den FOB-Drop-State, auch wenn Homebase noch Direct-Staging enthaelt.
- [ ] Homebase-Missionsstart nutzt den Homebase-Direct-Drop-State.
- [ ] Mission-Planning-State enthaelt nach jedem Start nur die erwartete Payload-Quelle.
- [ ] Bestehende Multi-Dropship-/FOB-Regressionen bleiben gruen.
- [ ] Headless-Verifier deckt den Konfliktfall ab.

## Erwartete Dateien
- `scripts/meta/meta_layer_flow.gd`
- `scripts/tests/task_348_homebase_fob_payload_state_isolation.gd`
- optional: `scripts/tests/task_346_homebase_direct_staging_character_popup.gd`

## Lokale Pruefung
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_348_homebase_fob_payload_state_isolation.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_346_homebase_direct_staging_character_popup.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_316_fob_fireteam_staging_migration.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/bugfix_mission_multi_dropship_cards.gd`
- [ ] `git diff --check`

## Risiken / offene Punkte
- Die Quelle muss sauber durch den Meta-Flow gehen, ohne eine zweite Mission-Planning-Wahrheit zu erzeugen.
- Preview-Map und Live-Start koennen unterschiedliche Sync-Zeitpunkte haben; beide muessen im Test abgedeckt werden.
