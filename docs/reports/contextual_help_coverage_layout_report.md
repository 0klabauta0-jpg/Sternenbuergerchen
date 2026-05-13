# Contextual Help Coverage Layout Report

## Summary
TASK_267 turns the contextual help system into a regression gate. The automated pass checks catalog shape, text length, wrappable copy, visible `help_id` coverage, popup viewport clamping, compact/detail width limits, off/compact/expanded settings behavior, hover timing, pinned detail help and the global help button.

## Automated Coverage
- Main Menu, Settings, Multiplayer Lobby, Map Editor, Homebase, FOB, Debrief and Mission HUD are instantiated headless and scanned for visible `help_id` metadata.
- Every visible `help_id` must exist in `data/contextual_help_catalog.json`.
- Required player-facing IDs from TASK_263 through TASK_266 must appear on visible controls unless listed as a documented exception.
- Ready catalog IDs that do not appear in the current fixture scenes are reported as unused fixture coverage, not silently ignored.

## Text Quality
- Titles must be present and stay below the compact title limit.
- Compact help must use one to three short lines.
- Detail lines must stay within the wrapping limit and must not contain local machine paths.
- Long unbroken tokens are rejected so labels can wrap inside the popup width.

## Layout and Timing
- Each catalog entry is rendered through `ContextualHelpPopup` in compact and detail form against top-left, top-right, bottom-left, bottom-right and center targets.
- Popups must remain in the viewport, respect 220 px compact width, 260 px detail width and the 45 percent viewport-height limit.
- When normal space exists, the popup must sit beside the target instead of covering it.
- Off mode suppresses help; compact mode never auto-expands detail; expanded mode reaches detail after the long-hover delay; pinned/global help paths are tested.
- The global help button is pressed in the Main Menu and must visibly open `shell.global_help_button`.

## Documented Exceptions
- `editor.back` stays `todo` because the current editor scene still has no visible Back control.
- `mission.command.roe_fire_rules` was resolved by TASK_271 and remains covered by the Tactical command/help gates.
- These exceptions are tracked in the catalog, matrix and verifier so later tasks cannot forget them.

## Manual Remainder
- Final copy tone and German/English wording still need human reading.
- Real monitor scale can still reveal subjective readability issues that headless layout cannot judge.
- Unused ready IDs reported by the fixture pass should be reviewed when new screen states or profile variants become visible.

## Follow-Up
TASK_268 should run the broader playability smoke with contextual help off, compact and expanded so the overlay gate is validated together with route, button and fixed-window behavior.
