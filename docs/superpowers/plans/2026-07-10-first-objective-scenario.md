# First Objective Scenario Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the existing AA -> Door -> Computer -> Cargo station route selectable from Homebase and verify its real path through MissionSetup, runtime gates and Debriefing.

**Architecture:** Keep the existing ScenarioData, MissionTestSetup, MissionCombatLoopDriver and MetaLayerFlow ownership boundaries. Add only the missing Homebase catalog entry and a read-only end-to-end verifier; `SimulationRoot` and the combat driver remain authoritative for actual mission state and resolution.

**Tech Stack:** Godot 4.6.2, GDScript, existing MetaLayerFlow, MissionCombatLoopDriver, MissionScenarioData and SceneTree verifiers.

## Global Constraints

- UI and diagnostics are read-only and do not own mission, command, combat or multiplayer truth.
- Do not add a second objective, cargo, door or debrief system.
- Reuse `station_route_one_screen_multiplayer_drill.json` and the current direct-Dropship mission path.
- Write tests before production changes and run Godot headless verifiers.

---

### Task 1: Prove the missing Player Entry

**Files:**
- Create: `scripts/tests/task_1063_first_objective_scenario.gd`
- Test: `scripts/tests/task_1063_first_objective_scenario.gd`

**Interfaces:**
- Consumes: `MetaLayerFlow._on_homebase_mission_selection_changed(mission_id)`, `MetaLayerFlow.get_homebase_to_mission_handoff_snapshot()`.
- Produces: red evidence that `station_route_one_screen_multiplayer_drill` is not selectable from the Homebase catalog.

- [ ] **Step 1: Write the failing test**

```gdscript
flow.call("_on_homebase_mission_selection_changed", "station_route_one_screen_multiplayer_drill")
var catalog: Array = Array(flow.get("_mission_catalog"))
_assert(_catalog_has_station_route(catalog), "Homebase catalog exposes the Station Route scenario")
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```powershell
& $godot --headless --path . -s res://scripts/tests/task_1063_first_objective_scenario.gd
```

Expected: the catalog assertion fails because no Station Route entry exists.

### Task 2: Add the Existing Scenario to Homebase

**Files:**
- Modify: `scripts/meta/meta_layer_flow.gd:HOMEBASE_MISSION_CATALOG`
- Test: `scripts/tests/task_1063_first_objective_scenario.gd`

**Interfaces:**
- Consumes: existing scenario path `res://data/mission_scenarios/station_route_one_screen_multiplayer_drill.json`.
- Produces: mission definition `station_route_one_screen_multiplayer_drill` with station map, 8 slots, objective capture and the existing scenario file.

- [ ] **Step 1: Add the minimal catalog definition**

```gdscript
{
    "mission_id": "station_route_one_screen_multiplayer_drill",
    "mission_name": "Operation: Station Route",
    "map_file_path": "res://maps/station_outpost_192x192.json",
    "scenario_file_path": "res://data/mission_scenarios/station_route_one_screen_multiplayer_drill.json",
    "slot_count": 8,
    "time_limit_seconds": 900.0,
    "win_condition": "objective_capture",
},
```

- [ ] **Step 2: Run the test to verify green entry and handoff**

The verifier must assert selected mission ID, map path and scenario path in the existing Homebase-to-Mission handoff snapshot.

### Task 3: Verify Gate Completion to Debriefing

**Files:**
- Modify: `scripts/tests/task_1063_first_objective_scenario.gd`
- Test: `scripts/tests/task_1063_first_objective_scenario.gd`

**Interfaces:**
- Consumes: `MissionCombatLoopDriver.update_mission_interaction_runtime_progress(payload)` and existing scenario gate IDs.
- Produces: route completion, combat result and MetaLayerFlow Debriefing evidence.

- [ ] **Step 1: Extend the verifier with the existing route**

```gdscript
combat_driver.call("set_mission_scenario_runtime_step_state", "disable_air_defense", "aa_disabled")
combat_driver.call("update_mission_interaction_runtime_progress", door_payload)
combat_driver.call("update_mission_interaction_runtime_progress", computer_payload)
combat_driver.call("update_mission_interaction_runtime_progress", cargo_payload)
```

- [ ] **Step 2: Assert authority and result handoff**

```gdscript
_assert(bool(result.get("mission_scenario_runtime_gates", {}).get("all_gates_complete", false)), "Mission result preserves complete gates")
_assert(String(flow.get("_current_meta_view")) == "debrief", "Completed station route opens Debriefing")
_assert(not bool(result.get("ui_sets_gameplay_truth", true)), "Result bridge remains read-only")
```

### Task 4: Document and Integrate

**Files:**
- Modify: `docs/IMPLEMENTATION_STATUS.md`
- Modify: `docs/TASK_ROADMAP.md`
- Modify: `docs/reports/spielstand_zwischenbericht_task1057_1058_2026_07_10.html`

- [ ] **Step 1: Record exact verifier counts and remaining visual/balance risk.**
- [ ] **Step 2: Run TASK_1063, TASK_726, TASK_586, TASK_1062, TASK_1061 and `git diff --check`.**
- [ ] **Step 3: Commit, push the task branch and fast-forward merge into `integration/core-foundation`.**
