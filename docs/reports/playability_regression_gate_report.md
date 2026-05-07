# Playability Regression Gate Report

## Summary
TASK_262 defines the repeatable local Playability Gate for UI and playability work. The gate groups the automated checks from TASK_256 through TASK_261 and keeps subjective checks in a short manual list.

## Gate Tasks
| Task | Scope | Script | Last Local Result |
| --- | --- | --- | --- |
| TASK_256 | Coverage contract and harness | `scripts/tests/task_256_automated_playability_coverage_contract.gd` | 50/0 |
| TASK_257 | Button reachability | `scripts/tests/task_257_button_reachability_and_interaction_verifier.gd` | 427/0 |
| TASK_258 | Fixed windows, clipping, scrollbars | `scripts/tests/task_258_fixed_window_clipping_scrollbar_playability_audit.gd` | 67/0 |
| TASK_259 | Character cards and roster switching | `scripts/tests/task_259_character_card_roster_switching_playability.gd` | 51/0 |
| TASK_260 | Loadout, decorative weapons, weight | `scripts/tests/task_260_loadout_selection_decorative_weapons_weight_playability.gd` | 72/0 |
| TASK_261 | Cross-screen state loss | `scripts/tests/task_261_cross_screen_state_loss_playability_smoke.gd` | 67/0 |

## Hard Failures
No hard failures are expected in the current gate baseline. A non-zero exit code from any gate task or from `git diff --check` is a hard failure.

## Warnings
Warnings should be reserved for documented automated limitations, such as headless-only coverage or intentionally manual visual judgement. Warnings must name the screen, task, and next action.

## Manual Items
Manual checks are limited to the items in `docs/manual_checks/playability_manual_open_items.md`: audio feel, subjective readability, drag-and-drop feel, screen transitions, and real two-client multiplayer behavior.

## Coverage Matrix
The coverage source of truth is `docs/qa/playability_coverage_matrix.md`. New UI screens, primary buttons, routes, or stateful flows must update the matrix and either join the automated gate or add a named manual item.

## Standard Command
Run the full local gate with:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/tests/run_task_262_playability_gate.ps1
```

Run the contract verifier with:

```powershell
godot_console.exe --headless --path . --script scripts/tests/task_262_playability_regression_gate_and_manual_open_items.gd
```
