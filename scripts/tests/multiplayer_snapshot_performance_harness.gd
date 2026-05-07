class_name MultiplayerSnapshotPerformanceHarness
extends RefCounted

const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const UNIT_REGISTRY_SCRIPT: GDScript = preload("res://scripts/registries/unit_registry.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")
const OBJECTIVE_STATUS_SCRIPT: GDScript = preload("res://scripts/core/objective_status.gd")
const SNAPSHOT_CONTRACT_SCRIPT: GDScript = preload("res://scripts/multiplayer/multiplayer_snapshot_contract.gd")

const SCENARIOS: Array = [
	{"id": "small_8_units", "unit_count": 8, "iterations": 8},
	{"id": "medium_32_units", "unit_count": 32, "iterations": 6},
	{"id": "large_96_units", "unit_count": 96, "iterations": 4},
]

var _contract = SNAPSHOT_CONTRACT_SCRIPT.new()


func run_all(scene_parent: Node) -> Dictionary:
	var scenarios: Dictionary = {}
	for config_variant in SCENARIOS:
		var config: Dictionary = Dictionary(config_variant)
		scenarios[String(config.get("id", ""))] = _run_scenario(scene_parent, config)
	var determinism: Dictionary = _run_determinism_probe()
	var frequency_plan: Dictionary = _build_frequency_plan()
	return {
		"schema_version": 1,
		"scenarios": scenarios,
		"determinism": determinism,
		"frequency_plan": frequency_plan,
		"summary": _build_summary(scenarios, determinism),
	}


func _run_scenario(scene_parent: Node, config: Dictionary) -> Dictionary:
	var unit_count: int = int(config.get("unit_count", 0))
	var iterations: int = int(config.get("iterations", 1))
	var server_context: Dictionary = _make_context(scene_parent, "Task221Server_%d" % unit_count)
	var client_context: Dictionary = _make_context(scene_parent, "Task221Client_%d" % unit_count)
	_register_units(server_context, unit_count, false)
	_register_units(client_context, unit_count, true)
	_configure_objective(server_context["simulation_root"], unit_count)
	_configure_objective(client_context["simulation_root"], unit_count)

	var build_times: Array = []
	var apply_times: Array = []
	var json_sizes: Array = []
	var dict_counts: Array = []
	var last_snapshot: Dictionary = {}
	var last_metrics: Dictionary = {}
	var last_apply_result: Dictionary = {}
	var accepted_apply_count: int = 0
	for iteration in range(iterations):
		var tick: int = iteration + 1
		var server_simulation: Node = server_context["simulation_root"]
		var client_simulation: Node = client_context["simulation_root"]
		server_simulation.set("tick_counter", tick)
		server_simulation.call("set_multiplayer_snapshot_context", _build_display_context(unit_count, tick, iteration % 2 == 1))

		var build_started_usec: int = Time.get_ticks_usec()
		var snapshot: Dictionary = Dictionary(server_simulation.call("build_multiplayer_snapshot"))
		build_times.append(Time.get_ticks_usec() - build_started_usec)

		var metrics: Dictionary = Dictionary(_contract.call("build_serialization_metrics", snapshot))
		json_sizes.append(int(metrics.get("json_bytes", 0)))
		dict_counts.append(int(metrics.get("dictionary_count", 0)))

		var apply_started_usec: int = Time.get_ticks_usec()
		var apply_result: Dictionary = Dictionary(client_simulation.call("apply_multiplayer_snapshot", snapshot))
		apply_times.append(Time.get_ticks_usec() - apply_started_usec)
		if bool(apply_result.get("accepted", false)):
			accepted_apply_count += 1

		last_snapshot = snapshot
		last_metrics = metrics
		last_apply_result = apply_result

	var client_simulation_final: Node = client_context["simulation_root"]
	var side_effects: Dictionary = {
		"command_queue_size": Array(client_simulation_final.get("command_queue")).size(),
		"effects_queue_size": Array(client_simulation_final.get("effects_queue")).size(),
		"apply_count": int(Dictionary(client_simulation_final.call("get_multiplayer_snapshot_debug_snapshot")).get("apply_count", 0)),
	}
	_cleanup_context(server_context)
	_cleanup_context(client_context)

	return {
		"id": String(config.get("id", "")),
		"unit_count": unit_count,
		"iterations": iterations,
		"accepted_apply_count": accepted_apply_count,
		"stats": {
			"build_usec": _stats(build_times),
			"apply_usec": _stats(apply_times),
			"json_bytes": _stats(json_sizes),
			"dictionary_count": _stats(dict_counts),
		},
		"last_snapshot_counts": Dictionary(last_metrics.get("field_counts", {})),
		"last_metrics": last_metrics,
		"last_apply_result": last_apply_result,
		"side_effects": side_effects,
		"id_only_payload": Array(last_metrics.get("large_payload_offenders", PackedStringArray())).is_empty(),
	}


func _run_determinism_probe() -> Dictionary:
	var first_snapshot: Dictionary = Dictionary(_contract.call("build_state_snapshot", _build_raw_payload(18, false, 42)))
	var second_snapshot: Dictionary = Dictionary(_contract.call("build_state_snapshot", _build_raw_payload(18, true, 42)))
	var first_json: String = String(_contract.call("build_canonical_payload_string", first_snapshot))
	var second_json: String = String(_contract.call("build_canonical_payload_string", second_snapshot))
	return {
		"canonical_equal": first_json == second_json,
		"unit_ids": _extract_ids(Array(first_snapshot.get("units", [])), "unit_id"),
		"fire_event_ids": _extract_ids(Array(first_snapshot.get("fire_events", [])), "event_id"),
		"feedback_bubble_ids": _extract_ids(Array(first_snapshot.get("feedback_bubbles", [])), "bubble_id"),
		"large_payload_offenders": PackedStringArray(Dictionary(_contract.call("build_serialization_metrics", first_snapshot)).get("large_payload_offenders", PackedStringArray())),
	}


func _make_context(scene_parent: Node, context_name: String) -> Dictionary:
	var root := Node.new()
	root.name = context_name
	scene_parent.add_child(root)
	var unit_registry = UNIT_REGISTRY_SCRIPT.new()
	unit_registry.name = "UnitRegistry"
	root.add_child(unit_registry)
	var simulation_root = SIMULATION_ROOT_SCRIPT.new()
	simulation_root.name = "SimulationRoot"
	simulation_root.unit_registry_path = NodePath("../UnitRegistry")
	root.add_child(simulation_root)
	return {
		"root": root,
		"unit_registry": unit_registry,
		"simulation_root": simulation_root,
	}


func _register_units(context: Dictionary, unit_count: int, reverse_order: bool) -> void:
	var indices: Array = range(unit_count)
	if reverse_order:
		indices.reverse()
	for index_variant in indices:
		var index: int = int(index_variant)
		var root: Node = context["root"]
		var unit_registry: Node = context["unit_registry"]
		var simulation_root: Node = context["simulation_root"]
		var team_id: String = "team_alpha" if index % 2 == 0 else "team_bravo"
		var unit_id: String = "unit_%03d" % index
		var unit: Node2D = TEST_UNIT_SCRIPT.new()
		unit.name = unit_id
		unit.unit_id = unit_id
		unit.display_name = "Snapshot Unit %03d" % index
		unit.team_id = team_id
		unit.fireteam_id = "blue" if team_id == "team_alpha" else "red"
		unit.weapon_1_id = _weapon_for_index(index)
		unit.weapon_2_id = unit.weapon_1_id
		unit.global_position = Vector2(float(index % 16) * 32.0, float(index / 16) * 32.0)
		if team_id == "team_bravo":
			unit.set_meta("enemy_security_group_id", "red_%02d" % int(index / 8))
			unit.set_meta("enemy_security_mode", "directional")
			unit.set_meta("enemy_tactics_group_id", "red_%02d" % int(index / 8))
			unit.set_meta("enemy_tactic_profile_id", "aggressive_push")
			unit.set_meta("enemy_visual_archetype_id", "orange_suit")
			unit.set_meta("enemy_advance_style", "push")
			unit.set_meta("enemy_role", "cover" if index % 4 == 1 else "point")
			unit.set_meta("enemy_tactic_label", "PUSH M%d" % (index % 5))
			unit.set_meta("enemy_facing_angle", 0.2 + float(index % 6) * 0.1)
		root.add_child(unit)
		unit_registry.call("register_unit", unit_id, unit)
		simulation_root.call("register_known_unit", unit_id, unit)


func _configure_objective(simulation_root: Node, unit_count: int) -> void:
	var objective_status = OBJECTIVE_STATUS_SCRIPT.new()
	objective_status.objective_id = "obj_task_221_%d" % unit_count
	objective_status.position = Vector2(128.0, 96.0)
	objective_status.capture_radius = 80.0
	objective_status.owning_team_id = "team_alpha"
	objective_status.capturing_team_id = "team_alpha"
	objective_status.capture_progress = 0.45
	objective_status.set_contested(false)
	simulation_root.call("set_objective_status", objective_status)


func _build_display_context(unit_count: int, tick: int, reverse_order: bool) -> Dictionary:
	var contacts: Array = []
	var fire_events: Array = []
	var feedback_bubbles: Array = []
	var enemy_security: Array = []
	var enemy_team_tactics: Array = []
	var group_count: int = maxi(int(ceil(float(unit_count) / 16.0)), 1)
	for group_index in range(group_count):
		var enemy_id: String = "unit_%03d" % maxi(group_index * 8 + 1, 1)
		var friendly_id: String = "unit_%03d" % maxi(group_index * 8, 0)
		contacts.append({
			"fireteam_id": "blue",
			"unit_id": enemy_id,
			"team_id": "team_bravo",
			"detection_state": "spotted",
			"last_known_position": Vector2(64.0 + group_index * 24.0, 96.0),
			"last_seen_tick": tick,
		})
		enemy_security.append({
			"security_group_id": "red_%02d" % group_index,
			"team_id": "team_bravo",
			"profile_id": "aggressive_push",
			"security_mode": "directional",
			"facing_angle": 0.35 + float(group_index) * 0.05,
			"sector_width": 1.8,
			"watch_label": "SEC %02d" % group_index,
			"unit_ids": PackedStringArray([enemy_id]),
			"watched_unit_ids": PackedStringArray([friendly_id]),
			"member_assignments": [{"unit_id": enemy_id, "weapon_id": "rifle", "weapon_tile_range": 25, "weapon_range_world": 1800.0}],
		})
		enemy_team_tactics.append({
			"security_group_id": "red_%02d" % group_index,
			"team_id": "team_bravo",
			"profile_id": "aggressive_push",
			"advance_style": "push",
			"cover_behavior": "cover_between_bounds",
			"tactic_label": "PUSH %02d" % group_index,
			"unit_ids": PackedStringArray([enemy_id]),
			"moving_unit_ids": PackedStringArray([enemy_id]),
			"covering_unit_ids": PackedStringArray(),
			"role_by_unit_id": {enemy_id: "point"},
			"target_positions_by_unit_id": {enemy_id: Vector2(180.0 + group_index * 16.0, 48.0)},
		})
	for index in range(mini(unit_count, 8)):
		var attacker_index: int = index + 1 if index % 2 == 0 else index
		var target_index: int = index if index % 2 == 0 else index - 1
		if attacker_index >= unit_count:
			attacker_index = unit_count - 1
		var attacker_id: String = "unit_%03d" % attacker_index
		var target_id: String = "unit_%03d" % maxi(target_index, 0)
		fire_events.append({
			"event_id": "fire_%03d_%03d" % [tick, index],
			"event_type": "weapon_fire",
			"source": "snapshot_perf",
			"tick": tick,
			"sequence": index,
			"attacker_unit_id": attacker_id,
			"attacker_team_id": "team_bravo",
			"target_unit_id": target_id,
			"target_team_id": "team_alpha",
			"weapon_id": _weapon_for_index(index),
			"muzzle_id": "muzzle_flash_%02d" % ((index % 5) + 1),
			"weapon_tile_range": 25,
			"weapon_range_world": 1800.0,
			"attacker_position": Vector2(96.0 + index * 8.0, 40.0),
			"target_position": Vector2(120.0 + index * 8.0, 48.0),
		})
		feedback_bubbles.append({
			"event_id": "bubble_%03d_%03d" % [tick, index],
			"bubble_id": "bubble_ftl_contact" if index % 2 == 0 else "bubble_npc_thought_focus",
			"unit_id": target_id,
			"fireteam_id": "blue",
			"team_id": "team_alpha",
			"category": "feedback",
			"source": "snapshot_perf",
			"text_key": "contact_ack",
			"anchor_position": Vector2(120.0 + index * 8.0, 48.0),
			"tick": tick,
			"sequence": index,
			"duration_seconds": 1.5,
		})
	if reverse_order:
		contacts.reverse()
		enemy_security.reverse()
		enemy_team_tactics.reverse()
		fire_events.reverse()
		feedback_bubbles.reverse()
	return {
		"dropship": {
			"visible": true,
			"state": "inbound",
			"has_lz": true,
			"position": Vector2(32.0, 32.0),
			"target_position": Vector2(128.0, 96.0),
			"lz_position": Vector2(128.0, 96.0),
			"progress": 0.25,
			"team_id": "team_alpha",
		},
		"contacts": contacts,
		"enemy_security": enemy_security,
		"enemy_team_tactics": enemy_team_tactics,
		"fire_events": fire_events,
		"feedback_bubbles": feedback_bubbles,
		"mission_result": {
			"result": "running",
			"friendly_team_id": "team_alpha",
			"duration_seconds": float(tick) * 0.2,
		},
	}


func _build_raw_payload(unit_count: int, reverse_order: bool, tick: int) -> Dictionary:
	var units: Array = []
	for index in range(unit_count):
		units.append({
			"unit_id": "unit_%03d" % index,
			"position": Vector2(float(index), float(index % 7)),
			"team_id": "team_alpha" if index % 2 == 0 else "team_bravo",
			"visible": true,
			"active_weapon_id": _weapon_for_index(index),
		})
	if reverse_order:
		units.reverse()
	var context: Dictionary = _build_display_context(unit_count, tick, reverse_order)
	return {
		"tick": tick,
		"units": units,
		"vital_updates": [],
		"objective": {
			"objective_id": "obj_task_221_determinism",
			"position": Vector2(128.0, 96.0),
			"owning_team_id": "team_alpha",
			"capturing_team_id": "team_alpha",
			"capture_progress": 0.5,
			"contested": false,
		},
		"dropship": context.get("dropship", {}),
		"contacts": context.get("contacts", []),
		"enemy_security": context.get("enemy_security", []),
		"enemy_team_tactics": context.get("enemy_team_tactics", []),
		"fire_events": context.get("fire_events", []),
		"feedback_bubbles": context.get("feedback_bubbles", []),
		"mission_result": context.get("mission_result", {}),
	}


func _build_frequency_plan() -> Dictionary:
	return {
		"every_snapshot": PackedStringArray(["tick", "units.position", "units.visible", "objective.capture_progress", "contacts.last_known_position"]),
		"event_or_delta_candidates": PackedStringArray(["vital_updates", "fire_events", "feedback_bubbles", "mission_result"]),
		"id_only_fields": PackedStringArray(["active_weapon_id", "weapon_id", "muzzle_id", "bubble_id", "text_key", "enemy_visual_archetype_id"]),
		"client_viewer_boundary": "apply_updates_display_state_only_no_commands_no_effects_no_ai",
	}


func _build_summary(scenarios: Dictionary, determinism: Dictionary) -> Dictionary:
	var scenario_count: int = scenarios.size()
	var all_timing: bool = true
	var all_size: bool = true
	var all_side_effect_free: bool = true
	var all_id_only: bool = true
	for scenario_variant in scenarios.values():
		var scenario: Dictionary = Dictionary(scenario_variant)
		var stats: Dictionary = Dictionary(scenario.get("stats", {}))
		all_timing = all_timing and _stat_has_samples(Dictionary(stats.get("build_usec", {}))) and _stat_has_samples(Dictionary(stats.get("apply_usec", {})))
		all_size = all_size and _stat_has_samples(Dictionary(stats.get("json_bytes", {}))) and _stat_has_samples(Dictionary(stats.get("dictionary_count", {})))
		all_side_effect_free = all_side_effect_free and int(Dictionary(scenario.get("side_effects", {})).get("command_queue_size", -1)) == 0 and int(Dictionary(scenario.get("side_effects", {})).get("effects_queue_size", -1)) == 0
		all_id_only = all_id_only and bool(scenario.get("id_only_payload", false))
	return {
		"scenario_count": scenario_count,
		"has_build_apply_timing": all_timing,
		"has_size_metrics": all_size,
		"deterministic_canonical_payload": bool(determinism.get("canonical_equal", false)),
		"all_scenarios_side_effect_free": all_side_effect_free,
		"all_payloads_id_only": all_id_only and Array(determinism.get("large_payload_offenders", PackedStringArray())).is_empty(),
	}


func _stats(values: Array) -> Dictionary:
	var numeric: Array = []
	for value_variant in values:
		numeric.append(float(value_variant))
	numeric.sort()
	if numeric.is_empty():
		return {"count": 0, "min": 0.0, "median": 0.0, "p95": 0.0, "p99": 0.0, "max": 0.0}
	return {
		"count": numeric.size(),
		"min": float(numeric.front()),
		"median": _percentile(numeric, 0.5),
		"p95": _percentile(numeric, 0.95),
		"p99": _percentile(numeric, 0.99),
		"max": float(numeric.back()),
	}


func _percentile(sorted_values: Array, percentile: float) -> float:
	if sorted_values.is_empty():
		return 0.0
	var index: int = clampi(int(ceil((sorted_values.size() - 1) * percentile)), 0, sorted_values.size() - 1)
	return float(sorted_values[index])


func _stat_has_samples(stat: Dictionary) -> bool:
	return int(stat.get("count", 0)) > 0 and float(stat.get("p99", -1.0)) >= float(stat.get("median", 0.0))


func _extract_ids(entries: Array, key: String) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	for entry_variant in entries:
		if typeof(entry_variant) == TYPE_DICTIONARY:
			result.append(String(Dictionary(entry_variant).get(key, "")))
	return result


func _weapon_for_index(index: int) -> String:
	var weapons: PackedStringArray = PackedStringArray(["rifle", "smg", "sniper", "rocket_launcher"])
	return weapons[index % weapons.size()]


func _cleanup_context(context: Dictionary) -> void:
	var root: Node = context.get("root", null)
	if root != null:
		root.free()
