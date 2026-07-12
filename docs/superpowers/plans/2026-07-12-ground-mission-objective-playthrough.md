# Ground Mission Objective Playthrough Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prove that the existing `grid_sweep` singleplayer mission can travel
from Homebase through deployment to an authoritative objective result.

**Architecture:** The verifier drives the existing MetaLayer flow and submits
the same commander intent that the player uses. Mission, ObjectiveStatus and
SimulationRoot remain the sole mutation owners; the verifier only observes
their snapshots and result handoff.

**Tech Stack:** Godot 4.6.2, GDScript, existing meta and mission test scenes.

## Global Constraints

- Use `SimulationRoot.enqueue_command()` through the existing controller path.
- Do not set unit positions, objective state, mission result, damage or contact
  state directly in test code.
- Do not add UI-owned gameplay state or a SceneTree scan to a runtime hotpath.
- Leave `builds/` and the user-owned untracked TASK_1064 file untouched.

---

### Task 1: Ground Mission End-to-End Verifier

**Files:**
- Create: `scripts/tests/task_1179_ground_mission_objective_playthrough.gd`
- Test: `scripts/tests/task_1179_ground_mission_objective_playthrough.gd`

**Interfaces:**
- Consumes: `MetaLayerFlow._on_homebase_mission_selection_changed`, Homebase
  start request, existing craft arrival/drop methods and
  `MissionTacticalSandboxController.issue_right_click_command_for_test`.
- Produces: a stage-labelled, read-only trace from Homebase to ObjectiveStatus
  and the existing debrief result handoff.

- [x] **Step 1: Write the failing verifier**

Create a trace that selects `grid_sweep`, starts Homebase, completes only the
existing transfer and drop callbacks, issues a normal `take` command to the
authored `objective_point`, and asserts an authoritatively completed result.

- [x] **Step 2: Run the verifier to verify the missing or broken stage**

Run: `godot_console.exe --headless --path . --script scripts/tests/task_1179_ground_mission_objective_playthrough.gd`

Expected: a non-zero exit with a stage-specific assertion, or a passing trace
that proves no production repair is required.

- [x] **Step 3: Repair only the observed owning path**

If the trace exposes a real defect, modify the smallest existing owner in the
MetaLayer, mission controller or objective resolver. Do not add a parallel
completion path in the test or HUD.

- [x] **Step 4: Run the verifier and focused regressions**

Run TASK_1179, TASK_344 and TASK_501. Expect all checks to pass and the
verifier to report every stage explicitly.

- [x] **Step 5: Update task documentation and commit**

Record the precise result and command output in IMPLEMENTATION_STATUS and the
roadmap, then commit only task-owned files.

## Plan Self-Review

- Scope is one existing mission flow and one focused verifier.
- No new systems, HUD state or scenario schema are introduced.
- The test has a direct authoritative result condition and forbids test-side
  truth mutation.
