extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const COMMAND_HIERARCHY_CONTRACT: GDScript = preload("res://scripts/ui/mission_command_hierarchy_contract.gd")
const TACTICAL_INPUT_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_315_mission_grid_tile_selection_command_gate.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_315 Mission Grid Tile Selection Command Gate ===")
	await _test_live_grid_and_default_tile_selection()
	await _test_tile_required_command_gate()
	_test_meta_bootstrap_clamp_without_viewport()
	_test_contract_and_docs()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_live_grid_and_default_tile_selection() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(24)

	var controller := scene.get_node_or_null("TacticalController")
	var primary_view := scene.get_node_or_null("Primary3DView")
	_assert(controller != null and primary_view != null, "Mission exposes TacticalController and Primary3DView")
	if controller == null or primary_view == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	var visual: Dictionary = Dictionary(snapshot.get("editor_visual_recovery", {}))
	_assert(int(snapshot.get("tile_grid_line_count", 0)) > 0, "Primary mission view renders terrain grid lines")
	_assert(float(visual.get("grid_line_width_factor", 0.0)) >= 0.04, "Grid line highlight is thick enough for mission readability")
	_assert(float(visual.get("grid_line_surface_y_offset", 1.0)) <= 0.06, "Grid line stays close to tile surface")
	_assert(bool(visual.get("grid_depth_tested", false)), "Grid remains depth-tested")
	_assert(String(visual.get("grid_line_color", "")).to_lower() != "ffe033e0", "Grid no longer uses the old low-contrast amber color")

	var selected_tile: Dictionary = Dictionary(controller.call("get_selected_tile_snapshot"))
	_assert(bool(selected_tile.get("has_selected_tile", false)), "Mission starts with an explicit selected tile")
	_assert(int(snapshot.get("selected_grid_count", 0)) == 1, "Selected tile is visible in the 3D grid")
	_assert(Array(snapshot.get("selected_grid_positions", [])).size() == 1, "Render snapshot exposes selected grid position")

	scene.queue_free()
	await _wait_frames(2)


func _test_tile_required_command_gate() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(24)

	var controller := scene.get_node_or_null("TacticalController")
	var primary_view := scene.get_node_or_null("Primary3DView")
	_assert(controller != null and primary_view != null, "Mission command gate scene exposes controller and 3D view")
	if controller == null or primary_view == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	var fireteam_id: String = _get_alpha_driver_fireteam_id(scene, controller)
	_assert(not fireteam_id.is_empty(), "Verifier resolves a fireteam with an active flow driver")
	var planning_state: Dictionary = Dictionary(controller.call("get_planning_state"))
	planning_state["selected_fireteams"] = [fireteam_id]
	planning_state["embarked_unit_ids"] = []
	planning_state["deployed_unit_ids"] = _get_all_friendly_unit_ids(controller)
	planning_state["has_selected_tile"] = false
	controller.call("set_planning_state", planning_state)
	controller.call("_set_selected_fireteams", PackedStringArray([fireteam_id]), false)
	await _wait_frames(5)

	var feedback_without_tile: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	var move_button_without_tile: Dictionary = Dictionary(Dictionary(feedback_without_tile.get("command_buttons", {})).get("move", {}))
	var move_action_without_tile: Dictionary = Dictionary(Dictionary(Dictionary(feedback_without_tile.get("command_hierarchy", {})).get("actions_by_id", {})).get("move", {}))
	_assert(bool(move_button_without_tile.get("disabled", false)), "Move button is disabled when no tile is selected")
	_assert(String(move_action_without_tile.get("disabled_reason", "")).contains("map tile"), "Move hierarchy explains the missing tile")
	_assert(not bool(controller.call("issue_move")), "Move command is blocked before a tile is selected")
	_assert(String(Dictionary(controller.call("get_command_feedback_snapshot")).get("last_command_text", "")).contains("SELECT TILE"), "Blocked command asks for tile selection")

	var objective_position: Vector2 = _get_objective_position(scene)
	var selected_tile: Dictionary = Dictionary(controller.call("select_tile_from_world_position_for_test", objective_position))
	await _wait_frames(5)
	_assert(bool(selected_tile.get("has_selected_tile", false)), "World-position helper selects an actual map tile")
	var selected_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(int(selected_snapshot.get("selected_grid_count", 0)) == 1, "3D selection marker appears after tile selection")

	var feedback_with_tile: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	var move_button_with_tile: Dictionary = Dictionary(Dictionary(feedback_with_tile.get("command_buttons", {})).get("move", {}))
	var move_action_with_tile: Dictionary = Dictionary(Dictionary(Dictionary(feedback_with_tile.get("command_hierarchy", {})).get("actions_by_id", {})).get("move", {}))
	_assert(not bool(move_button_with_tile.get("disabled", true)), "Move button is enabled after fireteam and tile selection")
	_assert(String(move_action_with_tile.get("disabled_reason", "")).is_empty(), "Move hierarchy clears the tile disabled reason")
	_assert(bool(controller.call("issue_move")), "Move command accepts once a tile is selected")
	var target_marker := scene.get_node_or_null("TargetMarker") as Node2D
	_assert(target_marker != null and target_marker.global_position.distance_to(Vector2(selected_tile.get("world_position", Vector2.ZERO))) <= 0.5, "Accepted command uses the selected tile as target")

	scene.queue_free()
	await _wait_frames(2)


func _test_contract_and_docs() -> void:
	var catalog: Array = Array(COMMAND_HIERARCHY_CONTRACT.call("get_action_catalog"))
	for action_id in ["move", "take", "defend", "flank"]:
		_assert(_catalog_action_requires_tile(catalog, action_id), "%s action requires a selected map tile" % action_id)
	var snapshot: Dictionary = Dictionary(COMMAND_HIERARCHY_CONTRACT.call("build_hierarchy_snapshot", {
		"selected_fireteam_count": 1,
		"single_fireteam_context": true,
		"can_issue_local_commands": true,
		"requires_tile_selection": true,
		"has_selected_tile": false,
	}, {}))
	var move_action: Dictionary = Dictionary(Dictionary(snapshot.get("actions_by_id", {})).get("move", {}))
	_assert(String(move_action.get("disabled_reason", "")).contains("map tile"), "Contract disables Move without a selected tile")
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_315 task file exists")
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	_assert(task_text.contains("## Status: IMPLEMENTIERT"), "TASK_315 is marked implemented")
	_assert(status_text.contains("TASK_315") and status_text.to_lower().contains("implementiert"), "Implementation status mentions TASK_315")
	_assert(roadmap_text.contains("TASK_315") and roadmap_text.to_lower().contains("implementiert"), "Roadmap mentions TASK_315")


func _test_meta_bootstrap_clamp_without_viewport() -> void:
	var controller: Node = TACTICAL_INPUT_CONTROLLER_SCRIPT.new()
	var target_position := Vector2(448.0, 285.0)
	var clamped_position: Vector2 = Vector2(controller.call("_clamp_world_position_to_viewport", target_position))
	_assert(clamped_position == target_position, "Tile selection clamp tolerates meta bootstrap before viewport attachment")
	controller.free()


func _catalog_action_requires_tile(catalog: Array, action_id: String) -> bool:
	for action_variant in catalog:
		var action: Dictionary = Dictionary(action_variant)
		if String(action.get("action_id", "")) != action_id:
			continue
		return bool(action.get("requires_tile_selection", false))
	return false


func _get_alpha_driver_fireteam_id(scene: Node, controller: Node) -> String:
	var alpha_driver := scene.get_node_or_null("AlphaFlowDriver")
	if alpha_driver != null:
		var fireteam_id: String = String(controller.call("_get_fireteam_id_for_flow_driver", alpha_driver)).strip_edges().to_lower()
		if not fireteam_id.is_empty():
			return fireteam_id
	var fireteams: PackedStringArray = PackedStringArray(controller.call("_get_available_fireteam_ids"))
	return String(fireteams[0]).strip_edges().to_lower() if fireteams.size() > 0 else ""


func _get_all_friendly_unit_ids(controller: Node) -> Array:
	var result: Array = []
	for unit in Array(controller.call("_get_all_friendly_units", true)):
		if unit != null and unit.has_method("get_unit_id"):
			result.append(String(unit.call("get_unit_id")).strip_edges())
	return result


func _get_objective_position(scene: Node) -> Vector2:
	var objective := scene.get_node_or_null("MapRoot/objective_point") as Node2D
	return objective.global_position if objective != null else Vector2(448.0, 285.0)


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


func _wait_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
