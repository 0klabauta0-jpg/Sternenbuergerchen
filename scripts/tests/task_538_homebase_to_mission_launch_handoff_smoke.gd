extends SceneTree

const META_LAYER_TEST_SCENE: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")
const UNIT_ROSTER_PRESETS_SCRIPT: GDScript = preload("res://scripts/npc/unit_roster_presets.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_538_homebase_to_mission_launch_handoff_smoke.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const META_LAYER_PATH: String = "res://scripts/meta/meta_layer_flow.gd"
const DROPSHIP_TEXTURE_PATH := "res://Assets/kenney_space-kit/Isometric/craft_speederB_SE.png"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_538 Homebase To Mission Launch Handoff Smoke ===")
	_test_docs_and_wiring()
	await _test_homebase_direct_launch_handoff_reaches_active_mission()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_538: FAILED")
		quit(1)
		return
	print("TASK_538: ALL PASSED")
	quit(0)


func _test_docs_and_wiring() -> void:
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_538 task file exists")
	_assert(_read_text(TASK_PATH).contains("## Status: IMPLEMENTIERT"), "TASK_538 task file marks implementation")
	_assert(_read_text(STATUS_PATH).contains("TASK_538 - Homebase To Mission Launch Handoff Smoke"), "Implementation status tracks TASK_538")
	_assert(_read_text(ROADMAP_PATH).contains("TASK_538 - Homebase To Mission Launch Handoff Smoke (implementiert)"), "Roadmap marks TASK_538 implemented")
	_assert(_read_text(REPORT_PATH).contains("TASK_538 - Homebase To Mission Launch Handoff Smoke"), "Review workbench tracks TASK_538")
	_assert(_read_text(META_LAYER_PATH).contains("get_homebase_to_mission_handoff_snapshot"), "MetaLayer exposes Handoff snapshot")


func _test_homebase_direct_launch_handoff_reaches_active_mission() -> void:
	var scene: Node = META_LAYER_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(5)
	scene.call("_on_homebase_mission_selection_changed", "frontier_probe_vertical_slice")
	await _wait_frames(2)

	var homebase_screen := scene.get_node("HomebaseScreen") as Control
	var roster: Array = UNIT_ROSTER_PRESETS_SCRIPT.call("get_homebase_roster")
	var selected_unit_ids := PackedStringArray(["unit_alpha", "unit_bravo"])
	var selected_fireteam_ids := PackedStringArray(["ft1", "ft1"])
	var fireteam_definitions: Array = [_build_fireteam_definition("ft1", "ALPHA", selected_unit_ids)]
	scene.set("_available_team_units", roster.duplicate(true))
	scene.set("_all_team_units", roster.duplicate(true))
	scene.set("_homebase_aircraft_definitions", [_build_dropship_definition("dropship_alpha", "Dropship Alpha")])
	scene.set("_assigned_aircraft_pilot_by_craft", {"dropship_alpha": "unit_delta"})
	scene.set("_aircraft_location_by_craft", {"dropship_alpha": "homebase"})
	homebase_screen.call("setup_roster", roster, selected_unit_ids)
	homebase_screen.call("set_fireteam_context", selected_fireteam_ids, fireteam_definitions)
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
	var readiness: Dictionary = Dictionary(homebase_screen.call("get_pre_mission_readiness_snapshot"))
	_assert(String(readiness.get("overall_state", "")) == "ready", "Homebase startflow is ready before launch")
	_assert(bool(homebase_screen.call("can_request_mission_start", "dropship_alpha")), "Homebase can request mission start for the boarded Dropship")

	homebase_screen.call("request_mission_start", "dropship_alpha")
	await _wait_frames(8)

	var active_mission: Node = scene.call("get_active_mission")
	var handoff: Dictionary = Dictionary(scene.call("get_homebase_to_mission_handoff_snapshot"))
	var planning: Dictionary = Dictionary(handoff.get("planning", {}))
	var mission_setup: Dictionary = Dictionary(handoff.get("mission_setup", {}))
	var tactical: Dictionary = Dictionary(handoff.get("tactical_controller", {}))
	_assert(active_mission != null, "Homebase launch creates an active mission")
	_assert(not bool(handoff.get("ui_sets_gameplay_truth", true)), "Handoff snapshot remains read-only")
	_assert(String(handoff.get("handoff_gate", "")) == "pass", "Handoff gate passes after Homebase launch")
	_assert(int(handoff.get("failed_count", -1)) == 0, "Handoff snapshot has no critical failures")
	_assert(String(handoff.get("selected_mission_id", "")) == "frontier_probe_vertical_slice", "Handoff preserves selected mission id")
	_assert(Array(handoff.get("selected_unit_ids", [])) == Array(selected_unit_ids), "Handoff selected units match Homebase Fireteam")
	_assert(Array(handoff.get("selected_fireteam_ids", [])) == Array(selected_fireteam_ids), "Handoff selected Fireteam IDs match Homebase Fireteam")
	_assert(String(planning.get("mission_drop_source", "")) == "homebase_direct", "Planning records Homebase-direct Dropship source")
	_assert(String(planning.get("mission_drop_craft_id", "")) == "dropship_alpha", "Planning records launched Dropship id")
	_assert(int(planning.get("mission_drop_passenger_count", 0)) == selected_unit_ids.size(), "Planning passenger count matches Fireteam operators")
	_assert(Array(planning.get("embarked_unit_ids", [])) == Array(selected_unit_ids), "Planning embarked unit ids match selected operators")
	_assert(bool(mission_setup.get("present", false)), "MissionSetup snapshot is present")
	_assert(Array(mission_setup.get("selected_team_unit_ids", [])) == Array(selected_unit_ids), "MissionSetup receives selected units")
	_assert(Array(mission_setup.get("selected_team_fireteam_ids", [])) == Array(selected_fireteam_ids), "MissionSetup receives Fireteam IDs")
	_assert(String(mission_setup.get("map_file_path", "")).ends_with("station_outpost_192x192.json"), "MissionSetup receives selected map")
	_assert(String(mission_setup.get("scenario_file_path", "")).ends_with("frontier_probe_vertical_slice.json"), "MissionSetup receives selected scenario")
	_assert(Dictionary(mission_setup.get("member_loadouts", {})).has("unit_alpha") and Dictionary(mission_setup.get("member_loadouts", {})).has("unit_bravo"), "MissionSetup receives member loadouts")
	_assert(bool(tactical.get("planning_state_present", false)), "TacticalController exposes planning state")
	_assert(String(tactical.get("mission_drop_craft_id", "")) == "dropship_alpha", "TacticalController receives Dropship planning reference")
	_assert(int(scene.get("_active_mission_started_at_msec")) > 0, "MetaLayer starts the mission timer")
	_assert(_check_passed(handoff, "member_loadouts_match"), "Handoff check confirms member loadouts")
	_assert(_check_passed(handoff, "unit_selection_matches"), "Handoff check confirms unit selection")
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


func _check_passed(handoff: Dictionary, check_id: String) -> bool:
	for check_variant in Array(handoff.get("checks", [])):
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
