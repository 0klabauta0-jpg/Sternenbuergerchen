# Contextual Help Popup UX Contract

## Purpose
Contextual help explains controls, values, commands and loadout entries without turning the interface into a manual page. Help is a UI aid only. It must never become gameplay truth, never write to `SimulationRoot`, and never define formulas that differ from existing data or contracts.

## Help Levels
The help system has three user-visible levels:

| Level | Use | Content |
| --- | --- | --- |
| `none` | A control is intentionally self-explanatory or help is disabled. | No popup is shown. Controls may still carry `help_id = ""` with an explicit no-help reason in audits. |
| `compact` | Default hover/focus hint. | Title plus 1 to 3 short lines. It answers "what is this?" and "why should I care?". |
| `detail` | Long hover, pinned help, or expanded help mode. | Compact help plus origin, effect, restrictions, examples or data source notes. |

Compact and detail text must be authored separately. Detail help may reuse the compact title, but it must not depend on a long single-line tooltip.

## Timing
Default timing for mouse and pointer input:

| Event | Delay | Rule |
| --- | --- | --- |
| Compact open | `0.45s` after stable hover | Do not open during fast cursor travel. Reset when target changes. |
| Detail open | `3.5s` after compact is open | Also available immediately when expanded help mode or pin mode is active. |
| Close | `0.15s` after leaving target and popup | Keep open while moving from target to popup. |
| Pin / help mode | immediate | The global help button can make eligible targets expose compact help without hover. |

Keyboard and controller focus use the same compact delay when focus is stable. Touch uses the global help button or an explicit press-and-hold affordance; no hover-only content is allowed.

## Layout
Help popups are fixed overlay UI. They must not resize, shift or replace the fixed Drop Light windows.

Rules:
- Compact popup width is at most `220 px`.
- Detail popup width is at most `260 px`.
- Popup height is at most `45%` of the viewport.
- Popup stays fully inside the viewport with at least `16 px` margin.
- Popup chooses the side with the most free space and should avoid covering the target control.
- Compact text wraps into separate lines; no long one-line tooltip is allowed.
- Detail overflow scrolls inside the popup or expands in a bounded panel.
- Popups are never nested inside screen cards or fixed content panels.
- Popups must not cover the global help button, primary route buttons or active mission command buttons when an alternative side is available.

## Settings
Settings expose a contextual help mode with these values:

| Mode | Meaning |
| --- | --- |
| `off` | No contextual popups. The global help button can still open the help overview later if implemented. |
| `compact` | Show compact help on stable hover/focus. Detail opens only by pin or explicit request. |
| `expanded` | Show compact help quickly and allow automatic detail after the long delay. |

The setting is presentation state. It must be stored with other game settings and must not alter command availability, loadout values, character state or mission state.

## Global Help Button
Each app-shell or HUD context that exposes contextual help gets a small global help button in the top shell/HUD area.

Contract:
- The button toggles help inspection mode for the current screen.
- It is an icon-size control, not a text-heavy panel.
- It does not take ownership of gameplay input.
- It has a stable `help_id` of `shell.global_help_button`.
- In `off` mode it may open a short help overview, but it must not re-enable hover popups until the user changes settings.

## Content Catalog
Help text lives in `data/contextual_help_catalog.json`. Controls reference a stable `help_id`; they do not carry hardcoded long text.

Required entry fields:
- `help_id`: stable lowercase ID, unique in the catalog.
- `screen_id`: screen or shell area that owns the target.
- `area_id`: local panel, control group or value block.
- `status`: `ready`, `draft`, `planned` or `not_applicable`.
- `title`: compact title, maximum 48 characters.
- `compact_lines`: 1 to 3 lines, each maximum 96 characters.
- `detail_lines`: optional detail lines, each maximum 140 characters.
- `target_audience`: `new_player`, `returning_player`, `advanced` or `developer`.
- `manual_review`: boolean.

Catalog-level required areas are listed under `required_screen_areas`. TASK_265 and TASK_266 may add entries, but they must not remove the required keys without updating this contract and its verifier.

## Quality Rules
- Help text explains player-facing meaning, not internal class names.
- A compact line may name a technical term only if the same line or the next line explains it.
- Formula or effect text must point to existing data, resolver names or a documented contract.
- Help may say that a feature is visual-only, decorative or read-only.
- Help must not promise future balance, hidden AI behavior or final art quality.
- Negative states should tell the player what to do next, not only what failed.
- Missing help is acceptable only with an explicit catalog status or no-help exception.

## Coverage
The playability coverage matrix must include contextual help coverage for:
- `main_menu`
- `settings`
- `homebase`
- `fob`
- `character_sheet`
- `loadout`
- `mission_hud`
- `map_editor`
- `multiplayer_lobby`
- `debrief`
- `shell.global_help_button`
- `help_catalog_schema`

Automated checks cover schema, required IDs and length rules. Visual judgment remains manual until TASK_267 adds popup layout checks.

## Non Goals
This contract does not build the popup component, tutorial flow, quest/dialogue help, final help copy for every control, or a full accessibility system. Those are follow-up tasks.
