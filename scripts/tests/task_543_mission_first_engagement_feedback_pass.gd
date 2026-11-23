extends SceneTree

const META_LAYER_TEST_SCENE: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")
const UNIT_ROSTER_PRESETS_SCRIPT: GDScript = preload("res://scripts/npc/unit_roster_presets.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_543_mission_first_engagement_feedback_pass.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const CONTROLLER_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const DROPSHIP_TEXTURE_PATH := "res://Assets/kenney_space-kit/Isometric/craft_speederB_SE.png"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_543 Mission First Engagement Feedback Pass ===")
	_test_docs_and_wiring()
	await _test_first_engagement_feedback_after_first_contact()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_543: FAILED")
		quit(1)
		return
	print("TASK_543: ALL PASSED")
	quit(0)


func _test_docs_and_wiring() -> void:
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_543 task file exists")
	_assert(_read_text(TASK_PATH).contains("Mission First Engagement Feedback Pass"), "TASK_543 task file names the task")
	_assert(_read_text(STATUS_PATH).contains("TASK_543 - Mission First Engagement Feedback Pass"), "Implementation status tracks TASK_543")
	_assert(_read_text(ROADMAP_PATH).contains("TASK_543 - Mission First Engagement Feedback Pass (implementiert)"), "Roadmap marks TASK_543 implemented")
	_assert(_read_text(REPORT_PATH).contains("TASK_543 - Mission First Engagement Feedback Pass"), "Review workbench tracks TASK_543")
	_assert(_read_text(CONTRACT_PATH).contains("get_mission_first_engagement_feedback_snapshot"), "Mission command feedback contract documents the first-engagement snapshot")
	_assert(_read_text(CONTROLLER_PATH).contains("get_mission_first_engagement_feedback_snapshot"), "TacticalController exposes first-engagement feedback snapshot")


func _test_first_engagement_feedback_after_first_contact() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = META_LAYER_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(5)
	scene.call("_on_homebase_mission_selection_changed", "frontier_probe_vertical_slice")
	await _wait_frames(2)

	var homebase_screen := scene.get_node("HomebaseScreen") as Control
	var roster: Array = UNIT_ROSTER_PRESETS_SCRIPT.call("get_homebase_roster")
	var selected_unit_ids := PackedStringArray(["unit_alpha", "unit_bravo"])
	var selected_fireteam_ids := PackedStringArray(["ft1", "ft1"])
	scene.set("_available_team_units", roster.duplicate(true))
	scene.set("_all_team_units", roster.duplicate(true))
	scene.set("_homebase_aircraft_definitions", [_build_dropship_definition("dropship_alpha", "Dropship Alpha")])
	scene.set("_assigned_aircraft_pilot_by_craft", {"dropship_alpha": "unit_delta"})
	scene.set("_aircraft_location_by_craft", {"dropship_alpha": "homebase"})
	homebase_screen.call("setup_roster", roster, selected_unit_ids)
	homebase_screen.call("set_fireteam_context", selected_fireteam_ids, [_build_fireteam_definition("ft1", "ALPHA", selected_unit_ids)])
	homebase_screen.call(
		"set_transport_state",
		[_build_dropship_definition("dropship_alpha", "Dropship Alpha")],
		{"dropship_alpha": "unit_delta"},
		[],
		[],
		{"dropship_alpha": "homebase"},
		{},
		{},
		[]
	)
	await _wait_frames(3)

	_drop_fireteam_on_shipcard(homebase_screen, "ft1", "dropship_alpha")
	await _finish_boarding(homebase_screen, "ft1")
	homebase_screen.call("request_mission_start", "dropship_alpha")
	await _wait_frames(8)
	_complete_mission_craft_arrival(scene, "dropship_alpha")
	scene.call("_show_mission")
	await _wait_frames(8)

	var active_mission: Node = scene.call("get_active_mission")
	var controller: Node = active_mission.get_node_or_null("TacticalController") if active_mission != null else null
	var primary_view: Node = active_mission.get_node_or_null("Primary3DView") if active_mission != null else null
	var combat_driver: Node = active_mission.get_node_or_null("CombatLoopDriver") if active_mission != null else null
	var simulation_root: Node = active_mission.get_node_or_null("SimulationRoot") if active_mission != null else null
	_assert(controller != null and primary_view != null and combat_driver != null and simulation_root != null, "Active Mission exposes TacticalController, Primary3DView, CombatLoopDriver and SimulationRoot")
	if controller == null or primary_view == null or combat_driver == null or simulation_root == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	var lz_world := Vector2(384.0, 224.0)
	controller.call("_on_mission_dropship_card_set_lz_pressed", "dropship_alpha")
	_assert(bool(controller.call("_place_lz_from_screen_position", primary_view.call("world_to_screen_position", lz_world))), "LZ placement succeeds before engagement feedback test")
	controller.call("_on_mission_dropship_card_drop_pressed", "dropship_alpha")
	await _wait_frames(4)
	controller.call("_complete_drop_sequence_deployment")
	controller.call("_advance_primary_drop_sequence_unloading", 999.0)
	controller.call("_flush_pending_drop_runtime_phase_starts")
	controller.call("_refresh_world_overlays")
	controller.call("_update_ui")
	await _wait_frames(10)

	var move_target := Vector2(544.0, 288.0)
	_assert(bool(controller.call("issue_right_click_command_for_test", move_target, "move", false)), "First move order can be planned before engagement feedback test")
	controller.call("_refresh_world_overlays")
	controller.call("_refresh_button_state")
	controller.call("_update_ui")
	await _wait_frames(3)

	_assert(bool(controller.call("execute_selected_fireteam_orders")), "GO executes the planned first move order before engagement")
	controller.call("_refresh_world_overlays")
	controller.call("_refresh_button_state")
	controller.call("_update_ui")
	await _wait_frames(2)

	var contact_setup: Dictionary = _position_first_enemy_near_fireteam(controller, "ft1")
	_assert(not contact_setup.is_empty(), "First enemy can be positioned near selected fireteam for reproducible engagement")
	_prepare_fireteam_for_first_engagement(controller, "ft1", Vector2(contact_setup.get("enemy_position", Vector2.ZERO)))
	_update_contact_tracking(combat_driver)
	_force_first_engagement_decision(controller, combat_driver, simulation_root, "ft1", contact_setup)
	controller.call("refresh_contact_overlay")
	controller.call("refresh_fireteam_security_state")
	controller.call("_refresh_world_overlays")
	controller.call("_update_ui")
	await _wait_frames(8)

	var snapshot: Dictionary = Dictionary(controller.call("get_mission_first_engagement_feedback_snapshot"))
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "First-engagement feedback snapshot is read-only")
	_assert(String(snapshot.get("gate", "")) == "pass", "First-engagement feedback gate passes after combat decision")
	_assert(_check_passed(snapshot, "selected_fireteam_has_contact"), "Selected Fireteam keeps a readable contact")
	_assert(_check_passed(snapshot, "engagement_decision_visible"), "Engagement decision exposes fired/waiting/blocked status")
	_assert(_check_passed(snapshot, "target_or_block_reason_visible"), "Engagement decision exposes target or block reason")
	_assert(_check_passed(snapshot, "fire_event_or_block_visible"), "Engagement exposes fire event or concrete waiting/block reason")
	_assert(_check_passed(snapshot, "cover_range_los_context_visible"), "Engagement exposes range, LOS or cover context")
	_assert(_check_passed(snapshot, "feedback_text_visible"), "Mission feedback text names the engagement decision")
	var diagnostics: Dictionary = Dictionary(snapshot.get("contact_decision_diagnostics", {}))
	_assert(not String(diagnostics.get("reason", "")).strip_edges().is_empty(), "Engagement diagnostics include a reason")
	if String(diagnostics.get("status", "")) == "fired":
		_assert(not String(diagnostics.get("attacker_unit_id", "")).strip_edges().is_empty(), "Fired engagement names attacker")
		_assert(not String(diagnostics.get("target_unit_id", "")).strip_edges().is_empty(), "Fired engagement names target")
		_assert(not String(diagnostics.get("weapon_id", "")).strip_edges().is_empty(), "Fired engagement names weapon")

	scene.queue_free()
	await _wait_frames(2)


func _build_dropship_definition(craft_id: String, display_name: String) -> Dictionary:
	return {
		"craft_id": craft_id,
		"craft_type": "dropship",
		"display_name": display_name,
		"texture_path": DROPSHIP_TEXTURE_PATH,
		"supports_cargo": false,
		"cargo_options": [],
	}


func _build_fireteam_definition(fireteam_id: String, label: String, unit_ids: PackedStringArray) -> Dictionary:
	return {
		"id": fireteam_id,
		"label": label,
		"lead_unit_id": String(unit_ids[0]) if not unit_ids.is_empty() else "",
		"member_unit_ids": Array(unit_ids),
		"loadout": "medium",
		"respawn_enabled": false,
		"member_loadouts": {
			"unit_alpha": {
				"armor": "medium",
				"weapon_1": "rifle",
				"weapon_2": "rocket_launcher",
			},
			"unit_bravo": {
				"armor": "medium",
				"weapon_1": "sniper",
				"weapon_2": "medictool",
			},
		},
	}


func _finish_boarding(screen: Control, fireteam_id: String) -> void:
	var total_seconds: float = float(screen.call("_debug_get_homebase_fireteam_boarding_total_seconds", fireteam_id))
	screen.call("_debug_advance_homebase_direct_boarding", total_seconds + 0.2)
	await _wait_frames(3)


func _complete_mission_craft_arrival(scene: Node, craft_id: String) -> void:
	scene.call("_remove_pending_mission_craft_transfer", craft_id)
	scene.call("_complete_mission_craft_transfer", {"craft_id": craft_id, "phase": "to_mission"})
	scene.call("_sync_homebase_direct_mission_drop_transport_fields")
	scene.call("_start_or_update_active_mission")


func _drop_fireteam_on_shipcard(screen: Control, fireteam_id: String, craft_id: String) -> void:
	var target := _find_shipcard_drop_target(screen, craft_id)
	if target == null:
		return
	target.call("_drop_data", Vector2.ZERO, {"type": "fob_fireteam_card", "fireteam_id": fireteam_id, "source_context": "fireteam_list"})


func _find_shipcard_drop_target(screen: Control, craft_id: String) -> Control:
	for node in _collect_nodes(screen):
		var control := node as Control
		if control != null \
			and bool(control.get_meta("homebase_fireteam_drop_target", false)) \
			and bool(control.get_meta("homebase_fireteam_drop_enabled", false)) \
			and String(control.get_meta("homebase_fireteam_drop_target_id", "")).strip_edges() == craft_id:
			return control
	return null


func _position_first_enemy_near_fireteam(controller: Node, fireteam_id: String) -> Dictionary:
	var friendly_units: Array = Array(controller.call("_get_fireteam_units", fireteam_id, true))
	var enemy_units: Array = Array(controller.call("_get_all_enemy_units", false))
	if enemy_units.is_empty():
		enemy_units = Array(controller.call("_get_all_enemy_units", true))
	if friendly_units.is_empty() or enemy_units.is_empty():
		return {}
	var friendly := friendly_units[0] as Node2D
	var enemy := enemy_units[0] as Node2D
	if friendly == null or enemy == null:
		return {}
	enemy.global_position = friendly.global_position + Vector2(58.0, 0.0)
	if enemy is CanvasItem:
		(enemy as CanvasItem).visible = true
	return {
		"fireteam_id": fireteam_id,
		"friendly_unit_id": _get_unit_id(friendly),
		"enemy_unit_id": _get_unit_id(enemy),
		"friendly_position": friendly.global_position,
		"enemy_position": enemy.global_position,
	}


func _prepare_fireteam_for_first_engagement(controller: Node, fireteam_id: String, enemy_position: Vector2) -> void:
	for unit_variant in Array(controller.call("_get_fireteam_units", fireteam_id, true)):
		var unit := unit_variant as Node2D
		if unit == null:
			continue
		if unit.has_method("set"):
			unit.set("skill_accuracy", 1.0)
		if unit.has_method("set_runtime_status"):
			unit.call(
				"set_runtime_status",
				"holding",
				"hold_position",
				30,
				"fire_at_will",
				"defend",
				1.0,
				0.0,
				0.0,
				1,
				enemy_position,
				"engage",
				"aimed",
				"task543_first_engagement",
				1.0,
				75.0
			)


func _force_first_engagement_decision(controller: Node, combat_driver: Node, simulation_root: Node, fireteam_id: String, contact_setup: Dictionary) -> void:
	var enemy_id: String = String(contact_setup.get("enemy_unit_id", "")).strip_edges()
	var detection_progress: Dictionary = Dictionary(combat_driver.get("_detection_progress")).duplicate(true)
	for unit_variant in Array(controller.call("_get_fireteam_units", fireteam_id, true)):
		var unit := unit_variant as Node2D
		if unit == null:
			continue
		var friendly_id: String = _get_unit_id(unit)
		if friendly_id.is_empty() or enemy_id.is_empty():
			continue
		detection_progress["%s:%s" % [friendly_id, enemy_id]] = 0
		detection_progress["%s:%s" % [enemy_id, friendly_id]] = 0
	combat_driver.set("_detection_progress", detection_progress)
	combat_driver.set("_current_tick", 120)
	combat_driver.call("align_to_common_decision_step_for_test")
	if combat_driver.has_method("_try_enqueue_attacks"):
		combat_driver.call("_try_enqueue_attacks", simulation_root)


func _update_contact_tracking(combat_driver: Node) -> void:
	if combat_driver.has_method("_update_contact_tracking"):
		combat_driver.call("_update_contact_tracking")
	if combat_driver.has_method("_advance_detection_timers"):
		combat_driver.call("_advance_detection_timers")
	if combat_driver.has_method("_update_contact_tracking"):
		combat_driver.call("_update_contact_tracking")


func _get_unit_id(unit: Node) -> String:
	if unit != null and unit.has_method("get_unit_id"):
		return String(unit.call("get_unit_id"))
	return unit.name if unit != null else ""


func _collect_nodes(root_node: Node) -> Array:
	var result: Array = []
	if root_node == null:
		return result
	result.append(root_node)
	for child in root_node.get_children():
		result.append_array(_collect_nodes(child))
	return result


func _check_passed(snapshot: Dictionary, check_id: String) -> bool:
	for check_variant in Array(snapshot.get("checks", [])):
		var check: Dictionary = Dictionary(check_variant)
		if String(check.get("id", "")) == check_id:
			return bool(check.get("passed", false))
	return false


func _wait_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
