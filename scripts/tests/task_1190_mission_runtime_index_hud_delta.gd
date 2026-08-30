extends SceneTree

const MISSION_RUNTIME_INDEX_SCRIPT: GDScript = preload("res://scripts/tactical/mission_runtime_index.gd")
const MISSION_HUD_READ_MODEL_SCRIPT: GDScript = preload("res://scripts/tactical/mission_hud_read_model.gd")
const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const CONTROLLER_SOURCE_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"

var _passed: int = 0
var _failed: int = 0


class IndexedTestUnit extends Node:
	var unit_id: String
	var team_id: String
	var fireteam_id: String
	var leadership_skill: float
	var is_fireteam_lead: bool

	func _init(next_unit_id: String, next_team_id: String, next_fireteam_id: String, next_leadership_skill: float = 0.0, next_is_fireteam_lead: bool = false) -> void:
		unit_id = next_unit_id
		team_id = next_team_id
		fireteam_id = next_fireteam_id
		leadership_skill = next_leadership_skill
		is_fireteam_lead = next_is_fireteam_lead

	func get_unit_id() -> String:
		return unit_id

	func get_team_id() -> String:
		return team_id

	func get_fireteam_id() -> String:
		return fireteam_id

	func get_leadership_skill() -> float:
		return leadership_skill


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1190 Mission Runtime Index HUD Delta ===")
	_test_contract_is_present()
	await _test_membership_index_reuses_sorted_lookup()
	_test_surface_revisions_are_narrow()
	await _test_direct_tile_feedback_is_immediate()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_contract_is_present() -> void:
	var controller_source: String = FileAccess.get_file_as_string(CONTROLLER_SOURCE_PATH)
	_assert(controller_source.contains("MISSION_RUNTIME_INDEX_SCRIPT"), "Controller loads the mission runtime index")
	_assert(controller_source.contains("MISSION_HUD_READ_MODEL_SCRIPT"), "Controller loads the HUD read model")
	_assert(controller_source.contains("_record_fireteam_security_revision"), "Security refresh records a revision instead of snapshot serialization")
	_assert(not _function_body(controller_source, "refresh_fireteam_security_state").contains("JSON.stringify"), "Security hotpath does not stringify whole snapshots")


func _test_membership_index_reuses_sorted_lookup() -> void:
	var mission_root := Node.new()
	root.add_child(mission_root)
	mission_root.add_child(IndexedTestUnit.new("unit_bravo", "team_alpha", "blue", 0.5))
	mission_root.add_child(IndexedTestUnit.new("unit_alpha", "team_alpha", "blue", 0.8, true))
	mission_root.add_child(IndexedTestUnit.new("enemy_delta", "team_bravo", "red"))
	var runtime_index: Node = MISSION_RUNTIME_INDEX_SCRIPT.new()
	mission_root.add_child(runtime_index)
	runtime_index.call("bind_mission_root", mission_root, "team_alpha")
	var first_units: Array = Array(runtime_index.call("get_friendly_units"))
	var initial_diagnostics: Dictionary = Dictionary(runtime_index.call("get_diagnostics_snapshot"))
	_assert(first_units.size() == 2 and String(first_units[0].call("get_unit_id")) == "unit_alpha", "Membership build sorts the friendly lookup once")
	for _index in range(24):
		runtime_index.call("get_friendly_units")
		runtime_index.call("get_fireteam_units", "blue")
		runtime_index.call("get_enemy_units")
	var stable_diagnostics: Dictionary = Dictionary(runtime_index.call("get_diagnostics_snapshot"))
	_assert(int(stable_diagnostics.get("membership_scan_count", 0)) == int(initial_diagnostics.get("membership_scan_count", 0)), "Unchanged lookups avoid a child scan and sort")
	mission_root.add_child(IndexedTestUnit.new("unit_charlie", "team_alpha", "gold"))
	await process_frame
	var changed_units: Array = Array(runtime_index.call("get_friendly_units"))
	var changed_diagnostics: Dictionary = Dictionary(runtime_index.call("get_diagnostics_snapshot"))
	_assert(changed_units.size() == 3 and int(changed_diagnostics.get("membership_revision", 0)) == int(initial_diagnostics.get("membership_revision", 0)) + 1, "A membership change rebuilds the index exactly once")
	_assert(Array(runtime_index.call("get_fireteam_units", "gold")).size() == 1, "Fireteam lookup reads the indexed membership")
	mission_root.queue_free()
	await process_frame


func _test_surface_revisions_are_narrow() -> void:
	var read_model: Node = MISSION_HUD_READ_MODEL_SCRIPT.new()
	read_model.call("set_light_state", "command_feedback", "AWAITING INPUT")
	var initial: Dictionary = Dictionary(read_model.call("get_diagnostics_snapshot"))
	read_model.call("set_light_state", "command_feedback", "MOVE ORDER")
	var feedback_changed: Dictionary = Dictionary(read_model.call("get_diagnostics_snapshot"))
	_assert(int(feedback_changed.get("light_revision", 0)) == int(initial.get("light_revision", 0)) + 1, "Command feedback only increments the light surface revision")
	_assert(int(feedback_changed.get("heavy_revision", 0)) == int(initial.get("heavy_revision", 0)), "Command feedback leaves the broad HUD revision stable")
	read_model.call("mark_fireteam_heavy_state_changed", "blue")
	var blue_changed: Dictionary = Dictionary(read_model.call("get_diagnostics_snapshot"))
	_assert(int(blue_changed.get("fireteam_heavy_revisions", {}).get("blue", 0)) == 1, "Blue receives its own heavy revision")
	_assert(not Dictionary(blue_changed.get("fireteam_heavy_revisions", {})).has("gold"), "Unchanged Gold receives no heavy revision")
	read_model.free()


func _test_direct_tile_feedback_is_immediate() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(12)
	var controller: Node = scene.get_node_or_null("TacticalController")
	var feedback_label := scene.get_node_or_null("TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamBodyRow/FireteamInfoScroll/FireteamInfoVBox/CommandFeedbackLabel") as Label
	_assert(controller != null and feedback_label != null, "Mission fixture exposes controller and command feedback label")
	if controller != null and feedback_label != null:
		var index_before: Dictionary = Dictionary(controller.call("get_mission_runtime_index_diagnostics"))
		for _index in range(12):
			controller.call("_get_all_friendly_units", true)
			controller.call("_get_fireteam_units", "blue", true)
		var index_after: Dictionary = Dictionary(controller.call("get_mission_runtime_index_diagnostics"))
		_assert(int(index_after.get("membership_scan_count", 0)) == int(index_before.get("membership_scan_count", 0)), "Wired controller reuses the unchanged mission membership index")
		var hud_before: Dictionary = Dictionary(controller.call("get_mission_hud_read_model_snapshot"))
		var updated: bool = bool(controller.call("_set_selected_tile_context", {"grid_position": Vector2i(3, 4), "world_position": Vector2(192.0, 128.0)}, "TILE SELECTED G3,4", false, true))
		_assert(updated and feedback_label.text.contains("TILE SELECTED G3,4"), "Direct tile feedback is visible in the same UI call")
		var hud_after: Dictionary = Dictionary(controller.call("get_mission_hud_read_model_snapshot"))
		_assert(int(hud_after.get("light_revision", 0)) > int(hud_before.get("light_revision", 0)), "Direct tile feedback advances only the wired light read revision")
	scene.queue_free()
	await _wait_frames(2)


func _wait_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame


func _function_body(source: String, function_name: String) -> String:
	var start: int = source.find("func %s(" % function_name)
	if start < 0:
		return ""
	var finish: int = source.find("\n\nfunc ", start + 5)
	return source.substr(start) if finish < 0 else source.substr(start, finish - start)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
