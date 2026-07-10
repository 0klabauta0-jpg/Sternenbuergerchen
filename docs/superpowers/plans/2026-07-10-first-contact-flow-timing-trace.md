# First Contact End-to-End Timing Trace Implementation Plan

> **For Codex:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Turn the opaque timeout in the Homebase-to-first-contact regression into a bounded, reproducible timing trace that names the slow lifecycle segment without changing gameplay behavior.

**Architecture:** A headless verifier drives the existing public/test-only Homebase, dropship, mission, LZ and first-contact paths. It owns only its local timeline evidence. The game continues to own all mission, transport, combat and multiplayer state. A stage budget ends the trace cleanly with the slowest reached stage rather than waiting for an external process timeout.

**Tech Stack:** Godot 4.6 GDScript SceneTree verifier, existing meta-layer test fixture, mission tactical controller, headless output.

---

### Task 1: Specify and write the bounded trace verifier

**Files:**
- Create: `docs/tasks/TASK_1045_mission_first_contact_end_to_end_timing_trace.md`
- Create: `scripts/tests/task_1045_mission_first_contact_end_to_end_timing_trace.gd`

1. Cover the same player stages as TASK 542: scene ready, mission selection, roster/transport setup, boarding, mission start, active mission, LZ, drop/deboard, first order/GO and first contact.
2. Record elapsed milliseconds, frame count and a completion/budget status per stage.
3. Abort the trace internally with a named stage when a bounded stage budget is exceeded; return a valid diagnostic result rather than waiting for a shell timeout.
4. Run it and record the first actual bottleneck.

### Task 2: Verify the trace preserves system boundaries

**Files:**
- Modify: `docs/dev/mission_command_feedback_contract.md`
- Modify: `docs/IMPLEMENTATION_STATUS.md`
- Modify: `docs/TASK_ROADMAP.md`

1. State that trace data is test evidence, not a gameplay or HUD source.
2. Add a small structural verifier check for no command/combat/damage/multiplayer truth produced by the trace itself.
3. Document the measured slowest stage and the directly justified next fix.

### Task 3: Publish measured findings

**Files:**
- Modify: `docs/reports/spielstand_zwischenbericht_task1043_mission_hud_hotpath_2026_07_10.html`

1. Update the HTML workbench with timeline evidence and the next fix target.
2. Run TASK 1045, TASK 1044, `git diff --check` and a targeted regression appropriate to the identified stage.
3. Commit and push the trace/report branch.
