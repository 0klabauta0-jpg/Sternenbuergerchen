# TASK_595 - Homebase Progression Visual Polish

## Ziel / Problem
TASK_594 macht Skill-/XP-Deltas nach der Mission im Character-Sheet wieder auffindbar. Die Zeile ist aber noch funktional-kompakt und kann im Homebase-Workflow visuell untergehen.

## Sinnhaftigkeit / Ursache
Der Spieler soll nach `Mission -> Debrief -> Homebase` sofort merken: Dieses Fireteam hat Fortschritt gemacht. Der Fortschritt bleibt weiterhin resolver-basiert und read-only; dieser Task verbessert nur die Lesbarkeit und den visuellen Anker.

## Umfang
- Die `Last Award`-Zeile im Character-Sheet bekommt eine eigene Highlight-Darstellung.
- Der Row-Contract bekommt `style_key`, `style_id` und ein kurzes Badge.
- `HomebaseTestScreen.get_post_mission_skill_delta_snapshot()` meldet die Visual-Style-Metadaten.
- Der laufende HTML-Zwischenbericht wird auf TASK_595 aktualisiert.

## Nicht-Ziele
- Kein neues XP-/Skill-Balancing.
- Keine Animation oder Sound.
- Keine Skill-Tree-UI.
- Keine Persistenz- oder Gameplay-Mutation in Homebase, Sheet oder Bericht.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_594_post_mission_skill_delta_homebase_bridge.md`
- `docs/dev/html_report_workbench_contract.md`
- `docs/reports/project_review_status_2026_06_28.html`
- `docs/ARCHITECTURE.md`

## Akzeptanzkriterien
- `Last Award` ist als eigene Highlight-Row mit stabiler `style_id = homebase_progression_delta_v1` erkennbar.
- Die Row bleibt read-only und nutzt nur `progression_award_summary` / `listed_awards`.
- Der Snapshot meldet Style-ID, Badge-Text und Gate `pass`.
- TASK_594- und Character-Sheet-Regressionen bleiben gruen.

## Betroffene Dateien
- `scripts/meta/character_sheet_formatter.gd`
- `scripts/meta/character_sheet_view.gd`
- `scripts/meta/homebase_screen.gd`
- `scripts/tests/task_595_homebase_progression_visual_polish.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_595_homebase_progression_visual_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_594_post_mission_skill_delta_homebase_bridge.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_259_character_card_roster_switching_playability.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Polish ist ein automatisiert pruefbarer UI-Anker, ersetzt aber keinen echten menschlichen Homebase-Sichttest.
- Ein spaeterer Task kann Hover-Texte, Animation oder eine kleine Fortschrittszusammenfassung im Roster/Team-Panel ergaenzen.
