extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const FIRETEAM_ORDER_VISUALIZER_SCRIPT: GDScript = preload("res://scripts/tactical/visuals/fireteam_order_visualizer.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_371 Fire Sector Security Arc Overlay Toggle ===")
	await _test_visualizer_security_overlay_toggle_and_filter()
	await _test_mission_fire_sector_feedback_and_truth_boundary()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_visualizer_security_overlay_toggle_and_filter() -> void:
	var visualizer: Node = FIRETEAM_ORDER_VISUALIZER_SCRIPT.new()
	root.add_child(visualizer)
	await _wait_frames(2)
	visualizer.call("set_selected_fireteam_ids", PackedStringArray(["blue"]))
	visualizer.call("set_security_dicts", [
		_security("blue", "360", true, [
			{"unit_id": "blue_a", "center_angle": 0.0, "arc_width": TAU},
		]),
		_security("gold", "sector", true, [
			{"unit_id": "gold_a", "center_angle": 0.0, "arc_width": PI * 0.5},
			{"unit_id": "gold_b", "center_angle": PI * 0.5, "arc_width": PI * 0.5},
		], true),
	])
	var disabled: Dictionary = Dictionary(visualizer.call("get_security_overlay_snapshot"))
	_assert(not bool(disabled.get("enabled", true)), "Visualizer security overlay defaults off")
	_assert(int(disabled.get("visible_security_count", -1)) == 0, "Visualizer hides sectors while toggle is off")

	visualizer.call("set_security_overlay_enabled", true)
	await _wait_frames(2)
	var blue_only: Dictionary = Dictionary(visualizer.call("get_security_overlay_snapshot"))
	var blue_modes: Dictionary = Dictionary(blue_only.get("mode_counts", {}))
	_assert(bool(blue_only.get("enabled", false)), "Visualizer security overlay toggles on")
	_assert(int(blue_only.get("visible_security_count", 0)) == 1 and int(blue_only.get("hidden_by_selection_count", 0)) == 1, "Visualizer respects selected-fireteam filter")
	_assert(int(blue_modes.get("360", 0)) == 1, "Visualizer distinguishes 360 security")
	_assert(String(blue_only.get("contact_visibility_policy", "")).contains("contact"), "Visualizer snapshot documents contact/FoW highlight policy")

	visualizer.call("set_selected_fireteam_ids", PackedStringArray(["gold"]))
	await _wait_frames(2)
	var gold_only: Dictionary = Dictionary(visualizer.call("get_security_overlay_snapshot"))
	var gold_modes: Dictionary = Dictionary(gold_only.get("mode_counts", {}))
	_assert(int(gold_modes.get("sector", 0)) == 1, "Visualizer distinguishes facing/sector security")
	_assert(int(gold_modes.get("overwatch_ready", 0)) == 1, "Visualizer distinguishes overwatch-ready sectors")
	visualizer.queue_free()
	await _wait_frames(2)


func _test_mission_fire_sector_feedback_and_truth_boundary() -> void:
	root.size = Vector2i(1920, 1080)
	var scene = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(12)
	var controller: Node = scene.get_node_or_null("TacticalController")
	var primary_view: Node = scene.get_node_or_null("Primary3DView")
	var simulation_root: Node = scene.get_node_or_null("SimulationRoot")
	_assert(controller != null and primary_view != null and simulation_root != null, "Mission scene exposes controller, Primary3DView and SimulationRoot")
	if controller == null or primary_view == null or simulation_root == null:
		scene.queue_free()
		await _wait_frames(2)
		return
	var command_count_before: int = simulation_root.command_queue.size()
	var effect_count_before: int = simulation_root.effects_queue.size()
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	controller.call("set_fire_sector_overlay_enabled", false)
	await _wait_frames(4)
	var disabled_feedback: Dictionary = Dictionary(controller.call("get_fire_sector_overlay_snapshot"))
	var disabled_primary: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(not bool(disabled_feedback.get("enabled", true)), "Controller feedback reports fire-sector overlay off")
	_assert(not bool(disabled_primary.get("friendly_fire_sector_overlay_enabled", true)), "Primary render snapshot reports fire-sector overlay off")

	controller.call("set_fire_sector_overlay_enabled", true)
	await _wait_frames(6)
	var enabled_feedback: Dictionary = Dictionary(controller.call("get_fire_sector_overlay_snapshot"))
	var enabled_primary: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	var feedback_primary: Dictionary = Dictionary(enabled_feedback.get("primary_3d", {}))
	_assert(bool(enabled_feedback.get("enabled", false)), "Controller feedback reports fire-sector overlay on")
	_assert(bool(enabled_primary.get("friendly_fire_sector_overlay_enabled", false)), "Primary render snapshot reports fire-sector overlay on")
	_assert(int(enabled_primary.get("friendly_aim_visual_count", 0)) > 0, "Primary render snapshot counts fire-sector visuals")
	_assert(String(feedback_primary.get("visual_mode", "")) == "los_line_only", "Controller feedback mirrors primary fire-sector visual mode")
	_assert(simulation_root.command_queue.size() == command_count_before, "Fire-sector overlay toggle enqueues no SimulationRoot commands")
	_assert(simulation_root.effects_queue.size() == effect_count_before, "Fire-sector overlay toggle enqueues no SimulationRoot effects")
	scene.queue_free()
	await _wait_frames(2)


func _security(fireteam_id: String, mode: String, active: bool, assignments: Array, overwatch_ready: bool = false) -> Dictionary:
	return {
		"fireteam_id": fireteam_id,
		"is_active": active,
		"security_mode": mode,
		"anchor_position": Vector2(120.0, 160.0),
		"security_radius_world": 96.0,
		"member_assignments": assignments,
		"overwatch_ready": overwatch_ready,
		"overwatch_unit_ids": PackedStringArray(["gold_a"]) if overwatch_ready else PackedStringArray(),
	}


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
