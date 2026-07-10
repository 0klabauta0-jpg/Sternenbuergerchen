# Mission HUD Hotpath Guard Implementation Plan

> **For Codex:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Remove the heavy full command-feedback build from the recurring mission event-log refresh so the live tactical HUD stays responsive without changing gameplay authority or the established CONTACT FIRE display rules.

**Architecture:** `MissionTacticalSandboxController` remains a read-only HUD producer. It will build a deliberately small event-log payload from the tactical event log, selected fireteam IDs and the existing combat/readability helpers. `TacticalEventLogPanel` will retain its signature-based render guard. The full `get_command_feedback_snapshot()` remains available for tests, reports and explicit inspection, but is no longer called by the recurring panel refresh.

**Tech Stack:** Godot 4.6 GDScript, existing mission tactical controller, `TacticalEventLogPanel`, headless SceneTree verifiers.

---

### Task 1: Define the hotpath contract and regression seam

**Files:**
- Create: `docs/tasks/TASK_1043_mission_hud_hotpath_event_log_guard.md`
- Modify: `docs/dev/mission_command_feedback_contract.md`
- Create: `scripts/tests/task_1043_mission_hud_hotpath_event_log_guard.gd`

1. Define the lightweight payload as read-only panel data: selected fireteam IDs, tactical event-log entries, release firefight display data and the existing event-log visual polish data.
2. Specify that it must not create commands, movement, combat, damage or multiplayer truth.
3. Write a failing verifier that proves the recurring refresh does not call `get_command_feedback_snapshot()` and that both normal and CONTACT FIRE entries remain renderable through the panel.
4. Run the verifier to confirm it fails before the controller change.

### Task 2: Build and use a narrow live event-log snapshot

**Files:**
- Modify: `scripts/tests/mission_tactical_sandbox_controller.gd`
- Modify: `scripts/tests/task_883_release_first_exchange_real_window_hud_source_sync_fix.gd`

1. Add `get_live_tactical_event_log_feedback_snapshot()` next to the existing tactical event-log APIs.
2. Reuse existing combat density, release-firefight display and source-sync helpers, but only populate their direct input fields.
3. Change `_refresh_tactical_event_log_panel()` to use the narrow snapshot.
4. Preserve the explicit full-feedback path in the non-recurring visual inspection functions.
5. Update the older structural verifier to expect the narrow recurring path and preserve its full-snapshot assertions where appropriate.

### Task 3: Verify runtime behavior and document the result

**Files:**
- Modify: `docs/IMPLEMENTATION_STATUS.md`
- Modify: `docs/TASK_ROADMAP.md`
- Create: `docs/reports/spielstand_zwischenbericht_task1043_mission_hud_hotpath_2026_07_10.html`

1. Run TASK 1043, the existing tactical event-log verifier, TASK 883, and the first-contact flow regression.
2. Use the local hotpath probe to compare a post-mission frame before and after the fix; report measured evidence without inventing a fixed cross-machine frame budget.
3. Update task status/roadmap and create a human-readable HTML workbench report with current work, test results, remaining risk and JSON export.
4. Run `git diff --check`, review the diff, commit and push the branch.
