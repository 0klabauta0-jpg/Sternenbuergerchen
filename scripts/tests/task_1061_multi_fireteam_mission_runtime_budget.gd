extends SceneTree

const META_LAYER_TEST_SCENE: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")
const UNIT_ROSTER_PRESETS_SCRIPT: GDScript = preload("res://scripts/npc/unit_roster_presets.gd")

const DROPSHIP_TEXTURE_PATH := "res://Assets/kenney_space-kit/Isometric/craft_speederB_SE.png"

var _passed := 0
var _failed := 0
var _timing_nodes: Dictionary = {}
var _stages: Array = []


func _init() -> void:
	call_deferred("_run_trace")


func _run_trace() -> void:
	print("=== TASK_1061 Multi-Fireteam Mission Runtime Budget ===")
	await _trace_two_fireteam_player_path()
	_print_summary()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _trace_two_fireteam_player_path() -> void:
	root.size = Vector2i(1920, 1080)
	var started_msec := Time.get_ticks_msec()
	var scene: Node = await _build_two_dropship_meta_scene()
	_mark_stage("scene_and_two_team_setup", started_msec)
	var homebase := scene.get_node_or_null("HomebaseScreen") as Control
	_assert(homebase != null, "Two-Fireteam runtime fixture exposes Homebase")
	if homebase == null:
		await _cleanup(scene)
		return

	started_msec = Time.get_ticks_msec()
	homebase.call("_on_homebase_shipcard_fireteam_dropped", "ft1", "dropship_alpha")
	await _finish_boarding(homebase, "ft1")
	homebase.call("request_mission_start", "dropship_alpha")
	await _wait_frames(8)
	homebase.call("_on_homebase_shipcard_fireteam_dropped", "ft2", "dropship_beta")
	await _finish_boarding(homebase, "ft2")
	homebase.call("request_mission_start", "dropship_beta")
	await _wait_frames(8)
	await _finish_all_mission_transfers(scene)
	scene.call("_show_mission")
	await _wait_frames(6)
	_mark_stage("two_dropship_transfer_to_visible_mission", started_msec)

	var mission: Node = scene.call("get_active_mission")
	var controller: Node = mission.get_node_or_null("TacticalController") if mission != null else null
	var combat_driver: Node = mission.get_node_or_null("CombatLoopDriver") if mission != null else null
	var primary_view: Node = mission.get_node_or_null("Primary3DView") if mission != null else null
	var simulation_root: Node = mission.get_node_or_null("SimulationRoot") if mission != null else null
	_assert(controller != null and combat_driver != null and primary_view != null and simulation_root != null, "Mission exposes all runtime timing surfaces")
	if controller == null or combat_driver == null or primary_view == null or simulation_root == null:
		await _cleanup(scene)
		return
	_enable_timing(controller, simulation_root, primary_view, combat_driver)
	await _wait_frames(2)

	started_msec = Time.get_ticks_msec()
	_deboard_two_dropships(controller, primary_view)
	await _wait_frames(4)
	_mark_stage("parallel_lz_drop_and_deboard", started_msec)

	started_msec = Time.get_ticks_msec()
	var runtime_units: Array = Array(combat_driver.call("_get_friendly_combat_units"))
	var enemies: Array = Array(combat_driver.call("_get_enemy_combat_units"))
	var ft1_los_ready := _position_enemy_for_fireteam(controller, combat_driver, runtime_units, enemies, "ft1", 0)
	var ft2_los_ready := _position_enemy_for_fireteam(controller, combat_driver, runtime_units, enemies, "ft2", 1)
	for _tick in range(18):
		combat_driver.call("_update_contact_tracking")
		combat_driver.call("_advance_detection_timers")
	combat_driver.call("_update_contact_tracking")
	controller.call("_set_selected_fireteams", PackedStringArray(["ft1", "ft2"]), false)
	controller.call("refresh_contact_overlay")
	controller.call("_refresh_world_overlays")
	controller.call("_update_ui")
	await _wait_frames(4)
	_mark_stage("two_team_contact_and_overlay", started_msec)
	_assert(ft1_los_ready and ft2_los_ready, "Both Fireteams reach the measured contact stage")

	started_msec = Time.get_ticks_msec()
	var planned := bool(controller.call("issue_right_click_command_for_test", Vector2(544.0, 288.0), "move", false))
	controller.call("_refresh_world_overlays")
	controller.call("_refresh_button_state")
	controller.call("_update_ui")
	await _wait_frames(3)
	var preview: Dictionary = Dictionary(controller.call("get_multi_fireteam_first_command_readability_snapshot"))
	_mark_stage("two_team_move_preview", started_msec)
	_assert(planned and String(preview.get("gate", "")) == "pass", "Measured player path keeps both previews actionable")

	started_msec = Time.get_ticks_msec()
	var go_started := bool(controller.call("execute_selected_fireteam_orders"))
	await _wait_frames(3)
	var coordination: Array = Array(controller.call("get_fireteam_coordination_snapshot"))
	_mark_stage("two_team_go_and_coordination", started_msec)
	_assert(go_started and not coordination.is_empty(), "Measured GO starts an observable two-team coordination")
	var coverage_before: Dictionary = _coverage_visual_identity(controller, "ft2")
	await _wait_frames(8)
	var coverage_after: Dictionary = _coverage_visual_identity(controller, "ft2")
	_assert(not coverage_before.is_empty() and coverage_before == coverage_after, "Suppression updates reuse unchanged Fireteam security coverage segments")
	_assert(controller.has_method("get_mission_ui_refresh_timing_debug_snapshot"), "Controller exposes an opt-in UI refresh timing snapshot")
	if controller.has_method("get_mission_ui_refresh_timing_debug_snapshot"):
		var ui_timing: Dictionary = Dictionary(controller.call("get_mission_ui_refresh_timing_debug_snapshot"))
		_assert(int(Dictionary(ui_timing.get("scopes_usec", {})).get("runtime_surfaces_usec", 0)) > 0, "UI timing splits runtime mission surfaces from the aggregate refresh")
	_assert(controller.has_method("get_mission_runtime_surface_timing_debug_snapshot"), "Controller exposes a detailed runtime-surface timing snapshot")
	if controller.has_method("get_mission_runtime_surface_timing_debug_snapshot"):
		var surface_timing: Dictionary = Dictionary(controller.call("get_mission_runtime_surface_timing_debug_snapshot"))
		_assert(int(Dictionary(surface_timing.get("scopes_usec", {})).get("world_overlays_usec", 0)) > 0, "Runtime timing isolates world overlays from card and layout work")
	_assert(_stages.size() == 6, "Trace records every player-facing runtime stage")

	_disable_timing()
	await _cleanup(scene)


func _enable_timing(controller: Node, simulation_root: Node, primary_view: Node, combat_driver: Node) -> void:
	_timing_nodes = {"controller": controller, "simulation": simulation_root, "terrain": primary_view, "combat": combat_driver}
	controller.call("set_mission_visible_frame_timing_debug_enabled", true)
	simulation_root.call("set_runtime_tick_budget_debug_enabled", true)
	primary_view.call("set_runtime_frame_timing_debug_enabled", true)
	combat_driver.call("set_combat_tick_budget_debug_enabled", true)


func _disable_timing() -> void:
	for kind_variant in _timing_nodes.keys():
		var node := _timing_nodes.get(kind_variant) as Node
		if node == null:
			continue
		match String(kind_variant):
			"controller": node.call("set_mission_visible_frame_timing_debug_enabled", false)
			"simulation": node.call("set_runtime_tick_budget_debug_enabled", false)
			"terrain": node.call("set_runtime_frame_timing_debug_enabled", false)
			"combat": node.call("set_combat_tick_budget_debug_enabled", false)
	_timing_nodes.clear()


func _mark_stage(stage_id: String, started_msec: int) -> void:
	var stage: Dictionary = {
		"stage_id": stage_id,
		"elapsed_msec": Time.get_ticks_msec() - started_msec,
		"controller": _snapshot_from("controller", "get_mission_visible_frame_timing_debug_snapshot"),
		"ui": _snapshot_from("controller", "get_mission_ui_refresh_timing_debug_snapshot"),
		"surfaces": _snapshot_from("controller", "get_mission_runtime_surface_timing_debug_snapshot"),
		"simulation": _snapshot_from("simulation", "get_runtime_tick_budget_debug_snapshot"),
		"terrain": _snapshot_from("terrain", "get_runtime_frame_timing_debug_snapshot"),
		"combat": _snapshot_from("combat", "get_combat_tick_budget_debug_snapshot"),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}
	_stages.append(stage)
	print("TRACE1061 stage=%s elapsed_msec=%d slowest=%s ui_scopes=%s surface_scopes=%s" % [stage_id, int(stage.get("elapsed_msec", 0)), _build_slowest_scope_text(stage), Dictionary(Dictionary(stage.get("ui", {})).get("scopes_usec", {})), Dictionary(Dictionary(stage.get("surfaces", {})).get("scopes_usec", {}))])


func _snapshot_from(kind: String, method_name: String) -> Dictionary:
	var node := _timing_nodes.get(kind) as Node
	if node == null or not node.has_method(method_name):
		return {}
	return Dictionary(node.call(method_name)).duplicate(true)


func _build_slowest_scope_text(stage: Dictionary) -> String:
	var slowest_scope := "none"
	var slowest_usec := -1
	for source_key in ["controller", "ui", "simulation", "terrain", "combat"]:
		var snapshot: Dictionary = Dictionary(stage.get(source_key, {}))
		for scope_variant in Dictionary(snapshot.get("scopes_usec", {})).keys():
			var duration_usec: int = int(Dictionary(snapshot.get("scopes_usec", {})).get(scope_variant, 0))
			if duration_usec > slowest_usec:
				slowest_usec = duration_usec
				slowest_scope = "%s.%s=%dus" % [source_key, String(scope_variant), duration_usec]
	return slowest_scope


func _print_summary() -> void:
	for stage_variant in _stages:
		var stage: Dictionary = Dictionary(stage_variant)
		print("TRACE1061 summary stage=%s elapsed_msec=%d slowest=%s ui_scopes=%s surface_scopes=%s" % [String(stage.get("stage_id", "")), int(stage.get("elapsed_msec", 0)), _build_slowest_scope_text(stage), Dictionary(Dictionary(stage.get("ui", {})).get("scopes_usec", {})), Dictionary(Dictionary(stage.get("surfaces", {})).get("scopes_usec", {}))])


func _deboard_two_dropships(controller: Node, primary_view: Node) -> void:
	controller.call("_on_mission_dropship_card_set_lz_pressed", "dropship_alpha")
	controller.call("_place_lz_from_screen_position", primary_view.call("world_to_screen_position", Vector2(384.0, 224.0)))
	controller.call("_on_mission_dropship_card_approach_pressed", "dropship_beta", "SE")
	controller.call("_on_mission_dropship_card_set_lz_pressed", "dropship_beta")
	controller.call("_place_lz_from_screen_position", primary_view.call("world_to_screen_position", Vector2(672.0, 352.0)))
	controller.call("_on_mission_dropship_card_drop_pressed", "dropship_alpha")
	controller.call("_on_mission_dropship_card_drop_pressed", "dropship_beta")
	for _step in range(180):
		controller.call("_update_drop_sequence", 0.2)
		var state: Dictionary = Dictionary(controller.call("get_planning_state"))
		if _all_dropship_payloads_deboarded(Array(state.get("mission_drop_cards", []))):
			return


func _position_enemy_for_fireteam(controller: Node, combat_driver: Node, runtime_units: Array, enemies: Array, fireteam_id: String, enemy_index: int) -> bool:
	if enemy_index < 0 or enemy_index >= enemies.size():
		return false
	var friendly: Node2D = _find_fireteam_friendly(runtime_units, fireteam_id)
	var enemy: Node2D = enemies[enemy_index] as Node2D
	if friendly == null or enemy == null:
		return false
	for offset in [Vector2(48.0, 0.0), Vector2(-48.0, 0.0), Vector2(0.0, 48.0), Vector2(0.0, -48.0), Vector2(96.0, 0.0), Vector2(-96.0, 0.0), Vector2(0.0, 96.0), Vector2(0.0, -96.0)]:
		enemy.global_position = Vector2(controller.call("_snap_world_position_to_primary_tile", friendly.global_position + offset))
		if bool(combat_driver.call("_has_valid_los", friendly, enemy)):
			return true
	return false


func _find_fireteam_friendly(units: Array, fireteam_id: String) -> Node2D:
	for unit_variant in units:
		var unit := unit_variant as Node2D
		if unit != null and unit.has_method("get_fireteam_id") and String(unit.call("get_fireteam_id")).strip_edges().to_lower() == fireteam_id:
			return unit
	return null


func _coverage_visual_identity(controller: Node, fireteam_id: String) -> Dictionary:
	var host := controller.get_node_or_null("../TacticalUI/FireteamMiniPanel/MiniMargin/MiniVBox/MiniCardsScroll/MiniCardsVBox") as Control
	if host == null:
		return {}
	for child in host.get_children():
		var card := child as Control
		if card == null or String(card.get_meta("fireteam_id", "")).strip_edges().to_lower() != fireteam_id:
			continue
		var bar := card.find_child("MiniSecurityCoverageBar", true, false) as Control
		if bar == null:
			return {}
		var child_ids: Array = []
		for bar_child in bar.get_children():
			child_ids.append(bar_child.get_instance_id())
		return {"bar_id": bar.get_instance_id(), "child_ids": child_ids}
	return {}


func _all_dropship_payloads_deboarded(cards: Array) -> bool:
	var payload_card_count := 0
	for card_variant in cards:
		if typeof(card_variant) != TYPE_DICTIONARY:
			continue
		var card: Dictionary = Dictionary(card_variant)
		if String(card.get("craft_id", "")).strip_edges().is_empty():
			continue
		payload_card_count += 1
		if not Array(card.get("embarked_unit_ids", [])).is_empty():
			return false
	return payload_card_count >= 2


func _build_two_dropship_meta_scene() -> Node:
	var scene: Node = META_LAYER_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(4)
	var homebase := scene.get_node("HomebaseScreen") as Control
	var roster: Array = UNIT_ROSTER_PRESETS_SCRIPT.call("get_homebase_roster")
	var craft_definitions := [_build_dropship_definition("dropship_alpha", "Dropship Alpha"), _build_dropship_definition("dropship_beta", "Dropship Beta")]
	var pilots := {"dropship_alpha": "unit_echo", "dropship_beta": "unit_foxtrot"}
	var locations := {"dropship_alpha": "homebase", "dropship_beta": "homebase"}
	scene.set("_available_team_units", roster.duplicate(true))
	scene.set("_all_team_units", roster.duplicate(true))
	scene.set("_homebase_aircraft_definitions", craft_definitions.duplicate(true))
	scene.set("_assigned_aircraft_pilot_by_craft", pilots.duplicate(true))
	scene.set("_aircraft_location_by_craft", locations.duplicate(true))
	homebase.call("set_mission_context", [], "res://maps/station_outpost_192x192.json", "Task 1061 Runtime Budget", 8, "task_1061_runtime_budget")
	homebase.call("setup_roster", roster, PackedStringArray(["unit_alpha", "unit_bravo", "unit_charlie", "unit_delta"]))
	homebase.call("set_fireteam_context", PackedStringArray(["ft1", "ft1", "ft2", "ft2"]), [
		_build_fireteam_definition("ft1", "ALPHA", PackedStringArray(["unit_alpha", "unit_bravo"])),
		_build_fireteam_definition("ft2", "BRAVO", PackedStringArray(["unit_charlie", "unit_delta"])),
	])
	homebase.call("set_transport_state", craft_definitions, pilots, [], [], locations, {}, {}, [])
	await _wait_frames(3)
	return scene


func _build_dropship_definition(craft_id: String, display_name: String) -> Dictionary:
	return {"craft_id": craft_id, "craft_type": "dropship", "display_name": display_name, "texture_path": DROPSHIP_TEXTURE_PATH, "supports_cargo": false, "cargo_options": []}


func _build_fireteam_definition(fireteam_id: String, label: String, unit_ids: PackedStringArray) -> Dictionary:
	return {"id": fireteam_id, "label": label, "lead_unit_id": String(unit_ids[0]), "member_unit_ids": Array(unit_ids), "loadout": "medium", "respawn_enabled": false}


func _finish_boarding(homebase: Control, fireteam_id: String) -> void:
	var total_seconds: float = float(homebase.call("_debug_get_homebase_fireteam_boarding_total_seconds", fireteam_id))
	homebase.call("_debug_advance_homebase_direct_boarding", total_seconds + 0.2)
	await _wait_frames(3)


func _finish_all_mission_transfers(scene: Node) -> void:
	for _index in range(24):
		scene.call("_on_homebase_transport_timer_timeout")
		await _wait_frames(2)


func _wait_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame


func _cleanup(scene: Node) -> void:
	if scene != null:
		scene.queue_free()
	await _wait_frames(2)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
