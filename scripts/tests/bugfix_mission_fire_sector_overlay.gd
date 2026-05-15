extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const FIRETEAM_INFO_VBOX_PATH: String = "TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamBodyRow/FireteamInfoScroll/FireteamInfoVBox"
const GO_BUTTON_PATH: String = "TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/GoCommandMatrixButton"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== Bugfix Mission Fire Sector Overlay ===")
	await _test_fire_sector_overlay_is_explicit_and_sector_based()
	await _test_direct_mode_hides_legacy_phase_controls()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_fire_sector_overlay_is_explicit_and_sector_based() -> void:
	var scene := MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(12)
	var controller := scene.get_node_or_null("TacticalController")
	var primary_view := scene.get_node_or_null("Primary3DView")
	_assert(controller != null and primary_view != null, "Mission scene exposes controller and Primary3DView")
	if controller == null or primary_view == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	controller.call("set_fire_sector_overlay_enabled", false)
	await _wait_frames(4)
	var disabled_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(not bool(disabled_snapshot.get("friendly_fire_sector_overlay_enabled", true)), "Friendly fire sector overlay defaults to explicit off-state")
	_assert(int(disabled_snapshot.get("friendly_aim_visual_count", -1)) == 0, "No friendly fire range visuals are drawn while the overlay is off")
	_assert(int(disabled_snapshot.get("selected_unit_marker_count", 0)) > 0, "Primary 3D view renders selected-unit markers at proxy positions")
	_assert(_count_visible_legacy_selection_rings(controller, "blue") == 0, "Primary 3D mission suppresses legacy 2D selection rings")

	controller.call("set_fire_sector_overlay_enabled", true)
	await _wait_frames(6)
	var enabled_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	var first_entry: Dictionary = _first_dictionary(Array(enabled_snapshot.get("friendly_aim_entries", [])))
	_assert(bool(enabled_snapshot.get("friendly_fire_sector_overlay_enabled", false)), "Friendly fire sector overlay can be toggled on")
	_assert(String(enabled_snapshot.get("friendly_fire_sector_visual_mode", "")) == "los_line_only", "Friendly fire overlay defaults to a cheap LOS line visualization")
	_assert(int(enabled_snapshot.get("friendly_aim_visual_count", 0)) > 0, "Selected fireteam exposes fire sector visuals when enabled")
	_assert(int(enabled_snapshot.get("friendly_fire_sector_tile_marker_count", -1)) == 0, "LOS line mode avoids reachable-tile marker floods")
	_assert(String(enabled_snapshot.get("friendly_fire_sector_scan_mode", "")) == "single_facing_los_line", "Friendly fire overlay performs one bounded facing LOS check per shown unit")
	_assert(int(enabled_snapshot.get("friendly_fire_sector_los_line_count", 0)) <= maxi(int(enabled_snapshot.get("friendly_aim_visual_count", 1)), 1), "Friendly fire overlay keeps LOS line sampling to one line per unit")
	_assert(String(first_entry.get("visual_shape", "")) == "los_line", "Friendly range readout is represented as a single sight line")
	_assert(not bool(first_entry.get("tile_aligned", true)), "Friendly range entry records that the visualization is not a tile-sector fill")
	_assert(float(first_entry.get("sector_angle_degrees", 0.0)) > 45.0 and float(first_entry.get("sector_angle_degrees", 180.0)) < 90.0, "Fire sector uses a narrow arc below ninety degrees")
	_assert(first_entry.has("facing_tip_position"), "Friendly sector entries include a short facing tip for direction readability")
	var unit_id: String = String(first_entry.get("unit_id", "")).strip_edges()
	var proxy_state_by_id: Dictionary = Dictionary(enabled_snapshot.get("unit_proxy_state_by_id", {}))
	var proxy_state: Dictionary = Dictionary(proxy_state_by_id.get(unit_id, {}))
	var origin_position: Vector2 = Vector2(first_entry.get("origin_position", Vector2.ZERO))
	var facing_tip_position: Vector2 = Vector2(first_entry.get("facing_tip_position", Vector2.ZERO))
	var facing_direction: Vector2 = (facing_tip_position - origin_position).normalized()
	var proxy_direction: Vector2 = Vector2(primary_view.call("_get_world_direction_from_proxy_yaw", origin_position, float(proxy_state.get("rotation_y_degrees", 0.0))))
	_assert(not proxy_state.is_empty() and facing_direction.dot(proxy_direction.normalized()) > 0.98, "Friendly sight sector follows the rendered NPC proxy rotation instead of drifting to the left")
	var unit := _find_unit_by_id(scene, unit_id)
	if unit != null:
		(unit as Node).set_meta("facing_angle", PI)
		if unit.has_method("set_target_position"):
			unit.call("set_target_position", origin_position + Vector2(140.0, 0.0))
		controller.call("_refresh_order_visuals")
		await _wait_frames(6)
		var target_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
		var target_entry: Dictionary = _first_dictionary(Array(target_snapshot.get("friendly_aim_entries", [])))
		var target_origin: Vector2 = Vector2(target_entry.get("origin_position", origin_position))
		var target_facing_tip: Vector2 = Vector2(target_entry.get("facing_tip_position", target_origin))
		var expected_direction: Vector2 = Vector2.LEFT
		var target_facing_direction: Vector2 = (target_facing_tip - target_origin).normalized()
		_assert(target_facing_direction.dot(expected_direction) > 0.94, "Friendly sight line stays bound to explicit facing instead of drifting to target metadata")

	controller.call("set_fire_sector_overlay_enabled", false)
	await _wait_frames(4)
	var disabled_again_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(int(disabled_again_snapshot.get("friendly_aim_visual_count", -1)) == 0, "Friendly fire sector visuals clear again after toggling off")
	scene.queue_free()
	await _wait_frames(2)


func _test_direct_mode_hides_legacy_phase_controls() -> void:
	var scene := MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(12)
	var controller := scene.get_node_or_null("TacticalController")
	_assert(controller != null, "Mission scene exposes controller for direct-mode UI checks")
	if controller == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	controller.call("_set_selected_fireteams", PackedStringArray(), false)
	controller.call("_refresh_fireteam_phase_panel")
	controller.call("_refresh_fireteam_status_panel")
	controller.call("_refresh_button_state")
	var phase_panel := scene.get_node_or_null("%s/FireteamPhasePanel" % FIRETEAM_INFO_VBOX_PATH) as Control
	var status_panel := scene.get_node_or_null("%s/FireteamStatusPanel" % FIRETEAM_INFO_VBOX_PATH) as Control
	var go_button := scene.get_node_or_null(GO_BUTTON_PATH) as Button
	var plan_button := scene.get_node_or_null("TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/PlanCommandMatrixButton") as Button
	_assert(phase_panel != null and not phase_panel.visible, "#17 hides the parked legacy phase panel in direct order mode")
	_assert(status_panel == null, "#17 no longer creates the old Ready/Plan/SUPP status panel")
	_assert(go_button != null and go_button.disabled, "GO in #16 is disabled when no selected fireteam order can execute")
	_assert(plan_button == null, "Plan in #16 is no longer a visible return-to-plan action")
	scene.queue_free()
	await _wait_frames(2)


func _first_dictionary(values: Array) -> Dictionary:
	for value in values:
		if typeof(value) == TYPE_DICTIONARY:
			return Dictionary(value)
	return {}


func _find_unit_by_id(scene: Node, unit_id: String) -> Node:
	if scene == null or unit_id.strip_edges().is_empty():
		return null
	for child in scene.get_children():
		if child != null and child.has_method("get_unit_id") and String(child.call("get_unit_id")).strip_edges() == unit_id.strip_edges():
			return child
	return null


func _count_visible_legacy_selection_rings(controller: Node, fireteam_id: String) -> int:
	if controller == null:
		return 0
	var count: int = 0
	for unit_variant in Array(controller.call("_get_fireteam_units", fireteam_id, true)):
		if not (unit_variant is Node):
			continue
		var ring := (unit_variant as Node).get_node_or_null("SelectionRing") as CanvasItem
		if ring != null and ring.visible:
			count += 1
	return count


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	print("FAIL: %s" % message)
