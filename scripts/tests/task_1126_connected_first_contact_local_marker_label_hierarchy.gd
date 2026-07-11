extends SceneTree

const MISSION_SCENE := preload("res://scenes/tests/mission_reactivity_test.tscn")

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== TASK_1126 Connected First Contact Local Marker Label Hierarchy ===")
	var detached_mission: Node = MISSION_SCENE.instantiate()
	var detached_controller: Node = detached_mission.get_node("TacticalController")
	_assert(not bool(detached_controller.call("_is_connected_multiplayer_hud_session")), "Detached mission treats multiplayer HUD session as disconnected")
	_assert(not bool(detached_controller.call("_is_connected_network_snapshot_client")), "Detached mission treats snapshot client as disconnected")
	detached_mission.free()
	var mission: Node = MISSION_SCENE.instantiate()
	root.add_child(mission)
	for _frame in range(10):
		await process_frame
	var view: Node = mission.get_node("Primary3DView")
	view.call("set_order_visual_payload", {
		"selected_fireteam_ids": PackedStringArray(["blue"]),
		"world_label_focus_mode": "connected_contact",
	})
	for _frame in range(3):
		await process_frame
	_assert(view.has_method("_is_connected_contact_marker_hierarchy_active"), "Primary3D exposes a connected Contact marker hierarchy gate")
	if view.has_method("_is_connected_contact_marker_hierarchy_active"):
		_assert(bool(view.call("_is_connected_contact_marker_hierarchy_active")), "Connected Contact marker hierarchy activates from the existing focus payload")
		_assert(bool(view.call("_should_suppress_release_firefight_unit_badge", "CONTACT")), "Connected Contact suppresses redundant CONTACT unit badges")
		_assert(bool(view.call("_should_suppress_release_firefight_unit_badge", "ENGAGE")), "Connected Contact suppresses redundant ENGAGE unit badges")
		_assert(not bool(view.call("_should_suppress_release_firefight_unit_badge", "HP 60/100")), "Connected Contact preserves wounded Health badges")
		_assert(not bool(view.call("_should_suppress_release_firefight_unit_badge", "DOWN")), "Connected Contact preserves critical Vital badges")
		var snapshot: Dictionary = Dictionary(view.call("get_render_snapshot"))
		_assert(bool(snapshot.get("connected_contact_marker_hierarchy_active", false)), "Render snapshot reports the active marker hierarchy")
		_assert(float(snapshot.get("connected_contact_selected_marker_radius", 99.0)) < float(snapshot.get("connected_contact_contact_marker_radius", 0.0)), "Selection marker is smaller than the Contact marker")
		_assert(float(snapshot.get("connected_contact_selected_marker_alpha", 1.0)) < 0.4, "Selection marker uses restrained opacity during Contact")
		var selected_entries: Array = Array(snapshot.get("selected_unit_marker_entries", []))
		_assert(not selected_entries.is_empty(), "Selected local units retain visible marker entries")
		_assert(_all_marker_entries_use_radius(selected_entries, float(snapshot.get("connected_contact_selected_marker_radius", -1.0))), "Every selected marker entry uses the Contact hierarchy radius")
	mission.queue_free()
	await process_frame
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _all_marker_entries_use_radius(entries: Array, expected_radius: float) -> bool:
	for entry_variant in entries:
		if not is_equal_approx(float(Dictionary(entry_variant).get("radius", 99.0)), expected_radius):
			return false
	return true


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
