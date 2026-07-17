# TASK_N004 — Canonical Product Mission

## Goal / problem

Move the player-visible mission entry off test paths while retaining legacy-verifier compatibility and integrate the recovered first-contact/live-fire trace on the public authored route.

## Cause / value

The product must not depend on `scripts/tests` or `scenes/tests` for its visible mission graph. The recovered `TASK_1180` trace is useful but currently exists only outside this checkout; it becomes current evidence only when ported to public commands and `grid_sweep` without private controller calls.

## Scope

- Add `scenes/mission/mission_runtime.tscn` as the canonical product mission.
- Move or wrap productive controllers/drivers under `scripts/mission` and `scripts/tactical`.
- Retain `scenes/tests/mission_reactivity_test.tscn` as a compatibility wrapper around the product scene.
- Make singleplayer and multiplayer lobby load the product scene.
- Port recovered `TASK_1180` task/verifier to the public command and authored-map path.

## Non-goals

- Do not big-bang rewrite tactical systems, delete test scenes, call private controller methods, teleport units/enemies, or alter combat outcome for a green trace.

## Relevant contracts / documents

- `docs/ARCHITECTURE.md`
- `docs/dev/runtime_script_layout_contract.md`
- `docs/dev/fireteam_runtime_execution_path_contract.md`
- `docs/tasks/TASK_N003_command_authority_parity.md`
- `docs/tasks/TASK_1179_ground_mission_objective_playthrough.md`
- recovered `TASK_1180_ground_mission_first_contact_live_fire_trace.md` as candidate source only

## Acceptance criteria

- Product scene graph has no dependency on `scripts/tests` or `scenes/tests`.
- The old test scene remains a working compatibility wrapper.
- Singleplayer and multiplayer lobby use the canonical product scene.
- An architecture test fails before extraction and passes after it.
- Integrated `TASK_1180` runs twice on authored `grid_sweep`, reaches real contact and a live fire/wait/blocked decision through public commands, and its snapshots remain read-only.

## Affected areas

Mission scene entry graph, mission/tactical adapters, lobby entry points, legacy test wrapper, public `TASK_1180` verifier/task documentation, and current evidence manifest.

## Verification

Run architecture test red then green; run existing test-scene verifiers; run `TASK_1180` twice plus `TASK_1179`, `TASK_542`, and `TASK_543` regressions; inspect the product dependency graph; run `git diff --check`.

## Risks / open points

Scene/resource extraction can break UIDs or autoload ownership, which N002 must already make reproducible. A legitimate first decision may be waiting or blocked, but it must expose its specific reason rather than being forced into a hit.

## Dependency / exit gate

Requires N003 command parity. `TASK_N005` and N006 may proceed only after the product entry is public-path clean, compatibility tests pass, and the formerly recovered `TASK_1180` is integrated with two fresh runs.
