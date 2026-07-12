# Station Route Live AA Pressure Design

## Goal

Prove the first Station Route objective through the normal player path: after
Homebase, insertion and deboarding, Alpha moves to the authored AA marker,
encounters the authored Bravo guard, exposes the AA contextual action and
completes it through the existing GO path.

## Design

The scope is a headless regression only. It reuses the real Homebase,
Dropship, MissionTacticalSandboxController, FireteamMovementController,
SimulationRoot and MissionCombatLoopDriver path. The test advances the real
SimulationRoot physics tick and controller execution with a bounded simulated
delta so the route is practical to run in CI. It never assigns a unit
position, gate state, contact, fire event, damage event or mission result.

The first normal move is a `move` order to `factory_danger_zone`. The test
records that the friendly formation has materially moved, that the authored
Bravo AA watch creates contact on arrival, and that the AA contextual action
is available only after arrival. The AA watch uses the existing
`factory_danger_zone` marker rather than the unrelated distant PvP spawn. It
then presses the existing contextual button, confirms that it created an
interaction intent, sends the existing GO command and observes the existing
runtime completion.

## Boundaries

- SimulationRoot remains the sole movement and interaction mutation path.
- UI controls only create the established command/intent; the test observes
  their results.
- The accelerated delta is test harness time, not a game-speed or balance
  change.
- This task does not alter combat, NPC tactics, map geometry, interaction
  rules, multiplayer authority or the HUD.

## Failure Interpretation

If the formation does not arrive, the test reports the existing movement state
and leaves production code unchanged until the concrete blocker is identified.
If a contact halts the order before arrival, that is useful evidence for the
next small gameplay task: a player must receive a legible recovery decision,
rather than the test bypassing the situation.
