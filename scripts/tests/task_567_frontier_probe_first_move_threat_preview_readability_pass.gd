extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const UNIT_ROSTER_PRESETS_SCRIPT: GDScript = preload("res://scripts/npc/unit_roster_presets.gd")

const SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const LARGE_MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const TASK_PATH: String = "res://docs/tasks/TASK_567_frontier_probe_first_move_threat_preview_readability_pass.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const CONTROLLER_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const TACTICAL_CLARITY_CONTRACT_PATH: String = "res://docs/dev/tactical_decision_clarity_contract.md"
const TASK_506_TEST_PATH: String = "res://scripts/tests/task_506_tactical_decision_clarity_contract.gd"
const TASK_540_TEST_PATH: String = "res://scripts/tests/task_540_mission_first_move_decision_readability_pass.gd"
const TASK_566_TEST_PATH: String = "res://scripts/tests/task_566_frontier_probe_multiplayer_f6_hover_panel_polish_pass.gd"
const DROPSHIP_TEXTURE_PATH := "res://Assets/kenney_space-kit/Isometric/craft_speederB_SE.png"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_567 Frontier Probe First Move Threat Preview Readability Pass ===")
	_test_docs_and_wiring()
	await _test_frontier_probe_first_move_threat_preview_before_go()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_567: FAILED")
		quit(1)
		return
	print("TASK_567: ALL PASSED")
	quit(0)


func _test_docs_and_wiring() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var tactical_contract_text: String = _read_text(TACTICAL_CLARITY_CONTRACT_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_567 task file exists")
	_assert(task_text.contains("Frontier Probe First Move Threat Preview Readability Pass"), "TASK_567 task file names the task")
	_assert(status_text.contains("TASK_567 - Frontier Probe First Move Threat Preview Readability Pass"), "Implementation status tracks TASK_567")
	_assert(roadmap_text.contains("TASK_567 - Frontier Probe First Move Threat Preview Readability Pass (implementiert)"), "Roadmap marks TASK_567 implemented")
	_assert(roadmap_text.contains("TASK_568 - Frontier Probe Risky Contact Preview Fixture"), "Roadmap names TASK_568 follow-up")
	_assert(report_text.contains("TASK_567 - Frontier Probe First Move Threat Preview Readability Pass"), "Review workbench tracks TASK_567")
	_assert(report_text.contains("TASK_568 - Frontier Probe Risky Contact Preview Fixture"), "Review workbench names TASK_568 follow-up")
	_assert(contract_text.contains("get_frontier_probe_first_move_threat_preview_readability_snapshot"), "Mission command feedback contract documents TASK_567")
	_assert(tactical_contract_text.contains("risk_state") and tactical_contract_text.contains("ui_sets_gameplay_truth = false"), "Tactical clarity contract still defines risk/read-only boundary")
	_assert(controller_text.contains("get_frontier_probe_first_move_threat_preview_readability_snapshot"), "TacticalController exposes TASK_567 snapshot")
	_assert(controller_text.contains("_build_waypoint_intent_threat_preview_text"), "TacticalController formats compact threat preview text")
	_assert(FileAccess.file_exists(TASK_506_TEST_PATH), "TASK_506 tactical clarity verifier remains available")
	_assert(FileAccess.file_exists(TASK_540_TEST_PATH), "TASK_540 first move verifier remains available")
	_assert(FileAccess.file_exists(TASK_566_TEST_PATH), "TASK_566 hover/panel verifier remains available")


func _test_frontier_probe_first_move_threat_preview_before_go() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	_configure_scene(scene)
	var simulation_root: Node = scene.get_node_or_null("SimulationRoot")
	if simulation_root != null and simulation_root.has_method("set_peer_team_assignments"):
		simulation_root.call("set_peer_team_assignments", {
			1: "team_alpha",
			2: "team_bravo",
		})
	root.add_child(scene)
	await _wait_frames(18)
	await _wait_physics_frames(4)

	var controller: Node = scene.get_node_or_null("TacticalController")
	var primary_view: Node = scene.get_node_or_null("Primary3DView")
	_assert(controller != null and primary_view != null and simulation_root != null, "Mission fixture exposes TacticalController, Primary3DView and SimulationRoot")
	if controller == null or primary_view == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	var friendly_units: Array = _collect_team_units(scene, "team_alpha")
	_assert(friendly_units.size() >= 3, "Mission fixture exposes Alpha units for first-move preview")
	if friendly_units.size() < 3:
		scene.queue_free()
		await _wait_frames(2)
		return
	_assign_fireteam_ids(friendly_units.slice(0, 5), "blue")
	_mark_units_deployed(controller, friendly_units.slice(0, 5))
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	controller.call("_refresh_world_overlays")
	controller.call("_update_ui")
	await _wait_frames(8)

	var move_target := Vector2(544.0, 288.0)
	_assert(bool(controller.call("issue_right_click_command_for_test", move_target, "move", false)), "First move order can be planned through existing right-click command path")
	controller.call("_refresh_world_overlays")
	controller.call("_sync_primary_3d_order_visuals")
	controller.call("_refresh_button_state")
	controller.call("_update_ui")
	await _wait_frames(8)

	var snapshot: Dictionary = Dictionary(controller.call("get_frontier_probe_first_move_threat_preview_readability_snapshot"))
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "TASK_567 snapshot is read-only")
	_assert(String(snapshot.get("gate", "")) == "pass", "TASK_567 threat preview readability gate passes before GO")
	_assert(_check_passed(snapshot, "first_move_gate_still_passes"), "TASK_540 first-move gate remains green")
	_assert(_check_passed(snapshot, "risk_state_visible_before_go"), "Risk state is visible before GO")
	_assert(_check_passed(snapshot, "risk_reason_visible"), "Risk reason is visible before GO")
	_assert(_check_passed(snapshot, "hud_order_text_names_risk"), "Selected Fireteam order text names risk")
	_assert(_check_passed(snapshot, "primary_preview_ghost_and_path_visible"), "Primary3D reports ghost and path preview")
	_assert(_check_passed(snapshot, "threat_line_count_matches_context"), "Threat-line count matches preview context")
	_assert(_check_passed(snapshot, "preview_remains_read_only"), "Threat preview stays read-only")
	_assert(String(snapshot.get("risk_state", "")).strip_edges().to_lower() == "unknown", "No-contact first move remains honestly unknown")
	_assert(String(snapshot.get("risk_preview_text", "")).contains("RISK ?"), "Risk preview text contains unknown risk marker")
	_assert(String(snapshot.get("risk_preview_text", "")).contains("no intel"), "Unknown risk preview explains missing intel")
	_assert(String(snapshot.get("selected_order_text", "")).contains("RISK ?"), "HUD order text carries compact risk marker")
	_assert(int(snapshot.get("render_preview_visual_count", 0)) > 0 or int(snapshot.get("render_preview_ghost_entry_count", 0)) > 0, "Render snapshot counts the ghost preview")
	_assert(int(snapshot.get("render_preview_path_line_count", 0)) > 0, "Render snapshot counts the path preview")

	scene.queue_free()
	await _wait_frames(2)


func _configure_scene(scene: Node) -> void:
	var mission_setup := scene.get_node_or_null("MissionSetup")
	if mission_setup != null:
		mission_setup.set("map_file_path", LARGE_MAP_PATH)
		mission_setup.set("scenario_file_path", SCENARIO_PATH)
		mission_setup.set("defer_friendly_runtime_activation", false)
	var combat_driver := scene.get_node_or_null("CombatLoopDriver")
	if combat_driver != null:
		combat_driver.set("enemy_advance_enabled", false)
		combat_driver.set("enemy_reposition_enabled", false)
		combat_driver.set("base_hit_chance", 0.0)
		combat_driver.set("damage_per_hit", 0)


func _assign_fireteam_ids(units: Array, fireteam_id: String) -> void:
	for unit_variant in units:
		var unit := unit_variant as Node
		if unit != null and unit.has_method("set_fireteam_id"):
			unit.call("set_fireteam_id", fireteam_id)


func _mark_units_deployed(controller: Node, units: Array) -> void:
	var deployed_ids: Dictionary = {}
	var deployed_positions: Dictionary = {}
	for unit_variant in units:
		var unit := unit_variant as Node
		if unit == null or not unit.has_method("get_unit_id"):
			continue
		var unit_id: String = String(unit.call("get_unit_id")).strip_edges()
		if unit_id.is_empty():
			continue
		deployed_ids[unit_id] = true
		if unit is Node2D:
			deployed_positions[unit_id] = (unit as Node2D).global_position
	controller.set("_deployed_unit_ids", deployed_ids)
	controller.set("_deployed_unit_positions", deployed_positions)


func _collect_team_units(root_node: Node, team_id: String) -> Array:
	var result: Array = []
	for node in _collect_nodes(root_node):
		if not node.has_method("get_team_id") or not node.has_method("get_unit_id"):
			continue
		if String(node.call("get_team_id")).strip_edges() == team_id:
			result.append(node)
	return result


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


func _wait_physics_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await physics_frame


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
