# First Engagement Release Recapture Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the first post-contact engagement decision readable and release-bound without adding gameplay mutation.

**Architecture:** Add one read-only `MissionTacticalSandboxController` snapshot that combines TASK_1172, TASK_543 and existing release evidence. The verifier supplies compact Handoff fixtures, asserts queue immutability, and leaves the heavy real engagement reproduction to TASK_543.

**Tech Stack:** Godot 4.6.2, GDScript, existing mission tactical contracts, headless SceneTree verifiers.

## Global Constraints

- `SimulationRoot` remains the only authoritative mutation path.
- No SceneTree scans or UI rebuilds are introduced in runtime hotpaths.
- The new snapshot sets `read_only = true`, `ui_sets_gameplay_truth = false`, and all `creates_*`/multiplayer-mutation flags to `false`.
- The task branch starts from `integration/core-foundation` and leaves unrelated untracked files untouched.

---

### Task 1: Specify and prove the release-recature contract

**Files:**
- Create: `docs/tasks/TASK_1173_first_engagement_feedback_release_recapture.md`
- Create: `docs/superpowers/specs/2026-07-12-first-engagement-release-recapture-design.md`
- Create: `scripts/tests/task_1173_first_engagement_feedback_release_recapture.gd`
- Modify: `scripts/tests/mission_tactical_sandbox_controller.gd`

**Interfaces:**
- Consumes: `get_mission_first_contact_readability_release_recapture_snapshot()` and `get_mission_first_engagement_feedback_snapshot()`.
- Produces: `get_mission_first_engagement_feedback_release_recapture_snapshot(first_contact_recapture_override: Dictionary = {}, engagement_feedback_override: Dictionary = {}) -> Dictionary`.

- [ ] **Step 1: Write the failing test**

```gdscript
var snapshot: Dictionary = Dictionary(controller.call(
    "get_mission_first_engagement_feedback_release_recapture_snapshot",
    _build_task_1172_handoff_fixture(),
    _build_task_543_engagement_fixture()
))
_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.mission_first_engagement_feedback_release_recapture.v1", "Snapshot schema is stable")
_assert(bool(snapshot.get("ready_for_first_fire_visual_recapture", false)), "Snapshot opens the first fire visual recapture")
_assert(Array(simulation_root.get("command_queue")).size() == command_count_before, "Snapshot enqueues no command")
```

- [ ] **Step 2: Run test to verify it fails**

Run: `godot_console.exe --headless --path . --script scripts/tests/task_1173_first_engagement_feedback_release_recapture.gd`

Expected: FAIL because `get_mission_first_engagement_feedback_release_recapture_snapshot` is not present.

- [ ] **Step 3: Write minimal implementation**

```gdscript
func get_mission_first_engagement_feedback_release_recapture_snapshot(first_contact_recapture_override: Dictionary = {}, engagement_feedback_override: Dictionary = {}) -> Dictionary:
    var first_contact_recapture: Dictionary = first_contact_recapture_override.duplicate(true) if not first_contact_recapture_override.is_empty() else get_mission_first_contact_readability_release_recapture_snapshot()
    var engagement_feedback: Dictionary = engagement_feedback_override.duplicate(true) if not engagement_feedback_override.is_empty() else get_mission_first_engagement_feedback_snapshot()
    # Read release evidence and return only derived readability fields.
```

- [ ] **Step 4: Run test to verify it passes**

Run: `godot_console.exe --headless --path . --script scripts/tests/task_1173_first_engagement_feedback_release_recapture.gd`

Expected: `TASK_1173: ALL PASSED` with zero failures.

- [ ] **Step 5: Document and commit**

Update `docs/dev/mission_command_feedback_contract.md`, `docs/IMPLEMENTATION_STATUS.md`, and `docs/TASK_ROADMAP.md`; then commit only task-related files.

### Task 2: Run integration and release gates

**Files:**
- Modify: none unless a verified regression exposes a TASK_1173 defect.
- Test: `scripts/tests/task_1172_first_contact_readability_release_recapture.gd`
- Test: `scripts/tests/task_543_mission_first_engagement_feedback_pass.gd`

**Interfaces:**
- Consumes: TASK_1173 snapshot and existing TASK_1172/TASK_543 verifiers.
- Produces: current release provenance after export.

- [ ] **Step 1: Run focused recapture regression**

Run: `godot_console.exe --headless --path . --script scripts/tests/task_1172_first_contact_readability_release_recapture.gd`

Expected: `TASK_1172: ALL PASSED`.

- [ ] **Step 2: Run actual engagement regression**

Run: `godot_console.exe --headless --path . --script scripts/tests/task_543_mission_first_engagement_feedback_pass.gd`

Expected: `TASK_543: ALL PASSED`.

- [ ] **Step 3: Export and validate release provenance**

Run: `powershell -ExecutionPolicy Bypass -File scripts/tools/export_runtime_release.ps1` followed by `powershell -ExecutionPolicy Bypass -File scripts/tools/release_runtime_start_check.ps1 -JsonOnly`.

Expected: export exit code `0`; release gate reports current `git_head` and no hard failures.

- [ ] **Step 4: Re-run TASK_1173 after export**

Run: `godot_console.exe --headless --path . --script scripts/tests/task_1173_first_engagement_feedback_release_recapture.gd`

Expected: `TASK_1173: ALL PASSED` against current release provenance.

- [ ] **Step 5: Diff check, review, merge and push**

Run: `git diff --check`, inspect the task diff, commit, merge into `integration/core-foundation`, and push task plus integration branches.
