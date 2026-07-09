# TASK_993 - Release First Decision Loop Two Player Loop Micro Objective Runtime Buttons

## Ziel / Problem
TASK_992 erzeugt einen vorbereitenden Command-Draft fuer die fokussierte Micro-Objective, aber die drei Micro-Objectives sind noch nicht als stabile Runtime-Button-Specs greifbar.

TASK_993 baut drei read-only Button-Specs fuer `SICHERN`, `DRUECKEN` und `SAMMELN`.

## Sinnhaftigkeit / Ursache
Der Loop soll sich fuer den Spieler wie eine echte naechste Entscheidung anfuehlen. Dafuer braucht er kompakte, stabile Button-Surfaces, die auf bekannte Command-Slots zeigen und trotzdem den bestehenden Confirm-/GO-Pfad respektieren.

## Umfang
- Neuer read-only Runtime-Buttons-Service fuer TASK_993.
- Bewertung einer bereiten TASK_992-Quelle plus TASK_991-HUD-Wiring.
- Drei Button-Specs auf `CommandSlot08`, `CommandSlot09` und `CommandSlot10`.
- Press-Action: `confirm_release_first_decision_loop_two_player_loop_micro_objective_button`.
- GO bleibt `execute_selected_fireteam_orders`.
- Controller-Snapshot und Command-Feedback-Export.
- Status-/Roadmap-/Contract-Update.

## Nicht-Ziele
- Kein echter Button-Click-Handler.
- Kein automatischer Command-Confirm.
- Kein automatischer `GO`.
- Kein Movement-, Combat-, Damage- oder Multiplayer-Rewrite.
- Keine Umordnung der bestehenden Command Matrix.

## Relevante Contracts / Dokumente
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_992_release_first_decision_loop_two_player_loop_micro_objective_choice_hook.md`
- `docs/tasks/TASK_991_release_first_decision_loop_two_player_loop_micro_objective_hud_wiring.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`

## Akzeptanzkriterien
- TASK_993 blockiert ehrlich, wenn TASK_992 oder TASK_991 nicht bereit oder nicht read-only ist.
- Ein bereiter TASK_992/TASK_991-Stand erzeugt drei Button-Specs.
- Button-Slots sind stabil: `CommandSlot08`, `CommandSlot09`, `CommandSlot10`.
- Buttons nennen `SICHERN`, `DRUECKEN` und `SAMMELN`.
- Press-Action und GO-Pfad sind getrennt; kein Button fuehrt automatisch GO aus.
- Controller exportiert TASK_993 im Command-Feedback.
- Snapshot und Controller-Export erzeugen keine UI-, Command-, Movement-, Fire-, Damage- oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_micro_objective_runtime_buttons.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_993_release_first_decision_loop_two_player_loop_micro_objective_runtime_buttons.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_993_release_first_decision_loop_two_player_loop_micro_objective_runtime_buttons.gd`
- Regression: TASK_992, TASK_991, TASK_990
- `git diff --check`

## Risiken / offene Punkte
- TASK_993 liefert Button-Specs, aber noch keinen echten Click-Confirm-Smoke.
- Naechster sinnvoller Schritt: `TASK_994 - Release First Decision Loop Two Player Loop Micro Objective Confirm Smoke`.
