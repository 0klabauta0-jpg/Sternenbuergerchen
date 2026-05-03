extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const OBJECTIVE_STATUS_SCRIPT: GDScript = preload("res://scripts/core/objective_status.gd")
const MISSION_COMBAT_AUTHORITY_CONTRACT_SCRIPT: GDScript = preload("res://scripts/mission/mission_combat_authority_contract.gd")
const MISSION_COMBAT_REMOTE_EVENT_BRIDGE_SCRIPT: GDScript = preload("res://scripts/mission/mission_combat_remote_event_bridge.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_162 Combat Authority Contract Verifier ===")
	_test_contract_lists_authority_boundaries()
	_test_snapshot_builder_merges_objective_and_result_state()
	_test_remote_event_payload_is_read_only()
	await _test_live_driver_exposes_contract_and_snapshot()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_contract_lists_authority_boundaries() -> void:
	var contract: Dictionary = Dictionary(MISSION_COMBAT_AUTHORITY_CONTRACT_SCRIPT.call("get_contract_snapshot"))
	var playability_keys: Array = Array(contract.get("playability_snapshot_keys", []))
	var objective_keys: Array = Array(contract.get("objective_state_keys", []))
	var contact_keys: Array = Array(contract.get("contact_state_keys", []))
	var result_keys: Array = Array(contract.get("mission_result_keys", []))
	var ui_event_keys: Array = Array(contract.get("read_only_ui_event_keys", []))
	var effect_types: Array = Array(contract.get("authoritative_effect_types", []))
	_assert(playability_keys.has("combat_state") and playability_keys.has("objective_capture_progress"), "Contract documents playability snapshot keys")
	_assert(objective_keys.has("objective_position") and objective_keys.has("objective_contested"), "Contract documents objective state keys")
	_assert(contact_keys.has("detection_state") and contact_keys.has("last_known_position"), "Contract documents contact state keys")
	_assert(result_keys.has("result") and result_keys.has("team_states"), "Contract documents mission result keys")
	_assert(ui_event_keys.has("read_only") and ui_event_keys.has("event_text"), "Contract documents read-only UI event keys")
	_assert(effect_types.has("damage") and effect_types.has("heal") and effect_types.has("bleedout") and effect_types.has("respawn"), "Contract lists combat effects committed through SimulationRoot")
	_assert(effect_types.has("dropship_embark_unit") and effect_types.has("dropship_deploy_unit"), "Contract lists dropship effects committed through SimulationRoot")
	_assert(bool(MISSION_COMBAT_AUTHORITY_CONTRACT_SCRIPT.call("is_authoritative_effect_type", "damage")), "Contract accepts known authoritative effect type")
	_assert(not bool(MISSION_COMBAT_AUTHORITY_CONTRACT_SCRIPT.call("is_authoritative_effect_type", "ui_event")), "Contract rejects read-only UI events as authoritative effects")


func _test_snapshot_builder_merges_objective_and_result_state() -> void:
	var objective = OBJECTIVE_STATUS_SCRIPT.new()
	objective.position = Vector2(448.0, 285.0)
	objective.capture_radius = 72.0
	objective.owning_team_id = "team_alpha"
	objective.capturing_team_id = "team_alpha"
	objective.capture_progress = 1.25
	objective.call("set_contested", true)
	var mission_result: Dictionary = Dictionary(
		MISSION_COMBAT_AUTHORITY_CONTRACT_SCRIPT.call(
			"build_mission_result",
			"victory",
			"team_alpha",
			"team_alpha",
			"objective_capture",
			true,
			12.5,
			[{"unit_id": "unit_alpha", "vital_state": "fit"}]
		)
	)
	var snapshot: Dictionary = Dictionary(
		MISSION_COMBAT_AUTHORITY_CONTRACT_SCRIPT.call(
			"build_playability_snapshot",
			{
				"combat_state": "resolved",
				"win_condition_type": "elimination",
				"mission_resolved": true,
				"result": "",
				"winning_team_id": "team_alpha",
				"enemy_fit_count": 0,
				"friendly_fit_count": 1,
				"duration_seconds": 12.5,
				"remaining_time_limit_seconds": -1.0,
				"last_event_text": "MISSION VICTORY",
			},
			objective,
			mission_result
		)
	)
	_assert(String(snapshot.get("result", "")) == "victory", "Snapshot builder overlays mission result")
	_assert(String(snapshot.get("win_condition_type", "")) == "objective_capture", "Snapshot builder preserves mission result win condition")
	_assert(is_equal_approx(float(snapshot.get("objective_capture_progress", 0.0)), 1.0), "Snapshot builder clamps objective progress")
	_assert(bool(snapshot.get("objective_contested", false)), "Snapshot builder includes objective contested state")
	_assert(bool(snapshot.get("objective_captured", false)), "Snapshot builder includes captured state from mission result")


func _test_remote_event_payload_is_read_only() -> void:
	var bridge = MISSION_COMBAT_REMOTE_EVENT_BRIDGE_SCRIPT.new()
	var payload: Dictionary = Dictionary(bridge.call("build_event_payload", "unit_alpha HIT", "unit_alpha", Color(1.0, 0.5, 0.25, 1.0), 1.4, "HIT"))
	_assert(String(payload.get("event_type", "")) == "combat_ui_event", "Remote event bridge marks combat UI event payloads")
	_assert(bool(payload.get("read_only", false)), "Remote event bridge marks events read-only")
	_assert(String(payload.get("event_text", "")) == "unit_alpha HIT", "Remote event bridge preserves event text")
	_assert(String(payload.get("unit_id", "")) == "unit_alpha", "Remote event bridge preserves unit id")


func _test_live_driver_exposes_contract_and_snapshot() -> void:
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(8)
	await _wait_physics_frames(2)
	var combat_driver := scene.get_node_or_null("CombatLoopDriver")
	_assert(combat_driver != null and combat_driver.has_method("get_authority_contract_snapshot"), "Live CombatLoopDriver exposes authority contract snapshot")
	_assert(combat_driver != null and combat_driver.has_method("get_playability_snapshot"), "Live CombatLoopDriver exposes playability snapshot")
	if combat_driver != null:
		var contract: Dictionary = Dictionary(combat_driver.call("get_authority_contract_snapshot"))
		var snapshot: Dictionary = Dictionary(combat_driver.call("get_playability_snapshot"))
		_assert(Array(contract.get("authoritative_effect_types", [])).has("damage"), "Live driver contract includes damage as SimulationRoot effect")
		_assert(snapshot.has("combat_state") and snapshot.has("friendly_fit_count"), "Live driver playability snapshot keeps base combat keys")
		_assert(snapshot.has("objective_capture_progress") and snapshot.has("objective_contested"), "Live driver playability snapshot includes objective state")
	scene.queue_free()
	await _wait_frames(2)


func _wait_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await process_frame


func _wait_physics_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await physics_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
