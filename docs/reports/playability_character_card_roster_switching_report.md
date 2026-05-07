# Playability Character Card Roster Switching Report

## Summary
TASK_259 covers the character-card and roster-switching paths that are most likely to lose identity, selection, fireteam assignment, or progression state. The automated verifier uses existing screen APIs and card signals only; UI does not become gameplay truth.

## Covered Screens
- Homebase: roster card access, transfer-team card access, pool-to-team staging, duplicate staging feedback, and team-to-pool removal.
- FOB: fireteam member card access, fireteam-to-fireteam reassignment, clear-to-pool, pool-to-fireteam reassignment, invalid reassignment blocking, and loadout-slot card overlay access.
- Mission HUD: selected-fireteam card access and character overlay synchronization.
- Debrief: character progression updates from the mission result.
- Roster Save/Load: fireteam assignment persistence and mission progression roster set integrity.

## State Integrity
- Selected unit IDs must remain unique after every reassignment.
- Selected fireteam assignments must stay aligned with selected unit IDs.
- Invalid reassignment attempts must not mutate assignment arrays.
- Save/load must preserve the expected fireteam IDs for staged operators.
- Mission progression must not drop or duplicate roster units.

## Automated Findings
The verifier is expected to fail on:
- missing or disconnected NPC compact-card open signals;
- missing character sheet or overlay after a card open;
- character sheet identity not matching the selected card;
- duplicate staged operators after repeated Homebase transfer attempts;
- lost selected units after FOB reassignment;
- missing loadout card access for staged fireteams;
- missing debrief character update text;
- save/load assignment mismatch.

## Manual Remainder
- Real mouse drag feel, hover state, and double-click timing remain manual checks.
- Portrait-by-portrait visual identity is sampled by automated data integrity and should still get a visual pass.
- Debrief does not yet expose full interactive character cards; this task verifies the progression/readback path and leaves deeper interaction to a later UI pass if required.
- Localized long display names should be read in the actual Full-HD viewport after text/localization changes.
