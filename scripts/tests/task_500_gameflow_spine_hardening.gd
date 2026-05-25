extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_500 Gameflow Spine Hardening ===")
	await _test_outbound_lz_remains_a_terrain_marker()
	_test_frontier_probe_uses_tracked_map()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_500: FAILED")
		quit(1)
	else:
		print("TASK_500: ALL PASSED")
		quit(0)


func _test_outbound_lz_remains_a_terrain_marker() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(10)
	var controller := scene.get_node_or_null("TacticalController")
	var primary_view := scene.get_node_or_null("Primary3DView")
	_assert(controller != null and primary_view != null, "Mission scene exposes tactical controller and Primary3DView")
	if controller == null or primary_view == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	var alpha_label: String = String(controller.call("_build_mission_dropship_lz_name", "dropship_alpha", "Dropship Alpha", 1))
	var beta_label: String = String(controller.call("_build_mission_dropship_lz_name", "dropship_beta", "Dropship Beta", 2))
	_assert(alpha_label == "LZ1 Dropship Alpha" and beta_label == "LZ2 Dropship Beta", "Mission Dropship labels keep numbered craft ownership")

	var planning_state: Dictionary = Dictionary(controller.call("get_planning_state"))
	planning_state["mission_drop_craft_id"] = "dropship_alpha"
	planning_state["mission_drop_display_name"] = "Dropship Alpha"
	planning_state["mission_drop_state"] = "outbound"
	planning_state["has_lz_position"] = true
	planning_state["lz_position"] = Vector2(448.0, 256.0)
	planning_state["mission_drop_cards"] = [
		{
			"craft_id": "dropship_alpha",
			"display_name": "Dropship Alpha",
			"state": "outbound",
			"progress": 55.0,
			"has_lz_position": true,
			"lz_position": Vector2(448.0, 256.0),
			"approach_angle": "NW",
		}
	]
	controller.call("set_planning_state", planning_state)
	await _wait_frames(4)
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(bool(snapshot.get("has_lz", false)), "Primary view keeps LZ state during outbound")
	_assert(int(snapshot.get("lz_tile_marker_count", 0)) == 1, "Outbound LZ remains visible as a terrain field marker")

	scene.queue_free()
	await _wait_frames(2)


func _test_frontier_probe_uses_tracked_map() -> void:
	var source_text: String = FileAccess.get_file_as_string("res://scripts/meta/meta_layer_flow.gd")
	_assert(source_text.find('"mission_id": "frontier_probe"') >= 0, "Homebase catalog still contains frontier_probe")
	_assert(source_text.find('"map_file_path": "res://maps/station_outpost_192x192.json"') >= 0, "frontier_probe uses the tracked expanded station outpost map")
	_assert(FileAccess.file_exists("res://maps/station_outpost_192x192.json"), "Tracked expanded frontier_probe map exists in the project")


func _wait_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
