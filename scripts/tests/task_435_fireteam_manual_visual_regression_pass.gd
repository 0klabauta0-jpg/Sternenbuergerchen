extends SceneTree

const DRILL_SCENE: PackedScene = preload("res://scenes/tests/fireteam_command_drill_map.tscn")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const FIRETEAM_BEHAVIOR_PROFILE_SCRIPT: GDScript = preload("res://scripts/command/fireteam_behavior_profile.gd")
const FIRETEAM_WAYPOINT_SCRIPT: GDScript = preload("res://scripts/command/fireteam_waypoint.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_435_fireteam_manual_visual_regression_pass.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const TERRAIN_VIEW_PATH: String = "res://scripts/terrain/terrain_map_3d_view.gd"
const CONTROLLER_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_435 Fireteam Manual Visual Regression Pass ===")
	await _test_drill_window_baseline_move_feedback_and_markers()
	await _test_muzzle_flash_remains_readable_in_visual_payload()
	await _test_engage_area_feedback_and_take_followup_are_distinct()
	_test_docs_capture_task()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_drill_window_baseline_move_feedback_and_markers() -> void:
	root.size = Vector2i(1920, 1080)
	var scene := DRILL_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(36)

	var setup := scene.get_node_or_null("MissionSetup")
	var controller := scene.get_node_or_null("TacticalController")
	var primary_view := scene.get_node_or_null("Primary3DView")
	_assert(setup != null and controller != null and primary_view != null, "Drill scene exposes setup, controller and primary 3D view")
	if setup == null or controller == null or primary_view == null:
		scene.queue_free()
		await _wait_frames(2)
		return
	if setup.has_method("set_fog_of_war_mode"):
		setup.call("set_fog_of_war_mode", "off")
	controller.call("_set_selected_fireteams", PackedStringArray(["drill"]), false)
	controller.call("_refresh_order_visuals")
	await _wait_frames(8)

	var presence: Dictionary = Dictionary(setup.call("get_expected_unit_presence_snapshot"))
	var friendly_ids: Array = Array(presence.get("friendly_unit_ids", []))
	var enemy_ids: Array = Array(presence.get("enemy_unit_ids", []))
	var initial_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	var visible_ids: Array = Array(initial_snapshot.get("visible_unit_proxy_ids", []))
	_assert(_contains_all(visible_ids, friendly_ids), "Window baseline shows all four friendly fireteam proxies")
	_assert(_contains_all(visible_ids, enemy_ids), "Window baseline shows all four enemy proxies")
	_assert(int(initial_snapshot.get("animated_unit_model_count", 0)) >= friendly_ids.size() + enemy_ids.size(), "Friendly and enemy proxies use animated 3D models")
	_assert(_enemy_bases_are_visible(Dictionary(initial_snapshot.get("unit_proxy_state_by_id", {})), enemy_ids), "Enemy proxies keep readable team bases")

	var units: Array = Array(controller.call("_get_fireteam_units", "drill", true))
	var leader = controller.call("_resolve_fireteam_leader_for_behavior", "drill")
	_assert(units.size() == 4 and leader is Node2D, "Drill fireteam exposes four runtime members and a leader")
	if units.size() != 4 or not (leader is Node2D):
		scene.queue_free()
		await _wait_frames(2)
		return

	controller.call("set_fireteams_tactical_stance", PackedStringArray(["drill"]), FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_CAUTIOUS)
	var target_position: Vector2 = (leader as Node2D).global_position + Vector2(260.0, -80.0)
	var profile = _make_profile("drill", FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_CAUTIOUS, target_position)
	controller.call("_set_active_behavior_profile", "drill", profile)
	var waypoint = FIRETEAM_WAYPOINT_SCRIPT.new()
	waypoint.waypoint_id = "task435_cautious_move"
	waypoint.command_type = FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_MOVE
	waypoint.status = FIRETEAM_WAYPOINT_SCRIPT.STATUS_ACTIVE
	waypoint.target_position = target_position
	var issued: bool = bool(controller.call("_issue_waypoint_for_fireteam", "drill", waypoint, 1, profile))
	controller.call("_refresh_order_visuals")
	await _wait_frames(10)

	var movement_state: Dictionary = Dictionary(controller.call("get_fireteam_movement_state", "drill"))
	_assert(issued and String(movement_state.get("effective_style", "")) == FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.ADVANCE_STYLE_RUSH, "C -> Move -> GO starts the baseline rush-group path")
	_assert(PackedStringArray(movement_state.get("current_moving_unit_ids", PackedStringArray())).size() == 4, "Cautious Move keeps all four members moving together")
	_assert(PackedStringArray(movement_state.get("current_covering_unit_ids", PackedStringArray())).is_empty(), "Cautious Move has no hidden covering subgroup")
	_assert(String(movement_state.get("tactical_stance", "")) == FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_CAUTIOUS, "Movement state carries C stance")
	_assert(_all_units_have_runtime_posture(units, "engage", "aimed", "move"), "Runtime posture for C Move is Aim/engage on every member")

	controller.call("_refresh_order_visuals")
	await _wait_frames(10)
	var move_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	var state_by_id: Dictionary = Dictionary(move_snapshot.get("unit_proxy_state_by_id", {}))
	_assert(_all_proxy_postures_match(state_by_id, _unit_ids(units), "engage", "aimed", "MOVE"), "3D proxies show Aim posture and MOVE badge instead of HOLD")
	_assert(_selected_markers_are_grounded(Array(move_snapshot.get("selected_unit_marker_entries", []))), "Selected fireteam markers stay on the ground plane")
	_assert(_legacy_selection_rings_are_hidden(Array(controller.call("_get_all_friendly_units", true))), "Legacy 2D selection rings stay hidden after selection refresh")

	var decision_snapshot: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	var decision_text: String = String(decision_snapshot.get("selected_decision_text", ""))
	_assert(decision_text.contains("MOVE") and decision_text.contains("C Aim"), "#17 decision text names Cautious Move concretely")
	var bubble_payload: Dictionary = Dictionary(controller.call("record_fireteamleader_feedback_bubble_for_unit", "go", "running", leader, "drill", "task435"))
	controller.call("_refresh_order_visuals")
	await _wait_frames(4)
	var bubble_snapshot: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	var bubbles: Array = Array(bubble_snapshot.get("fireteamleader_feedback_bubbles", []))
	var bubble_text: String = String(bubble_payload.get("text", ""))
	_assert(bubbles.size() == 1 and bubble_text.contains("MOVE") and bubble_text.contains("C Aim"), "FTL bubble is singular and carries the active Move order")

	var cautious_revision: int = int(movement_state.get("command_revision", 0))
	var aggressive_applied: bool = bool(controller.call("set_fireteams_tactical_stance", PackedStringArray(["drill"]), FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_AGGRESSIVE))
	await _wait_frames(6)
	var aggressive_state: Dictionary = Dictionary(controller.call("get_fireteam_movement_state", "drill"))
	_assert(aggressive_applied and int(aggressive_state.get("command_revision", 0)) > cautious_revision, "Live A update advances the active Move revision")
	_assert(_all_units_have_runtime_posture(units, "run", "lowered", "move"), "Live A update switches runtime posture to run/lowered")
	var normal_applied: bool = bool(controller.call("set_fireteams_tactical_stance", PackedStringArray(["drill"]), FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_NORMAL))
	await _wait_frames(6)
	_assert(normal_applied and _all_units_have_runtime_posture(units, "travel", "lowered", "move"), "Live N update returns runtime posture to walk/lowered")

	scene.queue_free()
	await _wait_frames(2)


func _test_muzzle_flash_remains_readable_in_visual_payload() -> void:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task435_muzzle", Vector2i(5, 5), Vector2.ZERO, 64.0, 32.0, 2)
	var primary_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(primary_view)
	primary_view.call("configure_from_map", map_data)
	primary_view.call(
		"set_order_visual_payload",
		{
			"phase_index": 1,
			"fire_event_dicts": [
				{
					"event_id": "task435_fire",
					"event_type": "weapon_fire",
					"attacker_unit_id": "task435_attacker",
					"target_unit_id": "task435_target",
					"weapon_id": "rifle",
					"attacker_position": Vector2(48.0, 96.0),
					"target_position": Vector2(232.0, 96.0),
				},
			],
		}
	)
	await _wait_frames(6)
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	var entries: Array = Array(snapshot.get("weapon_fire_vfx_entries", []))
	var entry: Dictionary = _find_entry(entries, "event_id", "task435_fire")
	_assert(int(snapshot.get("weapon_fire_vfx_visual_count", 0)) == 1, "Fire event creates one visible weapon-fire VFX")
	_assert(bool(entry.get("muzzle_flash_visible", false)), "Muzzle flash is visible")
	_assert(bool(entry.get("muzzle_bloom_visible", false)), "Muzzle bloom is visible")
	_assert(float(entry.get("muzzle_flash_pixel_size", 0.0)) >= 0.006 and float(entry.get("muzzle_flash_pixel_size", 0.0)) <= 0.014, "Muzzle flash stays in the small debug baseline")
	_assert(bool(entry.get("muzzle_texture_card_suppressed", false)) or bool(entry.get("muzzle_texture_missing", false)), "Large muzzle texture card is not rendered")
	primary_view.queue_free()
	await _wait_frames(2)


func _test_engage_area_feedback_and_take_followup_are_distinct() -> void:
	root.size = Vector2i(1920, 1080)
	var scene := DRILL_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(36)
	var controller := scene.get_node_or_null("TacticalController")
	_assert(controller != null, "Drill scene exposes controller for area feedback")
	if controller == null:
		scene.queue_free()
		await _wait_frames(2)
		return
	controller.call("_set_selected_fireteams", PackedStringArray(["drill"]), false)
	var units: Array = Array(controller.call("_get_fireteam_units", "drill", true))
	var leader = controller.call("_resolve_fireteam_leader_for_behavior", "drill")
	_assert(units.size() == 4 and leader is Node2D, "Area baseline has four members and a leader")
	if units.size() != 4 or not (leader is Node2D):
		scene.queue_free()
		await _wait_frames(2)
		return
	_assert(String(controller.call("_get_area_feedback_command_label", "engage")) == "ENGAGE", "Engage Area feedback label stays ENGAGE, not ATTACK")

	var base_position: Vector2 = (leader as Node2D).global_position + Vector2(160.0, -96.0)
	controller.call("create_area_order_for_fireteams_from_world_rect", PackedStringArray(["drill"]), base_position + Vector2(-32.0, -32.0), base_position + Vector2(32.0, 32.0), "engage")
	controller.call("create_area_order_for_fireteams_from_world_rect", PackedStringArray(["drill"]), base_position + Vector2(96.0, -32.0), base_position + Vector2(160.0, 32.0), "take")
	var started: bool = bool(controller.call("_activate_next_attack_area_order", "drill", 1))
	_assert(started, "First area order starts")
	var feedback_snapshot: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	_assert(String(feedback_snapshot.get("selected_decision_text", "")).contains("ENGAGE"), "#17 names the active Engage Area")
	var state: Dictionary = _get_area_attack_state(controller, "drill")
	_assert(String(state.get("command_type", "")) == "engage", "First active area order is Engage")
	_move_units_to_assignments(units, Array(state.get("assignments", [])))
	controller.call("_update_area_attack_execution", 0.016)
	await _wait_frames(2)
	state = _get_area_attack_state(controller, "drill")
	_assert(String(state.get("status", "")) == "engaged" and bool(state.get("waiting_for_go", false)), "Engage Area completes as fireline and waits for GO")
	_assert(not state.has("occupation_assignments"), "Engage Area does not create possession assignments")
	var continued: bool = bool(controller.call("_try_continue_active_area_attack", "drill"))
	await _wait_frames(2)
	state = _get_area_attack_state(controller, "drill")
	_assert(continued and String(state.get("command_type", "")) == "take", "GO after Engage starts the Take Area")
	_move_units_to_assignments(units, Array(state.get("assignments", [])))
	controller.call("_update_area_attack_execution", 0.016)
	await _wait_frames(2)
	state = _get_area_attack_state(controller, "drill")
	_assert(String(state.get("status", "")) == "occupying", "Take Area advances into occupation")
	_move_units_to_assignments(units, Array(state.get("assignments", [])))
	controller.call("_update_area_attack_execution", 0.016)
	await _wait_frames(2)
	state = _get_area_attack_state(controller, "drill")
	_assert(String(state.get("status", "")) == "secured" and bool(state.get("waiting_for_go", false)), "Take Area secures and waits for GO")
	scene.queue_free()
	await _wait_frames(2)


func _test_docs_capture_task() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var terrain_text: String = _read_text(TERRAIN_VIEW_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	_assert(task_text.contains("TASK_435 - Fireteam Manual Visual Regression Pass"), "TASK_435 task file exists")
	_assert(status_text.contains("TASK_435 - Fireteam Manual Visual Regression Pass"), "Implementation status documents TASK_435")
	_assert(roadmap_text.contains("TASK_435 - Fireteam Manual Visual Regression Pass"), "Roadmap lists TASK_435")
	_assert(terrain_text.contains("unit_status_badge_text"), "Terrain snapshot exposes visible unit status badges")
	_assert(controller_text.contains("AREA_ORDER_SCRIPT.COMMAND_TYPE_ENGAGE"), "Mission feedback labels Engage Area explicitly")


func _make_profile(fireteam_id: String, tactical_stance: String, target_position: Vector2):
	var profile = FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.new()
	profile.fireteam_id = fireteam_id
	profile.advance_style = FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.ADVANCE_STYLE_RUSH
	profile.tactical_stance = tactical_stance
	profile.cover_priority = 0.5
	profile.cohesion_threshold = 96.0
	profile.order_fidelity = 1.0
	profile.execution_cohesion = 0.65
	profile.initiative = 0.5
	profile.metadata = {
		"origin_command_type": "move",
		"rough_target_position": target_position,
	}
	return profile


func _unit_ids(units: Array) -> Array:
	var result: Array = []
	for unit in units:
		if unit != null and unit.has_method("get_unit_id"):
			var unit_id: String = String(unit.call("get_unit_id")).strip_edges()
			if not unit_id.is_empty():
				result.append(unit_id)
	return result


func _all_units_have_runtime_posture(units: Array, expected_movement_posture: String, expected_weapon_posture: String, expected_source_command: String) -> bool:
	for unit in units:
		if unit == null or not unit.has_method("get_runtime_status"):
			return false
		var runtime_status = unit.call("get_runtime_status")
		if runtime_status == null or not runtime_status.has_method("to_dict"):
			return false
		var runtime_dict: Dictionary = Dictionary(runtime_status.to_dict())
		if String(runtime_dict.get("movement_posture", "")) != expected_movement_posture:
			return false
		if String(runtime_dict.get("weapon_posture", "")) != expected_weapon_posture:
			return false
		if String(runtime_dict.get("source_command_type", "")) != expected_source_command:
			return false
	return true


func _all_proxy_postures_match(state_by_id: Dictionary, unit_ids: Array, expected_movement_posture: String, expected_weapon_posture: String, expected_badge: String) -> bool:
	if unit_ids.size() < 4:
		return false
	for unit_id_variant in unit_ids:
		var unit_id: String = String(unit_id_variant).strip_edges()
		var state: Dictionary = Dictionary(state_by_id.get(unit_id, {}))
		if state.is_empty():
			return false
		if String(state.get("unit_movement_posture", "")) != expected_movement_posture:
			return false
		if String(state.get("unit_weapon_posture", "")) != expected_weapon_posture:
			return false
		if expected_weapon_posture == "aimed" and not bool(state.get("unit_weapon_upper_body_pose_active", false)):
			return false
		if String(state.get("unit_status_badge_text", "")) != expected_badge:
			return false
	return true


func _enemy_bases_are_visible(state_by_id: Dictionary, enemy_ids: Array) -> bool:
	if enemy_ids.size() < 4:
		return false
	for enemy_id_variant in enemy_ids:
		var enemy_id: String = String(enemy_id_variant).strip_edges()
		var state: Dictionary = Dictionary(state_by_id.get(enemy_id, {}))
		if state.is_empty() or not bool(state.get("unit_team_base_visible", false)):
			return false
	return true


func _selected_markers_are_grounded(entries: Array) -> bool:
	if entries.size() < 4:
		return false
	for marker_variant in entries:
		if typeof(marker_variant) != TYPE_DICTIONARY:
			return false
		var marker: Dictionary = Dictionary(marker_variant)
		if float(marker.get("surface_offset", 999.0)) > 0.02:
			return false
	return true


func _legacy_selection_rings_are_hidden(units: Array) -> bool:
	for unit in units:
		if unit == null:
			continue
		var ring := (unit as Node).get_node_or_null("SelectionRing") as CanvasItem
		if ring != null and ring.visible:
			return false
	return true


func _move_units_to_assignments(units: Array, assignments: Array) -> void:
	var unit_by_id: Dictionary = {}
	for unit in units:
		if unit != null and unit.has_method("get_unit_id"):
			unit_by_id[String(unit.call("get_unit_id")).strip_edges()] = unit
	for assignment_variant in assignments:
		var assignment: Dictionary = Dictionary(assignment_variant)
		var unit_id: String = String(assignment.get("unit_id", "")).strip_edges()
		var unit = unit_by_id.get(unit_id, null)
		if unit is Node2D:
			(unit as Node2D).global_position = Vector2(assignment.get("target_position", (unit as Node2D).global_position))


func _get_area_attack_state(controller: Node, fireteam_id: String) -> Dictionary:
	if controller == null:
		return {}
	var states: Dictionary = Dictionary(controller.get("_area_attack_execution_by_fireteam"))
	return Dictionary(states.get(fireteam_id, {})).duplicate(true)


func _find_entry(entries: Array, key: String, expected_value: Variant) -> Dictionary:
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		if entry.get(key) == expected_value:
			return entry
	return {}


func _contains_all(values: Array, expected_values: Array) -> bool:
	if expected_values.size() < 4:
		return false
	for expected_variant in expected_values:
		if not values.has(expected_variant):
			return false
	return true


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""


func _wait_frames(count: int) -> void:
	for _index in range(maxi(count, 0)):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
