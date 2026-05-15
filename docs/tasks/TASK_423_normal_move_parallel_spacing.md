# TASK_423 - Normal Move Parallel Spacing

## Ziel / Problem
Im Playtest wirkt normales `Move` so, als wuerde sich nur ein NPC bewegen. Die Fireteam-Mitglieder koennen sich gegenseitig im Weg stehen, weil normale Move-Zielslots zu eng beieinander liegen. Bei normalem Move sollen alle fitten Fireteam-Mitglieder gleichzeitig laufen.

## Sinnhaftigkeit / Ursache
Der Mission-Tactical-Pfad erzeugt pro Mitglied `UnitCommand`-Dictionaries. Wenn die Zielpunkte innerhalb der Mindestabstands-/Avoidance-Logik liegen, koennen Units aus ihren eigenen Zielpunkten gedrueckt werden und der Movement-Controller sieht die Stage nicht sauber als erreicht. Das ist kein UI-Thema, sondern gehoert in die Runtime-Formation im `FireteamMovementController`.

## Umfang
- Normales `Move` im Rush-/Travel-Pfad bleibt eine parallele Bewegung aller fitten Mitglieder.
- Normale Move-Zielslots halten genug Abstand, damit sie nicht gegen die Mindestabstandsregel arbeiten.
- Bounding/Caterpillar bleiben bewusst sequenziell.
- Headless-Verifier prueft Command-Anzahl, Zielabstaende und parallelen Fortschritt.

## Nicht-Ziele
- Kein neues Pathfinding- oder Collision-System.
- Kein Umbau von Bounding/Caterpillar.
- Kein UI-Umbau und keine direkte Unit-State-Mutation ausserhalb des bestehenden Command-Pfads.

## Relevante Contracts / Dokumente
- `docs/dev/fireteam_runtime_execution_path_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_404_fireteam_movement_posture_bridge.md`
- `docs/tasks/TASK_421_move_stance_posture_speed_sight.md`
- `docs/tasks/TASK_422_go_continue_fireteam_hud_cleanup.md`

## Akzeptanzkriterien
- [x] `Move` + normale Haltung erzeugt fuer vier fitte Mitglieder vier Move-Commands im selben Stage.
- [x] Die erzeugten normalen Move-Zielpositionen liegen paarweise mindestens in der Naehe der Runtime-Mindestabstandsregel auseinander.
- [x] Ein kleiner Runtime-Smoke zeigt, dass alle vier Units im ersten Tick bewegt werden und der parallele Move mit Mindestabstand abschliessen kann.
- [x] Bounding/Caterpillar-Tests bleiben gruen.

## Betroffene Dateien
- `scripts/tactical/fireteam_movement_controller.gd`
- `scripts/tests/task_423_normal_move_parallel_spacing.gd`
- `docs/tasks/TASK_423_normal_move_parallel_spacing.md`
- `docs/TASK_ROADMAP.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_423_normal_move_parallel_spacing.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_421_move_stance_posture_speed_sight.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_404_fireteam_movement_posture_bridge.gd`
- `git diff --check`

## Risiken / offene Punkte
- Die Zielslot-Weite ist ein Headless-Verhaltenstest, kein finaler visueller Formation-Polish. Ein Godot-Fenster-Check bleibt sinnvoll, um die Lesbarkeit der Viererformation zu pruefen.
