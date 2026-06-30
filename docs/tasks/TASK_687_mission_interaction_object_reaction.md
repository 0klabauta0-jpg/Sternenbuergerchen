# TASK_687 - Mission Interaction Object Reaction

## Ziel / Problem
TASK_686 macht AA, Computer und Cargo als Labels sichtbar. Fuer Spielgefuehl und Lesbarkeit fehlt aber noch, dass das Missionsobjekt selbst einen Zustand zeigt: Terminal aktiv/kontrolliert, AA deaktiviert, Cargo-Beacon bereit, spaetere Doors geschlossen/offen.

## Sinnhaftigkeit / Ursache
Der Spieler soll nicht nur Text ueber einem Objekt lesen, sondern am Objekt erkennen, ob eine Interaktion bereit, aktiv, blockiert oder erledigt ist. Gleichzeitig darf die Anzeige keine Tile-, Door- oder Objective-Wahrheit schreiben. Deshalb leitet TASK_687 kleine read-only Objektreaktions-Proxies aus dem bestehenden Visualstate ab.

## Umfang
- Neuer Service `MissionInteractionObjectReaction`.
- `MissionTacticalSandboxController.get_mission_interaction_object_reaction_snapshot()`.
- Export in `get_command_feedback_snapshot()` und in das bestehende 3D-Mission-Status-Payload.
- `TerrainMap3DView` zeichnet kleine Objektreaktions-Proxies fuer Computer, AA, Cargo und Door-Familien.
- Render-Snapshot-Zaehler, Status-/Kind-Zaehler und Verifier fuer AA -> COM -> CARGO.

## Nicht-Ziele
- Kein echtes Door-Open/Closed-Tile-Swap.
- Kein Computer-Hack-Minispiel.
- Kein neues Objective-/Gate-System.
- Keine Mutation von TerrainMapData, TileData oder Scenario-Gates.
- Kein FullHD-Sichtentscheid in diesem Task.

## Relevante Contracts / Dokumente
- `docs/dev/mission_interaction_point_contract.md`
- `docs/tasks/TASK_686_mission_interaction_visual_state.md`
- `docs/tasks/TASK_685_mission_interaction_objective_gate.md`

## Akzeptanzkriterien
- Der Snapshot nennt Schema, Runtime-Autoritaet, `read_only = true` und `ui_sets_gameplay_truth = false`.
- Computer-Interaction bekommt im laufenden Zustand eine aktive Objektreaktion und nach Completion `controlled`.
- AA-Interaction bekommt nach Completion eine deaktivierte Objektreaktion.
- Cargo-Interaction bekommt nach Computer-Completion eine Beacon-/Ready-Reaktion.
- Door-Interactions werden als `door`-Kind mit Open-Fraction vorbereitet, ohne vorhandene Tiles zu mutieren.
- `TerrainMap3DView.get_render_snapshot()` exportiert Objektreaktions-Zaehler, Eintraege, Kind-/State-Zaehler und Style-ID.

## Betroffene Dateien
- `scripts/mission/mission_interaction_object_reaction.gd`
- `scripts/mission/mission_interaction_visual_state.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/task_687_mission_interaction_object_reaction.gd`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_687_mission_interaction_object_reaction.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_686_mission_interaction_visual_state.gd`
- `git diff --check`

## Risiken / offene Punkte
- Die Proxies sind bewusst schlanke Lesbarkeitsobjekte. Echte Asset-Swaps, Animationen und menschliche FullHD-Sichtabnahme bleiben Folgearbeit.
