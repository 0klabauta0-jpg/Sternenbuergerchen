# TASK_427 - Fireteam Decision Feedback Aim Pose

## Ziel / Problem

Im Playtest ist bei `Move + C` keine klare Aim-Pose sichtbar. Gleichzeitig sind die sichtbaren Rueckmeldungen zu allgemein: `GO` und Befehl-Bubbles sagen oft nur, dass ein Befehl verstanden wurde, statt den tatsaechlichen Auftrag mit Richtung, Distanz und Haltung zu nennen.

## Sinn / Ursache

Der Runtime-Pfad setzt fuer vorsichtigen Move bereits `movement_posture = "engage"` und `weapon_posture = "aimed"`. Der offene Punkt ist die sichtbare 3D-Pose im Drill-Pfad und die Lesbarkeit der Entscheidungsschicht im HUD. Fuer Playtests muss direkt sichtbar sein, ob gerade `MOVE C` nach Nordost, `DEFEND AREA`, `TAKE` oder `ENGAGE` aktiv ist und warum sich NPCs entsprechend verhalten.

## Umfang

- Drill-Szenenpfad prueft `Move + C` bis in den 3D-Render-Snapshot auf sichtbare Aim-Pose.
- Fireteam-/GO-Feedback erhaelt aktiven Befehl, Richtung, Distanz, Tile/Area-Kontext und C/N/A-Haltungswirkung.
- `#17`-Status und Feedback-Snapshot bekommen einen kompakten Entscheidungsreadout.
- HTML-Referenz erklaert `Move`, `Defend`, `Take`, `Engage`, `OVW`, C/N/A sowie Tile- vs. Area-Verarbeitung.

## Nicht-Ziele

- Keine neue Entscheidungs-KI.
- Kein Umbau des Plan-/GO-Modells.
- Keine neue Area-Queue oder gemischte Reihenfolge fuer Waypoints und AreaOrders.

## Relevante Contracts / Dokumente

- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/fireteam_runtime_execution_path_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_421_move_stance_posture_speed_sight.md`
- `docs/tasks/TASK_425_live_move_stance_update.md`
- `docs/tasks/TASK_426_cautious_move_parallel_aim.md`

## Akzeptanzkriterien

- [x] `Move + C` im Drill-Pfad erzeugt fuer alle vier Fireteam-Mitglieder eine sichtbare Aim-Pose im 3D-Snapshot.
- [x] GO-/Command-Bubbles koennen den tatsaechlichen Auftrag anzeigen, z.B. `MOVE Nordost` mit Distanz und Stance statt generischem Bestaetigungstext.
- [x] `get_command_feedback_snapshot()` enthaelt einen kompakten Entscheidungsreadout fuer das selektierte Fireteam.
- [x] `#17` zeigt die aktive Entscheidung kompakt in der Statuszeile.
- [x] Die HTML-Referenz erklaert Move/Defend/Take/Engage, C/N/A, Tile/Area und OVW.

## Betroffene Dateien

- `docs/tasks/TASK_427_fireteam_decision_feedback_aim_pose.md`
- `docs/reports/fireteam_command_decision_reference.html`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/ui/fireteamleader_feedback_bubble_resolver.gd`
- `scripts/tests/task_427_fireteam_decision_feedback_aim_pose.gd`

## Lokale Pruefung

- [x] `godot_console.exe --headless --path . --script scripts/tests/task_427_fireteam_decision_feedback_aim_pose.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_426_cautious_move_parallel_aim.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_425_live_move_stance_update.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_403_runtime_animation_combat_cases.gd`
- [x] `git diff --check`

## Risiken / offene Punkte

- Die Bubble-Texte muessen kurz bleiben, weil Comic-Bubbles bewusst klein sind.
- Der Entscheidungsreadout ist UI-/Feedback-Wahrheit und darf keinen Gameplay-State mutieren.
