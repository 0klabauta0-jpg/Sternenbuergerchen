# Mission Release Recapture Extraction Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move the data-only TASK_1172 and TASK_1173 release-recapture construction out of the legacy test controller without changing player-visible contracts.

**Architecture:** The controller continues to gather existing runtime evidence. A new mission-layer `RefCounted` service transforms supplied dictionaries into unchanged snapshot contracts, using no Node, UI, registry, or simulation dependency.

**Tech Stack:** Godot 4.6.2, GDScript, headless SceneTree verifiers.

## Global Constraints

- `SimulationRoot` remains the only gameplay mutation authority.
- No SceneTree scans, runtime UI rebuilds, or new gameplay state are introduced.
- TASK_1172/TASK_1173 public controller method names and schemas stay stable.
- Unrelated untracked files remain untouched.

---

### Task 1: Extract pure builders and delegate controller methods

**Files:**
- Create: `scripts/mission/mission_release_recapture_service.gd`
- Create: `scripts/tests/task_1174_mission_release_recapture_extraction.gd`
- Modify: `scripts/tests/mission_tactical_sandbox_controller.gd`

**Interfaces:**
- Consumes: already prepared TASK_1171, TASK_1172, TASK_542, TASK_543 and release-evidence dictionaries.
- Produces: `build_first_contact_recapture(...) -> Dictionary` and `build_first_engagement_recapture(...) -> Dictionary`.

- [ ] **Step 1: Write the failing service test**

```gdscript
var service_script: GDScript = load("res://scripts/mission/mission_release_recapture_service.gd") as GDScript
_assert(service_script != null, "Mission release recapture service exists")
var snapshot: Dictionary = Dictionary(service_script.call("build_first_engagement_recapture", contact_handoff, engagement, release, capture, host_window, client_window))
_assert(String(snapshot.get("task_id", "")) == "TASK_1173", "Service builds TASK 1173 contract")
```

- [ ] **Step 2: Run test to verify it fails**

Run: `godot_console.exe --headless --path . --script scripts/tests/task_1174_mission_release_recapture_extraction.gd`

Expected: FAIL because the service file does not exist.

- [ ] **Step 3: Implement the data-only service and controller delegation**

```gdscript
const MISSION_RELEASE_RECAPTURE_SERVICE_SCRIPT: GDScript = preload("res://scripts/mission/mission_release_recapture_service.gd")

func get_mission_first_engagement_feedback_release_recapture_snapshot(...) -> Dictionary:
    return Dictionary(MISSION_RELEASE_RECAPTURE_SERVICE_SCRIPT.call(
        "build_first_engagement_recapture", first_contact_recapture, engagement_feedback,
        release_provenance, capture_manifest, host_window, client_window
    ))
```

- [ ] **Step 4: Run service and delegation regressions**

Run: `godot_console.exe --headless --path . --script scripts/tests/task_1174_mission_release_recapture_extraction.gd`, then TASK_1172 and TASK_1173 verifiers.

Expected: all report `ALL PASSED`.

- [ ] **Step 5: Document, export, commit and merge**

Update the contract, status and roadmap; run `git diff --check`, export the current integration merge, verify the release start gate, then commit, push, merge and push integration.
