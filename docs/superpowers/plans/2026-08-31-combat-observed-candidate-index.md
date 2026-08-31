# Combat Observed Candidate Index Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reduce repeated all-pairs fire-target evaluation by letting the fire-decision path consume a tick-local, read-only candidate index derived from the contact observations already computed in the same authoritative combat tick.

**Architecture:** `MissionCombatLoopDriver._update_contact_tracking()` already evaluates friendly/enemy observations before `_try_enqueue_attacks()` runs. It will publish an internal per-attacker list of observed target IDs for the current tick; `CombatFireDecisionResolver.find_first_contact_pair()` may narrow its existing deterministic target loop to those IDs, while all range, LOS, detection, fire-rule, fairness and damage decisions remain in their current owners. The index is rebuilt every tick, never serialized and never becomes gameplay truth.

**Tech Stack:** Godot 4.6.2, GDScript, existing headless tactical harness and TASK-1193 release gate.

**Spec:** `docs/tasks/TASK_1195_tactical_performance_status_report.md`

## Global Constraints

- Keep `SimulationRoot` as the only gameplay mutation authority.
- Keep `MissionCombatLoopDriver` and `CombatFireDecisionResolver` behavior deterministic for the same input and seed.
- The candidate index is derived, tick-local, read-only and excluded from mission and multiplayer snapshots.
- Do not change `data/performance_budget_contract.json` thresholds.
- Preserve fireteam fairness, detection timing, friendly-fire behavior, target scoring, LOS, range and fire-rule semantics.
- Use the existing 16v12/600-tick fixture for before/after evidence.
- Commit the verifier separately from the production optimization.

---

### Task 1: Lock the observed-candidate contract with a failing verifier

**Files:**

- Create: `docs/tasks/TASK_1196_combat_observed_candidate_index.md`
- Create: `scripts/tests/task_1196_combat_observed_candidate_index.gd`
- Modify: `scripts/tests/mission_combat_loop_driver.gd`

**Interfaces:**

- Consumes: `MissionCombatLoopDriver._update_contact_tracking() -> void` and its already computed `contact_observations: Array`.
- Produces for tests: `MissionCombatLoopDriver.get_fire_candidate_index_debug_snapshot() -> Dictionary` with `tick`, `candidate_attacker_count`, `candidate_pair_count`, `pairs_by_attacker_id`, `derived_only`, `snapshot_serialized`, and `read_only`.
- The test helper must not expose Node references; `pairs_by_attacker_id` maps attacker IDs to sorted `PackedStringArray` target IDs.

- [ ] **Step 1: Write the task contract**

Create `docs/tasks/TASK_1196_combat_observed_candidate_index.md` with these acceptance criteria:

```markdown
- The index is rebuilt from real contact observations for every combat tick.
- It contains only attacker/target IDs and is absent from mission/multiplayer snapshots.
- With the index enabled and disabled, 600 deterministic 16v12 ticks produce identical contacts, fire events, hit results, unit vital states and mission result.
- The indexed path evaluates no more target pairs than the legacy path.
- TASK_1193 budgets remain unchanged.
```

- [ ] **Step 2: Add the failing debug-snapshot test**

In `scripts/tests/task_1196_combat_observed_candidate_index.gd`, load the same real tactical fixture pattern used by `task_1191_shared_combat_visibility_cache.gd`. After at least one contact update, assert:

```gdscript
var snapshot: Dictionary = Dictionary(driver.call("get_fire_candidate_index_debug_snapshot"))
_assert(int(snapshot.get("tick", -1)) >= 0, "Candidate index records its authoritative tick")
_assert(bool(snapshot.get("derived_only", false)), "Candidate index is explicitly derived")
_assert(bool(snapshot.get("read_only", false)), "Candidate index is read-only")
_assert(not bool(snapshot.get("snapshot_serialized", true)), "Candidate index is not serialized")
_assert(int(snapshot.get("candidate_pair_count", 0)) > 0, "Real contact observations build candidate pairs")
```

- [ ] **Step 3: Run the verifier and confirm the red state**

Run:

```powershell
C:\Users\bjoer\AppData\Local\Programs\Godot\Godot_v4.6.2-stable_win64_console.exe --headless --path . --script scripts/tests/task_1196_combat_observed_candidate_index.gd
```

Expected: FAIL because `get_fire_candidate_index_debug_snapshot()` and the candidate index do not exist.

- [ ] **Step 4: Add only the debug surface, still without narrowing target selection**

Add these members to `MissionCombatLoopDriver`:

```gdscript
var _fire_candidate_target_ids_by_attacker_id: Dictionary = {}
var _fire_candidate_index_tick: int = -1
var _fire_candidate_index_pair_count: int = 0
```

At the start of `_update_contact_tracking()`, clear the dictionary and counters. Initialize one explicit, possibly empty target-ID array for every friendly combat attacker. While building a successful observation, append the enemy ID under the friendly attacker ID and assign the packed array back to the dictionary. Sort every target-ID array after the observation loops. Enemy attackers intentionally receive no key because their existing attack path does not consume the friendly contact tracker. Use this append pattern:

```gdscript
var target_ids := PackedStringArray(_fire_candidate_target_ids_by_attacker_id.get(attacker_id, PackedStringArray()))
if not target_ids.has(enemy_unit_id):
    target_ids.append(enemy_unit_id)
    _fire_candidate_target_ids_by_attacker_id[attacker_id] = target_ids
    _fire_candidate_index_pair_count += 1
```

Add the debug surface:

```gdscript
func get_fire_candidate_index_debug_snapshot() -> Dictionary:
    var pairs_by_attacker_id: Dictionary = {}
    for attacker_id_variant in _fire_candidate_target_ids_by_attacker_id.keys():
        var attacker_id: String = String(attacker_id_variant)
        pairs_by_attacker_id[attacker_id] = PackedStringArray(
            _fire_candidate_target_ids_by_attacker_id.get(attacker_id_variant, PackedStringArray())
        )
    return {
        "tick": _fire_candidate_index_tick,
        "candidate_attacker_count": pairs_by_attacker_id.size(),
        "candidate_pair_count": _fire_candidate_index_pair_count,
        "pairs_by_attacker_id": pairs_by_attacker_id,
        "derived_only": true,
        "read_only": true,
        "snapshot_serialized": false,
    }
```

Do not change `get_multiplayer_combat_snapshot()`, `_publish_multiplayer_snapshot_context()` or any mission-result snapshot.

- [ ] **Step 5: Run the verifier and confirm the debug contract passes**

Run the TASK-1196 command again. Expected: the debug-snapshot assertions pass; no fire-selection behavior has changed yet.

- [ ] **Step 6: Commit the contract and failing behavior test**

```powershell
git add docs/tasks/TASK_1196_combat_observed_candidate_index.md scripts/tests/task_1196_combat_observed_candidate_index.gd scripts/tests/mission_combat_loop_driver.gd
git commit -m "test(combat): lock observed candidate index contract"
```

---

### Task 2: Narrow target loops without changing combat results

**Files:**

- Modify: `scripts/tactical/combat_fire_decision_resolver.gd`
- Modify: `scripts/tests/mission_combat_loop_driver.gd`
- Modify: `scripts/tests/task_1196_combat_observed_candidate_index.gd`

**Interfaces:**

- Consumes: context field `observed_target_ids_by_attacker_id: Dictionary`.
- Produces: `CombatFireDecisionResolver._filter_targets_for_attacker(attacker, targets, context) -> Array` preserving the original target order.
- A missing index entry or disabled option uses the complete legacy target array. This preserves the enemy-attacker path. An explicit empty friendly entry means that the already completed observation pass found no candidate for that attacker.

- [ ] **Step 1: Add an indexed-vs-legacy oracle test**

Run the real 16v12 fixture twice with the same seed: once with `use_observed_fire_candidate_index=false`, once with it `true`. Compare canonical snapshots containing:

```gdscript
{
    "contacts": driver.get_contact_snapshot(),
    "fire_events": driver.get_fire_event_snapshot(),
    "hotpath": driver.get_combat_hotpath_audit_snapshot(),
    "unit_states": _build_sorted_unit_state_snapshot(root),
    "mission_result": driver.get_mission_result(),
}
```

Exclude timing values and cache counters from equality. Assert exact equality for contacts, fire events, unit states and mission result. Separately assert:

```gdscript
_assert(indexed_pair_evaluation_count <= legacy_pair_evaluation_count, "Indexed selection never evaluates more pairs")
```

- [ ] **Step 2: Run the oracle and confirm the intended red state**

Expected: FAIL because the option and resolver filter do not exist and both runs evaluate the legacy pair set.

- [ ] **Step 3: Pass the derived index through the existing context**

Add an exported/test-settable boolean defaulting to `true` in `MissionCombatLoopDriver`:

```gdscript
var use_observed_fire_candidate_index: bool = true
```

In `_build_fire_decision_context()`, add only when enabled and the index tick matches `_current_tick`:

```gdscript
context["observed_target_ids_by_attacker_id"] = _fire_candidate_target_ids_by_attacker_id
context["use_observed_fire_candidate_index"] = true
```

The context remains read-only input to the resolver.

- [ ] **Step 4: Implement deterministic target filtering**

In `CombatFireDecisionResolver` add:

```gdscript
static func _filter_targets_for_attacker(attacker, targets: Array, context: Dictionary) -> Array:
    if not bool(context.get("use_observed_fire_candidate_index", false)):
        return targets
    var attacker_id: String = _get_unit_id(attacker)
    var by_attacker: Dictionary = Dictionary(context.get("observed_target_ids_by_attacker_id", {}))
    if attacker_id.is_empty() or not by_attacker.has(attacker_id):
        return targets
    var allowed_ids := PackedStringArray(by_attacker.get(attacker_id, PackedStringArray()))
    var filtered: Array = []
    for target in targets:
        if allowed_ids.has(_get_unit_id(target)):
            filtered.append(target)
    return filtered
```

Call it immediately before both `pick_target_from_units()` calls in `find_first_contact_pair()`. Friendly attackers use their explicit index entry; enemy attackers have no key and therefore retain the complete legacy target array. Do not reorder the surviving targets. Do not bypass `is_target_attackable()`, detection completion, contact state or `can_unit_attack()`.

- [ ] **Step 5: Run the oracle and all directly affected contracts**

```powershell
C:\Users\bjoer\AppData\Local\Programs\Godot\Godot_v4.6.2-stable_win64_console.exe --headless --path . --script scripts/tests/task_1196_combat_observed_candidate_index.gd
C:\Users\bjoer\AppData\Local\Programs\Godot\Godot_v4.6.2-stable_win64_console.exe --headless --path . --script scripts/tests/task_1191_shared_combat_visibility_cache.gd
C:\Users\bjoer\AppData\Local\Programs\Godot\Godot_v4.6.2-stable_win64_console.exe --headless --path . --script scripts/tests/task_162_combat_authority_contract_verifier.gd
C:\Users\bjoer\AppData\Local\Programs\Godot\Godot_v4.6.2-stable_win64_console.exe --headless --path . --script scripts/tests/task_208_enemy_team_tactics_playability_smoke.gd
```

Expected: all assertions pass; the indexed and legacy gameplay snapshots are identical; indexed pair evaluations are lower or equal.

- [ ] **Step 6: Commit the production slice**

```powershell
git add scripts/tactical/combat_fire_decision_resolver.gd scripts/tests/mission_combat_loop_driver.gd scripts/tests/task_1196_combat_observed_candidate_index.gd
git commit -m "perf(combat): reuse observed target candidates"
```

---

### Task 3: Measure the slice and make the next decision from evidence

**Files:**

- Modify: `docs/tasks/TASK_1196_combat_observed_candidate_index.md`
- Modify: `docs/IMPLEMENTATION_STATUS.md`
- Modify only if the report needs a new counter: `scripts/tests/tactical_map_frame_budget_harness.gd`

**Interfaces:**

- Consumes: unchanged `sternenbuergerchen.tactical_map_frame_budget.v1` output.
- Produces: SHA-bound before/after ranges for `combat.total_tick_usec`, `combat_scope.combat_fire_decision_usec`, `combat_scope.fire_find_contact_pair_usec`, `combat_scope.contact_tracking_usec`, `simulation.total_tick_usec`, and candidate-pair counters.

- [ ] **Step 1: Run one cold diagnostic on the committed production SHA**

```powershell
pwsh -NoProfile -File scripts/tests/run_task_1187_tactical_map_frame_budget.ps1 -GodotExecutable C:\Users\bjoer\AppData\Local\Programs\Godot\Godot_v4.6.2-stable_win64_console.exe -ColdRuns 1 -WarmRuns 0
```

Expected: runner succeeds as a measurement contract. Record budget status honestly; a cold run alone cannot release the build.

- [ ] **Step 2: Apply the minimum continuation gate**

Proceed to the full series only if all of these hold:

```text
TASK_1196 gameplay oracle: pass
indexed pair evaluations <= legacy pair evaluations
fire_find_contact_pair p99 does not regress by more than 5 percent
no new script, harness, leak or authority error
```

If any condition fails, revert only the TASK-1196 production commit with a normal revert commit and keep the verifier/evidence commit for diagnosis.

- [ ] **Step 3: Run the release-grade three-cold/five-warm series**

```powershell
pwsh -NoProfile -File scripts/tests/run_task_1187_tactical_map_frame_budget.ps1 -GodotExecutable C:\Users\bjoer\AppData\Local\Programs\Godot\Godot_v4.6.2-stable_win64_console.exe -Mode Measure -ColdRuns 3 -WarmRuns 5
```

Expected: eight SHA-identical JSON results. Compare ranges, not the best individual run.

- [ ] **Step 4: Select exactly one next package**

Use this deterministic decision order in the TASK-1196 result section:

```text
1. If fire_find_contact_pair remains the largest exclusive combat scope:
   next spec = CombatVisibilityCache key/allocation cost.
2. Else if contact_tracking is largest:
   next spec = contact observation fan-out reuse.
3. Else if enemy_team_tactics is largest:
   next spec = enemy tactics revision/dirty update.
4. If combat falls but simulation command_queue remains above 8 ms:
   next spec = command-type attribution before any SimulationRoot optimization.
5. Dynamic Overlay and FoW remain separate renderer tasks regardless of combat result.
```

Do not create more than the selected next spec in this task.

- [ ] **Step 5: Update status and commit evidence**

```powershell
git add docs/tasks/TASK_1196_combat_observed_candidate_index.md docs/IMPLEMENTATION_STATUS.md
git commit -m "docs(perf): record observed candidate index evidence"
git diff --check integration/core-foundation...HEAD
```

Expected: clean diff check and a task document containing exact SHA, machine profile, run count, metric ranges, test counts, remaining blockers and the selected next package.
