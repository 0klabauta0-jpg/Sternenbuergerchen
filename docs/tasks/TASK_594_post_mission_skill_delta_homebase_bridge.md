# TASK_594 - Post Mission Skill Delta Homebase Bridge

## Ziel / Problem
Nach `TASK_593` zeigt der Debrief echte Skill-/XP-Awards aus `MissionProgressionResolver.award_summary`, aber der Spieler findet diese Deltas nach der Rueckkehr in die Homebase noch nicht gezielt im Character-Sheet wieder.

## Sinnhaftigkeit / Ursache
Der Core Loop `Mission -> Debrief -> Homebase -> naechste Mission` braucht einen sichtbaren Fortschrittsanker. Die Gameplay-Wahrheit liegt bereits im aktualisierten Roster und in den resolver-basierten `unit_updates`; die Homebase soll nur anzeigen, welche Deltas zuletzt vergeben wurden.

## Umfang
- `MetaLayerFlow` reicht `progression_award_summary` an die Homebase weiter.
- `HomebaseTestScreen` speichert daraus einen read-only Lookup pro Unit fuer den aktuellen Homebase-Return.
- Das Character-Sheet zeigt eine kompakte `Last Award`-Zeile fuer den fokussierten Operator.
- Ein Snapshot prueft Schema, Authority, Read-only-Grenze und Sichtbarkeit.
- Der laufende HTML-Zwischenbericht wird aktualisiert.

## Nicht-Ziele
- Kein neues XP- oder Skill-Balancing.
- Keine Skill-Tree-UI.
- Keine Persistenz-Aenderung.
- Keine Berechnung von Awards in UI oder Character-Sheet.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_593_skill_progress_award_contract.md`
- `docs/reports/project_review_status_2026_06_28.html`
- `docs/ARCHITECTURE.md`

## Akzeptanzkriterien
- Homebase erhaelt `progression_award_summary` read-only aus dem MissionResult.
- Character-Sheet zeigt fuer einen ausgezeichneten Operator `Last Award` mit XP-/Skill-/FTL-Delta.
- Snapshot meldet `sternenbuergerchen.post_mission_skill_delta_homebase_bridge.v1`.
- Snapshot bestaetigt `authority = MissionProgressionResolver`, `read_only = true` und `ui_sets_gameplay_truth = false`.
- Bestehender Debrief-Award-Verifier bleibt gruen.

## Betroffene Dateien
- `scripts/meta/meta_layer_flow.gd`
- `scripts/meta/homebase_screen.gd`
- `scripts/meta/character_sheet_formatter.gd`
- `scripts/tests/task_594_post_mission_skill_delta_homebase_bridge.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_594_post_mission_skill_delta_homebase_bridge.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_593_skill_progress_award_contract.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_259_character_card_roster_switching_playability.gd`
- `git diff --check`

## Risiken / offene Punkte
- Die Anzeige ist bewusst kompakt. Ein spaeterer Polish kann bessere Hervorhebung, Filter oder animierte Deltas bauen.
- Ohne echten Spielersichttest ist nur der Contract abgesichert, nicht das finale Gefuehl der Homebase-Progression.
