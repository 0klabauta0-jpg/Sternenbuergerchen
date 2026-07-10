# Mission Runtime Surface Guard Implementation Plan

> **For Codex:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Remove repeated static/rebuild-heavy mission HUD work from the 0.35-second refresh while preserving live status changes, command affordances and the existing read-only HUD boundary.

**Architecture:** The mission tactical controller remains the HUD producer. It will retain small visual fingerprints for the command matrix, selected member cards and fireteam mini cards. A matching fingerprint skips node recreation and repeated styling; a changed fingerprint immediately rebuilds the affected surface. No gameplay state moves into UI and no simulation state changes.

**Tech Stack:** Godot 4.6 GDScript, `MissionTacticalSandboxController`, existing NPC compact cards and FOB fireteam mini cards, headless SceneTree verifiers.

---

### Task 1: Define a state-driven UI refresh contract and failing regression

**Files:**
- Create: `docs/tasks/TASK_1044_mission_hud_runtime_surface_guard.md`
- Create: `scripts/tests/task_1044_mission_hud_runtime_surface_guard.gd`
- Modify: `docs/dev/mission_command_feedback_contract.md`

1. Define the command matrix, selected member cards and mini cards as derived UI surfaces only.
2. Write a failing test that calls each refresh twice with unchanged runtime data and proves existing card nodes are retained.
3. Require an observable guard snapshot with apply/skip counts and no gameplay-mutation flags.
4. Run the verifier to establish the expected red failure.

### Task 2: Implement narrow visual fingerprints

**Files:**
- Modify: `scripts/tests/mission_tactical_sandbox_controller.gd`

1. Add controller-local fingerprints and counters for the three surfaces.
2. Build a command-matrix fingerprint from its actual visual inputs: firefight active state, GO readiness, fire-rule consensus, selected teams and local command mode.
3. Build card fingerprints from the selected/displayed fireteams and unit state that the cards expose: membership, selection, health, vital state, stance, runtime command and transport state.
4. Skip only unchanged visual work; keep the first refresh and changed-state refresh immediate.
5. Expose a read-only diagnostics snapshot for the verifier.

### Task 3: Measure the new cadence and report it

**Files:**
- Modify: `docs/IMPLEMENTATION_STATUS.md`
- Modify: `docs/TASK_ROADMAP.md`
- Modify: `docs/reports/spielstand_zwischenbericht_task1043_mission_hud_hotpath_2026_07_10.html`

1. Run TASK 1044 plus TASK 1043, TASK 366 and selected-card/mini-card regressions.
2. Run the local frame probe and compare periodic frame spikes before/after; do not claim a universal hardware frame budget.
3. Retry TASK 542 with an explicit timeout and record the real result.
4. Update the existing HTML report, then run `git diff --check`, review, commit and push.
