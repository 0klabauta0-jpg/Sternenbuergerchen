# Playability Button Reachability Report

## Summary
TASK_257 adds a headless button-reachability verifier for the current playability matrix. The verifier checks required controls for existence, visibility policy, viewport reachability, full-cover diagnostics, signal/action bindings, documented disabled states and a small set of safe click-state changes.

## Covered Screens
- Main Menu and local Settings panel.
- Multiplayer Lobby idle, host-ready and mission-start states.
- Map Editor top bar, authoring controls and marker buttons.
- Homebase fixed windows, aircraft controls and character sheet close path.
- FOB fireteam/loadout/flightdeck action controls.
- Mission HUD command matrix, selected-fireteam and mission-control controls.
- Debrief return buttons.

## Defective Interactions
- None known in the automated TASK_257 pass.
- Context-gated buttons are accepted only when the verifier documents the expected reason, such as host-only start, selected-fireteam context, mission launch readiness or cargo visibility.

## Manual Open Items
- Real mouse hover and focus-ring feel.
- Whether long localized text still reads well after art polish.
- Whether contextual disabled reasons are clear enough to the player without debug knowledge.
- Deep route playthrough from FOB to live mission to debrief remains a human playability check.

## Follow-Up Use
TASK_258 should reuse the same harness and focus on fixed-window clipping, scrollbars and overflow. TASK_259 and TASK_260 should add more specific roster-card and loadout interaction states instead of expanding this verifier into a full UI-flow simulator.
