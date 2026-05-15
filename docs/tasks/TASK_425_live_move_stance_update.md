# TASK_425 - Live Move Stance Update

## Ziel / Problem

Bei laufendem Fireteam-`Move` wird die C/N/A-Haltung zwar in der UI umgestellt, aber die bereits aktive Bewegung uebernimmt die neue Haltung nicht zuverlaessig. Dadurch bleibt `cautious` im Playtest sichtbar ohne Waffe im Aim, und ein Wechsel auf `aggressive` oder `normal` waehrend des Laufens aendert Bewegung und Waffe nicht.

## Sinn / Ursache

Der aktuelle Runtime-Pfad requeued Move-Commands bis zum Ziel. Ohne eigene Revision fuer eine live geaenderte Haltung koennen alte requeue-Kommandos die neue Haltung wieder ueberdecken. Die Haltung muss deshalb im `FireteamMovementController` autoritativ in die aktive Move-Ausfuehrung geschrieben und mit neuer Command-Revision erneut ausgegeben werden.

## Umfang

- Laufende `Move`-Executions koennen ihre `tactical_stance` live aktualisieren.
- C/N/A-Tasten und Mini-Card-Stance-Tasten reichen die neue Haltung an aktive Move-Kommandos weiter.
- Alte requeue-Move-Commands werden durch eine Command-Revision stale, sobald die Haltung live neu ausgegeben wird.
- Regressionstest fuer direkte Controller-Commands und den Drill-Szenen-UI-Pfad.

## Nicht-Ziele

- Kein neues Stance-/Plan-Datenmodell.
- Keine Aenderung an Bounding-/Caterpillar-Entscheidungslogik.
- Keine neue Combat- oder Gegner-KI.

## Relevante Contracts / Dokumente

- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/fireteam_runtime_execution_path_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_421_move_stance_posture_speed_sight.md`
- `docs/tasks/TASK_423_normal_move_parallel_spacing.md`
- `docs/tasks/TASK_424_fireteam_drill_enemy_visibility_grounding.md`

## Akzeptanzkriterien

- [x] Ein laufender `Move` wechselt bei `cautious` sofort auf `movement_posture = engage`, `weapon_posture = aimed`, Speed x0.65 und Sicht x1.2.
- [x] Ein laufender `Move` wechselt bei `normal` sofort auf `movement_posture = travel`, `weapon_posture = lowered`, Speed x1.0 und Sicht x1.0.
- [x] Ein laufender `Move` wechselt bei `aggressive` sofort auf `movement_posture = run`, `weapon_posture = lowered`, Speed x1.2 und Sicht x0.65.
- [x] Die Stance-Umschaltung im Drill-UI aktualisiert aktive Move-Commands, statt nur zukuenftige Waypoints zu beeinflussen.
- [x] Command-Tokens erhalten eine Revision, damit alte requeue-Kommandos nach einer Live-Haltungsumstellung nicht mehr autoritativ angewendet werden.

## Betroffene Dateien

- `docs/tasks/TASK_425_live_move_stance_update.md`
- `docs/TASK_ROADMAP.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `scripts/tactical/fireteam_movement_controller.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_425_live_move_stance_update.gd`

## Lokale Pruefung

- [x] `godot_console.exe --headless --path . --script scripts/tests/task_425_live_move_stance_update.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_421_move_stance_posture_speed_sight.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_422_go_continue_fireteam_hud_cleanup.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_109_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_423_normal_move_parallel_spacing.gd`
- [x] `git diff --check`

## Risiken / offene Punkte

- Die Live-Umstellung aendert bewusst nur die Haltung/Speed/Sicht des aktiven Move-Stages. Ein Wechsel von Rush zu Bounding/Caterpillar bleibt eine separate Befehls-/Planentscheidung.
- Bei sehr vielen schnellen Stance-Klicks entstehen kurz alte Commands in der Queue; durch Token-Revisionen werden sie beim Anwenden verworfen.
