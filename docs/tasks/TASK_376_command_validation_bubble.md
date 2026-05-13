# TASK_376 - Command Validation Bubble

## Ziel
Blockierte oder ungueltige Befehle sollen eine kurze, ortsnahe Validierungsbubble anzeigen, z. B. `Blocked route`, `Select tile first`, `Too far` oder `No LOS`.

## Status: IMPLEMENTIERT

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
- [x] Blockierte Commands erzeugen eine sichtbare, kurze Bubble mit Grund.
- [x] Bubble verweist auf vorhandenen Reject-/Validation-Key.
- [x] Mehrfachklicks erzeugen keine Bubble-Flut.
- [x] Existing Comic-Bubble-Gate bleibt kompatibel.
- [x] Headless-Test prueft `select_tile_first` und mindestens einen weiteren Blocker.

## Umsetzung
- `FireteamleaderFeedbackBubbleResolver` mappt bestehende Controller-/Reject-Details wie `no_tile` und `failed` auf kurze Validation-Keys und Texte (`select_tile_first`, `blocked_route`), ohne neue Command-Regeln einzufuehren.
- `ComicBubbleRuntimeGate` dedupliziert Validations pro Fireteam/Unit, Action und Validation-Key. Geblockte Validation-Bubbles tragen hoehere Prioritaet als normale Command-Flavor-Bubbles.
- `mission_tactical_sandbox_controller.gd` behält den bestehenden Bubble-Pfad, schuetzt aber aktive Blocker beim lokalen Max-Active-Cap vor niedriger priorisierten Bubbles.
- `task_376_command_validation_bubble.gd` prueft Resolver, Gate, `select_tile_first`, den zweiten Blocker `blocked_route` und die Dokumentationsmarker.

## Erwartete Dateien
- `scripts/ui/fireteamleader_feedback_bubble_resolver.gd`
- `scripts/ui/comic_bubble_runtime_gate.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_376_command_validation_bubble.gd`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_376_command_validation_bubble.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_315_mission_grid_tile_selection_command_gate.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_286_ui_feedback_truth_regression_review.gd`
- [x] `git diff --check`

## Risiken / offene Punkte
- Bubbles koennen die Karte ueberladen. Der Task muss mit den bestehenden Bubble-Modi normal/minimal/debug zusammenarbeiten.
- Finale optische Position/Lesbarkeit bleibt ein manueller Mission-HUD-Sichtcheck; Headless prueft Payload, Dedup und Snapshot-Vertrag.
