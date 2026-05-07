# Cross Screen State Loss Playability Report

## Summary
TASK_261 covers a deterministic cross-screen smoke for settings, Homebase, FOB, Mission, Debrief, Editor, and Multiplayer preparation. The test keeps the same selected unit IDs and fireteam assignments moving through the flow and checks that screens do not create stale or duplicate gameplay state.

## Main Flow
- Main Menu routes to Singleplayer, Multiplayer, and Editor are verified.
- Settings are changed, applied, and reloaded through the settings contracts.
- Homebase transfers an operator into the staged team and keeps the full roster represented.
- FOB receives the selected units, fireteam assignments, and Rocket/None loadout without stale Character Card identity.
- Mission setup receives selected unit IDs and loadout weight.
- Debrief receives a mission result and exposes character progression.
- Returning to Homebase keeps selected team size and unit identity.

## Editor Flow
- The editor opens after the main flow.
- Height authoring remains reachable.
- A small authored tile roundtrips through save/load.
- Editor authoring does not mutate selected roster state or persisted settings.

## Multiplayer Preparation
- Lobby host and join controls open after the editor flow.
- Host-ready state emits exactly one mission-start request.
- Client state cannot start the mission.
- Disconnect returns the lobby to idle.
- Lobby preparation does not create a gameplay `SimulationRoot`.

## State Invariants
- Roster ID set stays intact after mission progression.
- Selected unit order survives Homebase -> FOB.
- Fireteam assignment order survives Homebase -> FOB.
- Character Card identity updates when switching selected operators.
- Loadout weight stays `9.0` for the Rocket/None operator in FOB and Mission.
- Idle Main Menu and Lobby screens do not duplicate UI audio events.
- Settings persist unless explicitly changed.

## Open Items
- This is a headless smoke and does not replace manual checks for drag-and-drop feel, visual page transitions, or real two-client network behavior.
- End-to-end failure localization should still be paired with the smaller screen-specific verifiers.
