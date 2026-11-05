extends "res://scripts/tests/ui_zielbild_normal_capture.gd"
## Real normal launch, live Timer/transfer progression and native-owner reads.
## Reuses the inherited exact private QA-directory guard; no actor/time patches.

var _timer_probe_complete := false
var _noop_probe_complete := false


func _capture(id: String, view: Node = null, settle_frames: int = 8) -> void:
	await super._capture(id, view, settle_frames)
	if id == "01_main_menu" and DisplayServer.get_name() != "headless":
		var screen_size := DisplayServer.screen_get_size(DisplayServer.window_get_current_screen())
		_check(root.mode == Window.MODE_FULLSCREEN or root.mode == Window.MODE_EXCLUSIVE_FULLSCREEN, "Native regression window uses actual fullscreen mode")
		_check(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN or DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN, "DisplayServer confirms native fullscreen mode")
		_check(DisplayServer.window_get_size() == screen_size, "Native regression covers the active display resolution")
		_facts["native_window"] = {"root_mode": root.mode, "display_server_mode": DisplayServer.window_get_mode(), "screen_size": str(screen_size), "window_size": str(DisplayServer.window_get_size()), "viewport_size": str(root.get_visible_rect().size)}
	if id == "03_default_mission" and not _timer_probe_complete:
		_timer_probe_complete = true
		await _probe_real_transfer_timer(view)
	if id == "06_go_movement" and not _noop_probe_complete:
		_noop_probe_complete = true
		_probe_unchanged_live_planning(view)


func _control_identities(node: Node) -> Array:
	var identities: Array = []
	for control in node.find_children("*", "Control", true, false):
		identities.append(control.get_instance_id())
	identities.sort()
	return identities


func _probe_real_transfer_timer(view: Node) -> void:
	var flow := current_scene
	var mission := view.get_parent()
	var controller := mission.get_node_or_null("TacticalController")
	var homebase := flow.get_node_or_null("HomebaseScreen") as Control
	var timer := flow.get_node_or_null("HomebaseTransportTimer") as Timer
	if timer == null:
		timer = flow.get_node_or_null("TransportTimer") as Timer
	if not _check(homebase != null and controller != null, "Hitch regression uses the real hidden Homebase and mission controller"):
		return
	_check(not homebase.is_visible_in_tree(), "Homebase is hidden behind the active normal mission")
	_check(timer != null and not timer.is_stopped(), "Normal transfer owns an active repeating Timer")
	_check(is_equal_approx(Engine.time_scale, 1.0), "Transfer regression runs at normal 1x")
	var transfer_before: Array = Array(flow.get("_pending_mission_craft_transfers")).duplicate(true)
	_check(not transfer_before.is_empty(), "Normal launch owns a real pending craft transfer")
	var before_ids := _control_identities(homebase)
	var before_plan := _planning_snapshot(controller)
	var before_orders: Array = Array(_snapshot(controller, "get_planning_state").get("order_plans", [])).duplicate(true)
	flow.call("set_transport_refresh_timing_debug_enabled", true)
	# Wait for the real repeating one-second Timer. No direct timeout call,
	# transfer completion, Timer acceleration, actor mutation or forced phase.
	await create_timer(2.2).timeout
	var timer_snapshot := _snapshot(flow, "get_transport_refresh_timing_debug_snapshot")
	var transfer_after: Array = Array(flow.get("_pending_mission_craft_transfers")).duplicate(true)
	var after_plan := _planning_snapshot(controller)
	_check(int(timer_snapshot.get("invocation_count", 0)) >= 1, "Real repeating transport Timer executed during the sample")
	_check(not transfer_after.is_empty() and not transfer_before.is_empty() and float(Dictionary(transfer_after[0]).get("elapsed_seconds", 0.0)) > float(Dictionary(transfer_before[0]).get("elapsed_seconds", 0.0)), "Authoritative transfer elapsed time advances while Homebase is hidden")
	_check(float(after_plan.get("mission_drop_progress", 0.0)) > float(before_plan.get("mission_drop_progress", 0.0)), "Active mission receives increasing craft progress")
	_check(int(after_plan.get("mission_drop_eta_seconds", 0)) < int(before_plan.get("mission_drop_eta_seconds", 0)), "Active mission receives decreasing craft ETA")
	_check(_control_identities(homebase) == before_ids, "Transport Timer preserves all hidden Homebase controls without rebuilding")
	_check(Array(_snapshot(controller, "get_planning_state").get("order_plans", [])) == before_orders, "Transport delta preserves the complete tactical order plan")
	_check(flow.has_method("get_meta_presentation_debug_snapshot"), "Meta presentation exposes bounded read-only dirty/delta diagnostics")
	var presentation := _snapshot(flow, "get_meta_presentation_debug_snapshot")
	_check(bool(presentation.get("homebase_dirty", false)), "Hidden Homebase is marked dirty for its next actual display")
	_check(int(presentation.get("transport_delta_apply_count", 0)) >= 1, "Transport Timer uses the narrow mission transport consumer")
	_facts["hitch_timer_regression"] = {"timer": timer_snapshot, "presentation": presentation, "before": before_plan, "after": after_plan}


func _probe_unchanged_live_planning(view: Node) -> void:
	var flow := current_scene
	var controller := view.get_parent().get_node_or_null("TacticalController")
	if not _check(controller != null, "No-op regression retains the live tactical owner"):
		return
	controller.call("set_mission_visible_frame_timing_debug_enabled", true)
	var live_plan := _snapshot(controller, "get_planning_state")
	var before_ui := _snapshot(controller, "get_mission_ui_refresh_timing_debug_snapshot")
	var before_execution: Dictionary = Dictionary(controller.get("_phase_execution_by_fireteam")).duplicate(true)
	var before: Dictionary = _snapshot(flow, "get_meta_presentation_debug_snapshot")
	# This is the existing planning signal consumer with the owner's own fresh
	# state. It must not feed the same plan back into the emitting owner.
	flow.call("_on_mission_planning_state_changed", live_plan)
	var after_ui := _snapshot(controller, "get_mission_ui_refresh_timing_debug_snapshot")
	var after: Dictionary = _snapshot(flow, "get_meta_presentation_debug_snapshot")
	_check(int(after_ui.get("invocation_count", 0)) == int(before_ui.get("invocation_count", 0)), "Unchanged live planning does not trigger another full mission HUD refresh")
	_check(int(after.get("full_plan_apply_count", 0)) == int(before.get("full_plan_apply_count", 0)), "Unchanged live planning does not reapply the complete mission plan")
	_check(Dictionary(controller.get("_phase_execution_by_fireteam")) == before_execution, "No-op planning preserves live fireteam execution exactly")
	_check(bool(after.get("read_only", false)) and not bool(after.get("ui_sets_gameplay_truth", true)), "Meta presentation diagnostics remain read-only")
	_check(controller.has_method("apply_meta_transport_planning_delta"), "Live owner exposes the narrow transport delta consumer")
	if controller.has_method("apply_meta_transport_planning_delta"):
		var before_rejected_delta := _snapshot(controller, "get_planning_state")
		var rejected := not bool(controller.call("apply_meta_transport_planning_delta", {"mission_drop_progress": 1.0, "order_plans": []}))
		_check(rejected, "Transport consumer rejects non-transport planning atomically")
		_check(_snapshot(controller, "get_planning_state") == before_rejected_delta, "Rejected delta preserves the complete live planning state")
	_facts["hitch_noop_regression"] = {"before": before, "after": after, "ui_before": before_ui, "ui_after": after_ui}
	print("PLAYTEST_META_HITCH_REGRESSION_DONE")
