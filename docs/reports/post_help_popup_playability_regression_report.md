# Post Help Popup Playability Regression Report

## Summary
TASK_268 verifies that contextual help did not regress the existing playability gates. The smoke checks help off, compact and expanded modes against core controls, fixed-window stability and the global help button. It does not replace the deeper TASK_262 and TASK_267 gates; it links them and tests their interaction.

## Gate Links
- TASK_262 remains the broad playability regression gate for buttons, fixed windows, character card switching, loadout, cross-screen state and manual open items.
- TASK_267 remains the contextual help coverage/layout gate for catalog quality, popup clamping, timing and visible `help_id` metadata.
- TASK_268 runs a smaller integration smoke over both assumptions.

## Help Mode Smoke
- `off`: Help requests stay hidden and normal buttons remain reachable.
- `compact`: Short help appears without blocking required controls.
- `expanded`: Detail-capable help appears after long-hover style timing and still uses input-transparent popup behavior.
- The global help button opens `shell.global_help_button` only when help is enabled.

## Covered Flows
- Main Menu and Settings panel open/close while help is off, compact and expanded.
- Multiplayer Host/Join preparation controls stay visible and wired.
- Map Editor brush and height tools remain reachable.
- Homebase roster/character sheet controls remain reachable.
- FOB fireteam and loadout surfaces remain reachable/readable.
- Mission command and selected-fireteam controls remain reachable.
- Debrief return controls and character update help metadata remain present.

## Layout Findings
- Help popup uses `MOUSE_FILTER_IGNORE`, so it cannot intercept input.
- Help popup rendering does not move Drop Light fixed windows on Homebase, FOB or Mission HUD.
- Popups stay inside the viewport through the TASK_267 gate; this smoke verifies they also coexist with key controls.

## Manual Remainder
- Final copy tone and localized wording.
- Subjective readability at real monitor scale.
- Whether long detail text feels helpful rather than noisy during live play.

## Standard Commands
- `godot_console.exe --headless --path . --script scripts/tests/task_268_post_help_popup_playability_regression_smoke.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_262_playability_regression_gate_and_manual_open_items.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_267_contextual_help_coverage_layout_verifier.gd`
- `git diff --check`
