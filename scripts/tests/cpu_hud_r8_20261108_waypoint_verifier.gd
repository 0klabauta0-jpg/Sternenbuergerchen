extends "res://scripts/tests/runtime_hitches_r4_20261107_command_projection_verifier.gd"
## Real authored controller/visuals; no actor or timer patches.
class R8Probe extends "res://scripts/tests/mission_tactical_sandbox_controller.gd":
	var visual_calls := 0
	var fixture_contacts: Array = []
	func get_contact_snapshot() -> Array:
		return fixture_contacts.duplicate(true) if not fixture_contacts.is_empty() else super.get_contact_snapshot()
	var invalidate_targets := false
	func _set_waypoint_command_for_targets(targets: Array, command_type: String) -> bool:
		if invalidate_targets:
			_order_plans_by_key.clear()
		return super._set_waypoint_command_for_targets(targets, command_type)
	func _ready() -> void:
		super._ready()
		set_process(false)
		set_physics_process(false)
	func _refresh_order_visuals() -> void:
		visual_calls += 1
		super._refresh_order_visuals()
func _run() -> void:
	root.size = Vector2i(1920, 1080)
	var scene := MISSION.instantiate()
	var original := scene.get_node("TacticalController")
	var probe := R8Probe.new()
	for property in original.get_property_list():
		if (int(property.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE) != 0 and (int(property.usage) & PROPERTY_USAGE_EDITOR) != 0:
			probe.set(String(property.name), original.get(String(property.name)))
	scene.remove_child(original)
	original.free()
	probe.name = "TacticalController"
	scene.add_child(probe)
	root.add_child(scene)
	for frame in range(16):
		await process_frame
	var sim := scene.get_node("SimulationRoot")
	var view: Node = probe.call("_get_primary_3d_view")
	var legacy := scene.get_node("FireteamOrderVisualizer")
	var selected := probe.get_selected_fireteam_ids()
	_check(view != null and legacy != null and not selected.is_empty(), "Actual authored consumers and selection exist")
	var target: Vector2 = (scene.get_node("TargetMarker") as Node2D).global_position + Vector2(128, 0)
	var publications: Array[Dictionary] = []
	probe.planning_state_changed.connect(func(state: Dictionary) -> void: publications.append(state.duplicate(true)))
	for kind in ["move", "take", "defend", "flank"]:
		var actors := _actor_state(probe)
		var tick: int = sim.call("get_tick")
		var queue := str(sim.get("command_queue"))
		publications.clear()
		probe.visual_calls = 0
		var accepted := probe.issue_right_click_command_for_test(target, kind, false)
		_check(accepted, "Public waypoint planning accepts " + kind)
		_check(probe.visual_calls == 1, "Public finalized " + kind + " projects orders once")
		_check(publications.size() == 1 and publications[0] == probe.get_planning_state(), "Finalized " + kind + " publishes complete current planning state once")
		_check(_actor_state(probe) == actors and int(sim.call("get_tick")) == tick and str(sim.get("command_queue")) == queue, "Planning " + kind + " preserves actors/tick/command queue")
		_check(Array(view.get("_order_payload").get("plan_dicts", [])) == probe.call("_serialize_order_plans"), "Native complete " + kind + " plan payload is fresh")
		_check(Array(legacy.get("_plan_dicts")) == probe.call("_serialize_order_plans"), "Legacy complete " + kind + " plan payload is fresh")
		var native_before: Dictionary = view.get("_order_payload").duplicate(true)
		probe.call("_refresh_order_visuals")
		# Plan/source fields are exact; transient bubble TTL fields are not an oracle.
		var after: Dictionary = view.get("_order_payload")
		var equal := true
		for key in ["plan_dicts", "fireteam_anchors", "area_order_dicts", "ad_hoc_order_dicts", "security_dicts", "movement_state_dicts", "selected_fireteam_ids", "waypoint_intent_preview_entries"]:
			equal = equal and native_before.get(key) == after.get(key)
		_check(equal, "Explicit original visual refresh has identical complete authoritative-derived source fields for " + kind)
	probe.visual_calls = 0
	publications.clear()
	var plans_before: Array = probe.call("_serialize_order_plans")
	var count_before := 0
	for plan in plans_before:
		count_before += Array(plan.waypoints).size()
	_check(probe.issue_right_click_command_for_test(target + Vector2(16, 0), "take", true) and probe.visual_calls == 1, "Append command projects once with final type")
	var count_after := 0
	for plan in Array(probe.call("_serialize_order_plans")):
		count_after += Array(plan.waypoints).size()
	_check(count_after == count_before + selected.size() and publications.size() == 1, "Append retains previous pending orders and one publication")
	# Real connected-client planning entry: local pending plan, no network/gameplay command.
	probe.visual_calls = 0
	publications.clear()
	var before := _actor_state(probe)
	var queue_before := str(sim.get("command_queue"))
	var connected: bool = probe.call("_plan_connected_client_fireteam_command", "take", "TAKE", target)
	_check(connected and probe.visual_calls == 1, "Real connected-client planner projects only the finalized command")
	_check(publications.size() == 1 and publications[0] == probe.get_planning_state(), "Connected-client planner publishes exactly one complete state")
	_check(_actor_state(probe) == before and str(sim.get("command_queue")) == queue_before, "Connected-client planning retains authoritative commit boundary")
	_check(Array(view.get("_order_payload").get("plan_dicts", [])) == probe.call("_serialize_order_plans"), "Connected-client final native plan payload matches owner")
	# Synthetic contact-source inputs only; never inject actors or runtime commands.
	for direct in [true, false]:
		var unit_id := "r8_contact_direct" if direct else "r8_contact_connected"
		probe.fixture_contacts = [{"fireteam_id": String(selected[0]), "unit_id": unit_id, "approximate_position": target, "confidence": 1.0, "detection_state": "confirmed", "report_state": "current", "report_text": "R8 CONTACT"}]
		probe.visual_calls = 0
		var accepted: bool = probe.issue_right_click_command_for_test(target, "move", false) if direct else bool(probe.call("_plan_connected_client_fireteam_command", "take", "TAKE", target))
		_check(accepted and probe.visual_calls == 1, "Changed-contact finalizer keeps one full order projection")
		var owner_events: Array = probe.call("get_tactical_communication_event_snapshot")
		var native_events: Array = view.get("_order_payload").get("tactical_communication_event_dicts", [])
		var produced := false
		var included := false
		for event in owner_events:
			if String(event.get("unit_id", "")) == unit_id and String(event.get("event_type", "")) == "contact_report":
				produced = true
				included = native_events.has(event)
		_check(produced, "Changed contact creates a real visual communication owner event")
		_check(included, "Final native payload contains the complete newly produced contact-report event")
	probe.fixture_contacts = []

	# Interactive context-menu creation must retain its immediate preview.
	probe.visual_calls = 0
	var menu_targets: Array = probe.call("_create_waypoints_for_selected_fireteams", target, false, false)
	_check(not menu_targets.is_empty() and probe.visual_calls == 1, "Unfinalized context-menu creation still projects immediately")
	_check(Array(view.get("_order_payload").get("plan_dicts", [])) == probe.call("_serialize_order_plans"), "Menu preview includes all appended pending orders")
	probe.invalidate_targets = true
	probe.visual_calls = 0
	_check(not probe.issue_right_click_command_for_test(target, "move", false) and probe.visual_calls == 1, "Late invalid targets retain the original failure refresh")
	_check(Array(view.get("_order_payload").get("plan_dicts", [])).is_empty(), "Late failure clears obsolete native plans")
	probe.invalidate_targets = false
	probe.call("_set_selected_fireteams", PackedStringArray(), false)
	probe.visual_calls = 0
	_check(not probe.issue_right_click_command_for_test(target, "move", false) and probe.visual_calls == 1, "Empty-selection failure retains original refresh")
	scene.queue_free()
	await process_frame
	print("R8_WAYPOINT_DONE ", JSON.stringify({"passed": _passed, "failed": _failed}))
	quit(0 if _failed == 0 else 1)
