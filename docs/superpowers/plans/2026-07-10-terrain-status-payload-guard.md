# Terrain Mission Status Payload Guard Implementation Plan

> **For Codex:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Prevent `TerrainMap3DView` from rebuilding mission status 3D visuals when its status payload has not changed, while immediately rebuilding on a real objective, route, interaction or result change.

**Architecture:** `TerrainMap3DView` remains a visual consumer. It stores only the last normalized visual payload signature and local apply/rebuild/skip counters. It receives authoritative read-only payloads from the mission controller; it does not own simulation, objective, combat or multiplayer state.

**Tech Stack:** Godot 4.6 GDScript, `TerrainMap3DView`, existing render snapshot and SceneTree verifier.

---

### Task 1: Define the visual payload guard with a failing test

**Files:**
- Create: `docs/tasks/TASK_1046_terrain_mission_status_payload_signature_guard.md`
- Create: `scripts/tests/task_1046_terrain_mission_status_payload_signature_guard.gd`

1. Set an objective/route/interaction status payload twice and require the second identical payload to skip rebuild while retaining StatusRoot3D children.
2. Change capture progress or visible status data and require an immediate rebuild.
3. Require render snapshot counters and read-only visual-boundary flags.
4. Run the verifier red before modifying `TerrainMap3DView`.

### Task 2: Add normalized signature and diagnostics

**Files:**
- Modify: `scripts/terrain/terrain_map_3d_view.gd`

1. Add a local status-payload signature plus rebuild/skip counters.
2. Build a deterministic signature from every payload field that can affect status visuals, including Vector2 values, dictionaries and arrays.
3. Skip only exact identical payloads; retain the first apply and every changed apply.
4. Expose counts and current signature state through `get_render_snapshot()`.

### Task 3: Verify the integrated hotpath and publish result

**Files:**
- Modify: `docs/dev/mission_command_feedback_contract.md`
- Modify: `docs/IMPLEMENTATION_STATUS.md`
- Modify: `docs/TASK_ROADMAP.md`
- Modify: `docs/reports/spielstand_zwischenbericht_task1043_mission_hud_hotpath_2026_07_10.html`

1. Run TASK 1046, TASK 1045 and the terrain performance gate.
2. Run the combination probe and retry the bounded timing trace.
3. Record actual frame evidence, then commit and push.

**Result:** TASK_1046 passed 12/12 and TASK_170 passed 62/62. The guard retained `StatusRoot3D` nodes for identical rendered data and ignored diagnostics-only payload changes. The combined Controller + SimulationRoot + TerrainMap3DView probe remained about 3.396 seconds per frame, and five visible mission frames remained about 21.162 seconds. TASK_1047 must profile the cross-system frame before another fix is chosen.
