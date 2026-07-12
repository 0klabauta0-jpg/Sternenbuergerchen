extends SceneTree

const MISSION_SCENE := preload("res://scenes/tests/mission_reactivity_test.tscn")

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== TASK_1155 Contact Focus Empty Dropship Surface Retirement ===")
	var mission: Node = MISSION_SCENE.instantiate()
	root.add_child(mission)
	for _frame in range(10):
		await process_frame
	var controller := mission.get_node_or_null("TacticalController")
	_assert(controller != null, "Mission exposes tactical controller")
	if controller != null:
		_assert(controller.has_method("_is_contact_focus_active_from_snapshots"), "Controller exposes one Contact-focus decision for HUD surfaces")
		if controller.has_method("_is_contact_focus_active_from_snapshots"):
			_assert(bool(controller.call("_is_contact_focus_active_from_snapshots", {}, {"active": true, "compact_line": "CONTACT FIRE | BLUE"})), "Persisted First-Fire status activates Contact focus when connected diagnostics lag")
			_assert(not bool(controller.call("_is_contact_focus_active_from_snapshots", {}, {})), "Empty HUD snapshots do not activate Contact focus")
		_assert(controller.has_method("_should_refresh_dropship_panel_for_contact_focus"), "Dropship panel exposes a transition-only Contact refresh guard")
		if controller.has_method("_should_refresh_dropship_panel_for_contact_focus"):
			controller.set("_last_mission_dropship_contact_focus_active", false)
			_assert(not bool(controller.call("_should_refresh_dropship_panel_for_contact_focus", false)), "Stable non-Contact snapshots do not rebuild Dropship UI")
			_assert(bool(controller.call("_should_refresh_dropship_panel_for_contact_focus", true)), "First Contact transition requests one Dropship UI refresh")
			_assert(not bool(controller.call("_should_refresh_dropship_panel_for_contact_focus", true)), "Repeated Contact snapshots do not rebuild Dropship UI")
		var empty_outbound := [_card("dropship_blue", "outbound", []), _card("dropship_gold", "outbound", [])]
		_assert(Array(controller.call("_build_contact_focused_mission_dropship_card_entries", empty_outbound, true)).is_empty(), "Contact focus retires empty outbound Dropship surfaces")
		_assert(Array(controller.call("_build_contact_focused_mission_dropship_card_entries", empty_outbound, false)).size() == 2, "Outside Contact focus outbound Dropships remain visible")
		var loaded_outbound := [_card("dropship_loaded", "outbound", ["unit_alpha"])]
		_assert(Array(controller.call("_build_contact_focused_mission_dropship_card_entries", loaded_outbound, true)).size() == 1, "Loaded outbound Dropship remains visible")
		var waiting_empty := [_card("dropship_waiting", "waiting", [])]
		_assert(Array(controller.call("_build_contact_focused_mission_dropship_card_entries", waiting_empty, true)).size() == 1, "Actionable waiting Dropship remains visible")
		controller.set("_network_dropship_feedback_by_craft", {"dropship_feedback": {"compact_line": "HOST OK", "tone": "success"}})
		var feedback_outbound := [_card("dropship_feedback", "outbound", [])]
		_assert(Array(controller.call("_build_contact_focused_mission_dropship_card_entries", feedback_outbound, true)).is_empty(), "Historical craft feedback cannot pin an empty Dropship surface over Contact")
		controller.set("_pending_network_dropship_commands_by_craft", {"dropship_pending": {"remaining_seconds": 3.0}})
		var pending_outbound := [_card("dropship_pending", "outbound", [])]
		_assert(Array(controller.call("_build_contact_focused_mission_dropship_card_entries", pending_outbound, true)).size() == 1, "A real pending craft command keeps its Dropship surface visible")
	mission.queue_free()
	await process_frame
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _card(craft_id: String, state: String, payload_ids: Array) -> Dictionary:
	return {
		"craft_id": craft_id,
		"state": state,
		"eta_seconds": 0,
		"embarked_unit_ids": payload_ids,
		"passenger_count": payload_ids.size(),
		"pilot_unit_id": "",
	}


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
