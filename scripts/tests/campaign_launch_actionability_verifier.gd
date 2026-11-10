extends SceneTree
## Actual campaign UI: owner launch blockers stay visible and help leaves actions clear.
var _checks := 0
var _failed := 0

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failed += 1
		printerr("FAIL: " + label)

func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	load("res://scripts/meta/game_start_contract.gd").request_start(self, "campaign", "new")
	var flow: Node = load("res://scenes/meta/meta_layer_test.tscn").instantiate()
	root.add_child(flow)
	await process_frame
	var screen: Control = flow.get_node("HomebaseScreen")
	var operations: Control = screen.get("_operations_presenter")
	var runtime: Node = flow.get("_singleplayer_runtime")
	screen.call("request_operation", "navigate", {"mode": "mission"})
	var craft: Dictionary = screen.call("get_operations_snapshot").get("selected_craft", {})
	var craft_id := String(craft.get("id", ""))
	if Array(craft.get("payload_fireteam_ids", [])).is_empty():
		screen.call("request_operation", "board", {"craft_id": craft_id, "fireteam_id": "ft1"})
	var personnel: Node = runtime.call("get_base_personnel_runtime")
	screen.call("request_operation", "base_board", {"craft_id": craft_id, "fireteam_id": "ft1", "whole_fireteam": true})
	var sim: Node = personnel.call("get_simulation_root")
	for tick in range(3000):
		sim.call("_physics_process", 0.05)
		screen.call("_debug_advance_homebase_direct_boarding", 0.05)
		if personnel.call("is_pilot_aboard", craft_id) and bool(screen.call("_has_homebase_direct_launch_payload_for_craft", craft_id)):
			break
	_check(personnel.call("is_pilot_aboard", craft_id), "Visible launch uses a physically boarded pilot")
	operations.call("refresh")
	var start: Button = operations.get("_start")
	var reason: Label = operations.find_child("LaunchReadiness", true, false)
	_check(reason != null, "Abheben has a permanent readiness label")
	if reason == null:
		flow.queue_free()
		await process_frame
		_finish()
		return
	_check(start.disabled and reason.is_visible_in_tree(), "Missing campaign job disables visible Abheben action")
	_check(reason.text.contains("Mobilgerät") and reason.text.contains("Satellitenauftrag"), "Visible owner blocker gives concrete Mobilgeraet action")
	var before: Dictionary = runtime.call("get_snapshot")
	operations.call("refresh")
	_check(runtime.call("get_snapshot") == before, "Reading launch readiness never changes owner progress")
	var tutorial: Control = flow.get("_campaign_tutorial")
	for dimensions in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = dimensions
		root.content_scale_size = dimensions
		await process_frame
		await process_frame
		operations.call("refresh")
		tutorial.call("set_help_mode", "compact")
		tutorial.call("reopen_help")
		await process_frame
		var popup: Control = tutorial.get("_popup")
		var host: Control = tutorial.get_node_or_null("CampaignHelpScroll")
		var rendered: Control = host if host != null else popup.get_node("HelpFrame")
		var popup_rect: Rect2 = rendered.get_global_rect()
		var strip_rect: Rect2 = tutorial.get("_strip").get_global_rect()
		_check(Rect2(Vector2.ZERO, Vector2(dimensions)).encloses(popup_rect), "%s keeps actual visible help panel inside viewport" % str(dimensions))
		for action in [operations.get("_start"), operations.get("_board"), operations.get("_unboard")]:
			if action.is_visible_in_tree():
				_check(not popup_rect.intersects(action.get_global_rect()), "%s help does not cover %s" % [str(dimensions), action.name])
				_check(not strip_rect.intersects(action.get_global_rect()), "%s guidance strip does not cover %s" % [str(dimensions), action.name])
		for control in [tutorial.get("_hide_button"), tutorial.get("_dismiss_button"), tutorial.get("_help_button")]:
			_check(control.is_visible_in_tree() and Rect2(Vector2.ZERO, Vector2(dimensions)).encloses(control.get_global_rect()), "%s keeps %s reachable" % [str(dimensions), control.text])
		_check(start.is_visible_in_tree() and Rect2(Vector2.ZERO, Vector2(dimensions)).encloses(start.get_global_rect()), "%s keeps launch action visible: %s" % [str(dimensions), str(start.get_global_rect())])
		_check(reason.is_visible_in_tree() and Rect2(Vector2.ZERO, Vector2(dimensions)).encloses(reason.get_global_rect()), "%s keeps launch blocker readable: %s" % [str(dimensions), str(reason.get_global_rect())])
		tutorial.get("_dismiss_button").pressed.emit()
		_check(not bool(tutorial.call("get_presentation_snapshot").popup_visible), "Explicit close dismisses the actual popup")
		tutorial.get("_hide_button").pressed.emit()
		_check(bool(tutorial.call("get_presentation_snapshot").hints_hidden), "Hints can be hidden independently of launch readiness")
	tutorial.call("reopen_help")
	screen.call("_on_compact_card_open_requested", "campaign_pilot", screen.get("_profiles_by_id").get("campaign_pilot"), "test")
	tutorial.call("refresh")
	_check(not tutorial.is_visible_in_tree(), "Global campaign hint does not cover the large character detail header")
	screen.call("_on_close_sheet_button_pressed")
	tutorial.call("refresh")
	_check(tutorial.is_visible_in_tree(), "Closing large detail restores campaign guidance")
	_check(bool(screen.call("request_operation", "accept_job", {"job_id": "satellite_recovery"}).get("ok", false)), "Actual Mobilgeraet accepts first job")
	operations.call("refresh")
	_check(not start.disabled, "Accepted job plus real boarded payload enables visible launch")
	_check(not reason.text.contains("annehmen"), "Resolved owner blocker disappears")
	start.pressed.emit()
	_check(String(runtime.call("get_space_travel_snapshot").phase) == "orbit" and String(runtime.call("get_space_travel_snapshot").orbit_id) == "moon_orbit", "Actual visible button launches into moon orbit")
	_check(flow.get("_active_mission") == null and int(flow.get("_active_mission_started_at_msec")) == 0, "Launch starts no premature mission or mission timer")
	tutorial.call("refresh")
	_check(not tutorial.is_visible_in_tree(), "Star-map guidance stays in its sidebar without a global hint covering it")
	_check(not paused, "Campaign guidance never pauses gameplay")
	flow.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	print("CAMPAIGN_LAUNCH_ACTIONABILITY checks=%d failed=%d" % [_checks, _failed])
	quit(1 if _failed else 0)
