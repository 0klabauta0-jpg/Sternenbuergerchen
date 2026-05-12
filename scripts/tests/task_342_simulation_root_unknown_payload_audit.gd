extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_342_simulation_root_unknown_payload_audit.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/simulation_root_unknown_payload_audit.md"
const SIMULATION_ROOT_PATH: String = "res://scripts/core/simulation_root.gd"

const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_342 SimulationRoot Unknown Payload Audit ===")
	_test_docs_status_and_static_boundary()
	_test_unknown_command_is_diagnosed_without_crash()
	_test_unknown_effect_is_diagnosed_without_crash()
	_test_known_command_and_effect_do_not_raise_unknown_counters()
	_test_multiplayer_reject_does_not_count_as_unknown_payload()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_docs_status_and_static_boundary() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var simulation_text: String = _read_text(SIMULATION_ROOT_PATH)
	_assert(task_text.contains("## Status: IMPLEMENTIERT"), "TASK_342 task file marks implemented")
	_assert(not task_text.contains("- [ ]"), "TASK_342 checklist is complete")
	_assert(status_text.contains("### TASK_342 - SimulationRoot Unknown Payload Audit") and status_text.contains("- Status: implementiert"), "Implementation status marks TASK_342 implemented")
	_assert(roadmap_text.contains("TASK_342 - SimulationRoot Unknown Payload Audit (implementiert"), "Roadmap marks TASK_342 implemented")
	for token in ["sichtbar ignorieren", "Unknown-Payload", "Debug-Snapshot", "Multiplayer-Rejects"]:
		_assert(report_text.to_lower().contains(token.to_lower()), "Report documents %s" % token)
	_assert(simulation_text.contains("func get_unknown_payload_debug_snapshot"), "SimulationRoot exposes unknown payload debug snapshot")
	_assert(simulation_text.contains("_record_unknown_payload(cmd, \"command\""), "SimulationRoot records unknown command payloads")
	_assert(simulation_text.contains("_record_unknown_payload(effect, \"effect\""), "SimulationRoot records unknown effect payloads")


func _test_unknown_command_is_diagnosed_without_crash() -> void:
	var simulation_root = SIMULATION_ROOT_SCRIPT.new()
	simulation_root.call("_process_commands", [{
		"command_type": "typo_move_command",
		"team_id": "team_alpha",
		"unit_id": "unit_missing",
		"origin": "task_342",
	}], 0.016)
	var snapshot: Dictionary = Dictionary(simulation_root.call("get_unknown_payload_debug_snapshot"))
	var last_unknown: Dictionary = Dictionary(snapshot.get("last_unknown_payload", {}))
	var preview: Dictionary = Dictionary(last_unknown.get("preview", {}))
	_assert(int(snapshot.get("unknown_command_count", 0)) == 1, "Unknown command increments command counter")
	_assert(int(snapshot.get("unknown_effect_count", 0)) == 0, "Unknown command does not increment effect counter")
	_assert(String(last_unknown.get("payload_category", "")) == "command", "Unknown command records payload category")
	_assert(String(last_unknown.get("payload_type", "")) == "typo_move_command", "Unknown command records payload type")
	_assert(String(last_unknown.get("reason", "")) == "unknown_command_type", "Unknown command records reason")
	_assert(String(preview.get("origin", "")) == "task_342", "Unknown command preview keeps compact origin")
	simulation_root.free()


func _test_unknown_effect_is_diagnosed_without_crash() -> void:
	var simulation_root = SIMULATION_ROOT_SCRIPT.new()
	simulation_root.call("_process_effects", [{
		"effect_type": "typo_effect",
		"asset_id": "asset_unknown",
		"source_context": "task_342",
	}], 0.016)
	var snapshot: Dictionary = Dictionary(simulation_root.call("get_unknown_payload_debug_snapshot"))
	var last_unknown: Dictionary = Dictionary(snapshot.get("last_unknown_payload", {}))
	var preview: Dictionary = Dictionary(last_unknown.get("preview", {}))
	_assert(int(snapshot.get("unknown_command_count", 0)) == 0, "Unknown effect does not increment command counter")
	_assert(int(snapshot.get("unknown_effect_count", 0)) == 1, "Unknown effect increments effect counter")
	_assert(String(last_unknown.get("payload_category", "")) == "effect", "Unknown effect records payload category")
	_assert(String(last_unknown.get("payload_type", "")) == "typo_effect", "Unknown effect records payload type")
	_assert(String(last_unknown.get("reason", "")) == "unknown_effect_type", "Unknown effect records reason")
	_assert(String(preview.get("source_context", "")) == "task_342", "Unknown effect preview keeps compact source context")
	simulation_root.free()


func _test_known_command_and_effect_do_not_raise_unknown_counters() -> void:
	var simulation_root = SIMULATION_ROOT_SCRIPT.new()
	simulation_root.call("_process_commands", [{
		"command_type": "hold_position",
		"team_id": "team_alpha",
		"unit_id": "unit_alpha",
	}], 0.016)
	simulation_root.call("_process_effects", [{
		"effect_type": "air_asset_status_update",
		"asset_id": "dropship_task_342",
		"asset_type": "dropship",
		"state": "holding",
	}], 0.016)
	var snapshot: Dictionary = Dictionary(simulation_root.call("get_unknown_payload_debug_snapshot"))
	var air_snapshot: Dictionary = Dictionary(simulation_root.call("get_air_asset_status_snapshot", "dropship_task_342"))
	_assert(int(snapshot.get("unknown_total_count", 0)) == 0, "Known command/effect payloads do not increment unknown counters")
	_assert(String(air_snapshot.get("state", "")) == "holding", "Known effect still applies normally")
	simulation_root.free()


func _test_multiplayer_reject_does_not_count_as_unknown_payload() -> void:
	var simulation_root = SIMULATION_ROOT_SCRIPT.new()
	simulation_root.is_server_authoritative = true
	simulation_root.call("set_peer_team", 1, "team_alpha")
	var result: Dictionary = Dictionary(simulation_root.call("submit_network_command_for_peer", {
		"command_type": "network_typo_command",
		"team_id": "team_alpha",
	}, 1))
	var network_snapshot: Dictionary = Dictionary(simulation_root.call("get_network_command_contract_snapshot"))
	var unknown_snapshot: Dictionary = Dictionary(simulation_root.call("get_unknown_payload_debug_snapshot"))
	_assert(not bool(result.get("accepted", true)), "Unknown network command is rejected by multiplayer contract")
	_assert(String(result.get("reason", "")) == "command_not_whitelisted", "Network reject reason stays contract-specific")
	_assert(int(network_snapshot.get("rejected_count", 0)) == 1, "Network rejection counter increments")
	_assert(int(unknown_snapshot.get("unknown_total_count", 0)) == 0, "Network reject does not count as SimulationRoot unknown payload")
	_assert(simulation_root.command_queue.is_empty(), "Rejected network command is not enqueued")
	simulation_root.free()


func _read_text(path: String) -> String:
	if path.is_empty() or not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
