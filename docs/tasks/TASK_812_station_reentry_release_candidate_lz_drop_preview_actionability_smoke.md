# TASK_812 - Station Reentry Release Candidate LZ Drop Preview Actionability Smoke

## Ziel / Problem
Nach `Start Mission` muss der erste echte Missionsgriff spielbar bleiben: LZ setzen, Drop ausloesen, Fireteam deboarden, ein Move-Ziel planen und vor `GO` eine lesbare Preview sehen.

## Sinnhaftigkeit / Ursache
TASK_811 endet bewusst beim sichtbaren LZ-/Drop-Griff. Der naechste Fallstrick liegt direkt danach: Der Spieler darf nicht raten, ob der Drop wirklich Payload gebracht hat, ob das Fireteam aktiv ist oder ob ein Move bereits laeuft statt nur geplant zu sein.

## Umfang
- Read-only Snapshot `MetaLayerFlow.get_release_candidate_lz_drop_preview_actionability_snapshot()`.
- Main-Menu-`Einzelspieler`-Verifier bis `Start Mission`.
- LZ-Setzung und Drop ueber bestehende Mission-Dropship-Card-/TacticalController-Pfade.
- Fireteam-Deboarding und erster Move-Preview ueber bestehende Test-/Command-Pfade.
- Kombination aus Handoff-, TASK_539-Insertion- und TASK_540-First-Move-Snapshots.

## Nicht-Ziele
- Kein `GO` ausfuehren.
- Kein Combat-/Firefight-Smoke.
- Kein Screenshot-/Pixeltest.
- Keine neue Gameplay-, UI- oder Multiplayer-Wahrheit.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/tasks/TASK_811_station_reentry_release_candidate_mission_launch_actionability_smoke.md`
- `docs/tasks/TASK_539_mission_insertion_first_order_readability_pass.md`
- `docs/tasks/TASK_540_mission_first_move_decision_readability_pass.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Akzeptanzkriterien
- Der Testpfad lautet `MainMenu -> Einzelspieler -> Homebase -> Start Mission -> LZ -> Drop -> Move Preview`.
- Homebase-to-Mission-Handoff bleibt `pass`.
- LZ ist gesetzt, bevor Drop/Preview bewertet werden.
- Fireteam ist nach Drop deployed und aktiv.
- First-Move-Snapshot bleibt read-only und `pass`.
- Geplanter Waypoint, Waypoint-Preview und Visualisierung sind vor `GO` sichtbar.
- `GO` ist bereit, wird in diesem Task aber nicht ausgefuehrt.

## Betroffene Dateien
- `scripts/meta/meta_layer_flow.gd`
- `scripts/tests/task_812_station_reentry_release_candidate_lz_drop_preview_actionability_smoke.gd`
- `docs/tasks/TASK_812_station_reentry_release_candidate_lz_drop_preview_actionability_smoke.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_812_station_reentry_release_candidate_lz_drop_preview_actionability_smoke.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_811_station_reentry_release_candidate_mission_launch_actionability_smoke.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_540_mission_first_move_decision_readability_pass.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Smoke stoppt vor `GO`. TASK_813 sollte den ersten `GO` plus erste Firefight-Reaktion absichern.
- Der Test nutzt bestehende Debug-/Test-Helfer zum schnellen Deboarding. Das ist fuer Release-Smoke okay, aber kein Ersatz fuer einen echten Timing-/Feel-Playtest im Fenster.
