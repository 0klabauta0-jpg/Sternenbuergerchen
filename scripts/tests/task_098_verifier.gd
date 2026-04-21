extends SceneTree

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_098 Tactical Input Verifier ===")
	await _test_unit_click_selects_fireteam()
	await _test_ctrl_click_adds_second_fireteam()
	await _test_empty_click_clears_selection()
	await _test_lasso_selects_leaders_only()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_unit_click_selects_fireteam() -> void:
	var scene = await _load_scene()
	var controller = scene.get_node("TacticalController")
	var blue_lead = _get_selection_anchor(controller, "blue")
	_assert(blue_lead != null, "Blue fireteam exposes a selection anchor")
	if blue_lead == null:
		scene.queue_free()
		await process_frame
		return
	controller.call("_begin_selection_interaction", _to_screen(scene, blue_lead.global_position), false)
	controller.call("_finish_selection_interaction", _to_screen(scene, blue_lead.global_position))
	var selection: PackedStringArray = controller.call("get_selected_fireteam_ids")
	_assert(selection.size() == 1 and selection.has("blue"), "LMB on a unit selects its fireteam")
	_assert(bool(blue_lead.call("is_tactical_selected")), "Lead unit becomes visually selected")
	scene.queue_free()
	await process_frame


func _test_ctrl_click_adds_second_fireteam() -> void:
	var scene = await _load_scene()
	var controller = scene.get_node("TacticalController")
	var blue_lead = _get_selection_anchor(controller, "blue")
	var gold_lead = _get_selection_anchor(controller, "gold")
	_assert(blue_lead != null and gold_lead != null, "Blue and gold fireteams expose selection anchors")
	if blue_lead == null or gold_lead == null:
		scene.queue_free()
		await process_frame
		return
	controller.call("_begin_selection_interaction", _to_screen(scene, blue_lead.global_position), false)
	controller.call("_finish_selection_interaction", _to_screen(scene, blue_lead.global_position))
	controller.call("_begin_selection_interaction", _to_screen(scene, gold_lead.global_position), true)
	controller.call("_finish_selection_interaction", _to_screen(scene, gold_lead.global_position))
	var selection: PackedStringArray = controller.call("get_selected_fireteam_ids")
	_assert(selection.size() == 2 and selection.has("blue") and selection.has("gold"), "CTRL+LMB adds another fireteam to the selection")
	scene.queue_free()
	await process_frame


func _test_empty_click_clears_selection() -> void:
	var scene = await _load_scene()
	var controller = scene.get_node("TacticalController")
	var blue_lead = _get_selection_anchor(controller, "blue")
	_assert(blue_lead != null, "Blue fireteam anchor exists before clear-selection test")
	if blue_lead == null:
		scene.queue_free()
		await process_frame
		return
	controller.call("_begin_selection_interaction", _to_screen(scene, blue_lead.global_position), false)
	controller.call("_finish_selection_interaction", _to_screen(scene, blue_lead.global_position))
	controller.call("_begin_selection_interaction", Vector2(12.0, 12.0), false)
	controller.call("_finish_selection_interaction", Vector2(12.0, 12.0))
	var selection: PackedStringArray = controller.call("get_selected_fireteam_ids")
	_assert(selection.is_empty(), "LMB on empty terrain clears selection when no drag happened")
	scene.queue_free()
	await process_frame


func _test_lasso_selects_leaders_only() -> void:
	var scene = await _load_scene()
	var controller = scene.get_node("TacticalController")
	var blue_lead = _get_selection_anchor(controller, "blue")
	var gold_lead = _get_selection_anchor(controller, "gold")
	_assert(blue_lead != null, "Blue fireteam anchor exists for lasso selection")
	_assert(gold_lead != null, "Gold fireteam anchor exists for lasso selection")
	if blue_lead == null or gold_lead == null:
		scene.queue_free()
		await process_frame
		return
	var blue_screen: Vector2 = _to_screen(scene, blue_lead.global_position)
	var gold_screen: Vector2 = _to_screen(scene, gold_lead.global_position)
	var delta: Vector2 = gold_screen - blue_screen
	var horizontal_padding: float = 18.0
	var vertical_padding: float = 28.0
	var finish_x: float = blue_screen.x + horizontal_padding
	if absf(delta.x) > horizontal_padding * 2.0:
		finish_x = blue_screen.x + signf(delta.x) * ((absf(delta.x) * 0.45) - horizontal_padding)
	var finish := Vector2(finish_x, blue_screen.y + vertical_padding)
	var start := Vector2(blue_screen.x - horizontal_padding, blue_screen.y - vertical_padding)
	controller.call("_begin_selection_interaction", start, false)
	controller.call("_update_selection_drag", finish)
	controller.call("_finish_selection_interaction", finish)
	var selection: PackedStringArray = controller.call("get_selected_fireteam_ids")
	_assert(selection.size() == 1 and selection.has("blue"), "Drag lasso selects the fireteam whose leader is inside the rectangle")
	scene.queue_free()
	await process_frame


func _load_scene() -> Node:
	var scene = load("res://scenes/tests/mission_reactivity_test.tscn").instantiate()
	root.add_child(scene)
	for _index in range(8):
		await process_frame
	return scene


func _get_selection_anchor(controller: Node, fireteam_id: String) -> Node2D:
	if controller == null:
		return null
	return controller.call("_get_selection_anchor_for_fireteam", fireteam_id)


func _to_screen(scene: Node, world_position: Vector2) -> Vector2:
	return scene.get_viewport().get_canvas_transform() * world_position


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
