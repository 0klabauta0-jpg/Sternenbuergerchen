extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_335_tactical_feedback_truth_command_clarity_pass.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/tactical_feedback_truth_command_clarity_pass.md"
const CONTRACT_PATH: String = "res://scripts/ui/mission_command_hierarchy_contract.gd"
const ADAPTER_PATH: String = "res://scripts/mission/mission_command_feedback_snapshot_adapter.gd"

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const COMMAND_HIERARCHY_CONTRACT: GDScript = preload("res://scripts/ui/mission_command_hierarchy_contract.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_335 Tactical Feedback Truth Command Clarity Pass ===")
	_test_docs_status_and_report()
	_test_static_feedback_truth_boundary()
	_test_contract_reason_codes()
	await _test_live_command_feedback_clarity()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_docs_status_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	_assert(task_text.contains("## Status: IMPLEMENTIERT"), "TASK_335 task file marks implemented")
	_assert(not task_text.contains("- [ ]"), "TASK_335 checklist is complete")
	_assert(status_text.contains("### TASK_335 - Tactical Feedback Truth Command Clarity Pass") and status_text.contains("- Status: implementiert"), "Implementation status marks TASK_335 implemented")
	_assert(roadmap_text.contains("TASK_335 - Tactical Feedback Truth Command Clarity Pass (implementiert"), "Roadmap marks TASK_335 implemented")
	for token in ["Disabled-Reasons", "Tooltips", "Air Lane", "keine Gameplay-Wahrheit", "Playtest"]:
		_assert(report_text.to_lower().contains(token.to_lower()), "Report documents %s" % token)


func _test_static_feedback_truth_boundary() -> void:
	var contract_text: String = _read_text(CONTRACT_PATH)
	var adapter_text: String = _read_text(ADAPTER_PATH)
	_assert(contract_text.contains("UI_SETS_GAMEPLAY_TRUTH: bool = false"), "Command hierarchy contract declares UI truth boundary")
	_assert(contract_text.contains("disabled_reason_code"), "Command hierarchy exposes reason codes")
	_assert(contract_text.contains("get_disabled_reason_text"), "Command hierarchy exposes playable reason text")
	_assert(adapter_text.contains("\"command_clarity\""), "Feedback adapter forwards command clarity snapshot")
	for token in ["enqueue_command", "enqueue_effect", "set_runtime_status", "assign_unit_command", "drop_ship_requested ="]:
		_assert(not contract_text.contains(token), "UI contract contains no gameplay mutation token %s" % token)
		_assert(not adapter_text.contains(token), "Feedback adapter contains no gameplay mutation token %s" % token)


func _test_contract_reason_codes() -> void:
	var move_action: Dictionary = _get_contract_action("move")
	var call_action: Dictionary = _get_contract_action("call_dropship")
	var go_action: Dictionary = _get_contract_action("go_plan")
	_assert(not move_action.is_empty() and not call_action.is_empty() and not go_action.is_empty(), "Contract exposes core command actions")

	var no_selection: Dictionary = _build_contract_snapshot({
		"selected_fireteam_count": 0,
		"can_issue_local_commands": true,
		"can_edit_planning": true,
		"has_selected_tile": false,
		"selected_tile_valid": false,
		"requires_tile_selection": true,
	})
	var no_selection_move: Dictionary = _get_action_from_snapshot(no_selection, "move")
	_assert(String(no_selection_move.get("disabled_reason_code", "")) == "no_fireteam_selected", "Move distinguishes missing fireteam selection")
	_assert(String(no_selection_move.get("disabled_reason", "")).contains("select"), "Move keeps legacy no-selection reason")
	_assert(String(no_selection_move.get("disabled_reason_text", "")).contains("Select a fireteam"), "Move exposes short playable no-selection text")

	var no_tile: Dictionary = _build_contract_snapshot({
		"selected_fireteam_count": 1,
		"can_issue_local_commands": true,
		"can_edit_planning": true,
		"has_selected_tile": false,
		"selected_tile_valid": false,
		"requires_tile_selection": true,
	})
	var no_tile_move: Dictionary = _get_action_from_snapshot(no_tile, "move")
	_assert(String(no_tile_move.get("disabled_reason_code", "")) == "no_selected_tile", "Move distinguishes missing tile")
	_assert(String(no_tile_move.get("disabled_reason", "")).contains("map tile"), "Move keeps legacy missing-tile reason")

	var invalid_tile: Dictionary = _build_contract_snapshot({
		"selected_fireteam_count": 1,
		"can_issue_local_commands": true,
		"can_edit_planning": true,
		"has_selected_tile": true,
		"selected_tile_valid": false,
		"requires_tile_selection": true,
	})
	var invalid_tile_move: Dictionary = _get_action_from_snapshot(invalid_tile, "move")
	_assert(String(invalid_tile_move.get("disabled_reason_code", "")) == "invalid_selected_tile", "Move distinguishes invalid selected tile")

	var missing_lz: Dictionary = _build_contract_snapshot({
		"can_edit_planning": true,
		"drop_available": true,
		"drop_has_team": true,
		"has_lz": false,
	})
	_assert(String(_get_action_from_snapshot(missing_lz, "call_dropship").get("disabled_reason_code", "")) == "no_lz", "Drop distinguishes missing LZ")

	var air_blocked: Dictionary = _build_contract_snapshot({
		"can_edit_planning": true,
		"drop_available": true,
		"drop_has_team": true,
		"has_lz": true,
		"drop_air_lane_blocked": true,
	})
	_assert(String(_get_action_from_snapshot(air_blocked, "call_dropship").get("disabled_reason_code", "")) == "drop_air_lane_blocked", "Drop distinguishes blocked air lane")

	var no_team: Dictionary = _build_contract_snapshot({
		"can_edit_planning": true,
		"drop_available": true,
		"drop_has_team": false,
		"has_lz": true,
	})
	_assert(String(_get_action_from_snapshot(no_team, "call_dropship").get("disabled_reason_code", "")) == "no_drop_team", "Drop distinguishes missing drop team")

	var no_orders: Dictionary = _build_contract_snapshot({
		"selected_fireteam_count": 1,
		"can_issue_local_commands": true,
		"has_selected_fireteam_orders_to_execute": false,
	})
	_assert(String(_get_action_from_snapshot(no_orders, "go_plan").get("disabled_reason_code", "")) == "no_executable_orders", "GO distinguishes missing executable orders")

	var metadata: Dictionary = Dictionary(COMMAND_HIERARCHY_CONTRACT.call("build_button_metadata", call_action, {
		"can_edit_planning": true,
		"drop_available": true,
		"drop_has_team": true,
		"has_lz": false,
	}, {}))
	_assert(String(metadata.get("command_hierarchy_disabled_reason_code", "")) == "no_lz", "Button metadata mirrors disabled reason code")
	_assert(String(metadata.get("command_hierarchy_disabled_reason_text", "")).contains("Set LZ"), "Button metadata mirrors playable disabled reason text")


func _test_live_command_feedback_clarity() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(24)

	var controller := scene.get_node_or_null("TacticalController")
	var simulation_root := scene.get_node_or_null("SimulationRoot")
	_assert(controller != null and simulation_root != null, "Mission scene exposes controller and SimulationRoot")
	if controller == null or simulation_root == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	var command_count_before: int = simulation_root.command_queue.size()
	var effect_count_before: int = simulation_root.effects_queue.size()

	controller.call("_set_selected_fireteams", PackedStringArray(), false)
	await _wait_frames(6)
	var no_selection_feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	var no_selection_move: Dictionary = _get_feedback_action(no_selection_feedback, "move")
	var no_selection_move_button: Dictionary = _get_feedback_button(no_selection_feedback, "move")
	var no_selection_clarity: Dictionary = Dictionary(no_selection_feedback.get("command_clarity", {}))
	_assert(String(no_selection_move.get("disabled_reason_code", "")) == "no_fireteam_selected", "Live feedback codes missing selection")
	_assert(String(no_selection_move_button.get("command_hierarchy_disabled_reason_code", "")) == "no_fireteam_selected", "Live button metadata codes missing selection")
	_assert(String(no_selection_move_button.get("tooltip_text", "")).contains("Select a fireteam"), "Move tooltip shows playable missing-selection hint")
	_assert(bool(no_selection_clarity.get("visual_only", false)) and not bool(no_selection_clarity.get("ui_sets_gameplay_truth", true)), "Command clarity snapshot stays visual-only")
	_assert(Dictionary(no_selection_clarity.get("blocked_reasons_by_action", {})).has("move"), "Command clarity lists blocked move action")

	var fireteam_id: String = _get_alpha_driver_fireteam_id(scene, controller)
	_assert(not fireteam_id.is_empty(), "Verifier resolves a selectable fireteam")
	var planning_state: Dictionary = Dictionary(controller.call("get_planning_state"))
	planning_state["selected_fireteams"] = [fireteam_id]
	planning_state["embarked_unit_ids"] = []
	planning_state["deployed_unit_ids"] = _get_all_friendly_unit_ids(controller)
	planning_state["has_selected_tile"] = false
	controller.call("set_planning_state", planning_state)
	controller.call("_set_selected_fireteams", PackedStringArray([fireteam_id]), false)
	await _wait_frames(6)
	var no_tile_feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	var no_tile_move: Dictionary = _get_feedback_action(no_tile_feedback, "move")
	_assert(String(no_tile_move.get("disabled_reason_code", "")) == "no_selected_tile", "Live feedback codes missing tile")
	_assert(String(_get_feedback_button(no_tile_feedback, "move").get("tooltip_text", "")).contains("Pick a map tile"), "Move tooltip shows playable tile hint")
	_assert(not bool(controller.call("issue_move")), "Move command remains blocked before tile selection")
	_assert(String(Dictionary(controller.call("get_command_feedback_snapshot")).get("last_command_text", "")).contains("SELECT TILE"), "Blocked move writes tile command feedback")

	planning_state = Dictionary(controller.call("get_planning_state"))
	planning_state["has_selected_tile"] = true
	planning_state["selected_tile_grid_position"] = Vector2i(0, 0)
	planning_state["selected_tile_world_position"] = Vector2(999999.0, 999999.0)
	planning_state["selected_tile"] = {
		"has_selected_tile": true,
		"grid_position": Vector2i(0, 0),
		"world_position": Vector2(999999.0, 999999.0),
	}
	controller.call("set_planning_state", planning_state)
	await _wait_frames(6)
	var invalid_tile_feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	_assert(String(_get_feedback_action(invalid_tile_feedback, "move").get("disabled_reason_code", "")) == "invalid_selected_tile", "Live feedback codes invalid tile")
	_assert(not bool(controller.call("issue_move")), "Move command remains blocked for invalid selected tile")
	_assert(String(Dictionary(controller.call("get_command_feedback_snapshot")).get("last_command_text", "")).contains("INVALID TILE"), "Blocked move writes invalid tile command feedback")

	var friendly_ids: Array = _get_all_friendly_unit_ids(controller)
	_assert(not friendly_ids.is_empty(), "Verifier resolves friendly unit payload ids")
	var payload_id: String = String(friendly_ids[0])
	var drop_state: Dictionary = Dictionary(controller.call("get_planning_state"))
	drop_state["mission_drop_craft_id"] = "dropship_test"
	drop_state["mission_drop_display_name"] = "Dropship Test"
	drop_state["mission_drop_state"] = "waiting"
	drop_state["drop_ship_requested"] = false
	drop_state["drop_ship_staged"] = false
	drop_state["mission_drop_cards"] = [_build_drop_card("dropship_test", "waiting", [payload_id], false)]
	drop_state["embarked_unit_ids"] = [payload_id]
	drop_state["deployed_unit_ids"] = []
	drop_state["has_lz_position"] = false
	controller.call("set_planning_state", drop_state)
	await _wait_frames(6)
	var missing_lz_feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	_assert(String(_get_feedback_action(missing_lz_feedback, "call_dropship").get("disabled_reason_code", "")) == "no_lz", "Live drop feedback codes missing LZ")
	_assert(String(_get_feedback_button(missing_lz_feedback, "call_dropship").get("text", "")).contains("LZ"), "Drop button label exposes missing LZ")

	drop_state = Dictionary(controller.call("get_planning_state"))
	drop_state["has_lz_position"] = true
	drop_state["lz_position"] = Vector2(448.0, 285.0)
	drop_state["mission_drop_cards"] = [_build_drop_card("dropship_test", "waiting", [], true)]
	drop_state["embarked_unit_ids"] = []
	drop_state["deployed_unit_ids"] = friendly_ids
	controller.call("set_planning_state", drop_state)
	await _wait_frames(6)
	var no_team_feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	_assert(String(_get_feedback_action(no_team_feedback, "call_dropship").get("disabled_reason_code", "")) == "no_drop_team", "Live drop feedback codes missing team")
	_assert(String(Dictionary(no_team_feedback.get("command_clarity", {})).get("primary_hint", "")).strip_edges().length() > 0, "Command clarity exposes a primary hint")

	drop_state = Dictionary(controller.call("get_planning_state"))
	drop_state["mission_drop_cards"] = [_build_drop_card("dropship_test", "waiting", [payload_id], true)]
	drop_state["embarked_unit_ids"] = [payload_id]
	drop_state["deployed_unit_ids"] = []
	controller.call("set_planning_state", drop_state)
	controller.set("_drop_sequence_phase", "inbound")
	controller.set("_drop_sequence_craft_id", "dropship_busy")
	controller.call("_refresh_button_state")
	controller.call("_update_ui")
	await _wait_frames(6)
	var air_lane_feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	_assert(String(_get_feedback_action(air_lane_feedback, "call_dropship").get("disabled_reason_code", "")) == "drop_air_lane_blocked", "Live drop feedback codes blocked air lane")
	_assert(bool(Dictionary(air_lane_feedback.get("command_clarity", {})).get("drop_air_lane_blocked", false)), "Command clarity flags blocked air lane")

	command_count_before = simulation_root.command_queue.size()
	effect_count_before = simulation_root.effects_queue.size()
	var feedback_readback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	_assert(feedback_readback.has("command_clarity"), "Feedback readback includes command clarity snapshot")
	_assert(simulation_root.command_queue.size() == command_count_before, "Feedback reads enqueue no SimulationRoot commands")
	_assert(simulation_root.effects_queue.size() == effect_count_before, "Feedback reads enqueue no SimulationRoot effects")

	scene.queue_free()
	await _wait_frames(2)


func _build_contract_snapshot(context: Dictionary) -> Dictionary:
	var defaults: Dictionary = {
		"selected_fireteam_count": int(context.get("selected_fireteam_count", 0)),
		"single_fireteam_context": int(context.get("selected_fireteam_count", 0)) == 1,
		"multi_fireteam_context": int(context.get("selected_fireteam_count", 0)) > 1,
		"preview_mode": false,
		"can_issue_local_commands": true,
		"can_edit_planning": true,
		"phase_planning_enabled": true,
		"has_selected_tile": false,
		"selected_tile_valid": true,
		"requires_tile_selection": true,
		"drop_available": true,
		"drop_already_active": false,
		"drop_air_lane_blocked": false,
		"drop_has_team": true,
		"has_lz": true,
		"drop_cooldown_remaining": 0.0,
		"has_selected_fireteam_orders_to_execute": true,
		"can_return_selected_fireteams_to_plan": true,
		"has_deletable_order_focus": true,
	}
	defaults.merge(context, true)
	return Dictionary(COMMAND_HIERARCHY_CONTRACT.call("build_hierarchy_snapshot", defaults, {}))


func _get_contract_action(action_id: String) -> Dictionary:
	for action_variant in Array(COMMAND_HIERARCHY_CONTRACT.call("get_action_catalog")):
		var action: Dictionary = Dictionary(action_variant)
		if String(action.get("action_id", "")) == action_id:
			return action
	return {}


func _get_action_from_snapshot(snapshot: Dictionary, action_id: String) -> Dictionary:
	return Dictionary(Dictionary(snapshot.get("actions_by_id", {})).get(action_id, {}))


func _get_feedback_action(feedback: Dictionary, action_id: String) -> Dictionary:
	return _get_action_from_snapshot(Dictionary(feedback.get("command_hierarchy", {})), action_id)


func _get_feedback_button(feedback: Dictionary, action_id: String) -> Dictionary:
	return Dictionary(Dictionary(feedback.get("command_buttons", {})).get(action_id, {}))


func _build_drop_card(craft_id: String, state: String, embarked_unit_ids: Array, has_lz: bool) -> Dictionary:
	return {
		"craft_id": craft_id,
		"display_name": "Dropship Test",
		"state": state,
		"passenger_count": embarked_unit_ids.size(),
		"embarked_unit_ids": embarked_unit_ids,
		"boarded_fireteam_ids": [],
		"queued_fireteam_ids": [],
		"has_lz_position": has_lz,
		"lz_position": Vector2(448.0, 285.0),
		"approach_angle": "NW",
	}


func _get_alpha_driver_fireteam_id(scene: Node, controller: Node) -> String:
	var alpha_driver := scene.get_node_or_null("AlphaFlowDriver")
	if alpha_driver != null:
		var fireteam_id: String = String(controller.call("_get_fireteam_id_for_flow_driver", alpha_driver)).strip_edges().to_lower()
		if not fireteam_id.is_empty():
			return fireteam_id
	var fireteams: PackedStringArray = PackedStringArray(controller.call("_get_available_fireteam_ids"))
	return String(fireteams[0]).strip_edges().to_lower() if fireteams.size() > 0 else ""


func _get_all_friendly_unit_ids(controller: Node) -> Array:
	var result: Array = []
	for unit in Array(controller.call("_get_all_friendly_units", true)):
		if unit != null and unit.has_method("get_unit_id"):
			var unit_id: String = String(unit.call("get_unit_id")).strip_edges()
			if not unit_id.is_empty():
				result.append(unit_id)
	return result


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


func _wait_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
