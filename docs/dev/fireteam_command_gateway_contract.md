# Fireteam Command Gateway Contract

Status: N003 implementation contract; a release claim still requires fresh evidence records.

## Why this exists

A player should be able to give the same order with a button, a hotkey or a
right-click. Those are different input gestures, not different game rules.

In plain language: the UI writes a draft on a clipboard, `GO` hands that
clipboard to the referee, and only the referee (`SimulationRoot`) starts the
actual order. No UI control, renderer or legacy flow driver may quietly start
units before that point.

## One path

```text
Button / Hotkey / RMB
  -> MissionCommandEntryAdapter
  -> FireteamCommandGateway (plan only)
  -> GO
  -> SimulationRoot (validate + authoritative queue)
  -> authoritative tick emits commander_intent_committed
  -> reliable authority commit receipt for the requesting client
  -> Mission tactical execution / FireteamMovementController
  -> UnitCommand dictionaries return to SimulationRoot
```

`CommanderOrderIntent` carries the player-facing plan: doctrine, selected
Fireteams, target, phase, peer and entry source. `CommandSubmissionResult`
describes the result without changing gameplay: accepted/rejected, reason,
plan ID, token, pending/committed and per-Fireteam details.

## Authority rules

- Planning is mission-planning state only. It queues no gameplay command and
  does not change a UnitCommand or runtime status.
- `FireteamCommandGateway.submit_go()` creates one immutable commander intent
  per selected Fireteam, each with a peer-scoped plan namespace and its own
  command token.
- `SimulationRoot` is the sole validation and queue boundary. A stale revision,
  duplicate token, foreign team, source-peer spoof or invalid payload is
  rejected before enqueue. Its public next-revision query prevents a recreated
  gateway from restarting below an accepted Fireteam revision.
- The commander-intent tick activates mission execution. The generated member
  `UnitCommand` dictionaries are applied by `SimulationRoot` on its later
  authoritative drain, never by an input producer.
- A connected client sends the same envelope through `request_command()` and
  remains pending after queue acknowledgement. The authority sends a reliable
  commit receipt only after its tick; that receipt resolves the gateway result
  and produces read-only UI feedback. World state still comes from the normal
  authoritative runtime/snapshot path, so pressing `GO` cannot activate a
  waypoint locally.
- RMB waypoint and RMB area orders use the same adapter. Area plans carry a
  target-area ID and their authored area payload, then are activated only by
  the authoritative commander-intent tick.

## Compatibility boundary

`MissionCommandFlowDriver`, `RuntimeLeader` and `FTLTask` remain available for
historical tests and observability. They are not a visible input fallback.
The tactical controller may mirror an already authoritative order for legacy
readability, but button, hotkey, RMB and GO cannot invoke a flow-driver issue
method to create gameplay truth.

## Required regression evidence

- Focused N003 parity coverage: Move, Defend, Flank, Take, multi-Fireteam,
  waypoint and area RMB normalization, plan/GO separation, duplicate/stale,
  source-peer and foreign-team rejection. It includes a real loopback ENet
  client-to-host run, authority queue acknowledgement, commit receipt and
  recreated-client revision floor.
- Existing movement and multiplayer authority verifiers remain green.
- A real multi-Fireteam mission path proves that authoritative activation still
  applies tactical coordination after the second committed Fireteam intent.
- `TASK_1179` is a separate objective/debrief lifecycle gate. It is not made
  green by this contract and must retain its existing evidence caveat until a
  clean recapture exists.

## Growth rule

The adapter owns input normalization; the gateway owns plan/result transport;
`SimulationRoot` owns authority. Do not add renderer, HUD, networking UI or
combat decisions to these modules. If a new module approaches 800 lines,
extract a focused collaborator before extending it.
