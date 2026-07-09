# TASK_968 - Release First Decision Loop Two Runtime Button

## Ziel / Problem
TASK_967 macht den zweiten Entscheidungsgriff als Smoke-Evidence pruefbar, aber der Spieler braucht einen sichtbaren Runtime-Zugang. TASK_968 legt den zweiten Griff als `2ND`-Button in der bestehenden Command-Matrix an.

## Sinnhaftigkeit / Ursache
Der Release-First-Loop soll nicht nur in Snapshots existieren. Nach HOLD/ADV/BACK muss der Spieler im HUD einen kleinen, klaren Griff haben: `2ND` bestaetigt den empfohlenen zweiten Intent, danach bleibt `GO` als separater bestehender Ausfuehrungsschritt sichtbar.

## Umfang
- Neuer read-only Service `ReleaseFirstDecisionLoopTwoRuntimeButton`.
- Controller-Snapshot `get_release_first_decision_loop_two_runtime_button_snapshot()`.
- Runtime-Confirm-Methode `confirm_release_first_decision_loop_two_runtime_button()`.
- Bestehender Command-Matrix-Reserveplatz `CommandSlot07` wird als `2ND`-Button genutzt.
- Command-Feedback exportiert Runtime-Button-Snapshot, Zeile, Gate und Status.

## Nicht-Ziele
- Kein neues Ordersystem.
- Kein automatisches GO.
- Kein neuer Command-Queue-Besitzer.
- Keine Mutation im Snapshot-Service.
- Keine Aenderung an `SimulationRoot` oder Multiplayer-Wahrheit.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_967_release_first_decision_loop_two_go_smoke.md`
- `docs/tasks/TASK_966_release_first_decision_loop_two_execution_hook.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/ARCHITECTURE.md`

## Akzeptanzkriterien
- Fehlende oder unbrauchbare TASK_967-Source blockiert den Button.
- `needs_go_smoke_run` aus TASK_967 darf den manuellen Runtime-Button armen, damit der reale Smoke erzeugt werden kann.
- `loop_two_go_smoke_passed` markiert den Button als bereit fuer Real-Window-Capture.
- Button nutzt `CommandSlot07`, Text `2ND`, Tooltip und Callback.
- Der Callback bestaetigt nur ueber vorhandene Pfade: `_issue_command(...)` oder `return_selected_fireteams_to_plan()`.
- `execute_selected_fireteam_orders()` bleibt ein separater GO-Schritt.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_runtime_button.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_968_release_first_decision_loop_two_runtime_button.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_968_release_first_decision_loop_two_runtime_button.gd`
- `godot_console.exe --headless --path . --script res://scripts/tests/task_967_release_first_decision_loop_two_go_smoke.gd`
- `godot_console.exe --headless --path . --script res://scripts/tests/task_966_release_first_decision_loop_two_execution_hook.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_968 macht den Griff erreichbar, ersetzt aber keine echte Fensterabnahme. `TASK_969 - Release First Decision Loop Two Real Window Capture` sollte die zweite Entscheidung im realen Fenster capturen und beurteilen, ob Button, Confirm, GO und Feedback fuer den Spieler wirklich rund lesbar sind.
