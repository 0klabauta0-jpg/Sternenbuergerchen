extends "res://scripts/tests/runtime_hitches_r4_20261107_native_capture.gd"
## Unchanged normal performance window, then an additional real Move/GO toward
## an authored defense hex. Combat captures are not performance measurements.
const R4_CAMERA_VIEW: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const R4_MOVEMENT: GDScript = preload("res://scripts/tactical/fireteam_movement_controller.gd")

var _r4_mission_instance: int = 0
var _r4_contact_world: Vector2 = Vector2.ZERO
var _r4_visibility_rows: Array = []
var _r4_visibility_last: Dictionary = {}
var _r4_fire_probe_ran: bool = false
var _r4_mission_result: Dictionary = {}
var _r4_route_objective: Vector2 = Vector2.ZERO
var _r4_route_radius: float = 0.0
var _r4_route_path_checks: Dictionary = {}
var _r4_visual_originals: Dictionary = {}
var _r4_down_closeup: Dictionary = {}
var _r4_down_capture_attempted: bool = false

func _combat_only() -> bool:
	return _argument("--r4-combat-only", "false").to_lower() in ["true", "1", "yes"]

func _profile_normal_movement(view: Node) -> void:
	if _combat_only():
		_facts["r4_combat_only"] = {"enabled": true, "performance_measurement": false, "comparable_profile": false, "reason": "Separate fresh physical combat acceptance; no 90s prefix"}
		return
	await super._profile_normal_movement(view)

func _capture(id: String, view: Node = null, settle_frames: int = 8) -> void:
	if id == "06_go_movement" and _combat_only() and not _r4_fire_probe_ran:
		_r4_fire_probe_ran = true
		await _profile_normal_movement(view) # Explicit no-measurement scope above.
		if _check(is_instance_valid(view), "Fresh normal mission reaches the combat-only hook before overview encodings"):
			await _observe_actual_fire(view)
		return
	# Finish the normal 90s profile AND the complete parent 06/07/08/09
	# screenshot route before combat may naturally end the mission/view.
	await super._capture(id, view, settle_frames)
	if id != "06_go_movement" or _r4_fire_probe_ran:
		return
	_r4_fire_probe_ran = true
	if not _check(is_instance_valid(view), "Regular mission view survives the complete parent capture route before the additional combat probe"):
		return
	await _observe_actual_fire(view)

func _authored_mission_points(map_path: String, mission: Node) -> Dictionary:
	var points: Dictionary = super._authored_mission_points(map_path, mission)
	var terrain: Node = mission.get_node_or_null("TerrainRegistry")
	var target_grid := Vector2i(5, 15)
	if not _check(terrain != null and bool(terrain.call("is_walkable", target_grid)), "Current authored contact hex(5,15) remains walkable"):
		return {}
	_r4_contact_world = terrain.call("grid_to_world", target_grid)
	_r4_mission_instance = mission.get_instance_id()
	_facts["r4_contact_route"] = {"mission_instance_id": _r4_mission_instance, "map_path": map_path, "map_sha256": FileAccess.get_sha256(map_path), "target_grid": target_grid, "target_world": _r4_contact_world, "command_route": "existing selected-team Move then GO only after the unchanged measured window", "actor_writes": false, "creates_fire_event": false}
	return points

func _observe_actual_fire(view: Node) -> void:
	var mission: Node = view.get_parent()
	var controller: Node = mission.get_node_or_null("TacticalController")
	var simulation: Node = mission.get_node_or_null("SimulationRoot")
	var setup: Node = mission.get_node_or_null("MissionSetup")
	var registry: Node = mission.get_node_or_null("UnitRegistry")
	if not _check(DisplayServer.get_name() != "headless" and mission.get_instance_id() == _r4_mission_instance and controller != null and simulation != null and setup != null and registry != null, "Actual-fire diagnostic uses the same regular native mission owners"):
		return
	if not _check(view.has_method("get_weapon_fire_feedback_snapshot"), "Read-only transient-feedback diagnostic is available"):
		return
	var requested_size: float = clampf(float(_argument("--r4-fire-camera", "22")), 8.0, 60.0)
	view.call("zoom_camera", (float(view.call("get_camera_size")) - requested_size) / R4_CAMERA_VIEW.CAMERA_ZOOM_STEP)
	await _frames(3)
	if not _check(_context_alive(view, mission) and is_instance_valid(simulation) and is_instance_valid(controller), "Combat context survives camera settling before the additional real command"):
		return
	var capture_camera_size: float = float(view.call("get_camera_size"))
	_check(root.mode in [Window.MODE_FULLSCREEN, Window.MODE_EXCLUSIVE_FULLSCREEN] and DisplayServer.window_get_size() == _profile_screen_size, "Actual-fire images fill the physical fullscreen display")
	_check(is_equal_approx(Engine.time_scale, 1.0), "Actual-fire diagnostic observes real 1x simulation")
	var min_tick: int = int(simulation.call("get_tick"))
	var observed: Dictionary = {}
	for item in Array(controller.call("get_fire_event_snapshot")):
		observed[String(Dictionary(item).get("event_id", ""))] = true
	var combat: Node = mission.get_node_or_null("CombatLoopDriver")
	if not _check(combat != null and combat.has_signal("combat_resolved"), "The same mission exposes its public combat-resolution lifecycle signal"):
		return
	combat.connect("combat_resolved", Callable(self, "_record_r4_mission_result").bind(_r4_mission_instance), CONNECT_ONE_SHOT)
	var actors: Array = registry.call("get_all_units")
	for actor in actors:
		if is_instance_valid(actor) and actor.has_method("get_unit_id"):
			var actor_id: String = String(actor.call("get_unit_id"))
			_r4_visual_originals[actor_id] = _unit_visual_state(view, mission, actor_id, false)
	if not _choose_contact_route(mission, controller, simulation, actors):
		return
	if not _check(bool(controller.call("issue_right_click_command_for_test", _r4_contact_world, "move", false)) and bool(controller.call("execute_selected_fireteam_orders")), "Existing Move and GO send the original squad along the outside-objective contact side"):
		return
	var fresh_events: Array = []
	var candidate: Dictionary = {}
	var selected: Dictionary = {}
	var feedback: Dictionary = {}
	var started_msec: int = Time.get_ticks_msec()
	var end_msec: int = mini(_deadline, started_msec + roundi(clampf(float(_argument("--r4-fire-wait", "60")), 1.0, 90.0) * 1000.0))
	var visibility_sample_msec: int = 0
	while Time.get_ticks_msec() < end_msec and selected.is_empty():
		await process_frame
		if not _context_alive(view, mission) or not is_instance_valid(controller) or not is_instance_valid(simulation):
			break
		if mission.get_instance_id() != _r4_mission_instance:
			_check(false, "Actual-fire mission identity never changes during observation")
			break
		if Time.get_ticks_msec() - visibility_sample_msec >= 250:
			visibility_sample_msec = Time.get_ticks_msec()
			_capture_visibility_transitions(view, setup, actors, int(simulation.call("get_tick")))
			if not _observe_real_move_paths(simulation, registry):
				break
		for item in Array(controller.call("get_fire_event_snapshot")):
			var fire_event: Dictionary = Dictionary(item)
			var id: String = String(fire_event.get("event_id", ""))
			if observed.has(id) or int(fire_event.get("tick", -1)) <= min_tick:
				continue
			observed[id] = true
			fresh_events.append(fire_event.duplicate(true))
			if bool(view.call("_fow_allows_fire_event_visual", fire_event)):
				candidate[id] = fire_event.duplicate(true)
		feedback = view.call("get_weapon_fire_feedback_snapshot")
		for item in Array(feedback.get("entries", [])):
			var entry: Dictionary = Dictionary(item)
			var id: String = String(entry.get("event_id", ""))
			if candidate.has(id) and bool(entry.get("source_allowed", false)) and bool(entry.get("flash_visible", false)):
				selected = Dictionary(candidate[id])
				break
	var result: Dictionary = {"schema": "sternenbuergerchen.r4_actual_fire.v1", "display": _display_facts(), "mission_instance_id": _r4_mission_instance, "mission_view_alive_at_detection": _context_alive(view, mission), "tick_strictly_after": min_tick, "waited_msec": Time.get_ticks_msec() - started_msec, "camera_size": capture_camera_size, "fresh_authoritative_events": fresh_events, "selected_event": selected, "feedback_at_detection": feedback, "creates_fire_event": false, "actor_writes": false, "authority_writes": false, "sight_range_changes": false, "performance_measurement": false}
	if _check(not selected.is_empty(), "A fresh authoritative event produces an actual admitted live muzzle flash within the bounded normal mission window"):
		result["selected_target_at_detection"] = _unit_visual_state(view, mission, String(selected.get("target_unit_id", "")))
		result["temporal_samples"] = await _capture_live_shot(view, mission, selected)
		var tail_started_msec: int = Time.get_ticks_msec()
		var tail_end_msec: int = mini(_deadline, tail_started_msec + 10000)
		while Time.get_ticks_msec() < tail_end_msec and _context_alive(view, mission) and is_instance_valid(setup) and is_instance_valid(simulation):
			await create_timer(0.25).timeout
			if not _context_alive(view, mission) or not is_instance_valid(setup) or not is_instance_valid(simulation):
				break
			_capture_visibility_transitions(view, setup, actors, int(simulation.call("get_tick")))
			await _try_down_closeup(view, mission, String(selected.get("target_unit_id", "")))
		result["visibility_tail"] = {"duration_msec": Time.get_ticks_msec() - tail_started_msec, "requested_msec": 10000, "mission_view_alive_at_end": _context_alive(view, mission), "after_complete_90s_profile": not _combat_only(), "after_temporal_images": true, "combat_only": _combat_only(), "read_only": true, "issues_commands": false, "changes_actors_or_poses": false}
	else:
		result["reason"] = "No new admitted live flash observed; no synthetic fallback is accepted"
	var transition_count: int = 0
	for row in _r4_visibility_rows:
		if String(Dictionary(row).get("transition_kind", "")) == "changed":
			transition_count += 1
	result["visibility_transitions"] = _r4_visibility_rows.duplicate(true)
	result["visibility_transition_count"] = transition_count
	result["visibility_scope"] = "Actual target visibility transitions observed" if transition_count > 0 else "Only initial visibility states observed; no hide/show transition proved in this bounded window"
	result["mission_result_signal"] = _r4_mission_result.duplicate(true)
	result["actual_move_path_checks"] = _r4_route_path_checks.duplicate(true)
	if _r4_down_closeup.is_empty():
		_r4_down_closeup = {"available": false, "reason": "No real down/bleedout actor observed before this normal mission observation ended", "creates_down": false}
	result["down_closeup"] = _r4_down_closeup.duplicate(true)
	_facts["r4_actual_fire"] = result
	var path: String = _output.get_basename() + "_actual_fire.json"
	if _check(not FileAccess.file_exists(path), "Actual-fire evidence target is new"):
		var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
		if _check(file != null, "Actual-fire evidence opens"):
			file.store_string(JSON.stringify(result))
			file.close()
	print("R4_ACTUAL_FIRE_CAPTURE_DONE ", path)

func _choose_contact_route(mission: Node, controller: Node, simulation: Node, actors: Array) -> bool:
	var terrain: Node = mission.get_node_or_null("TerrainRegistry")
	var objective: Object = simulation.call("get_objective_status") as Object
	if not _check(terrain != null and objective != null, "Contact route reads the actual runtime objective and terrain owners"):
		return false
	_r4_route_objective = Vector2(objective.get("position"))
	_r4_route_radius = maxf(float(objective.get("capture_radius")), 0.0)
	var friendly_ids: Array = Array(_planning_snapshot(controller).get("deployed_unit_ids", []))
	var friendly_positions: Array[Vector2] = []
	for actor in actors:
		if is_instance_valid(actor) and actor is Node2D and friendly_ids.has(String(actor.call("get_unit_id"))):
			friendly_positions.append(actor.global_position)
	if not _check(not friendly_positions.is_empty(), "Outside-objective route uses the originally deployed operators"):
		return false
	# The normal Move formation uses this existing spacing. This is a route
	# clearance, never a change to gameplay capture radius, formation or actors.
	var clearance: float = R4_MOVEMENT.FORMATION_SLOT_SPACING
	var rejected: Array = []
	var route_facts: Dictionary = {"mission_instance_id": _r4_mission_instance, "objective_position": _r4_route_objective, "actual_capture_radius": _r4_route_radius, "capture_distance_metric": "SimulationRoot Euclidean world", "formation_route_clearance": clearance, "original_friendly_positions": friendly_positions, "rejected_candidates": rejected, "validated": false, "actor_writes": false, "gameplay_radius_changes": false, "combat_only": _combat_only()}
	_facts["r4_contact_route"] = route_facts
	for grid in [Vector2i(3, 17), Vector2i(2, 17), Vector2i(3, 18), Vector2i(2, 18), Vector2i(1, 18), Vector2i(1, 17), Vector2i(0, 18)]:
		var target: Vector2 = terrain.call("grid_to_world", grid)
		var clear: bool = bool(terrain.call("is_walkable", grid)) and target.distance_to(_r4_route_objective) > _r4_route_radius + clearance
		var minimum_distance: float = target.distance_to(_r4_route_objective)
		var blocked_cells: Array = []
		var reasons: Array = []
		if not bool(terrain.call("is_walkable", grid)):
			reasons.append("target_not_walkable")
		if target.distance_to(_r4_route_objective) <= _r4_route_radius + clearance:
			reasons.append("target_inside_capture_plus_formation_clearance")
		for position in friendly_positions:
			var from_grid: Vector2i = terrain.call("world_to_grid", position)
			var previous: Vector2 = position
			for cell in Array(terrain.call("get_grid_line", from_grid, grid)):
				var point: Vector2 = terrain.call("grid_to_world", cell)
				minimum_distance = minf(minimum_distance, _segment_objective_distance(previous, point))
				if not bool(terrain.call("is_walkable", cell)):
					blocked_cells.append({"original_position": position, "grid": cell, "start_grid": from_grid, "is_start_cell": cell == from_grid, "tile_exists": terrain.call("get_tile_at_grid", cell) != null})
				clear = clear and bool(terrain.call("is_walkable", cell)) and minimum_distance > _r4_route_radius + clearance
				previous = point
		if clear:
			_r4_contact_world = target
			route_facts.merge({"target_grid": grid, "target_world": target, "minimum_clear_hexline_distance": minimum_distance, "command_route": "ordinary Move/GO outside capture disk", "validated": true}, true)
			print("R4_CONTACT_ROUTE_PLAN ", JSON.stringify(route_facts))
			return _check(true, "An authored walkable contact side and clear approach remain outside the actual capture radius")
		if not blocked_cells.is_empty():
			reasons.append("blocked_or_missing_hexline_cell")
		if minimum_distance <= _r4_route_radius + clearance:
			reasons.append("approach_inside_capture_plus_formation_clearance")
		var rejected_candidate: Dictionary = {"grid": grid, "world": target, "minimum_distance": minimum_distance, "reasons": reasons, "blocked_cells": blocked_cells}
		rejected.append(rejected_candidate)
		print("R4_CONTACT_ROUTE_REJECTED ", JSON.stringify(rejected_candidate))
	print("R4_CONTACT_ROUTE_PLAN ", JSON.stringify(route_facts))
	return _check(false, "No validated outside-objective contact approach found; no forced combat or capture change")

func _segment_objective_distance(a: Vector2, b: Vector2) -> float:
	var segment: Vector2 = b - a
	var fraction: float = clampf((_r4_route_objective - a).dot(segment) / segment.length_squared(), 0.0, 1.0) if segment.length_squared() > 0.0001 else 0.0
	return (a + segment * fraction).distance_to(_r4_route_objective)

func _observe_real_move_paths(simulation: Node, registry: Node) -> bool:
	for item in Array(simulation.get("command_queue")):
		if not item is Dictionary:
			continue
		var command: Dictionary = Dictionary(item)
		var path: Array = Array(command.get("path", []))
		if path.is_empty():
			continue
		var id: String = String(command.get("unit_id", ""))
		var unit: Node2D = registry.call("get_unit", id) as Node2D
		if unit == null or String(unit.call("get_team_id")) != "team_alpha":
			continue
		var previous: Vector2 = unit.global_position
		var minimum: float = previous.distance_to(_r4_route_objective)
		for point in path:
			if typeof(point) != TYPE_VECTOR2:
				continue
			minimum = minf(minimum, _segment_objective_distance(previous, Vector2(point)))
			previous = Vector2(point)
		_r4_route_path_checks[id] = {"minimum_actual_path_distance": minimum, "capture_radius": _r4_route_radius, "point_count": path.size(), "read_only": true}
		if minimum <= _r4_route_radius:
			return _check(false, "Actual ordinary movement path enters capture disk; route evidence rejected without actor changes")
	return true

func _context_alive(view: Variant, mission: Variant) -> bool:
	return is_instance_valid(view) and is_instance_valid(mission) and view.is_inside_tree() and mission.is_inside_tree()

func _record_r4_mission_result(result: Dictionary, mission_instance_id: int) -> void:
	if mission_instance_id != _r4_mission_instance:
		return
	_r4_mission_result = _keep(result, ["result", "winning_team_id", "win_condition_type", "objective_captured", "duration_seconds"])
	_r4_mission_result["mission_instance_id"] = mission_instance_id
	_r4_mission_result["observed_wall_msec"] = Time.get_ticks_msec()
	_r4_mission_result["read_only_signal_observer"] = true
	print("R4_ACTUAL_MISSION_RESOLVED ", JSON.stringify(_r4_mission_result))

func _capture_live_shot(view: Node, mission: Node, shot: Dictionary) -> Array:
	var source_position: Vector2 = Vector2(shot.get("attacker_position", Vector2.ZERO))
	var target_position: Vector2 = Vector2(shot.get("target_position", source_position))
	view.call("focus_world_position", (source_position + target_position) * 0.5)
	var detected_usec: int = Time.get_ticks_usec()
	var samples: Array = []
	var live_flash_frames: int = 0
	for delay_msec in [0, 120, 900]:
		while Time.get_ticks_usec() - detected_usec < int(delay_msec) * 1000:
			await process_frame
		await RenderingServer.frame_post_draw
		var alive: bool = _context_alive(view, mission)
		var feedback: Dictionary = view.call("get_weapon_fire_feedback_snapshot") if alive else {}
		var same_shot_flash: bool = false
		for item in Array(feedback.get("entries", [])):
			var entry: Dictionary = Dictionary(item)
			if String(entry.get("event_id", "")) == String(shot.get("event_id", "")) and bool(entry.get("flash_visible", false)):
				same_shot_flash = true
		if delay_msec <= 120 and alive and same_shot_flash:
			live_flash_frames += 1
		samples.append({"requested_delay_msec": delay_msec, "actual_delay_usec": Time.get_ticks_usec() - detected_usec, "mission_view_alive": alive, "context_closed": not alive, "current_scene": current_scene.scene_file_path if is_instance_valid(current_scene) else "", "same_shot_flash_visible": same_shot_flash, "feedback": feedback, "selected_target": _unit_visual_state(view, mission, String(shot.get("target_unit_id", ""))), "image": root.get_texture().get_image()})
	_check(live_flash_frames > 0, "At least one 0/120ms native frame retains the same real live shot and mission view")
	# Take any genuine down close-up immediately after the 900ms readback,
	# before encoding can consume its short natural presentation window.
	await _try_down_closeup(view, mission, String(shot.get("target_unit_id", "")))
	# Encode after all native readbacks, preserving the short observation gap.
	for sample in samples:
		var path: String = _capture_root + "r4_actual_fire_%03dms.png" % int(sample.requested_delay_msec)
		var frame: Image = sample.image as Image
		var error: Error = ERR_ALREADY_EXISTS if FileAccess.file_exists(path) else frame.save_png(path)
		_check(error == OK, "Native real-shot temporal image saved at " + str(sample.requested_delay_msec) + "ms")
		sample.erase("image")
		sample["path"] = path
		sample["event_id"] = String(shot.get("event_id", ""))
		sample["sha256"] = FileAccess.get_sha256(path) if error == OK else ""
		sample["width"] = frame.get_width()
		sample["height"] = frame.get_height()
	return samples

func _unit_visual_state(view: Variant, mission: Variant, id: String, geometry: bool = true) -> Dictionary:
	if not _context_alive(view, mission):
		return {"unit_id": id, "available": false, "reason": "mission_view_context_closed"}
	var registry: Node = mission.get_node_or_null("UnitRegistry")
	var unit_value: Variant = registry.call("get_unit", id) if registry != null else null
	var unit: Node2D = unit_value as Node2D if is_instance_valid(unit_value) else null
	var proxy_value: Variant = Dictionary(view.get("_unit_proxies_by_id")).get(id)
	var proxy: Node3D = proxy_value as Node3D if is_instance_valid(proxy_value) else null
	var runtime: Dictionary = Dictionary(Dictionary(view.get("_unit_proxy_runtime_by_id")).get(id, {}))
	var model: Variant = runtime.get("model_root")
	if not is_instance_valid(model) and is_instance_valid(proxy):
		model = view.call("_find_unit_model_root", proxy)
	var core: Node3D = proxy.get_node_or_null("UnitBodyReadabilityCore") as Node3D if is_instance_valid(proxy) else null
	var original: Dictionary = Dictionary(_r4_visual_originals.get(id, {}))
	var result: Dictionary = {"unit_id": id, "available": unit != null, "unit_instance_id": unit.get_instance_id() if unit != null else 0, "vital": unit.call("get_vital_state") if unit != null else "unavailable", "hp": unit.call("get_health") if unit != null else -1, "unit_world_position": unit.global_position if unit != null else Vector2.ZERO, "unit_visible": unit.visible if unit != null else false, "proxy_instance_id": proxy.get_instance_id() if is_instance_valid(proxy) else 0, "proxy_visible": proxy.is_visible_in_tree() if is_instance_valid(proxy) else false, "proxy_global_position": proxy.global_position if is_instance_valid(proxy) else Vector3.ZERO, "model_instance_id": model.get_instance_id() if is_instance_valid(model) else 0, "model_visible": model.is_visible_in_tree() if is_instance_valid(model) else false, "model_local_transform": model.transform if is_instance_valid(model) else Transform3D.IDENTITY, "model_global_transform": model.global_transform if is_instance_valid(model) else Transform3D.IDENTITY, "model_rotation_degrees": model.rotation_degrees if is_instance_valid(model) else Vector3.ZERO, "body_core_exists": core != null, "body_core_visible": core.is_visible_in_tree() if core != null else false, "original_proxy_instance_id": original.get("proxy_instance_id", 0), "original_model_instance_id": original.get("model_instance_id", 0), "read_only": true, "sets_vital_hp_pose_or_position": false}
	if is_instance_valid(proxy):
		result["down_pose_active_meta"] = proxy.get_meta("unit_down_pose_active", false)
		result["body_visual_kind"] = proxy.get_meta("unit_body_visual_kind", "")
		result["animated_model"] = proxy.get_meta("uses_animated_character_model", false)
	if unit != null:
		result["ground_surface_position"] = view.call("_world_to_surface_3d_position", unit.global_position, 0.0)
		result["fow_target_visible"] = view.call("_fow_is_target_currently_visible", id)
		result["fow_tile_visible"] = view.call("_fow_is_world_position_currently_visible", unit.global_position)
	if geometry and is_instance_valid(model):
		result["mesh_bounds_estimate_in_proxy_space"] = view.call("_get_local_visual_bounds", model)
		result["mesh_bounds_scope"] = "Static mesh AABBs, not skinned pixel/ground acceptance"
	return result

func _try_down_closeup(view: Variant, mission: Variant, preferred_id: String) -> void:
	if _r4_down_capture_attempted or not _context_alive(view, mission):
		return
	var ids: Array = [preferred_id]
	for id in _r4_visual_originals:
		if String(id) != preferred_id:
			ids.append(String(id))
	for id_variant in ids:
		var id: String = String(id_variant)
		var before: Dictionary = _unit_visual_state(view, mission, id, false)
		if not ["down", "bleedout"].has(String(before.get("vital", ""))):
			continue
		before = _unit_visual_state(view, mission, id)
		_r4_down_capture_attempted = true
		var original_size: float = float(view.call("get_camera_size"))
		var original_focus: Vector2 = view.call("get_camera_focus_grid_position")
		var original_yaw: float = float(view.call("get_camera_yaw_degrees"))
		view.call("zoom_camera", (original_size - 8.0) / R4_CAMERA_VIEW.CAMERA_ZOOM_STEP)
		view.call("focus_world_position", Vector2(before.unit_world_position))
		await process_frame
		if not _context_alive(view, mission):
			_r4_down_closeup = {"available": false, "reason": "Real down observed, mission closed during camera settling", "before": before, "creates_down": false}
			return
		await RenderingServer.frame_post_draw
		var alive: bool = _context_alive(view, mission)
		var after: Dictionary = _unit_visual_state(view, mission, id)
		var frame: Image = root.get_texture().get_image()
		var closeup_camera: Dictionary = _camera_facts(view) if alive else {}
		var side_frame: Image = null
		var side: Dictionary = {"available": false, "reason": "Real down context ended before the camera-only side view", "yaw_delta_degrees": 90.0, "lying_pixel_acceptance": "unreviewed"}
		if alive and ["down", "bleedout"].has(String(after.get("vital", ""))):
			var side_before: Dictionary = _unit_visual_state(view, mission, id)
			view.call("rotate_camera", 90.0)
			await process_frame
			if _context_alive(view, mission):
				await RenderingServer.frame_post_draw
				var side_alive: bool = _context_alive(view, mission)
				var side_after: Dictionary = _unit_visual_state(view, mission, id)
				side_frame = root.get_texture().get_image()
				var side_available: bool = side_alive and ["down", "bleedout"].has(String(side_after.get("vital", ""))) and int(side_after.get("unit_instance_id", -1)) == int(side_before.get("unit_instance_id", 0)) and int(side_after.get("model_instance_id", -1)) == int(side_before.get("model_instance_id", 0))
				side = {"available": side_available, "reason": "Same genuine down actor at yaw+90; pixel review pending" if side_available else "Real down state or original model context ended before side readback", "before": side_before, "after": side_after, "yaw_delta_degrees": 90.0, "camera": _camera_facts(view) if side_alive else {}, "readback_usec": Time.get_ticks_usec(), "same_original_model": int(side_after.get("model_instance_id", -1)) == int(before.get("original_model_instance_id", 0)) and int(before.get("original_model_instance_id", 0)) != 0, "lying_pixel_acceptance": "unreviewed"}
		# Both native readbacks precede PNG encoding; restore only the camera.
		if _context_alive(view, mission):
			view.call("rotate_camera", original_yaw - float(view.call("get_camera_yaw_degrees")))
			view.call("zoom_camera", (float(view.call("get_camera_size")) - original_size) / R4_CAMERA_VIEW.CAMERA_ZOOM_STEP)
			view.call("focus_world_position", view.call("_grid_float_to_world", original_focus))
			await process_frame
		if side_frame != null:
			var side_path: String = _capture_root + "r4_actual_down_side_90.png"
			var side_saved: Error = ERR_ALREADY_EXISTS if FileAccess.file_exists(side_path) else side_frame.save_png(side_path)
			_check(side_saved == OK, "Camera-only yaw+90 native down readback is saved after both readbacks")
			side.merge({"path": side_path, "sha256": FileAccess.get_sha256(side_path) if side_saved == OK else "", "width": side_frame.get_width(), "height": side_frame.get_height()}, true)
		var path: String = _capture_root + "r4_actual_down_closeup.png"
		var saved: Error = ERR_ALREADY_EXISTS if FileAccess.file_exists(path) else frame.save_png(path)
		_check(saved == OK, "Native close-up of a genuinely down/bleedout original actor is saved without creating that state")
		var available: bool = alive and ["down", "bleedout"].has(String(after.get("vital", "")))
		_r4_down_closeup = {"available": available, "reason": "Real down/bleedout context captured; pixel review pending" if available else "Mission context closed or genuine down state ended before readback", "unit_id": id, "path": path, "sha256": FileAccess.get_sha256(path) if saved == OK else "", "width": frame.get_width(), "height": frame.get_height(), "before": before, "after": after, "same_original_model": int(after.get("model_instance_id", -1)) == int(before.get("original_model_instance_id", 0)) and int(before.get("original_model_instance_id", 0)) != 0, "camera_only": true, "closeup_camera": closeup_camera, "side_view": side, "camera_restored": _camera_facts(view) if _context_alive(view, mission) else {}, "creates_down": false, "changes_actor_hp_pose_position_or_timers": false, "lying_pixel_acceptance": "unreviewed"}
		print("R4_ACTUAL_DOWN_CLOSEUP ", JSON.stringify(_r4_down_closeup))
		return

func _capture_visibility_transitions(view: Node, setup: Node, actors: Array, tick: int) -> void:
	var terrain: Node = setup.get("_fog_terrain_registry") as Node
	var los: RefCounted = setup.get("_fog_of_war_los_system") as RefCounted
	var observers: Array = setup.call("_get_active_fog_observers")
	var viewer_team: String = String(setup.call("_get_fog_viewer_team_id"))
	var proxies: Dictionary = Dictionary(view.get("_unit_proxies_by_id"))
	for actor in actors:
		if not is_instance_valid(actor) or not (actor is Node2D) or String(actor.call("get_team_id")) == viewer_team:
			continue
		var id: String = String(actor.call("get_unit_id"))
		var proxy: Node3D = proxies.get(id) as Node3D
		var state: Dictionary = {"actor_visible": actor.visible, "target_visible": view.call("_fow_is_target_currently_visible", id), "tile_visible": view.call("_fow_is_world_position_currently_visible", actor.global_position), "proxy_visible": proxy != null and proxy.is_visible_in_tree()}
		if _r4_visibility_last.get(id, {}) == state:
			continue
		var initial_state: bool = not _r4_visibility_last.has(id)
		_r4_visibility_last[id] = state.duplicate(true)
		var observer_rows: Array = []
		for observer in observers:
			var range_world: float = float(setup.call("_get_effective_fog_sight_range_world", observer))
			var distance_world: float = float(terrain.call("get_movement_distance", observer.global_position, actor.global_position))
			var blocked_cells: Array = []
			var from_grid: Vector2i = terrain.call("world_to_grid", observer.global_position)
			var to_grid: Vector2i = terrain.call("world_to_grid", actor.global_position)
			for cell in Array(terrain.call("get_grid_line", from_grid, to_grid)):
				if cell == from_grid or cell == to_grid:
					continue
				if bool(terrain.call("blocks_los_at_grid", cell)):
					blocked_cells.append({"grid": cell, "object_height": terrain.call("get_object_height_at_grid", cell)})
			observer_rows.append({"id": observer.call("get_unit_id"), "position": observer.global_position, "effective_range_world": range_world, "registry_distance_world": distance_world, "line_of_sight": los.call("has_line_of_sight_between_points", observer.global_position, actor.global_position, range_world, terrain), "candidate_blocker_cells": blocked_cells})
		_r4_visibility_rows.append({"wall_msec": Time.get_ticks_msec(), "tick": tick, "target_id": id, "target_position": actor.global_position, "transition_kind": "initial" if initial_state else "changed", "state": state, "active_observers": observer_rows})
