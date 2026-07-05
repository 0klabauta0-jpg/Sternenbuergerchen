# TASK_813 - Station Reentry Release Candidate First GO Firefight Actionability Smoke

## Ziel / Problem
Nach LZ, Drop und Move-Preview muss der erste `GO` nicht nur technisch ausfuehrbar sein, sondern eine lesbare Bewegung, Kontaktlage und erste Firefight-/Engagement-Reaktion erzeugen.

## Sinnhaftigkeit / Ursache
TASK_812 stoppt bewusst vor `GO`. Der naechste Spielerfallstrick liegt direkt danach: Der Spieler darf nicht das Gefuehl haben, dass `GO` nichts tut, dass Kontakte magisch erscheinen oder dass Feuerentscheidungen ohne Rueckmeldung passieren.

## Umfang
- Read-only Snapshot `MetaLayerFlow.get_release_candidate_first_go_firefight_actionability_snapshot()`.
- Main-Menu-`Einzelspieler`-Verifier bis `Start Mission`, LZ, Drop, Move-Preview und `GO`.
- Bewegungsausfuehrung ueber den bestehenden `execute_selected_fireteam_orders()`-Pfad.
- Kontakt-/Engagement-Lesbarkeit ueber bestehende TASK_541-, TASK_542- und TASK_543-Snapshots.
- Reproduzierbarer erster Kontakt im Verifier durch Positionieren eines vorhandenen Gegners nahe am deployed Fireteam.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Keine neue Zielerkennungs-, Damage- oder Feuerlogik.
- Kein Debrief oder Mission-Ende.
- Kein neuer Multiplayer-Authority-Pfad.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/tasks/TASK_812_station_reentry_release_candidate_lz_drop_preview_actionability_smoke.md`
- `docs/tasks/TASK_541_mission_first_move_execution_feedback_pass.md`
- `docs/tasks/TASK_542_mission_first_contact_readability_pass.md`
- `docs/tasks/TASK_543_mission_first_engagement_feedback_pass.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Akzeptanzkriterien
- Der Testpfad lautet `MainMenu -> Einzelspieler -> Homebase -> Start Mission -> LZ -> Drop -> Move Preview -> GO -> First Contact -> First Engagement`.
- TASK_812-Vorbedingungen bleiben vor `GO` gruen.
- `GO` wird ueber den bestehenden Mission-Tactical-Pfad angenommen.
- Nach `GO` ist Execution-/Movement-Feedback sichtbar und an das ausgewaehlte Fireteam gebunden.
- Erster Kontakt ist als Kontaktmeldung/Overlay/Feedback lesbar.
- Erste Engagement-Entscheidung zeigt Status, Ziel oder Blockgrund sowie Range-/LOS-/Cover-Kontext.
- Der Meta-Snapshot bleibt read-only und setzt keine Gameplay- oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/meta/meta_layer_flow.gd`
- `scripts/tests/task_813_station_reentry_release_candidate_first_go_firefight_actionability_smoke.gd`
- `docs/tasks/TASK_813_station_reentry_release_candidate_first_go_firefight_actionability_smoke.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_813_station_reentry_release_candidate_first_go_firefight_actionability_smoke.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_812_station_reentry_release_candidate_lz_drop_preview_actionability_smoke.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_543_mission_first_engagement_feedback_pass.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Smoke erzwingt einen reproduzierbaren Kontakt fuer die Lesbarkeit. Er ersetzt keinen echten Fenster-Playtest zur Kampf-Dramaturgie.
- Der Slice prueft die erste Engagement-Reaktion, aber noch kein Missionsende, Debrief oder Langzeit-Performance im laufenden Firefight.
