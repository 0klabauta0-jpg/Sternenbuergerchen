# TASK_N003 — Command Authority and Parity

## Working status

Implementation candidate on `task/project-forward-strangler`. The focused
parity verifier includes a real loopback ENet client/host path; targeted
movement, authority and mission regressions protect the compatibility seam.
This task does not upgrade the separate TASK-1179 Objective/Debrief evidence.

## Goal / problem

Make visible commander controls share one plan-then-GO semantic path and restore `SimulationRoot` as the only authority that commits gameplay mutation.

## Cause / value

Visible button, hotkey, RMB, and GO entry points can drift when they normalize and mutate orders independently. That creates singleplayer/host/client divergence and permits status changes before an accepted authoritative command exists.

## Scope

- Add `CommanderOrderIntent` with command type, selected fireteam IDs, target, phase, and source peer.
- Add `CommandSubmissionResult` with accepted, reason, plan ID, and command token.
- Add `MissionCommandEntryAdapter` to normalize button, hotkey, waypoint RMB,
  area RMB, and GO input.
- Add `FireteamCommandGateway` for planning, validation, network transport, and commit.
- Preserve `MissionCommandFlowDriver` as a compatibility-only path, disconnected from visible product controls.

## Non-goals

- Do not redesign order doctrine, bypass `SimulationRoot`, replace multiplayer transport wholesale, or remove legacy verifier compatibility.

## Relevant contracts / documents

- `docs/ARCHITECTURE.md`
- `docs/dev/fireteam_command_gateway_contract.md`
- `docs/dev/fireteam_runtime_execution_path_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_N002_reproducible_godot_checkout.md`
- existing movement, multiplayer-authority, and objective verifier contracts

## Acceptance criteria

- Singleplayer, host, and connected-client commands plan first and execute only through GO.
- A real connected client stays pending after host queue acknowledgement and
  resolves only from the authority commit receipt; source-peer spoofing is rejected.
- A recreated gateway uses the public `SimulationRoot` revision floor, while a
  delayed older revision leaves the host queue unchanged.
- No product command producer calls `assign_unit_command()` before `SimulationRoot` commits an accepted command.
- Rejected or stale intents leave unit command and runtime status unchanged.
- Parity coverage proves Move, Defend, Flank, Take, waypoint and area RMB,
  multi-fireteam selection, rejection, stale token/revision, and GO.
- Tests first demonstrate pre-tick mutation and host/client semantic divergence, then pass after the narrow change.

## Affected areas

Mission input adapters, tactical command gateway/contracts, `SimulationRoot` command boundary, multiplayer command transport, visible command controls, and focused parity verifiers.

## Verification

Run the new authority/parity tests red then green; run existing fireteam
movement, multiplayer authority, right-click mission and first-command
regressions; inspect product producer call sites; run `git diff --check`.

## Risks / open points

Compatibility adapters may carry hidden side effects. Token lifecycle, peer
identity, revision handoff and network ordering must remain explicit so a
rejected or stale client submission cannot change local visible status.

## Dependency / exit gate

Requires the reproducible N002 checkout. `TASK_N004` may start only after public command entry has a passing plan/GO parity contract and all existing mission regressions remain compatible.
