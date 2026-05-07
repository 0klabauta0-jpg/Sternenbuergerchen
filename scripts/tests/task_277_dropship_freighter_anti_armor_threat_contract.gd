extends SceneTree

const AIR_ASSET_STATUS_SCRIPT: GDScript = preload("res://scripts/mission/air_asset_status.gd")
const AIR_ASSET_THREAT_RESOLVER_SCRIPT: GDScript = preload("res://scripts/combat/air_asset_threat_resolver.gd")
const WEAPON_DATA_SCRIPT: GDScript = preload("res://scripts/core/weapon_data.gd")
const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

const DOC_PATH: String = "res://docs/dev/air_asset_threat_damage_contract.md"
const TASK_PATH: String = "res://docs/tasks/TASK_277_dropship_freighter_anti_armor_threat_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_277 Dropship Freighter Anti Armor Threat Contract ===")
	_test_contract_files_and_weapon_gate()
	_test_status_model()
	_test_resolver_gates_and_warning()
	_test_lz_security_risk_modifier()
	await _test_mission_controller_authority_feedback()
	_test_task_status()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_contract_files_and_weapon_gate() -> void:
	_assert(FileAccess.file_exists(DOC_PATH), "Air asset threat contract doc exists")
	_assert(FileAccess.file_exists("res://scripts/mission/air_asset_status.gd"), "AirAssetStatus script exists")
	_assert(FileAccess.file_exists("res://scripts/combat/air_asset_threat_resolver.gd"), "AirAssetThreatResolver script exists")
	_assert(bool(WEAPON_DATA_SCRIPT.call("is_anti_armor_weapon_id", "rocket_launcher")), "Rocket launcher is anti-armor")
	_assert(bool(WEAPON_DATA_SCRIPT.call("is_anti_armor_weapon_id", "rail_gun")), "Rail gun is anti-armor")
	_assert(not bool(WEAPON_DATA_SCRIPT.call("is_anti_armor_weapon_id", "rifle")), "Rifle is not anti-armor")
	_assert(not bool(WEAPON_DATA_SCRIPT.call("is_anti_armor_weapon_id", "smg")), "SMG is not anti-armor")
	var doc_text: String = _read_text(DOC_PATH)
	for token in ["threatened", "locked", "damaged", "crashed", "rocket_launcher", "rail_gun", "range_tiles", "visible_in_fow", "ui_sets_gameplay_truth = false", "SimulationRoot"]:
		_assert(doc_text.contains(token), "Contract doc contains %s" % token)


func _test_status_model() -> void:
	var status = AIR_ASSET_STATUS_SCRIPT.call("from_dict", {
		"asset_id": "drop_01",
		"asset_type": "dropship",
		"state": "intact",
		"integrity": 100,
		"position": Vector2(320.0, 240.0),
	})
	_assert(status != null and bool(status.call("is_valid")), "AirAssetStatus validates base status")
	var snapshot: Dictionary = Dictionary(status.call("to_snapshot"))
	_assert(str(snapshot.get("runtime_authority", "")) == "SimulationRoot", "AirAssetStatus snapshot declares SimulationRoot authority")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "AirAssetStatus snapshot does not grant UI truth")
	status.call("apply_threat", {
		"event_id": "warn",
		"next_state": "locked",
		"weapon_id": "rocket_launcher",
		"risk": 0.7,
		"warning_visible": true,
	})
	var locked: Dictionary = Dictionary(status.call("to_snapshot"))
	_assert(str(locked.get("state", "")) == "locked" and bool(locked.get("warning_visible", false)), "Threat moves status into warning state")
	status.call("apply_damage", 125, {"terminal_state": "crashed"})
	var crashed: Dictionary = Dictionary(status.call("to_snapshot"))
	_assert(str(crashed.get("state", "")) == "crashed" and bool(crashed.get("terminal_state", false)), "Damage can terminally crash the asset")


func _test_resolver_gates_and_warning() -> void:
	var resolver = AIR_ASSET_THREAT_RESOLVER_SCRIPT.new()
	var status = _base_status()
	var rifle: Dictionary = Dictionary(resolver.call("evaluate_threat", status, _base_context({"weapon_id": "rifle", "sequence": "rifle"})))
	_assert(not bool(rifle.get("eligible", true)) and str(rifle.get("blocked_reason", "")) == "weapon_not_anti_armor", "Non anti-armor weapon is blocked")
	var range_blocked: Dictionary = Dictionary(resolver.call("evaluate_threat", status, _base_context({"range_tiles": 99.0, "sequence": "range"})))
	_assert(not bool(range_blocked.get("eligible", true)) and str(range_blocked.get("blocked_reason", "")) == "out_of_range", "Out-of-range threat is blocked")
	var los_blocked: Dictionary = Dictionary(resolver.call("evaluate_threat", status, _base_context({"has_line_of_sight": false, "sequence": "los"})))
	_assert(not bool(los_blocked.get("eligible", true)) and str(los_blocked.get("blocked_reason", "")) == "no_line_of_sight", "No-LOS threat is blocked")
	var fow_blocked: Dictionary = Dictionary(resolver.call("evaluate_threat", status, _base_context({"visible_in_fow": false, "sequence": "fow"})))
	_assert(not bool(fow_blocked.get("eligible", true)) and str(fow_blocked.get("blocked_reason", "")) == "not_visible_in_fow", "FoW-hidden threat is blocked")
	var altitude_blocked: Dictionary = Dictionary(resolver.call("evaluate_threat", status, _base_context({"altitude_layer": "high", "sequence": "altitude"})))
	_assert(not bool(altitude_blocked.get("eligible", true)) and str(altitude_blocked.get("blocked_reason", "")) == "altitude_not_vulnerable", "Safe altitude threat is blocked")

	var warning: Dictionary = Dictionary(resolver.call("evaluate_threat", status, _base_context({"sequence": "warning"})))
	_assert(bool(warning.get("eligible", false)), "Rocket threat is eligible")
	_assert(bool(warning.get("warning_required", false)) and bool(warning.get("warning_visible", false)), "First eligible threat creates visible warning")
	_assert(not bool(warning.get("hit_allowed", true)) and not bool(warning.get("destroy_allowed", true)), "First threat cannot instantly hit or destroy")
	_assert(not Dictionary(warning.get("simulation_effect", {})).is_empty(), "Warning threat builds SimulationRoot effect")

	var hit_status = AIR_ASSET_STATUS_SCRIPT.call("from_dict", Dictionary(warning.get("next_status", {})))
	var hit: Dictionary = Dictionary(resolver.call("evaluate_threat", hit_status, _base_context({"warning_seen": true, "damage": 45, "sequence": "hit"})))
	_assert(bool(hit.get("hit_allowed", false)) and int(hit.get("damage", 0)) == 45, "Second warned threat can hit")
	_assert(["hit", "damaged"].has(str(hit.get("next_state", ""))), "Hit resolves into hit or damaged state")
	_assert(Array(hit.get("vfx_events", [])).size() >= 2 and Array(hit.get("sfx_events", [])).size() >= 2, "Hit carries VFX/SFX events")

	var fragile_status = AIR_ASSET_STATUS_SCRIPT.call("from_dict", {"asset_id": "drop_01", "state": "locked", "integrity": 30, "warning_visible": true})
	var destroyed: Dictionary = Dictionary(resolver.call("evaluate_threat", fragile_status, _base_context({"warning_seen": true, "damage": 120, "sequence": "destroy"})))
	_assert(bool(destroyed.get("destroy_allowed", false)), "Warned lethal damage can destroy")
	_assert(str(destroyed.get("tactical_breakout_trigger", "")) == "air_asset_destroyed", "Destroyed threat emits air asset breakout trigger")


func _test_lz_security_risk_modifier() -> void:
	var resolver = AIR_ASSET_THREAT_RESOLVER_SCRIPT.new()
	var low_security: Dictionary = Dictionary(resolver.call("evaluate_threat", _base_status(), _base_context({"lz_secure_level": 0.0, "enemy_at_pressure": 0.8, "sequence": "low"})))
	var high_security: Dictionary = Dictionary(resolver.call("evaluate_threat", _base_status(), _base_context({"lz_secure_level": 0.9, "enemy_at_pressure": 0.8, "sequence": "high"})))
	_assert(float(high_security.get("risk", 1.0)) < float(low_security.get("risk", 0.0)), "LZ security lowers air asset risk")


func _test_mission_controller_authority_feedback() -> void:
	root.size = Vector2i(1920, 1080)
	var scene := MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(8)
	var controller: Node = scene.get_node("TacticalController")
	_assert(controller != null and controller.has_method("apply_air_asset_threat"), "Controller exposes air asset threat application")
	if controller == null:
		return
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	controller.call("set_air_asset_lz_secure_level_for_test", 0.1)
	var warning: Dictionary = Dictionary(controller.call("apply_air_asset_threat", {
		"weapon_id": "rocket_launcher",
		"attacker_unit_id": "enemy_at_01",
		"range_tiles": 8.0,
		"has_line_of_sight": true,
		"visible_in_fow": true,
		"altitude_layer": "low",
		"enemy_at_pressure": 0.8,
		"sequence": "mission_warning",
	}))
	_assert(bool(warning.get("warning_required", false)), "Controller applies warning before damage")
	var feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	var air_status: Dictionary = Dictionary(feedback.get("air_asset_status", {}))
	_assert(bool(air_status.get("warning_visible", false)), "Command feedback exposes air asset warning")
	_assert(int(feedback.get("air_asset_threat_count", 0)) >= 1, "Command feedback records air asset threat")
	_assert(int(feedback.get("tactical_communication_event_count", 0)) >= 1, "Air threat emits communication event")
	_assert(int(feedback.get("tactical_breakout_count", 0)) >= 1, "Air threat emits breakout record")

	await _wait_physics_frames(3)
	var simulation_root: Node = scene.get_node("SimulationRoot")
	var asset_id: String = str(warning.get("asset_id", "mission_dropship"))
	var sim_warning: Dictionary = Dictionary(simulation_root.call("get_air_asset_status_snapshot", asset_id))
	_assert(str(sim_warning.get("runtime_authority", "")) == "SimulationRoot" and str(sim_warning.get("state", "")) == str(warning.get("next_state", "")), "SimulationRoot stores authoritative warning snapshot")

	var destroyed: Dictionary = Dictionary(controller.call("apply_air_asset_threat", {
		"weapon_id": "rocket_launcher",
		"attacker_unit_id": "enemy_at_01",
		"range_tiles": 6.0,
		"warning_seen": true,
		"damage": 150,
		"enemy_at_pressure": 0.9,
		"sequence": "mission_destroy",
	}))
	_assert(bool(destroyed.get("destroy_allowed", false)), "Controller permits destroy only after warning")
	await _wait_physics_frames(3)
	var sim_destroyed: Dictionary = Dictionary(simulation_root.call("get_air_asset_status_snapshot", asset_id))
	_assert(bool(sim_destroyed.get("terminal_state", false)) or ["destroyed", "crashed"].has(str(sim_destroyed.get("state", ""))), "SimulationRoot stores terminal air asset state")
	scene.queue_free()
	await _wait_frames(2)


func _test_task_status() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	_assert(task_text.contains("## Status: IMPLEMENTIERT"), "Task file marks TASK_277 implemented")
	_assert(not task_text.contains("- [ ]"), "Task checklist is complete")
	_assert(status_text.contains("TASK_277") and status_text.to_lower().contains("implementiert"), "Implementation status mentions TASK_277 implemented")
	_assert(roadmap_text.contains("TASK_277") and roadmap_text.to_lower().contains("implementiert"), "Roadmap mentions TASK_277 implemented")


func _base_status() -> Dictionary:
	return {
		"asset_id": "drop_01",
		"asset_type": "dropship",
		"display_name": "Drop 01",
		"state": "intact",
		"integrity": 100,
		"max_integrity": 100,
		"position": Vector2(500.0, 500.0),
	}


func _base_context(overrides: Dictionary = {}) -> Dictionary:
	var context: Dictionary = {
		"weapon_id": "rocket_launcher",
		"attacker_unit_id": "enemy_at",
		"range_tiles": 8.0,
		"has_line_of_sight": true,
		"visible_in_fow": true,
		"altitude_layer": "low",
		"lz_secure_level": 0.25,
		"enemy_at_pressure": 0.6,
		"enemy_security_pressure": 0.35,
	}
	context.merge(overrides, true)
	return context


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _wait_physics_frames(count: int) -> void:
	for _index in range(count):
		await physics_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
