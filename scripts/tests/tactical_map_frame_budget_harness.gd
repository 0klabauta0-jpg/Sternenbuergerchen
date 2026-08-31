class_name TacticalMapFrameBudgetHarness
extends RefCounted

const META_LAYER_TEST_SCENE: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")
const COMBAT_FIXTURE_HARNESS_SCRIPT: GDScript = preload("res://scripts/tests/simulation_combat_ai_tick_budget_harness.gd")
const DEFAULT_DELTA: float = 1.0 / 60.0
const DEFAULT_WARMUP_TICKS: int = 120
const DEFAULT_PHYSICS_TICKS: int = 600
const DEFAULT_PROCESS_FRAMES: int = 3600
const DEFAULT_PROCESS_DURATION_MSEC: int = 60000
const DEFAULT_COMBAT_FIXTURE_REPETITIONS: int = 150
const PERFORMANCE_BUDGET_CONTRACT_PATH: String = "res://data/performance_budget_contract.json"
const SCOPE_BUDGET_RULES: Dictionary = {
	"frame_script_total_usec": {"p95": "max_frame_script_p95_usec", "p99": "max_frame_script_p99_usec", "max": "max_frame_script_max_usec"},
	"terrain.unit_proxy_sync_usec": {"p95": "max_unit_proxy_sync_p95_usec", "p99": "max_unit_proxy_sync_p99_usec"},
	"terrain.fow_work_usec": {"p99": "max_fow_work_conditional_p99_usec"},
	"terrain.dynamic_overlay_usec": {"p99": "max_dynamic_overlay_p99_usec"},
	"controller.execution_updates_usec": {"p99": "max_controller_execution_p99_usec"},
	"controller.hud_light_usec": {"p95": "max_hud_light_p95_usec", "p99": "max_hud_light_p99_usec"},
	"simulation.total_tick_usec": {"p99": "max_simulation_tick_p99_usec"},
	"combat.total_tick_usec": {"p99": "max_combat_tick_p99_usec"},
	"interaction.first_visible_frame_usec": {"p95": "max_command_to_visible_feedback_p95_usec"},
	"interaction.lz_input_usec": {"p95": "max_lz_input_p95_usec"},
}


func run(scene_tree: SceneTree, options: Dictionary = {}) -> Dictionary:
	var warmup_ticks: int = maxi(int(options.get("warmup_ticks", DEFAULT_WARMUP_TICKS)), 0)
	var physics_ticks: int = maxi(int(options.get("physics_ticks", DEFAULT_PHYSICS_TICKS)), 1)
	var minimum_process_frames: int = maxi(int(options.get("minimum_process_frames", DEFAULT_PROCESS_FRAMES)), 1)
	var minimum_process_duration_msec: int = maxi(int(options.get("minimum_process_duration_msec", DEFAULT_PROCESS_DURATION_MSEC)), 0)
	var combat_fixture_repetitions: int = maxi(int(options.get("combat_fixture_repetitions", DEFAULT_COMBAT_FIXTURE_REPETITIONS)), 1)
	var samples: Dictionary = _new_samples()
	var setup_started_usec: int = Time.get_ticks_usec()
	var flow: Node = META_LAYER_TEST_SCENE.instantiate()
	scene_tree.root.add_child(flow)
	await _wait_frames(scene_tree, 8)
	var homebase := flow.get_node_or_null("HomebaseScreen") as Control
	if homebase == null:
		return _build_failed_report("homebase_missing", samples, setup_started_usec)
	homebase.call("request_mission_start")
	await _wait_frames(scene_tree, 12)
	var mission: Node = flow.call("get_active_mission")
	var primary_view: Node = mission.get_node_or_null("Primary3DView") if mission != null else null
	var controller: Node = mission.get_node_or_null("TacticalController") if mission != null else null
	var simulation_root: Node = mission.get_node_or_null("SimulationRoot") if mission != null else null
	var combat_driver: Node = mission.get_node_or_null("CombatLoopDriver") if mission != null else null
	if primary_view == null or controller == null or simulation_root == null or combat_driver == null:
		await _cleanup(scene_tree, flow)
		return _build_failed_report("mission_runtime_missing", samples, setup_started_usec)

	primary_view.call("set_runtime_frame_timing_debug_enabled", true)
	controller.call("set_mission_visible_frame_timing_debug_enabled", true)
	simulation_root.call("set_runtime_tick_budget_debug_enabled", true)
	combat_driver.call("set_combat_tick_budget_debug_enabled", true)
	var first_visible_started_usec: int = Time.get_ticks_usec()
	await _wait_frames(scene_tree, 1)
	_record(samples, "interaction.first_visible_frame_usec", Time.get_ticks_usec() - first_visible_started_usec)
	primary_view.call("set_fog_of_war_state", _build_fog_of_war_probe_state())
	await _wait_frames(scene_tree, 2)
	var last_fow_work_invocation_count: int = _collect_frame_samples(samples, primary_view, controller, -1)

	var handoff: Dictionary = Dictionary(flow.call("get_homebase_to_mission_handoff_snapshot"))
	var craft_id: String = String(Dictionary(handoff.get("planning", {})).get("mission_drop_craft_id", "")).strip_edges()
	if not craft_id.is_empty():
		flow.call("_remove_pending_mission_craft_transfer", craft_id)
		flow.call("_complete_mission_craft_transfer", {"craft_id": craft_id, "phase": "to_mission"})
		flow.call("_sync_homebase_direct_mission_drop_transport_fields")
		flow.call("_start_or_update_active_mission")
		await _wait_frames(scene_tree, 6)
		mission = flow.call("get_active_mission")
		primary_view = mission.get_node_or_null("Primary3DView") if mission != null else null
		controller = mission.get_node_or_null("TacticalController") if mission != null else null
		simulation_root = mission.get_node_or_null("SimulationRoot") if mission != null else null
		combat_driver = mission.get_node_or_null("CombatLoopDriver") if mission != null else null
		if primary_view != null and controller != null:
			controller.call("set_mission_visible_frame_timing_debug_enabled", true)
			var spawn_position: Vector2 = Vector2(controller.call("get_mission_marker_world_position", "spawn_alpha", Vector2.ZERO))
			var lz_ui_refresh_before: Dictionary = Dictionary(controller.call("get_mission_ui_refresh_timing_debug_snapshot"))
			var lz_input_started_usec: int = Time.get_ticks_usec()
			controller.call("_on_mission_dropship_card_set_lz_pressed", craft_id)
			_record(samples, "interaction.lz_input_usec", Time.get_ticks_usec() - lz_input_started_usec)
			var lz_ui_refresh_after: Dictionary = Dictionary(controller.call("get_mission_ui_refresh_timing_debug_snapshot"))
			_record(samples, "interaction.lz_input_ui_refresh_count", int(lz_ui_refresh_after.get("invocation_count", -1)) - int(lz_ui_refresh_before.get("invocation_count", -1)))
			var planning_emit_started_usec: int = Time.get_ticks_usec()
			var lz_placed: bool = bool(controller.call("_place_lz_from_screen_position", primary_view.call("world_to_screen_position", spawn_position))) if spawn_position != Vector2.ZERO else false
			_record(samples, "interaction.planning_emit_usec", Time.get_ticks_usec() - planning_emit_started_usec)
			if lz_placed:
				var lz_action_started_usec: int = Time.get_ticks_usec()
				controller.call("_on_mission_dropship_card_drop_pressed", craft_id)
				_record(samples, "interaction.lz_action_usec", Time.get_ticks_usec() - lz_action_started_usec)
				var lz_and_deboard_started_usec: int = Time.get_ticks_usec()
				controller.call("_complete_drop_sequence_deployment")
				controller.call("_advance_primary_drop_sequence_unloading", 999.0)
				controller.call("_flush_pending_drop_runtime_phase_starts")
				_record(samples, "interaction.lz_and_deboard_msec", float(Time.get_ticks_usec() - lz_and_deboard_started_usec) / 1000.0)

	if simulation_root == null or combat_driver == null:
		await _cleanup(scene_tree, flow)
		return _build_failed_report("runtime_released_during_setup", samples, setup_started_usec)
	for _tick_index in range(warmup_ticks):
		simulation_root.call("_physics_process", DEFAULT_DELTA)
		await scene_tree.physics_frame

	for _tick_index in range(physics_ticks):
		simulation_root.call("_physics_process", DEFAULT_DELTA)
		await scene_tree.physics_frame
		_collect_tick_samples(samples, simulation_root, combat_driver)
		last_fow_work_invocation_count = _collect_frame_samples(samples, primary_view, controller, last_fow_work_invocation_count)

	var process_started_msec: int = Time.get_ticks_msec()
	var process_frame_count: int = 0
	while process_frame_count < minimum_process_frames or Time.get_ticks_msec() - process_started_msec < minimum_process_duration_msec:
		await scene_tree.process_frame
		process_frame_count += 1
		last_fow_work_invocation_count = _collect_frame_samples(samples, primary_view, controller, last_fow_work_invocation_count)

	var combat_fixture: Dictionary = await COMBAT_FIXTURE_HARNESS_SCRIPT.new().run_all(scene_tree.root, combat_fixture_repetitions)
	var large_combat_fixture: Dictionary = Dictionary(Dictionary(combat_fixture.get("scenarios", {})).get("four_fireteams_multi_enemy_medic_overwatch", {}))
	_collect_large_combat_fixture_samples(samples, large_combat_fixture)

	var report: Dictionary = _build_report(samples, {
		"status": "measured",
		"setup_duration_usec": Time.get_ticks_usec() - setup_started_usec,
		"physics_tick_count": physics_ticks,
		"warmup_tick_count": warmup_ticks,
		"process_frame_count": process_frame_count,
		"process_duration_msec": Time.get_ticks_msec() - process_started_msec,
		"runtime_unit_count": int(Dictionary(simulation_root.call("get_runtime_tick_budget_debug_snapshot")).get("registered_unit_count", 0)),
		"scenario": "grid_sweep_runtime_and_16v12_combat_fixture",
		"combat_fixture": {
			"friendly_unit_count": int(large_combat_fixture.get("friendly_count", 0)),
			"enemy_unit_count": int(large_combat_fixture.get("enemy_count", 0)),
			"physics_tick_count": int(combat_fixture.get("ticks_per_run", 0)) * combat_fixture_repetitions,
			"warmup_policy": "Grid Sweep runtime warmup only; fixture starts from a primed deterministic state.",
		},
	})
	await _cleanup(scene_tree, flow)
	return report


func _collect_frame_samples(samples: Dictionary, primary_view: Node, controller: Node, last_fow_work_invocation_count: int) -> int:
	if primary_view != null and is_instance_valid(primary_view):
		var terrain: Dictionary = Dictionary(primary_view.call("get_runtime_frame_timing_debug_snapshot"))
		var terrain_scopes: Dictionary = Dictionary(terrain.get("scopes_usec", {}))
		_record(samples, "terrain.unit_proxy_sync_usec", terrain_scopes.get("unit_proxy_sync_usec", null))
		_record(samples, "terrain.dynamic_overlay_usec", terrain_scopes.get("dynamic_order_visuals_usec", null))
		var terrain_counters: Dictionary = Dictionary(terrain.get("counters", {}))
		var fow_work_invocation_count: int = int(terrain_counters.get("fow_work_invocation_count", 0))
		if fow_work_invocation_count > last_fow_work_invocation_count:
			var conditional_scopes: Dictionary = Dictionary(terrain.get("conditional_scopes_usec", {}))
			_record(samples, "terrain.fow_work_usec", conditional_scopes.get("fow_work_usec", null))
			last_fow_work_invocation_count = fow_work_invocation_count
		_record(samples, "frame_script_total_usec", terrain.get("total_usec", null))
	if controller != null and is_instance_valid(controller):
		var frame: Dictionary = Dictionary(controller.call("get_mission_visible_frame_timing_debug_snapshot"))
		var frame_scopes: Dictionary = Dictionary(frame.get("scopes_usec", {}))
		_record(samples, "controller.execution_updates_usec", frame_scopes.get("execution_updates_usec", null))
		_record(samples, "controller.hud_light_usec", frame_scopes.get("hud_light_usec", null))
		var hud_heavy_usec: Variant = frame_scopes.get("hud_heavy_usec", null)
		if hud_heavy_usec != null and float(hud_heavy_usec) > 0.0:
			_record(samples, "controller.hud_heavy_usec", hud_heavy_usec)
	return last_fow_work_invocation_count


func _collect_tick_samples(samples: Dictionary, simulation_root: Node, combat_driver: Node) -> void:
	var simulation: Dictionary = Dictionary(simulation_root.call("get_runtime_tick_budget_debug_snapshot"))
	_record(samples, "simulation.total_tick_usec", simulation.get("total_tick_usec", null))
	_record_snapshot_scopes(samples, "simulation_scope", Dictionary(simulation.get("scopes_usec", {})))
	var combat: Dictionary = Dictionary(combat_driver.call("get_combat_tick_budget_debug_snapshot"))
	var scopes: Dictionary = Dictionary(combat.get("scopes_usec", {}))
	_record(samples, "combat.total_tick_usec", combat.get("total_tick_usec", null))
	_record_snapshot_scopes(samples, "combat_scope", scopes)
	_record(samples, "combat.contact_tracking_usec", scopes.get("contact_tracking_usec", null))
	_record(samples, "combat.enemy_security_usec", scopes.get("enemy_security_usec", null))
	var audit: Dictionary = Dictionary(combat.get("hotpath_audit", {}))
	_record(samples, "combat.los_pair_count", audit.get("last_contact_tracking_los_check_count", null))
	_record(samples, "combat.los_cache_hit_count", audit.get("last_contact_tracking_los_cache_hit_count", null))


func _collect_large_combat_fixture_samples(samples: Dictionary, fixture: Dictionary) -> void:
	for run_variant in Array(fixture.get("runs", [])):
		var run: Dictionary = Dictionary(run_variant)
		for tick_record_variant in Array(run.get("ticks", [])):
			var tick_record: Dictionary = Dictionary(tick_record_variant)
			var simulation: Dictionary = Dictionary(tick_record.get("simulation", {}))
			var combat: Dictionary = Dictionary(tick_record.get("combat", {}))
			_record(samples, "simulation.total_tick_usec", simulation.get("total_tick_usec", null))
			_record(samples, "combat.total_tick_usec", combat.get("total_tick_usec", null))
			_record_snapshot_scopes(samples, "simulation_scope", Dictionary(simulation.get("scopes_usec", {})))
			var combat_scopes: Dictionary = Dictionary(combat.get("scopes_usec", {}))
			_record_snapshot_scopes(samples, "combat_scope", combat_scopes)
			_record(samples, "combat.contact_tracking_usec", combat_scopes.get("contact_tracking_usec", null))
			_record(samples, "combat.enemy_security_usec", combat_scopes.get("enemy_security_usec", null))
			var audit: Dictionary = Dictionary(combat.get("hotpath_audit", {}))
			_record(samples, "combat.los_pair_count", audit.get("last_contact_tracking_los_check_count", null))
			_record(samples, "combat.los_cache_hit_count", audit.get("last_contact_tracking_los_cache_hit_count", null))


func _record_snapshot_scopes(samples: Dictionary, scope_namespace: String, scopes: Dictionary) -> void:
	for scope_name_variant in scopes.keys():
		var scope_name: String = String(scope_name_variant).strip_edges()
		if scope_name.is_empty():
			continue
		var report_scope_name: String = "%s.%s" % [scope_namespace, scope_name]
		if not samples.has(report_scope_name):
			samples[report_scope_name] = []
		_record(samples, report_scope_name, scopes.get(scope_name_variant, null))


func _build_fog_of_war_probe_state() -> Dictionary:
	return {
		"mode": "known_terrain",
		"team_id": "team_alpha",
		"visible_tile_ids": ["tile_4_4", "tile_4_5", "tile_5_4", "tile_5_5"],
		"explored_tile_ids": ["tile_3_4", "tile_3_5", "tile_4_3", "tile_5_3"],
	}


func _new_samples() -> Dictionary:
	var samples: Dictionary = {}
	for scope_name in [
		"frame_script_total_usec", "terrain.unit_proxy_sync_usec", "terrain.fow_work_usec", "terrain.dynamic_overlay_usec",
		"controller.execution_updates_usec", "controller.hud_light_usec", "controller.hud_heavy_usec",
		"combat.contact_tracking_usec", "combat.enemy_security_usec", "combat.los_pair_count", "combat.los_cache_hit_count",
		"simulation.total_tick_usec", "combat.total_tick_usec", "interaction.first_visible_frame_usec", "interaction.lz_input_usec", "interaction.lz_input_ui_refresh_count",
		"interaction.planning_emit_usec", "interaction.lz_action_usec", "interaction.lz_and_deboard_msec",
	]:
		samples[scope_name] = []
	return samples


func _record(samples: Dictionary, scope_name: String, value: Variant) -> void:
	if value == null or not samples.has(scope_name):
		return
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		return
	var numeric_value: float = float(value)
	if numeric_value < 0.0:
		return
	Array(samples[scope_name]).append(numeric_value)


func _build_report(samples: Dictionary, metadata: Dictionary) -> Dictionary:
	var scopes: Dictionary = {}
	for scope_name_variant in samples.keys():
		var scope_name: String = String(scope_name_variant)
		scopes[scope_name] = _build_scope_stats(Array(samples[scope_name]))
	return {
		"schema": "sternenbuergerchen.tactical_map_frame_budget.v1",
		"task_id": "TASK_1187",
		"mode": "Measure",
		"measurement_only": true,
		"git_sha": OS.get_environment("STERNENBUERGERCHEN_GIT_SHA"),
		"engine": Engine.get_version_info(),
		"machine_profile": {
			"declared_baseline_cpu": "Ryzen 7 7800X3D",
			"declared_baseline_memory": "64 GB",
			"declared_baseline_os": "Windows 10 19045",
			"gpu_metrics": null,
		},
		"metadata": metadata.duplicate(true),
		"scopes": scopes,
		"budget_status": _build_measurement_budget_status(scopes),
	}


func _build_scope_stats(values: Array) -> Dictionary:
	var numeric: Array = []
	for value in values:
		if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
			numeric.append(float(value))
	numeric.sort()
	if numeric.is_empty():
		return {"invocation_count": 0, "p50": null, "p95": null, "p99": null, "max": null}
	return {
		"invocation_count": numeric.size(),
		"p50": _percentile(numeric, 0.50),
		"p95": _percentile(numeric, 0.95),
		"p99": _percentile(numeric, 0.99),
		"max": float(numeric[numeric.size() - 1]),
	}


func _percentile(sorted_values: Array, percentile: float) -> float:
	var index: int = clampi(ceili(float(sorted_values.size()) * percentile) - 1, 0, sorted_values.size() - 1)
	return float(sorted_values[index])


func _build_measurement_budget_status(scopes: Dictionary) -> Dictionary:
	var contract: Dictionary = _load_performance_budget_contract()
	var status: Dictionary = {}
	for scope_name_variant in scopes.keys():
		var scope_name: String = String(scope_name_variant)
		var stat: Dictionary = Dictionary(scopes[scope_name])
		if int(stat.get("invocation_count", 0)) <= 0:
			status[scope_name] = {"status": "not_invoked", "violations": []}
			continue
		var rule: Dictionary = Dictionary(SCOPE_BUDGET_RULES.get(scope_name, {}))
		var violations: Array = []
		var thresholds: Dictionary = {}
		for percentile_variant in rule.keys():
			var percentile: String = String(percentile_variant)
			var contract_key: String = String(rule[percentile_variant])
			var limit: float = float(contract.get(contract_key, -1.0))
			if limit < 0.0:
				continue
			var measured_value: float = float(stat.get(percentile, -1.0))
			thresholds[percentile] = limit
			if measured_value > limit:
				violations.append({"percentile": percentile, "measured": measured_value, "limit": limit})
		status[scope_name] = {
			"status": "budget_exceeded" if not violations.is_empty() else "pass",
			"thresholds": thresholds,
			"violations": violations,
		}
	return status


func _load_performance_budget_contract() -> Dictionary:
	var file := FileAccess.open(PERFORMANCE_BUDGET_CONTRACT_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var project_budget: Dictionary = Dictionary(Dictionary(parsed).get("project_budget", {}))
	return Dictionary(project_budget.get("tactical_map", {})).duplicate(true)


func _build_failed_report(reason: String, samples: Dictionary, setup_started_usec: int) -> Dictionary:
	return _build_report(samples, {"status": "setup_failed", "reason": reason, "setup_duration_usec": Time.get_ticks_usec() - setup_started_usec})


func _wait_frames(scene_tree: SceneTree, count: int) -> void:
	for _index in range(maxi(count, 0)):
		await scene_tree.process_frame


func _cleanup(scene_tree: SceneTree, flow: Node) -> void:
	if flow != null and is_instance_valid(flow):
		flow.queue_free()
	await _wait_frames(scene_tree, 2)
