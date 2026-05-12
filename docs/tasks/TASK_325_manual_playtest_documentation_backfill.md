# TASK_325 - Manual Playtest Documentation Backfill

## Ziel
Die in den letzten manuellen Playtest-Stunden entstandenen Aenderungen werden als echte Task-Dokumentation nachgezogen, damit Code, Tests, Roadmap und Implementation Status wieder zusammenpassen.

## Status: IMPLEMENTIERT

## Kontext
Mehrere Playtest-Fixes wurden als direkter Arbeitsblock umgesetzt: Mission-Fireteams, Dropships, Map-Editor, Assets, Feuerbereiche, Team-Editor und Debrief/Main-Menu. Die Statusdatei hatte bereits Playtest-Bloecke, aber es fehlten passende `docs/tasks/TASK_...`-Dateien.

## Umfang
1. Task-Backfill:
   - `TASK_317` bis `TASK_324` dokumentieren die umgesetzten Playtest-Slices.
2. Roadmap:
   - Neue Phase `18ZD - Manual Playtest Followups Backfill` verankert die Tasknummern.
3. Implementation Status:
   - Manual-Playtest-Bloecke bekommen konkrete Tasknummern.
4. Session Report:
   - Ein kurzer Bericht fasst zusammen, was der Block fachlich geaendert hat.

## Nicht-Ziele
- Kein Commit/Push.
- Keine neuen Codeaenderungen ausserhalb der Dokumentation.
- Keine Rueckdatierung als waeren die Tasks vorab geplant gewesen.

## Akzeptanzkriterien
- [x] Fuer die Playtest-Slices existieren Task-Dateien.
- [x] Roadmap listet die Tasknummern.
- [x] Implementation Status verweist auf dieselben Tasknummern.
- [x] Der Backfill benennt Risiken und offene manuelle Sichtchecks.

## Erwartete Dateien
- `docs/tasks/TASK_317_manual_playtest_mission_fireteam_fob_payload_and_bubbles.md`
- `docs/tasks/TASK_318_manual_playtest_debrief_background_main_menu_team_library.md`
- `docs/tasks/TASK_319_manual_playtest_fob_second_dropship_assignment_scale.md`
- `docs/tasks/TASK_320_manual_playtest_dropship_cards_dispatch_return.md`
- `docs/tasks/TASK_321_manual_playtest_map_editor_station_floor_layering_undo.md`
- `docs/tasks/TASK_322_manual_playtest_map_editor_asset_import_rotation_context_menu.md`
- `docs/tasks/TASK_323_manual_playtest_mission_command_visuals_fire_sector_dropships.md`
- `docs/tasks/TASK_324_manual_playtest_team_editor_character_overlay_usability.md`
- `docs/tasks/TASK_325_manual_playtest_documentation_backfill.md`
- `docs/reports/manual_playtest_session_backfill_2026_05_10.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- [x] `rg "TASK_317|TASK_318|TASK_319|TASK_320|TASK_321|TASK_322|TASK_323|TASK_324|TASK_325" docs`
- [x] `git diff --check`

## Risiken
- Der Backfill dokumentiert den Arbeitsstand. Einzelne UI-Proportionen und Live-Gefuehl bleiben weiterhin manuelle Playtest-Abnahme.
