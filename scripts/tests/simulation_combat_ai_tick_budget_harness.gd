class_name SimulationCombatAITickBudgetHarness
extends RefCounted

const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const UNIT_REGISTRY_SCRIPT: GDScript = preload("res://scripts/registries/unit_registry.gd")
const TERRAIN_REGISTRY_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_registry.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")
const MISSION_COMBAT_LOOP_DRIVER_SCRIPT: GDScript = preload("res://scripts/tests/mission_combat_loop_driver.gd")
const COMBAT_VISIBILITY_CACHE_SCRIPT: GDScript = preload("res://scripts/mission/combat_visibility_cache.gd")

const DEFAULT_REPETITIONS: int = 3
const TICKS_PER_RUN: int = 4


func run_all(scene_parent: Node, repetitions: int = DEFAULT_REPETITIONS) -> Dictionary:
	var safe_repetitions: int = maxi(repetitions, 1)
	var scenarios: Dictionary = {}
	scenarios["small_mission"] = await _run_scale_scenario(scene_parent, "small_mission", 4, 3, 1, false, safe_repetitions)
	scenarios["two_fireteams_enemy_team"] = await _run_scale_scenario(scene_parent, "two_fireteams_enemy_team", 8, 6, 2, false, safe_repetitions)
	scenarios["four_fireteams_multi_enemy_medic_overwatch"] = await _run_scale_scenario(scene_parent, "four_fireteams_multi_enemy_medic_overwatch", 16, 12, 4, true, safe_repetitions)
	return {
		"schema_version": 1,
		"repetitions": safe_repetitions,
		"ticks_per_run": TICKS_PER_RUN,
		"scenarios": scenarios,
		"summary": _build_summary(scenarios),
	}


func _run_scale_scenario(scene_parent: Node, scenario_id: String, friendly_count: int, enemy_count: int, fireteam_count: int, include_medic_and_downed: bool, repetitions: int) -> Dictionary:
	var runs: Array = []
	for run_index in range(repetitions):
		var context: Dictionary = _make_combat_context(scene_parent, scenario_id, friendly_count, enemy_count, fireteam_count, include_medic_and_downed)
		await scene_parent.get_tree().process_frame
		_prime_state(context, include_medic_and_downed)
		var tick_records: Array = []
		var simulation_root = context["simulation_root"]
		var combat_driver = context["combat_driver"]
		for _tick_index in range(TICKS_PER_RUN):
			simulation_root.call("_physics_process", 0.1)
			tick_records.append({
				"simulation": Dictionary(simulation_root.call("get_runtime_tick_budget_debug_snapshot")),
				"combat": Dictionary(combat_driver.call("get_combat_tick_budget_debug_snapshot")),
			})
		runs.append({
			"run_index": run_index,
			"ticks": tick_records,
			"stats": _build_run_stats(tick_records),
		})
		_cleanup_context(context)
		await scene_parent.get_tree().process_frame
	return {
		"scenario_id": scenario_id,
		"friendly_count": friendly_count,
		"enemy_count": enemy_count,
		"fireteam_count": fireteam_count,
		"include_medic_and_downed": include_medic_and_downed,
		"runs": runs,
		"stats": _build_scenario_stats(runs),
		"hotpath_audit": _build_scenario_hotpath_audit(runs),
	}


func _make_combat_context(scene_parent: Node, scenario_id: String, friendly_count: int, enemy_count: int, fireteam_count: int, include_medic_and_downed: bool) -> Dictionary:
	var scene := Node.new()
	scene.name = "Task218_%s" % scenario_id
	scene_parent.add_child(scene)
	var unit_registry = UNIT_REGISTRY_SCRIPT.new()
	unit_registry.name = "UnitRegistry"
	scene.add_child(unit_registry)
	var terrain_registry = _make_terrain_registry(32, 32)
	terrain_registry.name = "TerrainRegistry"
	scene.add_child(terrain_registry)
	var simulation_root = SIMULATION_ROOT_SCRIPT.new()
	simulation_root.name = "SimulationRoot"
	simulation_root.unit_registry_path = NodePath("../UnitRegistry")
	simulation_root.terrain_registry_path = NodePath("../TerrainRegistry")
	simulation_root.navigation_debug_enabled = true
	simulation_root.runtime_tick_budget_debug_enabled = true
	simulation_root.unit_minimum_spacing_debug_enabled = true
	simulation_root.unit_minimum_spacing_distance = 24.0
	simulation_root.local_avoidance_enabled = true
	simulation_root.local_avoidance_debug_enabled = true
	scene.add_child(simulation_root)
	simulation_root.set_physics_process(false)
	var friendly_paths: Array[NodePath] = []
	var enemy_paths: Array[NodePath] = []
	var friendly_units: Array = []
	var enemy_units: Array = []
	for index in range(friendly_count):
		var fireteam_index: int = index % maxi(fireteam_count, 1)
		var friendly_row: int = int(index / maxi(fireteam_count, 1))
		var unit = _make_unit("task218_friendly_%02d" % index, "team_alpha", _fireteam_id_for_index(fireteam_index), Vector2(56.0 + float(fireteam_index * 52), 72.0 + float(friendly_row * 44)), index == fireteam_index)
		if include_medic_and_downed and index % 5 == 0:
			unit.role_id = "medic"
			unit.weapon_2_id = "medictool"
		scene.add_child(unit)
		unit.call("set_terrain_registry", terrain_registry)
		unit_registry.call("register_unit", unit.unit_id, unit)
		simulation_root.call("register_known_unit", unit.unit_id, unit)
		friendly_paths.append(NodePath("../%s" % String(unit.name)))
		friendly_units.append(unit)
	for index in range(enemy_count):
		var group_index: int = index % maxi(fireteam_count, 1)
		var enemy_row: int = int(index / maxi(fireteam_count, 1))
		var enemy = _make_unit("task218_enemy_%02d" % index, "team_bravo", "red_%d" % group_index, Vector2(330.0 + float(group_index * 52), 76.0 + float(enemy_row * 44)), index == 0)
		_apply_enemy_tactics(enemy, group_index)
		scene.add_child(enemy)
		enemy.call("set_terrain_registry", terrain_registry)
		unit_registry.call("register_unit", enemy.unit_id, enemy)
		simulation_root.call("register_known_unit", enemy.unit_id, enemy)
		enemy_paths.append(NodePath("../%s" % String(enemy.name)))
		enemy_units.append(enemy)
	var combat_visibility_cache: Node = COMBAT_VISIBILITY_CACHE_SCRIPT.new()
	combat_visibility_cache.name = "CombatVisibilityCache"
	scene.add_child(combat_visibility_cache)
	var combat_driver = MISSION_COMBAT_LOOP_DRIVER_SCRIPT.new()
	combat_driver.name = "CombatDriver"
	combat_driver.simulation_root_path = NodePath("../SimulationRoot")
	combat_driver.terrain_registry_path = NodePath("../TerrainRegistry")
	combat_driver.combat_visibility_cache_path = NodePath("../CombatVisibilityCache")
	combat_driver.friendly_unit_paths = friendly_paths
	combat_driver.enemy_unit_paths = enemy_paths
	combat_driver.preview_mode = true
	combat_driver.contact_range = 360.0
	combat_driver.enemy_engage_distance = 320.0
	combat_driver.ticks_between_attacks = 1
	combat_driver.combat_tick_budget_debug_enabled = true
	scene.add_child(combat_driver)
	return {
		"scene": scene,
		"unit_registry": unit_registry,
		"terrain_registry": terrain_registry,
		"simulation_root": simulation_root,
		"combat_driver": combat_driver,
		"friendly_units": friendly_units,
		"enemy_units": enemy_units,
	}


func _prime_state(context: Dictionary, include_medic_and_downed: bool) -> void:
	if not include_medic_and_downed:
		return
	var friendly_units: Array = Array(context.get("friendly_units", []))
	if friendly_units.size() > 1 and friendly_units[1].has_method("apply_damage"):
		friendly_units[1].call("apply_damage", 45, {"source": "task218_wounded_fixture"})
	if friendly_units.size() > 2 and friendly_units[2].has_method("apply_damage"):
		friendly_units[2].call("apply_damage", 120, {"source": "task218_downed_fixture"})


func _make_unit(unit_id: String, team_id: String, fireteam_id: String, position: Vector2, is_lead: bool):
	var unit = TEST_UNIT_SCRIPT.new()
	unit.name = unit_id
	unit.unit_id = unit_id
	unit.team_id = team_id
	unit.fireteam_id = fireteam_id
	unit.is_fireteam_lead = is_lead
	unit.weapon_1_id = "rifle"
	unit.weapon_2_id = "rifle"
	unit.skill_accuracy = 0.65
	unit.awareness = 0.7
	unit.recognition = 0.7
	unit.discipline = 0.8
	unit.global_position = position
	return unit


func _apply_enemy_tactics(enemy: Node, group_index: int) -> void:
	var profile_id: String = "aggressive_push" if group_index % 2 == 0 else "defensive_cover"
	var advance_style: String = "push" if group_index % 2 == 0 else "bounding"
	enemy.set_meta("enemy_tactics_config", {
		"group_id": "red_%d" % group_index,
		"profile_id": profile_id,
		"advance_style": advance_style,
		"security_mode": "directional",
		"facing": "west",
		"cover_behavior": "seek_cover",
		"team_id": "team_bravo",
	})


func _fireteam_id_for_index(index: int) -> String:
	match index:
		0:
			return "blue"
		1:
			return "gold"
		2:
			return "reserve"
		_:
			return "med"


func _make_terrain_registry(width: int, height: int):
	var registry = TERRAIN_REGISTRY_SCRIPT.new()
	registry.configure_iso_grid(Vector2.ZERO, 64.0, 32.0)
	for x in range(width):
		for y in range(height):
			var grid := Vector2i(x, y)
			var cover_value: int = 65 if x % 7 == 0 and y % 3 == 0 else 0
			registry.register_tile(TERRAIN_TILE_DATA_SCRIPT.new({
				"tile_id": "%d_%d" % [x, y],
				"type_id": "ground_flat",
				"grid_position": grid,
				"world_position": registry.grid_to_world(grid),
				"walkable": true,
				"blocks_los": cover_value > 0,
				"cover_value": cover_value,
				"height_level": 1 if x > 12 and x < 18 and y > 10 and y < 20 else 0,
				"edge_type": "slope",
				"surface_type": "sand" if (x + y) % 9 == 0 else "ground",
			}))
	return registry


func _build_run_stats(tick_records: Array) -> Dictionary:
	var simulation_totals: Array = []
	var combat_totals: Array = []
	var simulation_scopes: Dictionary = {}
	var combat_scopes: Dictionary = {}
	for tick_record_variant in tick_records:
		var tick_record: Dictionary = Dictionary(tick_record_variant)
		var simulation: Dictionary = Dictionary(tick_record.get("simulation", {}))
		var combat: Dictionary = Dictionary(tick_record.get("combat", {}))
		simulation_totals.append(float(simulation.get("total_tick_usec", 0.0)))
		combat_totals.append(float(combat.get("total_tick_usec", 0.0)))
		_collect_scope_values(simulation_scopes, Dictionary(simulation.get("scopes_usec", {})))
		_collect_scope_values(combat_scopes, Dictionary(combat.get("scopes_usec", {})))
	return {
		"simulation_total_tick_usec": _stats_from_values(simulation_totals),
		"combat_total_tick_usec": _stats_from_values(combat_totals),
		"simulation_scopes_usec": _stats_by_scope(simulation_scopes),
		"combat_scopes_usec": _stats_by_scope(combat_scopes),
	}


func _build_scenario_stats(runs: Array) -> Dictionary:
	var simulation_totals: Array = []
	var combat_totals: Array = []
	var simulation_scopes: Dictionary = {}
	var combat_scopes: Dictionary = {}
	for run_variant in runs:
		var run: Dictionary = Dictionary(run_variant)
		for tick_record_variant in Array(run.get("ticks", [])):
			var tick_record: Dictionary = Dictionary(tick_record_variant)
			var simulation: Dictionary = Dictionary(tick_record.get("simulation", {}))
			var combat: Dictionary = Dictionary(tick_record.get("combat", {}))
			simulation_totals.append(float(simulation.get("total_tick_usec", 0.0)))
			combat_totals.append(float(combat.get("total_tick_usec", 0.0)))
			_collect_scope_values(simulation_scopes, Dictionary(simulation.get("scopes_usec", {})))
			_collect_scope_values(combat_scopes, Dictionary(combat.get("scopes_usec", {})))
	return {
		"simulation_total_tick_usec": _stats_from_values(simulation_totals),
		"combat_total_tick_usec": _stats_from_values(combat_totals),
		"simulation_scopes_usec": _stats_by_scope(simulation_scopes),
		"combat_scopes_usec": _stats_by_scope(combat_scopes),
	}


func _build_scenario_hotpath_audit(runs: Array) -> Dictionary:
	for run_variant in runs:
		var run: Dictionary = Dictionary(run_variant)
		for tick_record_variant in Array(run.get("ticks", [])):
			var tick_record: Dictionary = Dictionary(tick_record_variant)
			var combat: Dictionary = Dictionary(tick_record.get("combat", {}))
			var audit: Dictionary = Dictionary(combat.get("hotpath_audit", {}))
			if not audit.is_empty():
				return audit
	return {}


func _collect_scope_values(target: Dictionary, scopes: Dictionary) -> void:
	for scope_name_variant in scopes.keys():
		var scope_name: String = String(scope_name_variant)
		var values: Array = Array(target.get(scope_name, []))
		values.append(float(scopes.get(scope_name_variant, 0.0)))
		target[scope_name] = values


func _stats_by_scope(scope_values: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for scope_name_variant in scope_values.keys():
		result[String(scope_name_variant)] = _stats_from_values(Array(scope_values.get(scope_name_variant, [])))
	return result


func _stats_from_values(values: Array) -> Dictionary:
	var numeric_values: Array = []
	for value_variant in values:
		numeric_values.append(float(value_variant))
	numeric_values.sort()
	if numeric_values.is_empty():
		return {
			"count": 0,
			"median": -1.0,
			"p95": -1.0,
			"p99": -1.0,
			"min": -1.0,
			"max": -1.0,
		}
	return {
		"count": numeric_values.size(),
		"median": _percentile(numeric_values, 50.0),
		"p95": _percentile(numeric_values, 95.0),
		"p99": _percentile(numeric_values, 99.0),
		"min": float(numeric_values[0]),
		"max": float(numeric_values[numeric_values.size() - 1]),
	}


func _percentile(sorted_values: Array, percentile: float) -> float:
	if sorted_values.is_empty():
		return -1.0
	var raw_index: int = int(ceili((percentile / 100.0) * float(sorted_values.size()))) - 1
	var index: int = clampi(raw_index, 0, sorted_values.size() - 1)
	return float(sorted_values[index])


func _build_summary(scenarios: Dictionary) -> Dictionary:
	return {
		"scenario_count": scenarios.size(),
		"has_small_mission": scenarios.has("small_mission"),
		"has_two_fireteams": scenarios.has("two_fireteams_enemy_team"),
		"has_large_medic_overwatch": scenarios.has("four_fireteams_multi_enemy_medic_overwatch"),
		"has_simulation_tick_percentiles": _all_scenarios_have_stat(scenarios, "simulation_total_tick_usec"),
		"has_combat_tick_percentiles": _all_scenarios_have_stat(scenarios, "combat_total_tick_usec"),
		"has_runtime_scopes": _all_scenarios_have_scopes(scenarios, "simulation_scopes_usec", ["command_queue_usec", "effect_queue_usec", "unit_minimum_spacing_usec", "tick_signal_emit_usec"]),
		"has_combat_scopes": _all_scenarios_have_scopes(scenarios, "combat_scopes_usec", ["contact_tracking_usec", "enemy_security_usec", "enemy_team_tactics_usec", "medic_support_usec", "enemy_advance_usec", "overwatch_security_usec", "combat_fire_decision_usec"]),
		"has_hotpath_audit": _all_scenarios_have_hotpath_audit(scenarios),
	}


func _all_scenarios_have_stat(scenarios: Dictionary, stat_name: String) -> bool:
	for scenario_variant in scenarios.values():
		var stats: Dictionary = Dictionary(Dictionary(scenario_variant).get("stats", {}))
		var stat: Dictionary = Dictionary(stats.get(stat_name, {}))
		if int(stat.get("count", 0)) <= 0 or not stat.has("median") or not stat.has("p95") or not stat.has("p99"):
			return false
	return true


func _all_scenarios_have_scopes(scenarios: Dictionary, scope_group: String, required_scope_names: Array) -> bool:
	for scenario_variant in scenarios.values():
		var stats: Dictionary = Dictionary(Dictionary(scenario_variant).get("stats", {}))
		var scopes: Dictionary = Dictionary(stats.get(scope_group, {}))
		for scope_name_variant in required_scope_names:
			if not scopes.has(String(scope_name_variant)):
				return false
	return true


func _all_scenarios_have_hotpath_audit(scenarios: Dictionary) -> bool:
	for scenario_variant in scenarios.values():
		var audit: Dictionary = Dictionary(Dictionary(scenario_variant).get("hotpath_audit", {}))
		if audit.is_empty() or not bool(audit.get("client_viewer_paths_read_only", false)):
			return false
	return true


func _cleanup_context(context: Dictionary) -> void:
	var scene = context.get("scene", null)
	if scene != null:
		scene.queue_free()
