# Drop Light Layout Profiles Compact Resolution

## Summary
TASK_334 keeps the existing Drop-Light `full_hd` contract as the fixed 1920x1080 reference and adds the `compact_720` profile for 1280x720 viewports. Homebase, FOB and Mission HUD now resolve their active profile from the visible viewport and continue to apply rectangles from `DropLightLayoutContract`.

## Automated Coverage
- FullHD layout rectangles for FOB, Homebase and Mission HUD are compared against the previous pixel values.
- Compact contract rectangles are checked for 1280x720 bounds, grid alignment and minimum window sizes.
- Compact Homebase, FOB and Mission HUD scene instances are checked for profile metadata, applied fixed rectangles, reachable critical buttons and internal scroll containers.
- Regression gates remain on the existing FullHD playability audit and the dropship command matrix layout gate.

## Manual Sightcheck
- At 1280x720, verify whether dense labels in FOB loadout rows and Mission selected-fireteam text feel comfortable after scrolling.
- At FullHD, confirm that the compact-profile plumbing did not visually shift the established Drop-Light composition.
- With OS/UI scaling enabled, confirm that clipped dynamic dropship labels such as cooldown or inbound states remain understandable through tooltip and context.
- In Mission HUD, check whether the compact command matrix feels better as five columns or should become a later profile-specific grid tuning task.

## Risks
The profile system must stay centralized in `DropLightLayoutContract`. Future fixes should add profile values there and should not reintroduce scattered screen-local pixel truths. Compact layout is intentionally a fixed-profile bridge, not a full responsive layout rewrite.
