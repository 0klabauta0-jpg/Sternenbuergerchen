# Station Route Live AA Pressure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Establish a no-teleport regression for the first playable Station
Route objective under the authored NPC guard pressure.

**Architecture:** The verifier drives existing Homebase, Dropship,
MissionTacticalSandboxController, SimulationRoot and combat-driver paths. It
uses bounded accelerated calls to the existing physics and controller ticks,
but does not add production code or a parallel mission state.

**Tech Stack:** Godot 4.6.2, GDScript, headless SceneTree verifier.

## Global Constraints

- No direct unit-position, contact, gate, result, fire or damage mutation.
- SimulationRoot remains authoritative for movement and interaction progress.
- Preserve existing singleplayer and multiplayer interaction paths.
- Keep the verification bounded and suitable for a headless regression run.

---

### Task 1: First AA Live Route Verifier

**Files:**
- Create: `scripts/tests/task_1175_station_route_live_aa_pressure.gd`
- Create: `docs/tasks/TASK_1175_station_route_live_aa_pressure.md`
- Modify: `docs/IMPLEMENTATION_STATUS.md`
- Modify: `docs/TASK_ROADMAP.md`

**Interfaces:**
- Consumes: `MissionTacticalSandboxController.issue_right_click_command_for_test()`, `execute_selected_fireteam_orders()`, `get_fireteam_movement_state()`, `get_primary_mission_interaction_button_snapshot()` and `SimulationRoot._physics_process(delta)`.
- Produces: A regression result proving normal movement, contact, contextual AA intent and existing AA completion, or a specific failing stage.

- [x] **Step 1: Write the failing test**

Create a SceneTree verifier that starts the Station Route through Homebase,
deboards at the authored LZ, issues `move` to `Vector2(5376, 7008)`, advances
the real simulation/controller ticks and expects formation movement, authored
contact, an enabled `AA` contextual button, a GO-separated interaction intent
and `aa_disabled` completion.

- [x] **Step 2: Run test to verify it fails**

Run: `godot_console.exe --headless --path . --script scripts/tests/task_1175_station_route_live_aa_pressure.gd`

Expected: A focused assertion failure at the first missing live route stage,
without parser errors or direct-state helper use.

- [x] **Step 3: Apply the smallest evidence-backed repair**

Only if the failure identifies a concrete existing path break, modify the
responsible existing movement or interaction bridge. Do not add automation,
teleports or test-only production flags.

- [x] **Step 4: Run the verifier and regressions**

Run: `godot_console.exe --headless --path . --script scripts/tests/task_1175_station_route_live_aa_pressure.gd`

Expected: `0 failed`, with normal movement and existing AA completion.

Run: `godot_console.exe --headless --path . --script scripts/tests/task_1078_station_route_approach_contact_timing.gd`

Expected: `0 failed`, preserving the original first-contact path.

- [x] **Step 5: Document and commit**

Update the task, implementation status and roadmap with the actual evidence.
Run `git diff --check`, stage only TASK_1175 files and changed runtime files,
then commit the isolated task.
