extends SceneTree

const FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tactical/fireteam_movement_controller.gd")
const FIRETEAM_BEHAVIOR_PROFILE_SCRIPT: GDScript = preload("res://scripts/command/fireteam_behavior_profile.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")
const UNIT_COMMAND_SCRIPT: GDScript = preload("res://scripts/npc/unit_command.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_461_fireteam_engage_visual_stuck_hotfix.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/fireteam_behavior_modes_contract.md"

var _passed: int = 0
var _failed: int = 0


class SimulationStub:
	extends RefCounted
	var commands: Array = []

	func enqueue_command(command_dict: Dictionary) -> void:
		commands.append(command_dict.duplicate(true))


class WalkableTargetStub:
	extends RefCounted
	var adjustment: Vector2 = Vector2(36.0, 0.0)

	func resolve_walkable_target(world_pos: Vector2) -> Dictionary:
		return {
			"original_position": world_pos,
			"original_grid": Vector2i.ZERO,
			"target_walkable": false,
			"replacement_grid": Vector2i(1, 0),
			"replacement_position": world_pos + adjustment,
			"blocked_grid": Vector2i.ZERO,
			"blocked_position": world_pos,
			"blocker_reason": "test_blocked_slot",
		}


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_461 Fireteam Engage Visual Stuck Hotfix ===")
	_test_engage_completion_uses_walkable_runtime_slots()
	await _test_motion_target_overrides_stale_security_facing()
	await _test_hostile_readability_core_is_window_visible()
	await _test_fire_vfx_keeps_bloom_and_trace_without_texture()
	_test_docs_capture_task()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_engage_completion_uses_walkable_runtime_slots() -> void:
	var controller = FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT.new()
	var simulation = SimulationStub.new()
	var terrain = WalkableTargetStub.new()
	var units: Array = _make_fireteam_units("task461")
	var result: Dictionary = Dictionary(controller.call(
		"start_execution",
		"drill",
		"engage",
		1,
		Vector2(72.0, 0.0),
		_make_profile(FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_AGGRESSIVE),
		units,
		units[0],
		simulation,
		terrain
	))
	var state: Dictionary = Dictionary(result.get("movement_state", {}))
	_assert(bool(result.get("started", false)), "Engage execution starts with terrain target resolver")
	_assert(int(state.get("current_walkable_target_adjustment_count", 0)) >= 1, "Movement state records walkable target-slot adjustment")
	_assert(_all_commands_match_resolved_targets(simulation.commands, Dictionary(state.get("current_target_positions", {}))), "Runtime commands use the same resolved target slots as completion")
	for unit in units:
		var unit_id: String = String(unit.call("get_unit_id"))
		unit.global_position = Vector2(Dictionary(state.get("current_target_positions", {})).get(unit_id, unit.global_position))
	var update_result: Dictionary = Dictionary(controller.call("update_execution", "drill", units, units[0], simulation, terrain))
	_assert(bool(update_result.get("finished", false)), "Engage execution can finish when units reach resolved walkable slots")
	_cleanup_units(units)


func _test_motion_target_overrides_stale_security_facing() -> void:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task461_facing", Vector2i(6, 6), Vector2.ZERO, 64.0, 32.0, 2)
	var view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(view)
	view.call("configure_from_map", map_data)
	var unit = _make_unit("task461_alpha", "team_alpha", "drill", true, Vector2(128.0, 128.0))
	root.add_child(unit)
	unit.call("assign_unit_command", UNIT_COMMAND_SCRIPT.new({
		"command_type": UNIT_COMMAND_SCRIPT.TYPE_ENGAGE_AREA,
		"target_position": Vector2(224.0, 128.0),
		"fire_status": UNIT_COMMAND_SCRIPT.FIRE_STATUS_FIRE_AT_WILL,
		"source_command_type": "engage",
		"weapon_posture": UNIT_COMMAND_SCRIPT.WEAPON_POSTURE_AIMED,
	}))
	unit.set_meta("security_facing_angle", PI)
	view.call("set_unit_nodes", [unit])
	await _wait_frames(8)
	var aim_direction: Vector2 = Vector2(view.call("_resolve_unit_aim_direction", unit, unit.global_position)).normalized()
	_assert(aim_direction.dot(Vector2.RIGHT) > 0.95, "Motion/target direction wins over stale security-facing when no fire event is active")
	view.queue_free()
	unit.queue_free()
	await _wait_frames(2)


func _test_hostile_readability_core_is_window_visible() -> void:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task461_body", Vector2i(6, 6), Vector2.ZERO, 64.0, 32.0, 2)
	var view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(view)
	view.call("configure_from_map", map_data)
	var enemy = _make_unit("task461_enemy", "team_bravo", "enemy", false, Vector2(128.0, 128.0))
	root.add_child(enemy)
	view.call("set_unit_nodes", [enemy])
	await _wait_frames(8)
	var snapshot: Dictionary = Dictionary(view.call("get_render_snapshot"))
	var state: Dictionary = Dictionary(Dictionary(snapshot.get("unit_proxy_state_by_id", {})).get("task461_enemy", {}))
	_assert(bool(state.get("unit_body_readability_core_visible", false)), "Hostile proxy exposes readability body core")
	_assert(float(state.get("unit_body_readability_core_radius", 0.0)) >= 0.16, "Hostile readability core is large enough for the drill window")
	_assert(float(state.get("unit_body_readability_core_alpha", 0.0)) >= 0.85, "Hostile readability core is opaque enough for the drill window")
	view.queue_free()
	enemy.queue_free()
	await _wait_frames(2)


func _test_fire_vfx_keeps_bloom_and_trace_without_texture() -> void:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task461_fire_vfx", Vector2i(6, 6), Vector2.ZERO, 64.0, 32.0, 2)
	var view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(view)
	view.call("configure_from_map", map_data)
	view.set("_weapon_fire_vfx_catalog", {
		"default_id": "missing_flash",
		"default_by_weapon": {"rifle": "missing_flash"},
		"muzzle_flashes": [{
			"id": "missing_flash",
			"path": "res://missing/task461_muzzle.png",
			"barrel_offset_world": 12.0,
			"pixel_size": 0.01,
		}],
	})
	view.call("set_order_visual_payload", {
		"selected_fireteam_ids": PackedStringArray(["drill"]),
		"fire_event_dicts": [{
			"event_id": "task461_fire",
			"event_type": "weapon_fire",
			"attacker_unit_id": "task461_alpha",
			"target_unit_id": "task461_enemy",
			"attacker_position": Vector2(128.0, 128.0),
			"target_position": Vector2(224.0, 128.0),
			"weapon_id": "rifle",
		}],
	})
	await _wait_frames(8)
	var snapshot: Dictionary = Dictionary(view.call("get_render_snapshot"))
	var entry: Dictionary = _find_entry(Array(snapshot.get("weapon_fire_vfx_entries", [])), "event_id", "task461_fire")
	_assert(not entry.is_empty(), "Fire event still creates a VFX entry without a muzzle texture")
	_assert(bool(entry.get("muzzle_texture_missing", false)), "VFX entry records missing muzzle texture")
	_assert(bool(entry.get("muzzle_bloom_visible", false)) and bool(entry.get("trace_visible", false)), "Missing texture still leaves visible bloom and trace")
	view.queue_free()
	await _wait_frames(2)


func _test_docs_capture_task() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	_assert(task_text.contains("TASK_461 - Fireteam Engage Visual Stuck Hotfix"), "TASK_461 task file exists")
	_assert(status_text.contains("TASK_461 - Fireteam Engage Visual Stuck Hotfix"), "Implementation status documents TASK_461")
	_assert(roadmap_text.contains("TASK_461 - Fireteam Engage Visual Stuck Hotfix"), "Roadmap lists TASK_461")
	_assert(contract_text.contains("TASK_461 Engage-Visual/Stuck-Hotfix"), "Behavior contract documents TASK_461")


func _make_profile(tactical_stance: String) -> Dictionary:
	return {
		"advance_style": FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.ADVANCE_STYLE_RUSH,
		"tactical_stance": tactical_stance,
		"cover_priority": 0.55,
		"cohesion_threshold": 120.0,
		"order_fidelity": 1.0,
		"execution_cohesion": 0.65,
		"initiative": 0.5,
	}


func _make_fireteam_units(prefix: String) -> Array:
	return [
		_make_unit("%s_lead" % prefix, "team_alpha", "drill", true, Vector2(0.0, 0.0)),
		_make_unit("%s_a" % prefix, "team_alpha", "drill", false, Vector2(-18.0, 4.0)),
		_make_unit("%s_b" % prefix, "team_alpha", "drill", false, Vector2(16.0, -4.0)),
		_make_unit("%s_c" % prefix, "team_alpha", "drill", false, Vector2(0.0, 18.0)),
	]


func _make_unit(unit_id: String, team_id: String, fireteam_id: String, is_lead: bool, position_value: Vector2):
	var unit = TEST_UNIT_SCRIPT.new()
	unit.name = unit_id
	unit.unit_id = unit_id
	unit.team_id = team_id
	unit.fireteam_id = fireteam_id
	unit.display_name = unit_id
	unit.is_fireteam_lead = is_lead
	unit.global_position = position_value
	unit.weapon_1_id = "rifle"
	unit.skill_speed = 0.5
	unit.skill_toughness = 0.5
	unit.skill_accuracy = 0.5
	unit._ready()
	return unit


func _all_commands_match_resolved_targets(commands: Array, target_positions: Dictionary) -> bool:
	if commands.is_empty() or target_positions.is_empty():
		return false
	for command_variant in commands:
		if typeof(command_variant) != TYPE_DICTIONARY:
			return false
		var command: Dictionary = Dictionary(command_variant)
		var unit_id: String = String(command.get("unit_id", ""))
		if not target_positions.has(unit_id):
			continue
		var target_variant: Variant = command.get("target_position", null)
		if typeof(target_variant) != TYPE_VECTOR2:
			return false
		if Vector2(target_variant).distance_to(Vector2(target_positions.get(unit_id))) > 0.01:
			return false
	return true


func _find_entry(entries: Array, key: String, expected_value: Variant) -> Dictionary:
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		if entry.get(key) == expected_value:
			return entry
	return {}


func _cleanup_units(units: Array) -> void:
	for unit in units:
		if unit is Node:
			var node := unit as Node
			if node.is_inside_tree():
				node.queue_free()
			else:
				node.free()


func _wait_frames(count: int) -> void:
	for _index in range(maxi(count, 0)):
		await process_frame


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	push_error("  FAIL: %s" % message)
