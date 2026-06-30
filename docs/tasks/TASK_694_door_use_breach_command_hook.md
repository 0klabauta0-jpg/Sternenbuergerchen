# TASK_694 - Door Use/Breach Command Hook

## Ziel / Problem
TASK_693 kann Door-Runtime-State auf die `TerrainRegistry` anwenden. Fuer den Spieler fehlt aber noch ein klarer Door-spezifischer Use-/Breach-Hook, der aus einer nutzbaren Door-Interaction einen lesbaren Befehl im bestehenden GO-/Waypoint-Pfad erzeugt.

## Sinnhaftigkeit / Ursache
Ohne Hook ist die Technik vorhanden, aber die Bedienung bleibt implizit: Door-Interactions koennen zwar als Runtime-State wirken, aber der Spieler sieht keinen klaren `BREACH -> GO`-Pfad. Der Hook soll die Tuer bedienbar machen, ohne UI-Callbacks zur Gameplay-Wahrheit zu machen.

## Umfang
- Neuer Controller-Snapshot `get_mission_interaction_door_use_breach_command_hook_snapshot()`.
- Neue Methode `create_selected_mission_interaction_door_use_breach_command_hook(interaction_id = "")`.
- Door-Use/Breach nutzt den bestehenden `create_selected_mission_interaction_use_intent()`-Pfad.
- Door-Waypoints erhalten Runtime-Metadaten fuer den Door-State-Producer.
- `get_command_feedback_snapshot()` exportiert den Hook fuer UI/Verifier.
- Neuer Verifier prueft Hook, Waypoint-Metadaten und Runtime-State-Producing aus diesen Metadaten.

## Nicht-Ziele
- Kein Sofort-Oeffnen ohne GO-/Runtime-Pfad.
- Kein neues Door-State-System.
- Kein neues UI-Layout.
- Keine Door-Animation und kein Asset-Swap.
- Kein Mission-Flow-Rewrite.

## Relevante Contracts / Dokumente
- `docs/dev/mission_interaction_point_contract.md`
- `docs/tasks/TASK_693_door_runtime_state_producer.md`
- `docs/tasks/TASK_678_mission_interaction_runtime_progress.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`

## Akzeptanzkriterien
- Eine nutzbare Door-Interaction erzeugt einen akzeptierten Door-Use/Breach-Hook.
- Der Hook nutzt den bestehenden Use-Intent und bleibt `requires_go = true`.
- Der erzeugte Waypoint traegt `door_runtime_hook`, `door_runtime_state_target` und `door_runtime_producer`.
- Der Hook wird im Command-Feedback-Snapshot exportiert.
- Runtime-Progress aus den Hook-Metadaten kann den Door-State-Producer auf `open` setzen.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_694_door_use_breach_command_hook.gd`
- `docs/tasks/TASK_694_door_use_breach_command_hook.md`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_694_door_use_breach_command_hook.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_693_door_runtime_state_producer.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Hook ist noch ein Controller-/Verifier-Pfad. Ein sichtbarer HUD-Button oder Shortcut bleibt ein separater UI-Polish-Slice.
- Der echte FullHD-Sichtlauf bleibt offen.
