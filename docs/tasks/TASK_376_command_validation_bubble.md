# TASK_376 - Command Validation Bubble

## Ziel
Blockierte oder ungueltige Befehle sollen eine kurze, ortsnahe Validierungsbubble anzeigen, z. B. `Blocked route`, `Select tile first`, `Too far` oder `No LOS`.

## Status: GEPLANT

## Sinnhaftigkeitscheck
Der Review-Punkt ist sinnvoll, weil TASK_315 bereits Command-Gates kennt und Feedbacktexte existieren. Der Task soll diese Gruende sichtbarer machen, nicht neue Validierungslogik bauen.

## Problem
Wenn ein Befehl gesperrt oder abgelehnt wird, ist der Grund nicht immer an der Stelle sichtbar, an der der Spieler gerade plant.

## Ursache
Validierungsgruende liegen in Command-Hierarchy-/Feedback-Snapshots, werden aber oft nur als Labeltext gezeigt.

## Umfang
- Bestehende Reject-/Blocked-Gruende aus MissionCommandHierarchyContract und Controller-Feedback lesen.
- Kurze Bubble am Button, Tile oder Fireteam-Anker anzeigen.
- Bubbles deduplizieren und zeitlich begrenzen.
- Critical/blocked Bubbles nicht von normalen Flavor-Bubbles verdraengen lassen.
- Keine neuen Command-Regeln im Bubble-Control.

## Akzeptanzkriterien
- [ ] Blockierte Commands erzeugen eine sichtbare, kurze Bubble mit Grund.
- [ ] Bubble verweist auf vorhandenen Reject-/Validation-Key.
- [ ] Mehrfachklicks erzeugen keine Bubble-Flut.
- [ ] Existing Comic-Bubble-Gate bleibt kompatibel.
- [ ] Headless-Test prueft `select_tile_first` und mindestens einen weiteren Blocker.

## Erwartete Dateien
- `scripts/ui/fireteamleader_feedback_bubble_resolver.gd`
- `scripts/ui/comic_bubble_runtime_gate.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_376_command_validation_bubble.gd`

## Lokale Pruefung
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_376_command_validation_bubble.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_315_mission_grid_tile_selection_command_gate.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_286_ui_feedback_truth_regression_review.gd`
- [ ] `git diff --check`

## Risiken / offene Punkte
- Bubbles koennen die Karte ueberladen. Der Task muss mit den bestehenden Bubble-Modi normal/minimal/debug zusammenarbeiten.

