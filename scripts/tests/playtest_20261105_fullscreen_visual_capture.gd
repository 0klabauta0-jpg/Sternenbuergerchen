extends "res://scripts/tests/ui_zielbild_normal_capture.gd"
## Normal menu/Homebase/mission route, real flight and optional real fire only.

var _native_screen_size := Vector2i.ZERO
var _flight_samples: Array = []
var _flight_recorded: bool = false
var _shot_recorded: bool = false


func _initialize() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Fullscreen visual capture requires a real display server.")
		quit(2)
		return
	_native_screen_size = DisplayServer.screen_get_size(DisplayServer.window_get_current_screen())
	if DisplayServer.get_name() != "headless":
		root.mode = Window.MODE_FULLSCREEN
		root.content_scale_size = _native_screen_size
	super._initialize() # Existing exact isolated QA namespace guard stays intact.


func _argument(key: String, fallback: String = "") -> String:
	if key == "--ui-size":
		return super._argument(key, "%dx%d" % [_native_screen_size.x, _native_screen_size.y])
	return super._argument(key, fallback)


func _capture(id: String, view: Node = null, settle_frames: int = 8) -> void:
	if DisplayServer.get_name() != "headless":
		root.mode = Window.MODE_FULLSCREEN
	await super._capture(id, view, settle_frames)
	if DisplayServer.get_name() == "headless":
		return
	_check(root.mode in [Window.MODE_FULLSCREEN, Window.MODE_EXCLUSIVE_FULLSCREEN], "Visual capture stays genuinely fullscreen: " + id)
	_check(DisplayServer.window_get_size() == _native_screen_size, "Fullscreen visual image covers the active physical display: " + id)
	_check(is_equal_approx(Engine.time_scale, 1.0), "Visual sequence remains at actual 1x: " + id)
	_facts["fullscreen_visual_display"] = _display_facts()
	if id == "04_lz_approach" and view != null and not _flight_recorded:
		_flight_recorded = true
		await _observe_real_flight(view)
	if id == "06_go_movement" and view != null and not _shot_recorded:
		_shot_recorded = true
		_facts["mission_hud_native_groups"] = _hud_groups(view.get_parent())
		await _observe_real_shot(view)


func _display_facts() -> Dictionary:
	return {
		"window_mode": DisplayServer.window_get_mode(),
		"physical_screen_size": _native_screen_size,
		"physical_window_size": DisplayServer.window_get_size(),
		"logical_viewport_size": root.get_visible_rect().size,
		"content_scale_size": root.content_scale_size,
		"time_scale": Engine.time_scale,
		"renderer": RenderingServer.get_current_rendering_method(),
		"display_server": DisplayServer.get_name(),
	}


func _visual_snapshot(view: Node) -> Dictionary:
	var result: Dictionary = super._visual_snapshot(view)
	result["air_visual_motion"] = _snapshot(view, "_get_air_visual_motion_snapshot")
	result["hex_grid_coverage"] = _snapshot(view, "_get_hex_grid_coverage_snapshot")
	return result


func _observe_real_flight(view: Node) -> void:
	var seen := {"descent": false, "contact": false, "takeoff": false}
	var end: int = mini(_deadline, Time.get_ticks_msec() + 24000)
	while Time.get_ticks_msec() < end and not bool(seen.takeoff):
		var motion: Dictionary = _snapshot(view, "_get_air_visual_motion_snapshot")
		for entry_variant in Array(motion.get("entries", [])):
			var entry: Dictionary = Dictionary(entry_variant)
			var phase: String = String(entry.get("phase", ""))
			var clearance: float = float(entry.get("clearance", -1.0))
			_flight_samples.append({"wall_msec": Time.get_ticks_msec(), "motion": entry.duplicate(true)})
			if phase == "inbound" and clearance < 4.6 and clearance > 0.15 and not bool(seen.descent):
				seen.descent = true
				await super._capture("10_real_descent", view, 0)
			elif phase in ["landed", "unloading"] and clearance <= 0.10 and not bool(seen.contact):
				seen.contact = true
				await super._capture("11_real_ground_contact", view, 0)
			elif phase in ["outbound", "departing"] and clearance > 0.5 and not bool(seen.takeoff):
				seen.takeoff = true
				await super._capture("12_real_takeoff", view, 0)
		await create_timer(0.08).timeout
	_facts["real_flight_visual_sequence"] = {"observed": seen, "samples": _flight_samples, "private_runtime_writes": false}
	for key in seen:
		_check(bool(seen[key]), "Normal timed flight visually captured: " + key)


func _hud_groups(mission: Node) -> Dictionary:
	var result: Dictionary = {"display": _display_facts(), "groups": {}, "portraits": []}
	for path in ["TacticalUI/FireteamMiniPanel", "TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel", "TacticalUI/A5TargetOrderPanel", "TacticalUI/MissionDropshipPanel", "TacticalUI/TacticalEventLogPanel", "TacticalUI/BottomDock"]:
		var control := mission.get_node_or_null(NodePath(path)) as Control
		if control != null:
			result.groups[path] = {"rect": str(control.get_global_rect()), "visible": control.is_visible_in_tree(), "mouse_filter": control.mouse_filter}
	var cards := mission.get_node_or_null("TacticalUI/FireteamMiniPanel/MiniMargin/MiniVBox/MiniCardsScroll/MiniCardsVBox")
	if cards != null:
		for card in cards.get_children():
			var strip := card.get_node_or_null("Margin/VBox/FireteamMemberPortraitStrip")
			if strip == null:
				continue
			for portrait in strip.get_children():
				if portrait is TextureRect:
					result.portraits.append({"unit_id": String(portrait.get_meta("mission_member_unit_id", "")), "rect": str(portrait.get_global_rect()), "texture": portrait.texture.resource_path if portrait.texture != null else ""})
	return result


func _observe_real_shot(view: Node) -> void:
	var controller := view.get_parent().get_node_or_null("TacticalController")
	if controller == null:
		return
	var camera_before: Dictionary = {"size": view.get("_camera_size"), "pitch": view.get("_camera_pitch_degrees"), "yaw": view.get("_camera_yaw_degrees"), "focus": view.get("_focus_grid_position")}
	var observed_ids: Dictionary = {}
	for event in Array(controller.call("get_fire_event_snapshot")):
		observed_ids[String(event.get("event_id", ""))] = true
	var shot: Dictionary = {}
	var wait_seconds: float = clampf(float(_argument("--shot-wait-seconds", "12")), 0.0, 40.0)
	var end: int = mini(_deadline, Time.get_ticks_msec() + roundi(wait_seconds * 1000.0))
	while Time.get_ticks_msec() < end and shot.is_empty():
		await process_frame
		for event_variant in Array(controller.call("get_fire_event_snapshot")):
			var event: Dictionary = Dictionary(event_variant)
			if observed_ids.has(String(event.get("event_id", ""))):
				continue
			if not bool(view.call("_fow_allows_fire_event_visual", event)):
				continue
			shot = event.duplicate(true)
			break
	if shot.is_empty():
		_facts["real_weapon_temporal_capture"] = {"observed": false, "bounded_wait_seconds": wait_seconds, "reason": "No new visible real weapon event during this normal-route window", "creates_fire_event": false}
		return
	var detected_usec: int = Time.get_ticks_usec()
	view.set("_camera_size", 8.0)
	view.set("_camera_pitch_degrees", 32.0)
	if typeof(shot.get("attacker_position", null)) == TYPE_VECTOR2:
		view.call("focus_world_position", Vector2(shot.attacker_position))
	view.call("_request_viewport_redraw", true, 3000)
	var samples: Array = []
	for delay_msec in [0, 120, 900]:
		while Time.get_ticks_usec() - detected_usec < int(delay_msec) * 1000:
			await process_frame
		await RenderingServer.frame_post_draw
		var frame_image: Image = root.get_texture().get_image()
		samples.append({"requested_delay_msec": delay_msec, "actual_delay_usec": Time.get_ticks_usec() - detected_usec, "image": frame_image, "tick": shot.get("tick"), "visual_events": Array(view.get("_weapon_fire_vfx_entries")).duplicate(true)})
	# PNG encoding follows all three readbacks so encoding cannot consume the
	# requested 120ms sampling window. Actual timings remain explicit evidence.
	for sample in samples:
		var id: String = "13_real_weapon_%03dms" % int(sample.requested_delay_msec)
		var path: String = _capture_root + id + ".png"
		var saved: Error = ERR_ALREADY_EXISTS if FileAccess.file_exists(path) else (sample.image as Image).save_png(path)
		_check(saved == OK, "Real weapon temporal frame saved: " + id)
		_captures.append({"id": id, "path": path, "sha256": FileAccess.get_sha256(path) if saved == OK else "", "width": (sample.image as Image).get_width(), "height": (sample.image as Image).get_height(), "requested_delay_msec": sample.requested_delay_msec, "actual_delay_usec": sample.actual_delay_usec, "event_id": shot.get("event_id")})
		sample.erase("image")
	_facts["real_weapon_temporal_capture"] = {"observed": true, "event": shot, "samples": samples, "creates_fire_event": false, "camera_only_adjustment": true}
	view.set("_camera_size", camera_before.size)
	view.set("_camera_pitch_degrees", camera_before.pitch)
	view.set("_camera_yaw_degrees", camera_before.yaw)
	view.set("_focus_grid_position", camera_before.focus)
	view.call("_update_camera_transform")
