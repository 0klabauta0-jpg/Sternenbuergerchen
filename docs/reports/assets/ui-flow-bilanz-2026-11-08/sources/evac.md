# Mission Evacuation Abort Contract

## Scope

TASK_1069 adds a small mission-wide evacuation outcome for the current
singleplayer or host-authoritative Station Route. It reuses the existing
CombatLoopDriver result signal and MetaLayerFlow Debrief handoff.

## Authority

- `MissionCombatLoopDriver` owns the authoritative abort result.
- Only local server authority may accept an evacuation request.
- The Tactical Controller checks player-facing LZ eligibility and asks the
  Combat Driver to resolve; it does not write a MissionResult itself.
- Non-authority calls return a rejected result and do not create local result,
  movement, damage, fire or multiplayer truth.

## Eligibility

Evacuation is available only when all of these are true:

- a mission LZ exists;
- at least one selected Ground-Fireteam is active;
- every selected Ground-Fireteam anchor is within the evacuation LZ radius;
- the mission is active and the caller is local authority.

The button may explain a missing LZ or a Fireteam outside the radius. It never
stores eligibility as a second gameplay state.

## Result

An accepted request resolves the current mission once with:

- `result = aborted`
- `mission_outcome = aborted`
- `win_condition_type = evacuation`
- empty `winning_team_id`

The existing `combat_resolved` signal carries this result to MetaLayerFlow.
MetaLayerFlow continues to enrich it with team state and Mini AAR before
opening Debrief.

## Multiplayer Boundary

TASK_1069 is not a unilateral PvP team extraction feature. In a multiplayer
mission, only host authority can end the shared mission through this path.
Client-side request transport and per-team extraction need a separate task.

## Non Goals

- No auto-GO or auto-withdraw.
- No dropship boarding animation.
- No new pathfinding, damage, combat or replication system.
