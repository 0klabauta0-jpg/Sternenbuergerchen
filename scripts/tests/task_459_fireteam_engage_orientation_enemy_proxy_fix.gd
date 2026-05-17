extends SceneTree

const DRILL_SCENE: PackedScene = preload("res://scenes/tests/fireteam_command_drill_map.tscn")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")
const UNIT_COMMAND_SCRIPT: GDScript = preload("res://scripts/npc/unit_command.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_459_fireteam_engage_orientation_enemy_proxy_fix.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/fireteam_behavior_modes_contract.md"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_459 Fireteam Engage Orientation Enemy Proxy Fix ===")
	await _test_contact_and_fire_event_override_security_facing()
	await _test_drill_enemies_keep_visible_body_fallbacks()
	_test_docs_capture_task()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_contact_and_fire_event_override_security_facing() -> void:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task459_orientation", Vector2i(8, 8), Vector2.ZERO, 64.0, 32.0, 2)
	var view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(view)
	view.call("configure_from_map", map_data)
	var unit = _make_unit("task459_alpha", "team_alpha", "drill", Vector2(128.0, 128.0))
	root.add_child(unit)
	unit.call("assign_unit_command", UNIT_COMMAND_SCRIPT.new({
		"command_type": UNIT_COMMAND_SCRIPT.TYPE_ENGAGE_AREA,
		"target_position": Vector2(64.0, 128.0),
		"fire_status": UNIT_COMMAND_SCRIPT.FIRE_STATUS_FIRE_AT_WILL,
		"weapon_posture": UNIT_COMMAND_SCRIPT.WEAPON_POSTURE_AIMED,
	}))
	unit.set_meta("security_facing_angle", PI)
	view.call("set_unit_nodes", [unit])
	view.call("set_contact_entries", [{
		"fireteam_id": "drill",
		"unit_id": "task459_enemy",
		"team_id": "team_bravo",
		"last_known_position": Vector2(224.0, 128.0),
		"detection_state": "confirmed",
	}], PackedStringArray(["drill"]))
	await _wait_frames(8)
	var contact_direction: Vector2 = Vector2(view.call("_resolve_unit_aim_direction", unit, unit.global_position)).normalized()
	_assert(contact_direction.dot(Vector2.RIGHT) > 0.95, "Confirmed contact direction overrides stale security-facing direction")
	view.call("set_order_visual_payload", {
		"selected_fireteam_ids": PackedStringArray(["drill"]),
		"fire_event_dicts": [{
			"event_id": "task459_fire",
			"event_type": "weapon_fire",
			"attacker_unit_id": "task459_alpha",
			"target_unit_id": "task459_enemy",
			"attacker_position": unit.global_position,
			"target_position": Vector2(224.0, 128.0),
			"weapon_id": "rifle",
		}],
	})
	await _wait_frames(8)
	var fire_direction: Vector2 = Vector2(view.call("_resolve_unit_aim_direction", unit, unit.global_position)).normalized()
	_assert(fire_direction.dot(Vector2.RIGHT) > 0.95, "Active fire event keeps aim/facing on the enemy before move target or defense")
	var snapshot: Dictionary = Dictionary(view.call("get_render_snapshot"))
	var state_by_id: Dictionary = Dictionary(snapshot.get("unit_proxy_state_by_id", {}))
	var state: Dictionary = Dictionary(state_by_id.get("task459_alpha", {}))
	_assert(absf(float(state.get("unit_aim_pose_yaw_delta_degrees", 180.0))) < 45.0, "Proxy aim yaw stays close to active contact direction")
	view.queue_free()
	unit.queue_free()
	await _wait_frames(2)


func _test_drill_enemies_keep_visible_body_fallbacks() -> void:
	root.size = Vector2i(1920, 1080)
	var scene := DRILL_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(90)
	var setup := scene.get_node_or_null("MissionSetup")
	var primary_view := scene.get_node_or_null("Primary3DView")
	_assert(setup != null and primary_view != null, "Drill scene exposes setup and primary 3D view")
	if setup == null or primary_view == null:
		scene.queue_free()
		await _wait_frames(2)
		return
	if setup.has_method("set_fog_of_war_mode"):
		setup.call("set_fog_of_war_mode", "off")
	await _wait_frames(8)
	var presence: Dictionary = Dictionary(setup.call("get_expected_unit_presence_snapshot"))
	var enemy_ids: Array = Array(presence.get("enemy_unit_ids", []))
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	var state_by_id: Dictionary = Dictionary(snapshot.get("unit_proxy_state_by_id", {}))
	_assert(enemy_ids.size() == 4, "Drill scenario still expects four hostile units")
	_assert(_all_hostile_units_have_body_fallback(state_by_id, enemy_ids), "All hostile proxies expose a visible body/readability fallback")
	scene.queue_free()
	await _wait_frames(2)


func _all_hostile_units_have_body_fallback(state_by_id: Dictionary, enemy_ids: Array) -> bool:
	if enemy_ids.size() < 4:
		return false
	for enemy_id_variant in enemy_ids:
		var enemy_id: String = String(enemy_id_variant).strip_edges()
		var state: Dictionary = Dictionary(state_by_id.get(enemy_id, {}))
		if state.is_empty():
			return false
		if not bool(state.get("visible", false)):
			return false
		if not bool(state.get("unit_body_visual_visible", false)):
			return false
		if not bool(state.get("unit_body_readability_core_visible", false)):
			return false
	return true


func _test_docs_capture_task() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	_assert(task_text.contains("TASK_459 - Fireteam Engage Orientation Enemy Proxy Fix"), "TASK_459 task file exists")
	_assert(status_text.contains("TASK_459 - Fireteam Engage Orientation Enemy Proxy Fix"), "Implementation status documents TASK_459")
	_assert(roadmap_text.contains("TASK_459 - Fireteam Engage Orientation Enemy Proxy Fix"), "Roadmap lists TASK_459")
	_assert(contract_text.contains("TASK_459 Engage-Orientation/Enemy-Proxies"), "Behavior contract documents TASK_459")


func _make_unit(unit_id: String, team_id: String, fireteam_id: String, position_value: Vector2):
	var unit = TEST_UNIT_SCRIPT.new()
	unit.name = unit_id
	unit.unit_id = unit_id
	unit.team_id = team_id
	unit.fireteam_id = fireteam_id
	unit.display_name = unit_id
	unit.global_position = position_value
	unit.weapon_1_id = "rifle"
	unit._ready()
	return unit


func _wait_frames(count: int) -> void:
	for _i in range(count):
		await process_frame


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	push_error("  FAIL: %s" % message)
