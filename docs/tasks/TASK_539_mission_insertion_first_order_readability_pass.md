# TASK_539 - Mission Insertion First Order Readability Pass

## Status: IMPLEMENTIERT

## Ziel / Problem
Nach dem Homebase-zu-Mission-Handoff muss der erste sichtbare Missionsschritt lesbar sein: Dropship, Payload, LZ-Zustand, Deploy-Bereitschaft, ausgewaehltes Fireteam und erste Order-Kontrollen duerfen nicht nur intern vorhanden sein, sondern muessen im Missionsbild als konsistenter Zustand pruefbar sein.

## Sinnhaftigkeit / Ursache
Der Startflow ist inzwischen gut abgesichert, aber Playtests fallen direkt danach wieder in Sucharbeit: Ist das richtige Fireteam im Schiff, wo setze ich die LZ, warum kann ich noch nicht droppen, und welche erste Order gehoert zum gewaehlten Fireteam? Dieser Task macht diesen Insertion-/First-Order-Zustand read-only beobachtbar.

## Umfang
- `MissionTacticalSandboxController` expose't einen read-only `get_mission_insertion_first_order_readability_snapshot()`.
- Der Snapshot kombiniert bestehende Planning-, Dropship-Karten-, Command-Feedback- und Primary3DView-Daten.
- Ein Smoke startet eine Homebase-Direktmission, prueft den Zustand vor LZ und nach gesetzter LZ.
- Der laufende HTML-Arbeitsbericht wird als Zwischenbericht aktualisiert.

## Nicht-Ziele
- Kein neuer Dropship-Flow.
- Keine neue Command- oder GO-Logik.
- Kein Combat-, LOS- oder Threat-Rewrite.
- Kein per-frame UI-Rebuild oder neuer Hotpath.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_538_homebase_to_mission_launch_handoff_smoke.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/runtime_script_layout_contract.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Akzeptanzkriterien
- Vor LZ ist die Dropship-Karte sichtbar, Payload vorhanden und Drop nachvollziehbar blockiert.
- Mission Control oder Card-Controls zeigen den LZ-Zustand.
- Das ausgewaehlte Fireteam und erste Order-Kontrollen sind im Command-Feedback-Snapshot vorhanden.
- Nach LZ-Setzung ist die LZ im World-/Render-Snapshot sichtbar und Drop auf der Card bereit.
- Der Snapshot setzt `ui_sets_gameplay_truth = false` und fuehrt keinen Befehl aus.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_539_mission_insertion_first_order_readability_pass.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_539_mission_insertion_first_order_readability_pass.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_538_homebase_to_mission_launch_handoff_smoke.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_396_mission_dropship_lz_drop_hotfix.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Task prueft Headless-Snapshots und vorhandene Render-Zaehler, aber keinen menschlichen Pixel-Sichttest im Godot-Fenster.
- Die erste echte Move-Order nach Deboarding bleibt ein naechster spielbarer Anschluss.
