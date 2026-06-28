extends SceneTree

const META_LAYER_TEST_SCENE: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")
const UNIT_ROSTER_PRESETS_SCRIPT: GDScript = preload("res://scripts/npc/unit_roster_presets.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_540_mission_first_move_decision_readability_pass.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const CONTROLLER_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const DROPSHIP_TEXTURE_PATH := "res://Assets/kenney_space-kit/Isometric/craft_speederB_SE.png"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_540 Mission First Move Decision Readability Pass ===")
	_test_docs_and_wiring()
	await _test_first_move_decision_after_deboarding()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_540: FAILED")
		quit(1)
		return
	print("TASK_540: ALL PASSED")
	quit(0)


func _test_docs_and_wiring() -> void:
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_540 task file exists")
	_assert(_read_text(TASK_PATH).contains("Mission First Move Decision Readability Pass"), "TASK_540 task file names the task")
	_assert(_read_text(STATUS_PATH).contains("TASK_540 - Mission First Move Decision Readability Pass"), "Implementation status tracks TASK_540")
	_assert(_read_text(ROADMAP_PATH).contains("TASK_540 - Mission First Move Decision Readability Pass (implementiert)"), "Roadmap marks TASK_540 implemented")
	_assert(_read_text(REPORT_PATH).contains("TASK_540 - Mission First Move Decision Readability Pass"), "Review workbench tracks TASK_540")
	_assert(_read_text(CONTRACT_PATH).contains("get_mission_first_move_decision_readability_snapshot"), "Mission command feedback contract documents the first move snapshot")
	_assert(_read_text(CONTROLLER_PATH).contains("get_mission_first_move_decision_readability_snapshot"), "TacticalController exposes first move readability snapshot")


func _test_first_move_decision_after_deboarding() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = META_LAYER_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(5)
	scene.call("_on_homebase_mission_selection_changed", "frontier_probe_vertical_slice")
	await _wait_frames(2)

	var homebase_screen := scene.get_node("HomebaseScreen") as Control
	var roster: Array = UNIT_ROSTER_PRESETS_SCRIPT.call("get_homebase_roster")
	var selected_unit_ids := PackedStringArray(["unit_alpha", "unit_bravo"])
	var selected_fireteam_ids := PackedStringArray(["ft1", "ft1"])
	scene.set("_available_team_units", roster.duplicate(true))
	scene.set("_all_team_units", roster.duplicate(true))
	scene.set("_homebase_aircraft_definitions", [_build_dropship_definition("dropship_alpha", "Dropship Alpha")])
	scene.set("_assigned_aircraft_pilot_by_craft", {"dropship_alpha": "unit_delta"})
	scene.set("_aircraft_location_by_craft", {"dropship_alpha": "homebase"})
	homebase_screen.call("setup_roster", roster, selected_unit_ids)
	homebase_screen.call("set_fireteam_context", selected_fireteam_ids, [_build_fireteam_definition("ft1", "ALPHA", selected_unit_ids)])
	homebase_screen.call(
		"set_transport_state",
		[_build_dropship_definition("dropship_alpha", "Dropship Alpha")],
		{"dropship_alpha": "unit_delta"},
		[],
		[],
		{"dropship_alpha": "homebase"},
		{},
		{},
		[]
	)
	await _wait_frames(3)

	_drop_fireteam_on_shipcard(homebase_screen, "ft1", "dropship_alpha")
	await _finish_boarding(homebase_screen, "ft1")
	homebase_screen.call("request_mission_start", "dropship_alpha")
	await _wait_frames(8)
	_complete_mission_craft_arrival(scene, "dropship_alpha")
	scene.call("_show_mission")
	await _wait_frames(8)

	var active_mission: Node = scene.call("get_active_mission")
	var controller: Node = active_mission.get_node_or_null("TacticalController") if active_mission != null else null
	var primary_view: Node = active_mission.get_node_or_null("Primary3DView") if active_mission != null else null
	_assert(controller != null and primary_view != null, "Active Mission exposes TacticalController and Primary3DView")
	if controller == null or primary_view == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	var lz_world := Vector2(384.0, 224.0)
	controller.call("_on_mission_dropship_card_set_lz_pressed", "dropship_alpha")
	_assert(bool(controller.call("_place_lz_from_screen_position", primary_view.call("world_to_screen_position", lz_world))), "LZ placement succeeds before first move test")
	controller.call("_on_mission_dropship_card_drop_pressed", "dropship_alpha")
	await _wait_frames(4)
	controller.call("_complete_drop_sequence_deployment")
	controller.call("_advance_primary_drop_sequence_unloading", 999.0)
	controller.call("_flush_pending_drop_runtime_phase_starts")
	controller.call("_refresh_world_overlays")
	controller.call("_update_ui")
	await _wait_frames(10)

	var move_target := Vector2(544.0, 288.0)
	_assert(bool(controller.call("issue_right_click_command_for_test", move_target, "move", false)), "First move order can be planned through existing right-click command path")
	controller.call("_refresh_world_overlays")
	controller.call("_refresh_button_state")
	controller.call("_update_ui")
	await _wait_frames(8)

	var snapshot: Dictionary = Dictionary(controller.call("get_mission_first_move_decision_readability_snapshot"))
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "First move snapshot is read-only")
	_assert(String(snapshot.get("gate", "")) == "pass", "First move readability gate passes after planning")
	_assert(_check_passed(snapshot, "selected_fireteam_deployed"), "Selected Fireteam is deployed and active")
	_assert(_check_passed(snapshot, "move_control_visible"), "Move control remains visible")
	_assert(_check_passed(snapshot, "planned_waypoint_present"), "Planned waypoint exists before GO")
	_assert(_check_passed(snapshot, "waypoint_preview_visible"), "Waypoint intent preview exists")
	_assert(_check_passed(snapshot, "waypoint_visualized"), "Waypoint visualizer exposes the order")
	_assert(_check_passed(snapshot, "go_ready"), "GO is enabled for the first move")
	_assert(int(snapshot.get("deployed_selected_unit_ids", []).size()) == selected_unit_ids.size(), "Snapshot lists both deployed selected operators")

	scene.queue_free()
	await _wait_frames(2)


func _build_dropship_definition(craft_id: String, display_name: String) -> Dictionary:
	return {
		"craft_id": craft_id,
		"craft_type": "dropship",
		"display_name": display_name,
		"texture_path": DROPSHIP_TEXTURE_PATH,
		"supports_cargo": false,
		"cargo_options": [],
	}


func _build_fireteam_definition(fireteam_id: String, label: String, unit_ids: PackedStringArray) -> Dictionary:
	return {
		"id": fireteam_id,
		"label": label,
		"lead_unit_id": String(unit_ids[0]) if not unit_ids.is_empty() else "",
		"member_unit_ids": Array(unit_ids),
		"loadout": "medium",
		"respawn_enabled": false,
		"member_loadouts": {
			"unit_alpha": {
				"armor": "medium",
				"weapon_1": "rifle",
				"weapon_2": "rocket_launcher",
			},
			"unit_bravo": {
				"armor": "medium",
				"weapon_1": "sniper",
				"weapon_2": "medictool",
			},
		},
	}


func _finish_boarding(screen: Control, fireteam_id: String) -> void:
	var total_seconds: float = float(screen.call("_debug_get_homebase_fireteam_boarding_total_seconds", fireteam_id))
	screen.call("_debug_advance_homebase_direct_boarding", total_seconds + 0.2)
	await _wait_frames(3)


func _complete_mission_craft_arrival(scene: Node, craft_id: String) -> void:
	scene.call("_remove_pending_mission_craft_transfer", craft_id)
	scene.call("_complete_mission_craft_transfer", {"craft_id": craft_id, "phase": "to_mission"})
	scene.call("_sync_homebase_direct_mission_drop_transport_fields")
	scene.call("_start_or_update_active_mission")


func _drop_fireteam_on_shipcard(screen: Control, fireteam_id: String, craft_id: String) -> void:
	var target := _find_shipcard_drop_target(screen, craft_id)
	if target == null:
		return
	target.call("_drop_data", Vector2.ZERO, {"type": "fob_fireteam_card", "fireteam_id": fireteam_id, "source_context": "fireteam_list"})


func _find_shipcard_drop_target(screen: Control, craft_id: String) -> Control:
	for node in _collect_nodes(screen):
		var control := node as Control
		if control != null \
			and bool(control.get_meta("homebase_fireteam_drop_target", false)) \
			and bool(control.get_meta("homebase_fireteam_drop_enabled", false)) \
			and String(control.get_meta("homebase_fireteam_drop_target_id", "")).strip_edges() == craft_id:
			return control
	return null


func _collect_nodes(root_node: Node) -> Array:
	var result: Array = []
	if root_node == null:
		return result
	result.append(root_node)
	for child in root_node.get_children():
		result.append_array(_collect_nodes(child))
	return result


func _check_passed(snapshot: Dictionary, check_id: String) -> bool:
	for check_variant in Array(snapshot.get("checks", [])):
		var check: Dictionary = Dictionary(check_variant)
		if String(check.get("id", "")) == check_id:
			return bool(check.get("passed", false))
	return false


func _wait_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
