# TASK_540 - Mission First Move Decision Readability Pass

## Status: IMPLEMENTIERT

## Ziel / Problem
Nach der Dropship-Insertion muss die erste echte Move-/GO-Entscheidung lesbar sein. Der Spieler soll erkennen, welches Fireteam am Boden ist, welches Ziel geplant ist, ob Preview/Waypoint sichtbar sind und ob GO jetzt sinnvoll bereit ist.

## Sinnhaftigkeit / Ursache
TASK_539 macht Dropship, LZ und erste Insertion sichtbar. Der naechste Reibungspunkt liegt direkt danach: Nach dem Deboarding darf der Spieler nicht raten muessen, ob ein Move-Ziel angenommen wurde, ob der richtige Trupp gemeint ist oder ob GO blockiert ist.

## Umfang
- `MissionTacticalSandboxController` expose't einen read-only `get_mission_first_move_decision_readability_snapshot()`.
- Der Snapshot kombiniert bestehende Command-Feedback-, Waypoint-Intent-, Visualized-Waypoint-, Selection- und Deploy-Daten.
- Ein Smoke startet eine Homebase-Direktmission, setzt LZ, dropped das Fireteam, legt eine erste Move-Order an und prueft Preview/GO-Lesbarkeit.
- Der laufende HTML-Arbeitsbericht wird aktualisiert.

## Nicht-Ziele
- Kein neuer Movement-Resolver.
- Keine Aenderung an GO-Ausfuehrung oder Pathfinding.
- Kein Combat-/Threat-Rewrite.
- Kein per-frame HUD-Rebuild.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_539_mission_insertion_first_order_readability_pass.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/runtime_script_layout_contract.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Akzeptanzkriterien
- Nach Deboarding ist das ausgewaehlte Fireteam als aktiv/deployed lesbar.
- Eine erste Move-Order erzeugt geplante Waypoints.
- Waypoint-Intent-Preview und visualisierte Waypoints sind vorhanden.
- GO ist fuer die geplante Order vorhanden und nicht blockiert.
- Der Snapshot setzt `ui_sets_gameplay_truth = false` und fuehrt keinen Befehl aus.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_540_mission_first_move_decision_readability_pass.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_540_mission_first_move_decision_readability_pass.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_539_mission_insertion_first_order_readability_pass.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Task prueft Headless-Snapshots und bestehende Visualizer-Zaehler, aber keinen echten manuellen Pixel-Sichttest.
- Die eigentliche GO-Ausfuehrung und Bewegungsankunft bleiben ein Folge-Slice, falls die Lesbarkeit nach GO noch hakelt.
