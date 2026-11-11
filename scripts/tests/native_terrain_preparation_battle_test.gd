extends "res://scripts/tests/native_glut_battle_profile.gd"
## Opt-in native integration probe. Inherits the real B/1x battle unchanged.
const PREPARATION_OUTPUT := "res://output/native_glut_maps/B_terrain_preparation.json"
const PREPARATION_SCREENSHOT := "res://output/native_glut_maps/B_terrain_preparation.png"
const PREPARATION_BATTLE_PROFILE := "res://output/native_glut_maps/B_battle_profile.json"
var _preparation_observing := false
var _preparation_frames := 0
var _preparation_pending_frames := 0
var _preparation_ready_observed := false
var _preparation_errors: Dictionary = {}
var _preparation_transitions: Array[Dictionary] = []
var _preparation_last_status := ""
var _preparation_started_msec := 0
var _preparation_ram_peak := 0
var _preparation_video_peak := 0
var _preparation_screenshot_pending := false
var _preparation_screenshot_receipt: Dictionary = {}
var _preparation_handoff: Dictionary = {}
var _preparation_camera_receipts: Array[Dictionary] = []


func _run() -> void:
	if not _check(OS.get_cmdline_user_args().has("continue-chapter") and OS.get_cmdline_user_args().has("1x"),
			"Preparation battle requires the normal post-A checkpoint and explicit 1x"):
		quit(1)
		return
	var private_root := ProjectSettings.globalize_path("res://output/native_glut_maps/").replace("\\", "/").to_lower()
	if not _check(OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(private_root),
			"Preparation receipt reset requires the same private APPDATA guard as the base profile"):
		quit(1)
		return
	# Only this fixed generated output is removed. A subsequent receipt must come
	# from this run, including if the inherited battle exits early.
	if FileAccess.file_exists(PREPARATION_BATTLE_PROFILE):
		if not _check(DirAccess.remove_absolute(ProjectSettings.globalize_path(PREPARATION_BATTLE_PROFILE)) == OK,
				"Prior fixed battle receipt clears before the new run"):
			quit(1)
			return
	process_frame.connect(_observe_preparation_frame)
	await super._run()


func _observe_preparation_frame() -> void:
	if not _preparation_observing or _preparation_ready_observed or not is_instance_valid(_flow): return
	var loading: Dictionary = _flow.call("get_surface_preparation_snapshot", _craft_id)
	var status := String(loading.get("status", "idle"))
	if status not in ["loading_data", "preparing_resources", "ready", "failed", "cancelled"]: return
	# A previous sortie's retained ready result is not this preparation interval.
	if status == "ready" and _preparation_pending_frames == 0: return
	_preparation_frames += 1
	if status != _preparation_last_status:
		_preparation_transitions.append({"elapsed_ms": Time.get_ticks_msec() - _preparation_started_msec, "snapshot": loading})
		_preparation_last_status = status
	if status in ["failed", "cancelled"]: _preparation_errors[status + ":" + String(loading.get("reason", ""))] = true
	if bool(loading.get("ready", false)):
		_preparation_ready_observed = true
		return
	_preparation_ram_peak = maxi(_preparation_ram_peak, OS.get_static_memory_usage())
	_preparation_video_peak = maxi(_preparation_video_peak, RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED))
	_preparation_pending_frames += 1
	# These are narrow owner reads; never project the complete campaign each frame.
	var travel: Dictionary = _runtime.call("get_space_travel_snapshot", _craft_id)
	if String(travel.get("phase", "")) != "approach": _preparation_errors["pending_left_approach"] = true
	if _flow.get("_active_mission") != null: _preparation_errors["mission_created_before_ready"] = true
	if int(_flow.get("_active_mission_started_at_msec")) != 0: _preparation_errors["mission_timer_started_before_ready"] = true
	if status == "preparing_resources" and float(loading.get("progress", 0.0)) >= 0.1 and _preparation_screenshot_receipt.is_empty() and not _preparation_screenshot_pending:
		_preparation_screenshot_pending = true
		_capture_preparation_progress()


func _capture_preparation_progress() -> void:
	await RenderingServer.frame_post_draw
	if not _preparation_observing or not is_instance_valid(_flow):
		_preparation_screenshot_pending = false
		return
	var loading: Dictionary = _flow.call("get_surface_preparation_snapshot", _craft_id)
	if String(loading.get("status", "")) != "preparing_resources" or bool(loading.get("ready", false)):
		_preparation_screenshot_pending = false
		return
	var star_map_visible := String(_flow.get("_current_meta_view")) == "star_map"
	var error := root.get_texture().get_image().save_png(ProjectSettings.globalize_path(PREPARATION_SCREENSHOT))
	_preparation_screenshot_receipt = {"path": PREPARATION_SCREENSHOT, "save_error": error,
		"star_map_visible": star_map_visible, "loading": loading, "process_frame": Engine.get_process_frames()}
	_preparation_screenshot_pending = false


func _launch_and_land(scenario_id: String, map_path: String) -> bool:
	_preparation_observing = true
	_preparation_started_msec = Time.get_ticks_msec()
	var landed := await super._launch_and_land(scenario_id, map_path)
	_preparation_observing = false
	if not landed: return false
	var mission: Node = _flow.get("_active_mission")
	var view: Node = mission.get_node("Primary3DView")
	_preparation_handoff = view.call("get_terrain_resource_preparation_snapshot")
	_check(bool(_preparation_handoff.get("ready", false)) and int(_preparation_handoff.get("expected_chunks", 0)) == 2161 and int(_preparation_handoff.get("prepared_chunks", 0)) == 2161,
		"Real MissionSetup receives all 2161 prepared terrain chunks")
	_check(int(_preparation_handoff.get("geometry_build_count", -1)) == 0 and int(_preparation_handoff.get("resource_restore_count", 0)) > 0,
		"Real mission restores prepared resources without initial geometry construction")
	var cache: RefCounted = view.call("get_prepared_terrain_resource_cache")
	if not _check(cache != null, "Mission keeps the transferred resource cache"): return false
	var identity := _preparation_cache_identity(cache)
	var focus: Vector2 = view.call("get_camera_focus_grid_position")
	for target in [Vector2i(190, 75), Vector2i(-110, -65), Vector2i(190, -65)]:
		view.call("focus_world_position", view.call("grid_to_world_position", target))
		await _settle_preparation_camera(view)
		var receipt := _preparation_camera_snapshot(view, cache)
		receipt["target_grid"] = [target.x, target.y]
		_preparation_camera_receipts.append(receipt)
		_check(receipt.identity == identity, "Distant camera keeps actual cache instance, context and geometry resource IDs " + str(target))
		_check(int(receipt.preparation.geometry_build_count) == 0 and bool(receipt.settled), "Distant camera settles with no geometry rebuild " + str(target))
		_check(bool(receipt.preparation.ready) and int(receipt.preparation.prepared_chunks) == 2161, "Distant camera retains complete preparation " + str(target))
		_check(int(receipt.retained_nodes) <= int(receipt.active_chunks) + 64, "Distant camera keeps bounded terrain scene nodes " + str(target))
	view.call("focus_world_position", view.call("grid_to_world_position", focus))
	await _settle_preparation_camera(view)
	var restored := _preparation_camera_snapshot(view, cache)
	restored["restored_original_focus"] = true
	_preparation_camera_receipts.append(restored)
	_check(restored.identity == identity and int(restored.preparation.geometry_build_count) == 0 and bool(restored.settled), "Returning camera reuses the same complete map resources")
	_check(int(restored.preparation.resource_restore_count) > int(_preparation_handoff.resource_restore_count), "Distant camera really restores additional terrain chunks")
	return true


func _settle_preparation_camera(view: Node) -> void:
	view.call("_refresh_visual_streaming_chunks")
	for frame in range(600):
		await process_frame
		if view.get("_regional_pending_chunks").is_empty() and not bool(view.get("_visual_streaming_refresh_queued")): return


func _preparation_cache_identity(cache: RefCounted) -> Dictionary:
	var resources: Dictionary = cache.get("_resources")
	var ids: Array = resources.keys()
	ids.sort()
	var digest := HashingContext.new()
	digest.start(HashingContext.HASH_SHA256)
	digest.update(var_to_bytes(ids))
	var snapshot: Dictionary = cache.call("get_debug_snapshot")
	return {"cache_instance_id": cache.get_instance_id(), "context_fingerprint": snapshot.context_fingerprint,
		"geometry_resource_count": ids.size(), "actual_sorted_resource_ids_sha256": digest.finish().hex_encode()}


func _preparation_camera_snapshot(view: Node, cache: RefCounted) -> Dictionary:
	return {"identity": _preparation_cache_identity(cache), "preparation": view.call("get_terrain_resource_preparation_snapshot"),
		"retained_nodes": view.get("_regional_chunk_nodes").size(), "active_chunks": view.get("_visual_streaming_active_chunks").size(),
		"settled": view.get("_regional_pending_chunks").is_empty() and not bool(view.get("_visual_streaming_refresh_queued"))}


func _finish() -> void:
	_preparation_observing = false
	if process_frame.is_connected(_observe_preparation_frame): process_frame.disconnect(_observe_preparation_frame)
	_check(_preparation_pending_frames > 0 and _preparation_ready_observed and _preparation_errors.is_empty(), "Observed pending approach creates no mission, mission units or mission timer before ready")
	_check(not _preparation_screenshot_receipt.is_empty() and int(_preparation_screenshot_receipt.get("save_error", -1)) == OK and bool(_preparation_screenshot_receipt.get("star_map_visible", false)), "Native screenshot records real StarMap terrain loading progress")
	# The event ring can expire earlier shots by the time the inherited battle
	# finishes. Its written profile preserves the maximum observed shot count.
	var battle: Dictionary = {}
	if FileAccess.file_exists(PREPARATION_BATTLE_PROFILE):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PREPARATION_BATTLE_PROFILE))
		if parsed is Dictionary: battle = parsed
	var profile_matches := String(battle.get("private_user_path", "")) == ProjectSettings.globalize_path("user://") \
		and String(battle.get("map_sha256", "")) == FileAccess.get_sha256("res://maps/trade_outpost.json") \
		and float(battle.get("scale", 0.0)) == 1.0
	_check(profile_matches, "Fresh inherited battle receipt matches this private profile, map and 1x scale")
	var shots := int(battle.get("shots", 0)) if profile_matches else 0
	_check(shots >= 8 and Engine.time_scale == 1.0, "Inherited B encounter fires at least eight actual shots at 1x")
	var file := FileAccess.open(PREPARATION_OUTPUT, FileAccess.WRITE)
	if _check(file != null, "Separate terrain preparation receipt opens"):
		file.store_string(JSON.stringify({"schema": "native_terrain_preparation_handoff_v1", "native_run": DisplayServer.get_name() != "headless",
			"memory_scope": "process static allocator + renderer-reported video memory; not total process RSS or physical dedicated VRAM",
			"preparation_static_memory_peak_bytes": _preparation_ram_peak, "preparation_renderer_video_peak_bytes": _preparation_video_peak,
			"observed_frames": _preparation_frames, "pending_frames": _preparation_pending_frames, "errors": _preparation_errors.keys(),
			"transitions": _preparation_transitions, "loading_screenshot": _preparation_screenshot_receipt,
			"mission_handoff": _preparation_handoff, "camera_receipts": _preparation_camera_receipts, "actual_shots": shots,
			"battle_receipt": {"path": PREPARATION_BATTLE_PROFILE, "fresh": profile_matches, "shot_count_source": "inherited maximum observed fire events",
				"private_user_path": battle.get("private_user_path", ""), "map_sha256": battle.get("map_sha256", ""), "scale": battle.get("scale", 0.0)},
			"scale": Engine.time_scale, "map_sha256": FileAccess.get_sha256("res://maps/trade_outpost.json")}, "\t"))
	await super._finish()
