extends SceneTree

const EVENT_SCRIPT: GDScript = preload("res://scripts/tactical/tactical_communication_event.gd")
const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const META_LAYER_SCENE: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")

const TASK_PATH: String = "res://docs/tasks/TASK_279_lz_security_air_asset_tactical_playability_smoke.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/lz_security_air_asset_playability_smoke.md"
const FIXTURE_PATH: String = "res://maps/test_lz_air_asset_threat_fixture.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_279 LZ Security Air Asset Tactical Playability Smoke ===")
	_test_fixture_report_and_status()
	await _test_secure_lz_success_path()
	await _test_threat_loss_and_meta_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_fixture_report_and_status() -> void:
	_assert(FileAccess.file_exists(REPORT_PATH), "Playability smoke report exists")
	_assert(FileAccess.file_exists(FIXTURE_PATH), "LZ/AT fixture map exists")
	var fixture: Dictionary = _read_json(FIXTURE_PATH)
	_assert(Vector2i(Dictionary(fixture.get("grid_size", {})).get("x", 0), Dictionary(fixture.get("grid_size", {})).get("y", 0)) == Vector2i(32, 32), "Fixture is a compact 32x32 map")
	var markers: Dictionary = Dictionary(fixture.get("markers", {}))
	for marker_id in ["lz_secure", "lz_risky", "enemy_at_team", "objective_point"]:
		_assert(markers.has(marker_id), "Fixture defines marker %s" % marker_id)
	var report_text: String = _read_text(REPORT_PATH)
	for token in ["success path", "threat path", "loss path", "SimulationRoot", "MetaLayerFlow", "ui_sets_gameplay_truth = false", "softlock_guard"]:
		_assert(report_text.contains(token), "Report documents %s" % token)
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	_assert(task_text.contains("## Status: IMPLEMENTIERT"), "Task file marks TASK_279 implemented")
	_assert(not task_text.contains("- [ ]"), "Task checklist is complete")
	_assert(status_text.contains("### TASK_279 - LZ Security Air Asset Tactical Playability Smoke"), "Implementation status has TASK_279 section")
	_assert(roadmap_text.contains("TASK_279 - LZ Security Air Asset Tactical Playability Smoke (implementiert)"), "Roadmap marks TASK_279 implemented")


func _test_secure_lz_success_path() -> void:
	var scene := MISSION_TEST_SCENE.instantiate()
	_configure_two_fireteam_scene(scene)
	_stage_waiting_dropship(scene.get_node("TacticalController"), "task_279_success_drop", "TASK 279 Secure Drop")
	root.add_child(scene)
	await _wait_frames(16)
	await _wait_physics_frames(4)
	var controller: Node = scene.get_node("TacticalController")
	var primary_view: Node = scene.get_node("Primary3DView")
	var simulation_root: Node = scene.get_node("SimulationRoot")
	var objective_position: Vector2 = _get_objective_position(scene, Vector2(960.0, 960.0))
	_assert(controller != null and primary_view != null and simulation_root != null, "Mission exposes controller, primary view and SimulationRoot")
	controller.call("_set_selected_fireteams", PackedStringArray(["blue", "gold"]), false)
	_assert(_place_lz_via_player_path(controller, primary_view, objective_position), "Secure path places player LZ through 2.5D picking")
	var area_refs: Array = Array(controller.call("create_area_order_for_fireteams_from_world_rect", PackedStringArray(["blue", "gold"]), objective_position + Vector2(-88.0, -72.0), objective_position + Vector2(88.0, 64.0), "take"))
	controller.call("_refresh_order_visuals")
	await _wait_frames(8)
	controller.call("set_air_asset_lz_secure_level_for_test", 1.0)
	var warning: Dictionary = Dictionary(controller.call("apply_air_asset_threat", {
		"weapon_id": "rocket_launcher",
		"attacker_unit_id": "enemy_at_secure",
		"attacker_label": "Enemy AT team",
		"range_tiles": 8.0,
		"has_line_of_sight": true,
		"visible_in_fow": true,
		"altitude_layer": "low",
		"enemy_at_pressure": 0.35,
		"enemy_security_pressure": 0.1,
		"lz_secure_level": 1.0,
		"sequence": "task279_secure_warning",
	}))
	await _wait_physics_frames(4)
	var feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	var status: Dictionary = Dictionary(feedback.get("air_asset_status", {}))
	var map_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(area_refs.size() == 2, "Two Fireteams receive one coordinated LZ area order each")
	_assert(int(feedback.get("multi_fireteam_plan_count", 0)) >= 1, "Secure path keeps coordinated Fireteam plan visible")
	_assert(_has_communication_type(Array(feedback.get("tactical_communication_events", [])), EVENT_SCRIPT.EVENT_PLAN_ROLE_ASSIGNED), "Secure path communication explains Fireteam roles")
	_assert(bool(warning.get("warning_required", false)) and not bool(warning.get("hit_allowed", true)), "Secure LZ first contact warns without hit")
	_assert(int(status.get("integrity", 0)) == int(status.get("max_integrity", 100)), "Secure LZ leaves Air Asset undamaged")
	_assert(not bool(status.get("damage_state", true)) and not bool(status.get("terminal_state", true)), "Secure LZ status is not damaged or terminal")
	_assert(str(status.get("runtime_authority", "")) == "SimulationRoot" and not bool(status.get("ui_sets_gameplay_truth", true)), "Secure status keeps authority boundary")
	_assert(int(map_snapshot.get("multi_fireteam_plan_visual_count", 0)) >= 2, "Mission map visualizes two Fireteam LZ roles")
	_assert(_simulation_status_matches(simulation_root, "task_279_success_drop", status.get("state", "")), "SimulationRoot mirrors secure warning status")
	scene.queue_free()
	await _wait_frames(2)


func _test_threat_loss_and_meta_roundtrip() -> void:
	var scene := MISSION_TEST_SCENE.instantiate()
	_configure_two_fireteam_scene(scene)
	_stage_waiting_dropship(scene.get_node("TacticalController"), "task_279_loss_drop", "TASK 279 Loss Drop")
	root.add_child(scene)
	await _wait_frames(16)
	await _wait_physics_frames(4)
	var controller: Node = scene.get_node("TacticalController")
	var simulation_root: Node = scene.get_node("SimulationRoot")
	var objective_position: Vector2 = _get_objective_position(scene, Vector2(960.0, 960.0))
	controller.call("_set_selected_fireteams", PackedStringArray(["blue", "gold"]), false)
	controller.call("create_area_order_for_fireteams_from_world_rect", PackedStringArray(["blue", "gold"]), objective_position + Vector2(-96.0, -72.0), objective_position + Vector2(96.0, 64.0), "take")
	await _wait_frames(8)
	controller.call("set_air_asset_lz_secure_level_for_test", 0.0)
	var warning: Dictionary = Dictionary(controller.call("apply_air_asset_threat", {
		"weapon_id": "rocket_launcher",
		"attacker_unit_id": "enemy_at_loss",
		"attacker_label": "Enemy AT team",
		"range_tiles": 5.0,
		"has_line_of_sight": true,
		"visible_in_fow": true,
		"altitude_layer": "low",
		"enemy_at_pressure": 0.95,
		"enemy_security_pressure": 0.75,
		"lz_secure_level": 0.0,
		"sequence": "task279_loss_warning",
	}))
	await _wait_physics_frames(4)
	var warning_feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	var warning_status: Dictionary = Dictionary(warning.get("next_status", {}))
	_assert(bool(warning.get("warning_required", false)) and String(warning_status.get("last_reason", "")).contains("Enemy AT"), "Threat path gives visible warning and cause")
	_assert(_has_communication_type(Array(warning_feedback.get("tactical_communication_events", [])), EVENT_SCRIPT.EVENT_AIR_ASSET_THREATENED), "Threat warning emits air asset communication")
	_assert(_has_breakout_trigger(Array(warning_feedback.get("tactical_breakouts", [])), "air_asset_threatened"), "Threat warning records tactical breakout")

	var destroyed: Dictionary = Dictionary(controller.call("apply_air_asset_threat", {
		"weapon_id": "rocket_launcher",
		"attacker_unit_id": "enemy_at_loss",
		"attacker_label": "Enemy AT team",
		"range_tiles": 4.0,
		"has_line_of_sight": true,
		"visible_in_fow": true,
		"altitude_layer": "low",
		"warning_seen": true,
		"damage": 150,
		"enemy_at_pressure": 1.0,
		"enemy_security_pressure": 0.9,
		"lz_secure_level": 0.0,
		"sequence": "task279_loss_destroy",
	}))
	await _wait_physics_frames(4)
	var loss_feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	var loss_status: Dictionary = Dictionary(loss_feedback.get("air_asset_status", {}))
	_assert(bool(destroyed.get("destroy_allowed", false)), "Warned second AT strike can destroy Air Asset")
	_assert(_array_contains(Array(destroyed.get("vfx_events", [])), "air_asset_explosion"), "Loss path carries explosion VFX")
	_assert(_array_contains(Array(destroyed.get("sfx_events", [])), "air_asset_explosion"), "Loss path carries explosion SFX")
	_assert(str(loss_status.get("state", "")) == "crashed" and bool(loss_status.get("terminal_state", false)), "Mission status is terminal crashed")
	_assert(_has_communication_type(Array(loss_feedback.get("tactical_communication_events", [])), EVENT_SCRIPT.EVENT_AIR_ASSET_DESTROYED), "Loss path emits destroyed communication")
	_assert(_has_breakout_trigger(Array(loss_feedback.get("tactical_breakouts", [])), "air_asset_destroyed"), "Loss path records destroyed breakout")
	_assert(_simulation_status_matches(simulation_root, "task_279_loss_drop", "crashed"), "SimulationRoot stores crashed Air Asset")
	_assert(str(loss_status.get("runtime_authority", "")) == "SimulationRoot" and not bool(loss_status.get("ui_sets_gameplay_truth", true)), "Loss status keeps snapshot boundary clean")

	var mission_result: Dictionary = {
		"result": "defeat",
		"mission_outcome": "ended",
		"win_condition_type": "air_asset_lost",
		"objective_captured": false,
		"duration_seconds": 64.0,
		"air_asset_status": loss_status,
	}
	scene.queue_free()
	await _wait_frames(2)
	await _assert_meta_roundtrip(mission_result)


func _assert_meta_roundtrip(mission_result: Dictionary) -> void:
	var scene := META_LAYER_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(5)
	scene.set("_homebase_aircraft_definitions", [_craft_definition()])
	scene.set("_assigned_aircraft_pilot_by_craft", {"task_279_loss_drop": "unit_hotel"})
	scene.set("_aircraft_location_by_craft", {"task_279_loss_drop": "mission"})
	scene.set("_mission_planning_state", {
		"launch_ready_craft_id": "task_279_loss_drop",
		"mission_drop_craft_id": "task_279_loss_drop",
		"mission_drop_display_name": "TASK 279 Loss Drop",
		"mission_drop_pilot_unit_id": "unit_hotel",
		"mission_drop_state": "waiting",
		"drop_ship_staged": true,
	})
	var result: Dictionary = Dictionary(scene.call("apply_air_asset_recovery_from_mission_result_for_test", mission_result))
	var recovery: Dictionary = Dictionary(result.get("air_asset_recovery", {}))
	_assert(str(recovery.get("meta_state", "")) == "destroyed_replacement_pending", "Meta roundtrip creates replacement recovery state")
	_assert(bool(result.get("softlock_guard", false)) and bool(recovery.get("can_recover", false)), "Meta roundtrip carries softlock guard and can recover")
	_assert(str(recovery.get("runtime_authority", "")) == "MetaLayerFlow" and not bool(recovery.get("ui_sets_gameplay_truth", true)), "Recovery snapshot keeps MetaLayerFlow authority")
	var debrief: Node = scene.get_node("DebriefScreen")
	debrief.call("set_mission_result", result)
	await _wait_frames(2)
	var labels: PackedStringArray = _collect_label_texts(debrief)
	_assert(_labels_contain(labels, "Air asset:") and _labels_contain(labels, "replacement ETA"), "Debrief explains air asset loss and ETA")
	var homebase: Node = scene.get_node("HomebaseScreen")
	var fob: Node = scene.get_node("FOBScreen")
	var home_snapshot: Dictionary = Dictionary(homebase.call("get_aircraft_panel_snapshot"))
	var fob_snapshot: Dictionary = Dictionary(fob.call("get_flightdeck_snapshot"))
	_assert(not bool(home_snapshot.get("can_send_selected", true)), "Homebase blocks sending lost/replacement craft")
	_assert(not bool(fob_snapshot.get("can_board", true)) and not bool(fob_snapshot.get("can_start_mission", true)), "FOB blocks boarding/start for lost craft")
	scene.call("advance_air_asset_recovery_time", 999.0)
	var completed: Dictionary = Dictionary(Dictionary(scene.call("get_air_asset_recovery_snapshot")).get("task_279_loss_drop", {}))
	_assert(str(completed.get("meta_state", "")) == "craft_available" and not bool(completed.get("softlock_guard", true)), "Recovery timer clears softlock after replacement")
	scene.queue_free()
	await _wait_frames(2)


func _configure_two_fireteam_scene(scene: Node) -> void:
	root.size = Vector2i(1920, 1080)
	var mission_setup := scene.get_node_or_null("MissionSetup")
	if mission_setup != null:
		mission_setup.set("defer_friendly_runtime_activation", true)
		mission_setup.set("allow_full_roster_when_selection_empty", false)
		mission_setup.set("selected_team_unit_ids", PackedStringArray(["unit_alpha", "unit_bravo", "unit_charlie", "unit_delta", "unit_echo", "unit_foxtrot", "unit_golf", "unit_hotel"]))
		mission_setup.set("selected_team_fireteam_ids", PackedStringArray(["blue", "blue", "blue", "blue", "gold", "gold", "gold", "gold"]))
		mission_setup.set("selected_fireteam_definitions", [
			{"id": "blue", "label": "BLUE", "lead_unit_id": "unit_alpha", "respawn_enabled": false, "loadout": "medium"},
			{"id": "gold", "label": "GOLD", "lead_unit_id": "unit_echo", "respawn_enabled": false, "loadout": "heavy"},
		])
	var combat_driver := scene.get_node_or_null("CombatLoopDriver")
	if combat_driver != null:
		combat_driver.set("enemy_advance_enabled", false)
		combat_driver.set("enemy_reposition_enabled", false)
		combat_driver.set("base_hit_chance", 0.0)
		combat_driver.set("damage_per_hit", 0)


func _stage_waiting_dropship(controller: Node, craft_id: String, display_name: String) -> void:
	var planning_state: Dictionary = Dictionary(controller.call("get_planning_state"))
	planning_state["mission_drop_state"] = "waiting"
	planning_state["mission_drop_craft_id"] = craft_id
	planning_state["mission_drop_display_name"] = display_name
	planning_state["mission_drop_title_text"] = display_name
	planning_state["mission_drop_texture_path"] = "res://Assets/kenney_space-kit/Side/craft_speederB.png"
	planning_state["mission_drop_status_line"] = "Holding over LZ"
	planning_state["mission_drop_progress"] = 100.0
	planning_state["mission_drop_passenger_count"] = 8
	planning_state["mission_drop_pilot_unit_id"] = "unit_hotel"
	planning_state["selected_fireteam"] = "BLUE/GOLD"
	planning_state["selected_fireteams"] = ["blue", "gold"]
	planning_state["embarked_unit_ids"] = ["unit_alpha", "unit_bravo", "unit_charlie", "unit_delta", "unit_echo", "unit_foxtrot", "unit_golf", "unit_hotel"]
	planning_state["deployed_unit_ids"] = []
	planning_state["drop_ship_requested"] = false
	planning_state["drop_ship_staged"] = false
	planning_state["has_lz_position"] = false
	planning_state["air_asset_status"] = {
		"asset_id": craft_id,
		"asset_type": "dropship",
		"display_name": display_name,
		"state": "intact",
		"integrity": 100,
		"max_integrity": 100,
		"pilot_unit_id": "unit_hotel",
	}
	controller.call("set_planning_state", planning_state)


func _place_lz_via_player_path(controller: Node, primary_view: Node, world_position: Vector2) -> bool:
	controller.call("_on_set_lz_pressed")
	var screen_position: Vector2 = primary_view.call("world_to_screen_position", world_position) if primary_view != null and primary_view.has_method("world_to_screen_position") else controller.get_viewport().get_canvas_transform() * world_position
	return bool(controller.call("_place_lz_from_screen_position", screen_position))


func _get_objective_position(scene: Node, fallback: Vector2) -> Vector2:
	var simulation_root := scene.get_node_or_null("SimulationRoot")
	if simulation_root != null and simulation_root.has_method("get_objective_status"):
		var objective_status = simulation_root.call("get_objective_status")
		if objective_status != null and typeof(objective_status.get("position")) == TYPE_VECTOR2:
			return Vector2(objective_status.get("position"))
	var marker := scene.get_node_or_null("ObjectivePoint") as Node2D
	if marker != null:
		return marker.global_position
	return fallback


func _simulation_status_matches(simulation_root: Node, asset_id: String, expected_state) -> bool:
	if simulation_root == null or not simulation_root.has_method("get_air_asset_status_snapshot"):
		return false
	var status: Dictionary = Dictionary(simulation_root.call("get_air_asset_status_snapshot", asset_id))
	return str(status.get("state", "")) == str(expected_state) and str(status.get("runtime_authority", "")) == "SimulationRoot" and not bool(status.get("ui_sets_gameplay_truth", true))


func _has_communication_type(events: Array, event_type: String) -> bool:
	for event_variant in events:
		if typeof(event_variant) != TYPE_DICTIONARY:
			continue
		if String(Dictionary(event_variant).get("event_type", "")) == event_type:
			return true
	return false


func _has_breakout_trigger(records: Array, trigger: String) -> bool:
	for record_variant in records:
		if typeof(record_variant) != TYPE_DICTIONARY:
			continue
		if String(Dictionary(record_variant).get("trigger", "")) == trigger:
			return true
	return false


func _array_contains(entries: Array, needle: String) -> bool:
	for entry_variant in entries:
		if typeof(entry_variant) == TYPE_DICTIONARY:
			if String(Dictionary(entry_variant).get("event_type", "")).contains(needle):
				return true
		elif String(entry_variant).contains(needle):
			return true
	return false


func _craft_definition() -> Dictionary:
	return {
		"craft_id": "task_279_loss_drop",
		"craft_type": "dropship",
		"display_name": "TASK 279 Loss Drop",
		"summary": "Task 279 air asset smoke craft",
		"texture_path": "res://Assets/kenney_space-kit/Isometric/craft_speederB_SE.png",
		"supports_cargo": false,
		"cargo_options": [],
	}


func _collect_label_texts(node: Node) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	if node == null:
		return result
	if node is Label:
		result.append((node as Label).text)
	for child in node.get_children():
		result.append_array(_collect_label_texts(child))
	return result


func _labels_contain(labels: PackedStringArray, needle: String) -> bool:
	var normalized_needle: String = needle.to_lower()
	for label in labels:
		if String(label).to_lower().contains(normalized_needle):
			return true
	return false


func _read_json(path: String) -> Dictionary:
	var text: String = _read_text(path)
	if text.is_empty():
		return {}
	var parsed = JSON.parse_string(text)
	return Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


func _wait_frames(count: int) -> void:
	for _index in range(maxi(count, 0)):
		await process_frame


func _wait_physics_frames(count: int) -> void:
	for _index in range(maxi(count, 0)):
		await physics_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
