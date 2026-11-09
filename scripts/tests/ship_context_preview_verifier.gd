extends SceneTree
## Catches previews that keep a departed craft on its pad or show space for another craft.
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
	var flow: Node = load("res://scenes/meta/meta_layer_test.tscn").instantiate()
	root.add_child(flow)
	await process_frame
	var screen: Control = flow.get_node("HomebaseScreen")
	var runtime: Node = flow.get("_singleplayer_runtime")
	var operations: Control = screen.get("_operations_presenter")
	screen.call("request_operation", "navigate", {"mode": "squad"})
	operations.call("refresh")
	await process_frame
	await process_frame
	var state: Dictionary = operations.call("get_presentation_snapshot")
	_check(String(state.get("reference_stage_kind", "")) == "base_pad", "Trupp & Ausruestung uses actual pad context rather than static screenshot")
	if String(state.get("reference_stage_kind", "")) != "base_pad":
		flow.free()
		_finish()
		return
	var craft: Dictionary = screen.call("get_operations_snapshot").get("selected_craft", {})
	var craft_id := String(craft.get("id", ""))
	_check(bool(state.base.preview_mode) and String(state.base.focused_craft_id) == craft_id, "Grounded preview focuses selected actual craft pad")
	_check(state.base.projected_crafts.any(func(entry: Dictionary): return String(entry.craft_id) == craft_id), "Real selected craft is projected on its real home pad")
	_check(bool(state.get("ship_preview_visible", false)), "Narrow squad layout exposes its ship preview")
	var bounds: Rect2 = operations.get_global_rect()
	_check(bounds.encloses(Rect2(state.ship_preview_rect)), "Narrow squad preview stays in the visible workspace")
	var snapshot_before: Dictionary = runtime.call("get_snapshot")
	for repeat in range(5):
		operations.call("refresh")
	_check(runtime.call("get_snapshot") == snapshot_before, "Pad presentation does not mutate authoritative transport")
	screen.call("request_operation", "select_destination", {"location_id": "satellite_crash"})
	screen.call("_debug_advance_homebase_direct_boarding", 30.0)
	var launched: Dictionary = screen.call("request_operation", "start", {"craft_id": craft_id})
	_check(bool(launched.get("ok", false)), "Actual boarded craft takes off")
	var opened: Dictionary = runtime.call("request_operation", "space_open_operations", {})
	_check(bool(opened.get("ok", false)), "Trupp & Ausruestung is reachable in orbit")
	operations.call("refresh")
	state = operations.call("get_presentation_snapshot")
	_check(String(state.reference_stage_kind) == "space" and String(state.ship_preview_phase) == "orbit", "Moon-orbit craft is shown in space")
	_check(not bool(state.base.active), "Orbital preview deactivates ground-pad rendering")
	_check(String(state.ship_preview_caption).contains("Mondorbit"), "Space scene identifies the current moon orbit")
	_check(not state.base.projected_crafts.any(func(entry: Dictionary): return String(entry.craft_id) == craft_id), "Departed craft no longer appears on the home pad")
	var jump: Dictionary = runtime.call("request_operation", "space_start_quantum", {"craft_id": craft_id, "target_orbit_id": "planet_orbit"})
	_check(bool(jump.get("ok", false)), "Owner begins real quantum travel")
	operations.call("refresh")
	state = operations.call("get_presentation_snapshot")
	_check(String(state.ship_preview_phase) == "quantum" and String(state.ship_preview_caption).contains("Quantum"), "Quantum preview follows current travel phase")
	var abort: Dictionary = runtime.call("request_operation", "space_abort_quantum", {"craft_id": craft_id})
	_check(bool(abort.get("ok", false)), "Owner aborts real travel")
	operations.call("refresh")
	state = operations.call("get_presentation_snapshot")
	_check(String(state.reference_stage_kind) == "space" and String(state.ship_preview_phase) == "stopped", "Aborted ship remains in space in its held state")
	_check(String(state.ship_preview_caption).contains("abgebrochen"), "Held-position preview has clear feedback")
	var original: Dictionary = screen.call("get_operations_snapshot")
	var other: Dictionary = original.duplicate(true)
	other.selected_craft = craft.duplicate(true)
	other.selected_craft.id = "another_ship"
	other.singleplayer.crafts.append({"craft_id": "another_ship", "landing_pad_id": "homebase_pad_02", "location_id": "homebase", "visible_on_pad": true, "busy": false})
	operations.call("_update_flight", other.selected_craft, other)
	operations.call("_update_base_surface", other)
	state = operations.call("get_presentation_snapshot")
	_check(String(state.reference_stage_kind) == "base_pad", "Different selected grounded craft does not inherit active ship space context")
	operations.call("refresh")
	var resumed: Dictionary = runtime.call("request_operation", "space_start_quantum", {"craft_id": craft_id, "target_orbit_id": "moon_orbit"})
	_check(bool(resumed.get("ok", false)), "Held ship can return toward moon")
	var deadline := Time.get_ticks_msec() + 5000
	while String(runtime.call("get_space_travel_snapshot").phase) == "quantum" and Time.get_ticks_msec() < deadline:
		await process_frame
	_check(bool(runtime.call("request_operation", "space_land_homebase", {"craft_id": craft_id}).get("ok", false)), "Actual moon landing completes")
	screen.call("request_operation", "navigate", {"mode": "mission"})
	operations.call("refresh")
	state = operations.call("get_presentation_snapshot")
	_check(String(state.reference_stage_kind) == "base_pad" and bool(state.base.preview_mode), "Flightdeck returns to actual pad preview after real landing")
	_check(bool(state.ship_preview_visible) and Rect2(state.ship_preview_rect).has_area(), "Einsatz & Abflug actually displays its selected craft scene")
	screen.call("request_operation", "navigate", {"mode": "squad"})
	screen.call("request_operation", "navigate", {"mode": "mission"})
	operations.call("refresh")
	_check(bool(operations.call("get_presentation_snapshot").ship_preview_visible), "Switching Trupp/Ausruestung and Flightdeck does not hide the cached pad viewport")
	root.size = Vector2i(1920, 1080)
	root.content_scale_size = Vector2i(1920, 1080)
	await process_frame
	await process_frame
	operations.call("refresh")
	state = operations.call("get_presentation_snapshot")
	_check(operations.get_global_rect().encloses(Rect2(state.ship_preview_rect)) and bool(state.ship_preview_visible), "FullHD Flightdeck has a visible pad preview within its bounds")
	var teardown_deadline := Time.get_ticks_msec() + 3000
	while bool(flow.get_meta("singleplayer_visible_homebase_post_show_guard_pending", false)) and Time.get_ticks_msec() < teardown_deadline:
		await process_frame
	flow.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	print("SHIP_CONTEXT_PREVIEW checks=%d failed=%d" % [_checks, _failed])
	quit(1 if _failed else 0)
