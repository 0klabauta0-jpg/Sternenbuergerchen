# Playability Layout Clipping Scrollbar Report

## Summary
TASK_258 audits fixed-window playability without making the top-level screens responsive. The automated pass checks fixed Full-HD contracts, viewport containment, required ScrollContainers, long roster fixture data, critical label/button overflow approximations and editor palette scrollability.

## Covered Screens
- Main Menu and Settings panel.
- Multiplayer Lobby at its 1280x720 shell size.
- Homebase fixed Full-HD windows with a long roster fixture.
- FOB fixed Full-HD windows with transfer/loadout fixture data.
- Mission HUD fixed Full-HD panels and scroll surfaces.
- Map Editor top bar, palette and property panel.

## Automated Findings
- No known fixed-window regression in the automated TASK_258 pass.
- Long Homebase roster data stays inside `RosterScroll`.
- FOB fireteams, loadout members and flightdeck queue keep explicit ScrollContainers.
- Mission command, selected fireteam and mission control panels keep explicit ScrollContainers.
- Editor palette remains an `ItemList`, which provides built-in scrolling for long tile catalogs.

## Manual Remainder
- Final text legibility and visual polish at real monitor scale.
- Hover/focus visibility inside scrollable regions.
- Whether intentional portrait or icon masks feel cropped in a good way.
- Optional 1280x720 warning-profile judgement for Full-HD-only Drop Light screens.

## Follow-Up
TASK_259 should use the same harness for character-card switching and roster state. TASK_260 should stress loadout rows with decorative/non-selectable weapon data instead of turning this audit into a broad feature test.
