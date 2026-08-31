# Tactical Performance Budget Diagnostics Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Expose every already-measured Combat- and Simulation-Tick-Subscope in the tactical-frame report, so the next optimization targets a measured cause instead of aggregate timing.

**Architecture:** `TacticalMapFrameBudgetHarness` already reads snapshots from `SimulationRoot` and `MissionCombatLoopDriver`. It will copy their existing per-tick scope dictionaries into namespaced report entries while preserving the established aggregate metrics and release contract. The TASK_1194 verifier runs the real harness with reduced sample options and asserts observable report contents.

**Tech Stack:** Godot 4.6.2, GDScript, existing headless tactical harness.

**Spec:** `docs/tasks/TASK_1194_tactical_performance_budget_reduction.md`

## Global Constraints

- Keep `SimulationRoot` as gameplay authority and do not create UI-held mission or combat truth.
- Do not change `data/performance_budget_contract.json` thresholds in this slice.
- Use real `TacticalMapFrameBudgetHarness` output; do not assert source text or mocks.
- Preserve all existing TASK_1187 aggregate metric names and measurement-only behavior.

---

### Task 1: Namespaced tactical scope reporting

**Files:**

- Create: `scripts/tests/task_1194_tactical_performance_budget_reduction.gd`
- Modify: `scripts/tests/tactical_map_frame_budget_harness.gd`
- Modify: `docs/tasks/TASK_1194_tactical_performance_budget_reduction.md`

**Interfaces:**

- Consumes: `SimulationRoot.get_runtime_tick_budget_debug_snapshot() -> Dictionary` with `scopes_usec`.
- Consumes: `MissionCombatLoopDriver.get_combat_tick_budget_debug_snapshot() -> Dictionary` with `scopes_usec`.
- Produces: `TacticalMapFrameBudgetHarness.run(...).scopes` entries named `simulation_scope.<existing_scope>` and `combat_scope.<existing_scope>`, each containing `invocation_count`, `p50`, `p95`, `p99`, and `max`.

- [ ] **Step 1: Write the failing test**

```gdscript
func _test_report_exposes_real_combat_and_simulation_subscopes() -> void:
	var report: Dictionary = await TacticalMapFrameBudgetHarness.new().run(self, {
		"warmup_ticks": 0,
		"physics_ticks": 4,
		"minimum_process_frames": 1,
		"minimum_process_duration_msec": 0,
		"combat_fixture_repetitions": 1,
	})
	var scopes: Dictionary = Dictionary(report.get("scopes", {}))
	_assert(int(Dictionary(scopes.get("combat_scope.combat_fire_decision_usec", {})).get("invocation_count", 0)) > 0, "Report exposes real combat fire-decision samples")
	_assert(int(Dictionary(scopes.get("simulation_scope.tick_signal_emit_usec", {})).get("invocation_count", 0)) > 0, "Report exposes real SimulationRoot tick-signal samples")
```

The test catches the production break “the diagnostic report hides the expensive existing subscopes.” It exercises the real scene, `SimulationRoot`, Combat driver, and harness.

- [ ] **Step 2: Run test to verify it fails**

Run:

```powershell
godot_console.exe --headless --path . --script scripts/tests/task_1194_tactical_performance_budget_reduction.gd
```

Expected: the task verifier reaches the real harness but fails because the two namespaced scope entries do not exist yet.

- [ ] **Step 3: Implement the minimal report collection**

```gdscript
func _record_snapshot_scopes(samples: Dictionary, namespace: String, scopes: Dictionary) -> void:
	for scope_name_variant in scopes.keys():
		var scope_name: String = String(scope_name_variant).strip_edges()
		if scope_name.is_empty():
			continue
		_record(samples, "%s.%s" % [namespace, scope_name], scopes.get(scope_name_variant, null))
```

Call it from both `_collect_tick_samples()` and `_collect_large_combat_fixture_samples()` after their snapshot dictionaries are read. Initialize the two expected entries in `_new_samples()` so missing invocation is observable rather than silently omitted.

- [ ] **Step 4: Run test to verify it passes**

Run the same TASK_1194 command. Expected: `=== RESULTS: ... 0 failed ===`, with non-zero invocation counts for the two namespaced metrics.

- [ ] **Step 5: Capture the first hotspot evidence**

Run:

```powershell
pwsh -NoProfile -File scripts/tests/run_task_1187_tactical_map_frame_budget.ps1 -GodotExecutable C:\\Users\\bjoer\\AppData\\Local\\Programs\\Godot\\Godot_v4.6.2-stable_win64_console.exe -ColdRuns 1 -WarmRuns 0
```

Record the largest `combat_scope.*` and `simulation_scope.*` p99 values in the TASK_1194 document before selecting the production fix.

- [ ] **Step 6: Commit**

```powershell
git add docs/tasks/TASK_1194_tactical_performance_budget_reduction.md docs/superpowers/plans/2026-08-31-tactical-performance-budget-diagnostics.md scripts/tests/task_1194_tactical_performance_budget_reduction.gd scripts/tests/tactical_map_frame_budget_harness.gd
git commit -m "test(perf): expose tactical tick subscopes"
```
