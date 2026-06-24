# TASK_507 - Order Preview Ghosts MVP

## Ziel / Problem
Beim Setzen eines pending Move-Ziels soll der Spieler Zielposition, Pfad und ETA vor dem Commit sehen.

## Umfang
- Bestehenden Ghost-Pfad aus `TASK_375` beibehalten.
- Risk-Farbe und kurze Statuszeile an den Preview-Payload koppeln.
- Preview bleibt vor `GO`, verschwindet nach Cancel/Delete/Commit.

## Nicht-Ziele
- Keine Pathfinding-Entscheidung im Visualizer.
- Keine SimulationRoot-Mutation.

## Akzeptanzkriterien
- Ghost-Position und Pfad sind im 2D-Visualizer und Primary-3D-Order-Payload sichtbar.
- Render-Snapshot meldet Preview-Visuals.

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_506_tactical_decision_clarity_contract.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_375_waypoint_intent_preview.gd`

## Risiken / offene Punkte
- ETA bleibt ein Planungsestimate.
