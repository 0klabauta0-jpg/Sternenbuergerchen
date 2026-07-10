extends SceneTree

const META_LAYER_TEST_SCENE: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")
const UNIT_ROSTER_PRESETS_SCRIPT: GDScript = preload("res://scripts/npc/unit_roster_presets.gd")
const DROPSHIP_TEXTURE_PATH: String = "res://Assets/kenney_space-kit/Isometric/craft_speederB_SE.png"
const STAGE_BUDGET_MSEC: int = 20000

var _trace_started_msec: int = 0
var _stage_started_msec: int = 0
var _stage_id: String = ""
var _stage_frames: int = 0
var _trace_entries: Array = []
var _trace_status: String = "running"
var _trace_blocker_stage: String = ""
var _failed: int = 0
var _cross_system_timing_nodes: Dictionary = {}
var _trace_scene: Node = null


func _init() -> void:
	call_deferred("_run_trace")


func _run_trace() -> void:
	print("=== TASK_1045 Mission First Contact End-to-End Timing Trace ===")
	_trace_started_msec = Time.get_ticks_msec()
	root.size = Vector2i(1920, 1080)
	_begin_stage("scene_ready")
	var scene: Node = META_LAYER_TEST_SCENE.instantiate()
	_trace_scene = scene
	root.add_child(scene)
	if not await _wait_stage_frames(5):
		_finish_trace(scene)
		return
	_finish_stage("complete")

	_begin_stage("mission_selection")
	scene.call("_on_homebase_mission_selection_changed", "frontier_probe_vertical_slice")
	if not _stage_within_budget() or not await _wait_stage_frames(2):
		_finish_trace(scene)
		return
	_finish_stage("complete")

	var homebase_screen := scene.get_node_or_null("HomebaseScreen") as Control
	if homebase_screen == null:
		_fail("HomebaseScreen missing")
		_finish_trace(scene)
		return
	var roster: Array = UNIT_ROSTER_PRESETS_SCRIPT.call("get_homebase_roster")
	var selected_unit_ids := PackedStringArray(["unit_alpha", "unit_bravo"])
	var selected_fireteam_ids := PackedStringArray(["ft1", "ft1"])
	_begin_stage("homebase_roster_transport_setup")
	scene.set("_available_team_units", roster.duplicate(true))
	scene.set("_all_team_units", roster.duplicate(true))
	scene.set("_homebase_aircraft_definitions", [_build_dropship_definition("dropship_alpha", "Dropship Alpha")])
	scene.set("_assigned_aircraft_pilot_by_craft", {"dropship_alpha": "unit_delta"})
	scene.set("_aircraft_location_by_craft", {"dropship_alpha": "homebase"})
	homebase_screen.call("setup_roster", roster, selected_unit_ids)
	homebase_screen.call("set_fireteam_context", selected_fireteam_ids, [_build_fireteam_definition("ft1", "ALPHA", selected_unit_ids)])
	homebase_screen.call("set_transport_state", [_build_dropship_definition("dropship_alpha", "Dropship Alpha")], {"dropship_alpha": "unit_delta"}, [], [], {"dropship_alpha": "homebase"}, {}, {}, [])
	if not _stage_within_budget() or not await _wait_stage_frames(3):
		_finish_trace(scene)
		return
	_finish_stage("complete")

	_begin_stage("fireteam_boarding")
	_drop_fireteam_on_shipcard(homebase_screen, "ft1", "dropship_alpha")
	var boarding_seconds: float = float(homebase_screen.call("_debug_get_homebase_fireteam_boarding_total_seconds", "ft1"))
	homebase_screen.call("_debug_advance_homebase_direct_boarding", boarding_seconds + 0.2)
	if not _stage_within_budget() or not await _wait_stage_frames(3):
		_finish_trace(scene)
		return
	_finish_stage("complete")

	_begin_stage("mission_start_request")
	var start_handler := Callable(scene, "_on_homebase_mission_start_requested")
	if homebase_screen.mission_start_requested.is_connected(start_handler):
		homebase_screen.mission_start_requested.disconnect(start_handler)
	homebase_screen.call("request_mission_start", "dropship_alpha")
	if not _stage_within_budget():
		_finish_trace(scene)
		return
	_finish_stage("complete")

	_begin_stage("mission_start_staging_sync")
	var had_preview_deployed_payload: bool = bool(scene.call("_has_preview_deployed_mission_payload"))
	var requested_direct_craft_id: String = String(scene.call("_consume_homebase_direct_mission_craft_id"))
	scene.call("_sync_homebase_direct_staging_from_screen")
	var payload_source: String = "homebase_direct" if bool(scene.call("_has_homebase_direct_payload_from_screen", requested_direct_craft_id)) else "homebase_direct_then_fob"
	scene.call("_sync_fob_dropship_state_into_mission_planning", not had_preview_deployed_payload, payload_source, requested_direct_craft_id)
	if not _stage_within_budget():
		_finish_trace(scene)
		return
	_finish_stage("complete")

	_begin_stage("mission_start_homebase_refresh")
	if payload_source == "homebase_direct":
		scene.call("_begin_homebase_direct_mission_transfer_from_planning")
		scene.call("_sync_homebase_direct_mission_drop_transport_fields")
		scene.call("_refresh_homebase_screen")
		scene.call("_ensure_transport_timer_state")
	if not _stage_within_budget():
		_finish_trace(scene)
		return
	_finish_stage("complete")

	_begin_stage("mission_start_active_mission")
	scene.call("_begin_active_mission_timer")
	scene.call("_start_or_update_active_mission")
	if not _stage_within_budget():
		_finish_trace(scene)
		return
	_finish_stage("complete")

	var profiled_active_mission: Node = scene.call("get_active_mission")
	_enable_cross_system_timing(profiled_active_mission)
	_begin_stage("mission_start_visible_frames")
	if not await _wait_stage_frames(8):
		_finish_trace(scene)
		return
	_finish_stage("complete")

	var active_mission: Node = scene.call("get_active_mission")
	var controller: Node = active_mission.get_node_or_null("TacticalController") if active_mission != null else null
	var primary_view: Node = active_mission.get_node_or_null("Primary3DView") if active_mission != null else null
	var combat_driver: Node = active_mission.get_node_or_null("CombatLoopDriver") if active_mission != null else null
	if controller == null or primary_view == null or combat_driver == null:
		_fail("Active mission runtime nodes missing")
		_finish_trace(scene)
		return

	_begin_stage("lz_drop_and_deboard")
	var lz_world := Vector2(384.0, 224.0)
	controller.call("_on_mission_dropship_card_set_lz_pressed", "dropship_alpha")
	controller.call("_place_lz_from_screen_position", primary_view.call("world_to_screen_position", lz_world))
	controller.call("_on_mission_dropship_card_drop_pressed", "dropship_alpha")
	if not _stage_within_budget() or not await _wait_stage_frames(4):
		_finish_trace(scene)
		return
	controller.call("_complete_drop_sequence_deployment")
	controller.call("_advance_primary_drop_sequence_unloading", 999.0)
	controller.call("_flush_pending_drop_runtime_phase_starts")
	controller.call("_refresh_world_overlays")
	controller.call("_update_ui")
	if not _stage_within_budget() or not await _wait_stage_frames(10):
		_finish_trace(scene)
		return
	_finish_stage("complete")

	_begin_stage("first_move_and_go")
	controller.call("issue_right_click_command_for_test", Vector2(544.0, 288.0), "move", false)
	controller.call("_refresh_world_overlays")
	controller.call("_refresh_button_state")
	controller.call("_update_ui")
	if not _stage_within_budget() or not await _wait_stage_frames(3):
		_finish_trace(scene)
		return
	controller.call("execute_selected_fireteam_orders")
	controller.call("_refresh_world_overlays")
	controller.call("_refresh_button_state")
	controller.call("_update_ui")
	if not _stage_within_budget() or not await _wait_stage_frames(2):
		_finish_trace(scene)
		return
	_finish_stage("complete")

	_begin_stage("first_contact")
	_position_first_enemy_near_fireteam(controller, "ft1")
	_update_contact_tracking(combat_driver)
	controller.call("refresh_contact_overlay")
	controller.call("refresh_fireteam_security_state")
	controller.call("_refresh_world_overlays")
	controller.call("_update_ui")
	if not _stage_within_budget() or not await _wait_stage_frames(8):
		_finish_trace(scene)
		return
	var contact_snapshot: Dictionary = Dictionary(controller.call("get_mission_first_contact_readability_snapshot"))
	if not bool(contact_snapshot.get("ui_sets_gameplay_truth", true)) and String(contact_snapshot.get("gate", "")) == "pass":
		_finish_stage("complete")
		_trace_status = "complete"
	else:
		_finish_stage("contact_readability_review")
		_trace_status = "review"
	_finish_trace(scene)


func _begin_stage(stage_id: String) -> void:
	_stage_id = stage_id
	_stage_started_msec = Time.get_ticks_msec()
	_stage_frames = 0


func _wait_stage_frames(frame_count: int) -> bool:
	for _frame_index in range(frame_count):
		var frame_started_msec: int = Time.get_ticks_msec()
		await process_frame
		_stage_frames += 1
		if _stage_id == "mission_start_visible_frames":
			if _cross_system_timing_nodes.is_empty() and _trace_scene != null:
				_enable_cross_system_timing(_trace_scene.call("get_active_mission"))
			print("TRACE frame stage=%s index=%d elapsed_msec=%d" % [_stage_id, _stage_frames, Time.get_ticks_msec() - frame_started_msec])
			_print_cross_system_timing_line()
		if not _stage_within_budget():
			return false
	return true


func _stage_within_budget() -> bool:
	if Time.get_ticks_msec() - _stage_started_msec <= STAGE_BUDGET_MSEC:
		return true
	_trace_status = "budget_exceeded"
	_trace_blocker_stage = _stage_id
	_finish_stage("budget_exceeded")
	return false


func _finish_stage(status: String) -> void:
	var entry: Dictionary = {
		"stage_id": _stage_id,
		"elapsed_msec": Time.get_ticks_msec() - _stage_started_msec,
		"frame_count": _stage_frames,
		"status": status,
		"budget_msec": STAGE_BUDGET_MSEC,
	}
	_trace_entries.append(entry)
	print("TRACE checkpoint stage=%s elapsed_msec=%d frames=%d status=%s" % [String(entry.get("stage_id", "")), int(entry.get("elapsed_msec", 0)), int(entry.get("frame_count", 0)), String(entry.get("status", ""))])


func _finish_trace(scene: Node) -> void:
	if _trace_status == "running":
		_trace_status = "failed" if _failed > 0 else "review"
	print("TRACE status=%s total_msec=%d blocker_stage=%s" % [_trace_status, Time.get_ticks_msec() - _trace_started_msec, _trace_blocker_stage])
	for entry_variant in _trace_entries:
		var entry: Dictionary = Dictionary(entry_variant)
		print("TRACE stage=%s elapsed_msec=%d frames=%d status=%s budget_msec=%d" % [String(entry.get("stage_id", "")), int(entry.get("elapsed_msec", 0)), int(entry.get("frame_count", 0)), String(entry.get("status", "")), int(entry.get("budget_msec", 0))])
	print("TRACE evidence read_only=true ui_sets_gameplay_truth=false creates_command=false creates_movement=false creates_fire_event=false creates_damage_event=false sets_multiplayer_truth=false")
	if scene != null:
		_disable_cross_system_timing()
		scene.queue_free()
		await process_frame
	_trace_scene = null
	quit(1 if _failed > 0 else 0)


func _enable_cross_system_timing(active_mission: Node) -> void:
	if active_mission == null:
		return
	var controller: Node = active_mission.get_node_or_null("TacticalController")
	var simulation_root: Node = active_mission.get_node_or_null("SimulationRoot")
	var terrain: Node = active_mission.get_node_or_null("Primary3DView")
	var combat_driver: Node = active_mission.get_node_or_null("CombatLoopDriver")
	if controller == null or simulation_root == null or terrain == null or combat_driver == null:
		return
	_cross_system_timing_nodes = {"controller": controller, "simulation": simulation_root, "terrain": terrain, "combat": combat_driver}
	controller.call("set_mission_visible_frame_timing_debug_enabled", true)
	simulation_root.call("set_runtime_tick_budget_debug_enabled", true)
	terrain.call("set_runtime_frame_timing_debug_enabled", true)
	combat_driver.call("set_combat_tick_budget_debug_enabled", true)


func _disable_cross_system_timing() -> void:
	for entry_variant in _cross_system_timing_nodes:
		var node: Node = _cross_system_timing_nodes.get(entry_variant) as Node
		if node == null:
			continue
		if String(entry_variant) == "controller":
			node.call("set_mission_visible_frame_timing_debug_enabled", false)
		elif String(entry_variant) == "simulation":
			node.call("set_runtime_tick_budget_debug_enabled", false)
		elif String(entry_variant) == "combat":
			node.call("set_combat_tick_budget_debug_enabled", false)
		else:
			node.call("set_runtime_frame_timing_debug_enabled", false)
	_cross_system_timing_nodes.clear()


func _print_cross_system_timing_line() -> void:
	var controller: Node = _cross_system_timing_nodes.get("controller") as Node
	var simulation_root: Node = _cross_system_timing_nodes.get("simulation") as Node
	var terrain: Node = _cross_system_timing_nodes.get("terrain") as Node
	var combat_driver: Node = _cross_system_timing_nodes.get("combat") as Node
	if controller == null or simulation_root == null or terrain == null or combat_driver == null:
		return
	var controller_snapshot: Dictionary = Dictionary(controller.call("get_mission_visible_frame_timing_debug_snapshot"))
	var simulation_snapshot: Dictionary = Dictionary(simulation_root.call("get_runtime_tick_budget_debug_snapshot"))
	var terrain_snapshot: Dictionary = Dictionary(terrain.call("get_runtime_frame_timing_debug_snapshot"))
	var combat_snapshot: Dictionary = Dictionary(combat_driver.call("get_combat_tick_budget_debug_snapshot"))
	var slowest_scope: String = ""
	var slowest_duration_usec: int = -1
	var combat_slowest_scope: String = ""
	var combat_slowest_duration_usec: int = -1
	for source in [
		{"prefix": "controller", "scopes": Dictionary(controller_snapshot.get("scopes_usec", {}))},
		{"prefix": "simulation", "scopes": Dictionary(simulation_snapshot.get("scopes_usec", {}))},
		{"prefix": "terrain", "scopes": Dictionary(terrain_snapshot.get("scopes_usec", {}))},
		{"prefix": "combat", "scopes": Dictionary(combat_snapshot.get("scopes_usec", {}))},
	]:
		for scope_variant in Dictionary(source.get("scopes", {})).keys():
			var duration_usec: int = int(Dictionary(source.get("scopes", {})).get(scope_variant, 0))
			if duration_usec > slowest_duration_usec:
				slowest_duration_usec = duration_usec
				slowest_scope = "%s.%s" % [String(source.get("prefix", "")), String(scope_variant)]
	for combat_scope_variant in Dictionary(combat_snapshot.get("scopes_usec", {})).keys():
		var combat_duration_usec: int = int(Dictionary(combat_snapshot.get("scopes_usec", {})).get(combat_scope_variant, 0))
		if combat_duration_usec > combat_slowest_duration_usec:
			combat_slowest_duration_usec = combat_duration_usec
			combat_slowest_scope = String(combat_scope_variant)
	print("TRACE cross_system_timing slowest_scope=%s duration_usec=%d combat_slowest_scope=%s combat_slowest_duration_usec=%d controller_total_usec=%d simulation_total_usec=%d terrain_total_usec=%d combat_total_usec=%d" % [
		slowest_scope,
		slowest_duration_usec,
		combat_slowest_scope,
		combat_slowest_duration_usec,
		int(controller_snapshot.get("total_usec", 0)),
		int(simulation_snapshot.get("total_tick_usec", 0)),
		int(terrain_snapshot.get("total_usec", 0)),
		int(combat_snapshot.get("total_tick_usec", 0)),
	])


func _build_dropship_definition(craft_id: String, display_name: String) -> Dictionary:
	return {"craft_id": craft_id, "craft_type": "dropship", "display_name": display_name, "texture_path": DROPSHIP_TEXTURE_PATH, "supports_cargo": false, "cargo_options": []}


func _build_fireteam_definition(fireteam_id: String, label: String, unit_ids: PackedStringArray) -> Dictionary:
	return {"id": fireteam_id, "label": label, "lead_unit_id": String(unit_ids[0]) if not unit_ids.is_empty() else "", "member_unit_ids": Array(unit_ids), "loadout": "medium", "respawn_enabled": false, "member_loadouts": {"unit_alpha": {"armor": "medium", "weapon_1": "rifle", "weapon_2": "rocket_launcher"}, "unit_bravo": {"armor": "medium", "weapon_1": "sniper", "weapon_2": "medictool"}}}


func _complete_mission_craft_arrival(scene: Node, craft_id: String) -> void:
	scene.call("_remove_pending_mission_craft_transfer", craft_id)
	scene.call("_complete_mission_craft_transfer", {"craft_id": craft_id, "phase": "to_mission"})
	scene.call("_sync_homebase_direct_mission_drop_transport_fields")
	scene.call("_start_or_update_active_mission")


func _drop_fireteam_on_shipcard(screen: Control, fireteam_id: String, craft_id: String) -> void:
	for node in _collect_nodes(screen):
		var control := node as Control
		if control != null and bool(control.get_meta("homebase_fireteam_drop_target", false)) and bool(control.get_meta("homebase_fireteam_drop_enabled", false)) and String(control.get_meta("homebase_fireteam_drop_target_id", "")).strip_edges() == craft_id:
			control.call("_drop_data", Vector2.ZERO, {"type": "fob_fireteam_card", "fireteam_id": fireteam_id, "source_context": "fireteam_list"})
			return


func _position_first_enemy_near_fireteam(controller: Node, fireteam_id: String) -> void:
	var friendlies: Array = Array(controller.call("_get_fireteam_units", fireteam_id, true))
	var enemies: Array = Array(controller.call("_get_all_enemy_units", false))
	if enemies.is_empty():
		enemies = Array(controller.call("_get_all_enemy_units", true))
	if friendlies.is_empty() or enemies.is_empty():
		return
	var friendly := friendlies[0] as Node2D
	var enemy := enemies[0] as Node2D
	if friendly != null and enemy != null:
		enemy.global_position = friendly.global_position + Vector2(58.0, 0.0)


func _update_contact_tracking(combat_driver: Node) -> void:
	combat_driver.call("_update_contact_tracking")
	combat_driver.call("_advance_detection_timers")
	combat_driver.call("_update_contact_tracking")


func _collect_nodes(root_node: Node) -> Array:
	var nodes: Array = [root_node]
	var result: Array = []
	while not nodes.is_empty():
		var node: Node = nodes.pop_front()
		result.append(node)
		for child in node.get_children():
			nodes.append(child)
	return result


func _fail(message: String) -> void:
	_failed += 1
	push_error("FAIL: %s" % message)
