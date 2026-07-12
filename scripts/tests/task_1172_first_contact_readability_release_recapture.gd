extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

const TASK_PATH := "res://docs/tasks/TASK_1172_first_contact_readability_release_recapture.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const SCENARIO_PATH := "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const CONTACT_FIXTURE_MAP_PATH := "res://maps/station_outpost_64x64.json"
const SCHEMA := "sternenbuergerchen.mission_first_contact_readability_release_recapture.v1"

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1172 First Contact Readability Release Recapture ===")
	_test_docs_and_static_hooks()
	await _test_first_contact_release_recapture_snapshot()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_1172: FAILED")
		quit(1)
		return
	print("TASK_1172: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text := _read_text(TASK_PATH)
	var status_text := _read_text(STATUS_PATH)
	var roadmap_text := _read_text(ROADMAP_PATH)
	var contract_text := _read_text(COMMAND_CONTRACT_PATH)
	var controller_text := _read_text(CONTROLLER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK 1172 task document exists")
	_assert(task_text.contains("First Contact Readability Release Recapture"), "Task document names TASK 1172")
	_assert(task_text.contains("get_mission_first_contact_readability_release_recapture_snapshot"), "Task document names snapshot contract")
	_assert(status_text.contains("TASK_1172 - First Contact Readability Release Recapture"), "Implementation status tracks TASK 1172")
	_assert(roadmap_text.contains("TASK_1172 - First Contact Readability Release Recapture"), "Roadmap tracks TASK 1172")
	_assert(contract_text.contains("get_mission_first_contact_readability_release_recapture_snapshot"), "Mission feedback contract documents TASK 1172")
	_assert(controller_text.contains("get_mission_first_contact_readability_release_recapture_snapshot"), "Controller exposes TASK 1172 snapshot")


func _test_first_contact_release_recapture_snapshot() -> void:
	root.size = Vector2i(1280, 720)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	_configure_scene(scene)
	var simulation_root: Node = scene.get_node_or_null("SimulationRoot")
	var combat_driver: Node = scene.get_node_or_null("CombatLoopDriver")
	root.add_child(scene)
	await _wait_frames(18)
	await _wait_physics_frames(4)

	var controller: Node = scene.get_node_or_null("TacticalController")
	_assert(controller != null and simulation_root != null and combat_driver != null, "Mission fixture exposes TacticalController, SimulationRoot and CombatLoopDriver")
	if controller == null or simulation_root == null or combat_driver == null:
		scene.queue_free()
		await _wait_frames(2)
		return
	_assert(controller.has_method("get_mission_first_contact_readability_release_recapture_snapshot"), "Controller has TASK 1172 public snapshot method")
	if not controller.has_method("get_mission_first_contact_readability_release_recapture_snapshot"):
		scene.queue_free()
		await _wait_frames(2)
		return

	var execution_snapshot: Dictionary = _build_task_1171_handoff_fixture()
	_assert(bool(execution_snapshot.get("ready_for_first_contact_recapture", false)), "TASK 1171 handoff fixture is ready before first contact")
	var contact_readability_snapshot: Dictionary = _build_task_542_contact_readability_fixture()
	_assert(String(contact_readability_snapshot.get("gate", "")) == "pass", "TASK 542 contact readability fixture is ready")

	var command_count_before := Array(simulation_root.get("command_queue")).size()
	var effect_count_before := Array(simulation_root.get("effects_queue")).size()
	var snapshot: Dictionary = Dictionary(controller.call("get_mission_first_contact_readability_release_recapture_snapshot", execution_snapshot, contact_readability_snapshot))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema is stable")
	_assert(String(snapshot.get("task_id", "")) == "TASK_1172", "Snapshot identifies TASK 1172")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_1171", "Snapshot links TASK 1171")
	_assert(String(snapshot.get("status", "")) == "recaptured", "Snapshot recaptures first-contact readability")
	_assert(bool(snapshot.get("ready_for_first_engagement_recapture", false)), "Snapshot opens first-engagement recapture")
	_assert(_snapshot_is_read_only(snapshot), "TASK 1172 snapshot remains read-only")
	_assert(Array(simulation_root.get("command_queue")).size() == command_count_before, "TASK 1172 snapshot enqueues no command")
	_assert(Array(simulation_root.get("effects_queue")).size() == effect_count_before, "TASK 1172 snapshot enqueues no effect")

	var execution_handoff: Dictionary = Dictionary(snapshot.get("execution_recapture", {}))
	var contact_readability: Dictionary = Dictionary(snapshot.get("first_contact_readability", {}))
	var release: Dictionary = Dictionary(snapshot.get("release_provenance", {}))
	var capture: Dictionary = Dictionary(snapshot.get("capture_manifest", {}))
	var first_contact: Dictionary = Dictionary(snapshot.get("first_contact", {}))
	_assert(String(execution_handoff.get("task_id", "")) == "TASK_1171", "TASK 1171 execution handoff source is read")
	_assert(bool(snapshot.get("execution_handoff_read", false)), "TASK 1172 links the TASK 1171 handoff")
	_assert(String(contact_readability.get("gate", "")) == "pass", "TASK 542 first-contact readability gate passes")
	_assert(int(snapshot.get("selected_contact_count", 0)) > 0, "Selected fireteam contact count is visible")
	_assert(not String(first_contact.get("report_text", "")).strip_edges().is_empty(), "First contact report text is visible")
	_assert(bool(snapshot.get("contact_overlay_visible", false)), "Contact overlay or Primary3D contact is visible")
	_assert(bool(snapshot.get("tactical_context_visible", false)), "Threat, cover, security or event context is visible")
	_assert(bool(release.get("matches_git_head", false)), "Release provenance matches Git HEAD")
	_assert(bool(capture.get("gate_passed", false)) and bool(capture.get("deployment_converged", false)), "Capture manifest proves deployed release context")
	_assert(Array(snapshot.get("accepted_surfaces", [])).has("first_contact_report_after_first_move"), "Accepted surfaces include contact report after first move")
	_assert(String(snapshot.get("recommended_next_task", "")).begins_with("TASK_1173"), "Snapshot recommends TASK 1173")

	scene.queue_free()
	await _wait_frames(2)


func _configure_scene(scene: Node) -> void:
	var mission_setup := scene.get_node_or_null("MissionSetup")
	if mission_setup != null:
		mission_setup.set("map_file_path", CONTACT_FIXTURE_MAP_PATH)
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


func _update_contact_tracking(combat_driver: Node) -> void:
	if combat_driver.has_method("_update_contact_tracking"):
		combat_driver.call("_update_contact_tracking")
	if combat_driver.has_method("_advance_detection_timers"):
		combat_driver.call("_advance_detection_timers")
	if combat_driver.has_method("_update_contact_tracking"):
		combat_driver.call("_update_contact_tracking")


func _collect_team_units(root_node: Node, team_id: String) -> Array:
	var result: Array = []
	for node in _collect_nodes(root_node):
		if not node.has_method("get_team_id") or not node.has_method("get_unit_id"):
			continue
		if String(node.call("get_team_id")).strip_edges() == team_id:
			result.append(node)
	return result


func _collect_nodes(root_node: Node) -> Array:
	var result: Array = []
	if root_node == null:
		return result
	result.append(root_node)
	for child in root_node.get_children():
		result.append_array(_collect_nodes(child))
	return result


func _get_unit_id(unit: Node) -> String:
	if unit != null and unit.has_method("get_unit_id"):
		return String(unit.call("get_unit_id"))
	return unit.name if unit != null else ""


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) \
		and not bool(snapshot.get("ui_sets_gameplay_truth", true)) \
		and not bool(snapshot.get("creates_command", true)) \
		and not bool(snapshot.get("creates_effect", true)) \
		and not bool(snapshot.get("creates_contact", true)) \
		and not bool(snapshot.get("creates_fire_event", true)) \
		and not bool(snapshot.get("creates_damage_event", true)) \
		and not bool(snapshot.get("sets_multiplayer_truth", true))


func _build_task_1171_handoff_fixture() -> Dictionary:
	return {
		"schema": "sternenbuergerchen.mission_first_move_execution_feedback_release_recapture.v1",
		"task_id": "TASK_1171",
		"status": "recaptured",
		"ready_for_first_contact_recapture": true,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_effect": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
	}


func _build_task_542_contact_readability_fixture() -> Dictionary:
	var first_contact := {
		"fireteam_id": "blue",
		"unit_id": "enemy_probe_01",
		"detection_state": "confirmed",
		"last_known_position": Vector2(602.0, 288.0),
		"confidence": 0.82,
		"report_text": "1 Kontakt, vermutlich Rifleman, zuletzt vor 2s gesehen",
	}
	return {
		"task_id": "TASK_542",
		"gate": "pass",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"selected_fireteam_ids": ["blue"],
		"selected_contact_count": 1,
		"selected_contacts": [first_contact],
		"first_contact": first_contact,
		"contact_overlay_visible_count": 1,
		"contact_overlay_contacts": [first_contact],
		"primary_contact_snapshot": {
			"contact_count": 1,
			"contact_entries": [first_contact],
		},
		"security_state": {
			"fireteam_id": "blue",
			"is_active": true,
			"main_threat_position": Vector2(602.0, 288.0),
		},
		"cover_effectiveness_readout": {
			"readout_text": "Kontakt sichtbar, Deckung pruefen",
			"contact_readouts": [first_contact],
		},
		"contact_decision_diagnostics": {
			"status": "contact_visible",
			"reason": "selected_fireteam_has_contact",
		},
		"tactical_communication_event_count": 1,
		"tactical_event_log_count": 1,
		"contact_feedback_text": "KONTAKT | 1 Gegner | Deckung pruefen",
		"checks": [
			{"id": "selected_fireteam_has_contact", "passed": true},
			{"id": "contact_fields_visible", "passed": true},
			{"id": "contact_report_text_visible", "passed": true},
			{"id": "contact_overlay_or_primary_visible", "passed": true},
			{"id": "tactical_feedback_mentions_contact", "passed": true},
			{"id": "threat_or_cover_context_visible", "passed": true},
			{"id": "read_only", "passed": true},
		],
		"failed_checks": [],
	}


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
