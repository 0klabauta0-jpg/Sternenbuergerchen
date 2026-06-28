# TASK_541 - Mission First Move Execution Feedback Pass

## Status: IMPLEMENTIERT

## Ziel / Problem
Nach der ersten Move-/GO-Entscheidung muss die Ausfuehrung selbst lesbar sein. Der Spieler soll erkennen, dass GO angenommen wurde, welches Fireteam laeuft, welche Bewegung aktiv ist und ob Fortschritt oder Ankunft im Feedback sichtbar werden.

## Sinnhaftigkeit / Ursache
TASK_540 prueft die Entscheidung vor GO. Direkt danach darf der Spieler nicht raten, ob der Befehl wirklich gestartet ist oder ob das Fireteam still in Planning/Preview haengt.

## Umfang
- `MissionTacticalSandboxController` expose't einen read-only `get_mission_first_move_execution_feedback_snapshot()`.
- Der Snapshot fasst bestehende Command-Feedback-, Phase-Execution-, Movement-, Waypoint- und Visualizer-Snapshots zusammen.
- Ein Smoke startet eine Homebase-Direktmission, setzt LZ, dropped/deboarded das Fireteam, plant eine Move-Order, fuehrt GO aus und prueft Ausfuehrungsfeedback.
- Der laufende HTML-Arbeitsbericht wird aktualisiert.

## Nicht-Ziele
- Kein neuer Movement-Resolver.
- Keine Aenderung an Pathfinding, Local Avoidance oder Combat.
- Kein neues HUD-System und kein per-frame UI-Rebuild.
- Kein manueller Pixel-/F6-Sichttest in diesem Task.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_540_mission_first_move_decision_readability_pass.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/runtime_script_layout_contract.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Akzeptanzkriterien
- GO wird ueber den bestehenden `execute_selected_fireteam_orders()`-Pfad ausgefuehrt.
- Der Snapshot setzt `ui_sets_gameplay_truth = false`.
- Der aktive Execution-State fuer das ausgewaehlte Fireteam ist sichtbar.
- Der aktive Movement-State fuer das ausgewaehlte Fireteam ist sichtbar.
- Ziel/Progress-/Readability-Daten sind im Snapshot vorhanden.
- Command-Feedback zeigt die GO-Annahme oder laufende Ausfuehrung.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_541_mission_first_move_execution_feedback_pass.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_541_mission_first_move_execution_feedback_pass.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_540_mission_first_move_decision_readability_pass.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Task prueft Headless-Snapshots und keine menschliche Pixelwirkung.
- Wenn die Bewegung sehr schnell ankommt, muss der Snapshot sowohl aktive Bewegung als auch erkennbaren Completion-/Progress-Status akzeptieren, ohne dadurch stillen Queue-Stau zu uebersehen.
