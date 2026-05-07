extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_289_final_sneaky_code_review_patch_queue.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reviews/final_sneaky_code_review_patch_queue.md"

const COMMANDER_INTENT_SCRIPT: GDScript = preload("res://scripts/command/commander_intent.gd")
const AIR_ASSET_STATUS_SCRIPT: GDScript = preload("res://scripts/mission/air_asset_status.gd")
const MULTIPLAYER_SNAPSHOT_CONTRACT_SCRIPT: GDScript = preload("res://scripts/multiplayer/multiplayer_snapshot_contract.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_289 Final Sneaky Code Review Patch Queue ===")
	_test_report_status_and_shape()
	_test_commander_intent_normalization_warnings()
	_test_air_asset_status_normalization_warnings()
	_test_snapshot_contract_carries_diagnostics_compactly()
	_test_patch_queue_is_small_and_actionable()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_report_status_and_shape() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	_assert(task_text.contains("## Status: IMPLEMENTIERT"), "Task file marks TASK_289 implemented")
	_assert(not task_text.contains("- [ ]"), "Task checklist is complete")
	_assert(status_text.contains("### TASK_289 - Final Sneaky Code Review Patch Queue") and status_text.contains("- Status: implementiert"), "Implementation status marks TASK_289 implemented")
	_assert(roadmap_text.contains("TASK_289 - Final Sneaky Code Review Patch Queue (implementiert)"), "Roadmap marks TASK_289 implemented")
	for token in ["## Findings", "### P0", "### P1", "### P2", "### P3", "file", "Risiko", "Repro", "Fix", "Gate", "Ready for polish"]:
		_assert(report_text.to_lower().contains(token.to_lower()), "Review report contains %s" % token)


func _test_commander_intent_normalization_warnings() -> void:
	var intent = COMMANDER_INTENT_SCRIPT.call("from_dict", {
		"command_id": "task_289_unknown_intent",
		"verb": "teleport",
		"fireteam_id": "blue",
		"team_id": "team_alpha",
		"target_position": Vector2(64.0, 96.0),
		"tempo": "warp",
		"fire_rule": "laser",
		"contact_response": "dance",
		"risk": "extreme",
	})
	var intent_dict: Dictionary = Dictionary(intent.call("to_dict"))
	var intent_metadata: Dictionary = Dictionary(intent_dict.get("metadata", {}))
	var warnings: PackedStringArray = PackedStringArray(intent_dict.get("normalization_warnings", PackedStringArray()))
	_assert(bool(intent.call("is_valid")), "CommanderIntent keeps safe fallback validity")
	_assert(String(intent_dict.get("verb", "")) == "move", "Unknown CommanderIntent verb falls back to move")
	_assert(String(intent_dict.get("tempo", "")) == "normal", "Unknown tempo falls back to normal")
	_assert(String(intent_dict.get("fire_rule", "")) == "return", "Unknown fire rule falls back to return")
	_assert(String(intent_dict.get("contact_response", "")) == "report", "Unknown contact response falls back to report")
	_assert(String(intent_dict.get("risk", "")) == "normal", "Unknown risk falls back to normal")
	for warning in [
		"unknown_verb:teleport:fallback_move",
		"unknown_tempo:warp:fallback_normal",
		"unknown_fire_rule:laser:fallback_return",
		"unknown_contact_response:dance:fallback_report",
		"unknown_risk:extreme:fallback_normal",
	]:
		_assert(warnings.has(warning), "CommanderIntent carries %s" % warning)
		_assert(PackedStringArray(intent_metadata.get("normalization_warnings", PackedStringArray())).has(warning), "CommanderIntent metadata carries %s" % warning)


func _test_air_asset_status_normalization_warnings() -> void:
	var status = AIR_ASSET_STATUS_SCRIPT.call("from_dict", {
		"asset_id": "task_289_air",
		"asset_type": "dropship",
		"state": "teleported",
		"integrity": 100,
	})
	var snapshot: Dictionary = Dictionary(status.call("to_snapshot"))
	var warnings: PackedStringArray = PackedStringArray(snapshot.get("normalization_warnings", PackedStringArray()))
	var metadata: Dictionary = Dictionary(snapshot.get("metadata", {}))
	_assert(String(snapshot.get("state", "")) == "intact", "Unknown AirAssetStatus state falls back to intact")
	_assert(warnings.has("unknown_state:teleported:fallback_intact"), "AirAssetStatus snapshot carries unknown-state warning")
	_assert(PackedStringArray(metadata.get("normalization_warnings", PackedStringArray())).has("unknown_state:teleported:fallback_intact"), "AirAssetStatus metadata carries unknown-state warning")
	status.call("apply_threat", {"next_state": "panic", "risk": 0.6, "event_id": "task_289_panic"})
	var threatened: Dictionary = Dictionary(status.call("to_snapshot"))
	_assert(PackedStringArray(threatened.get("normalization_warnings", PackedStringArray())).has("unknown_state:panic:fallback_intact"), "AirAssetStatus keeps warning for unknown threat state")


func _test_snapshot_contract_carries_diagnostics_compactly() -> void:
	var intent = COMMANDER_INTENT_SCRIPT.call("from_dict", {
		"command_id": "task_289_snapshot_intent",
		"verb": "teleport",
		"fireteam_id": "blue",
		"team_id": "team_alpha",
		"target_position": Vector2(64.0, 96.0),
	})
	var air_status = AIR_ASSET_STATUS_SCRIPT.call("from_dict", {"asset_id": "task_289_air_snapshot", "state": "offline-ish"})
	var contract = MULTIPLAYER_SNAPSHOT_CONTRACT_SCRIPT.new()
	var snapshot: Dictionary = Dictionary(contract.call("build_state_snapshot", {
		"tick": 289,
		"commander_intents": [intent.call("get_snapshot")],
		"air_asset_status": [air_status.call("to_snapshot")],
	}))
	var intent_snapshot: Dictionary = Dictionary(Array(snapshot.get("commander_intents", []))[0])
	var air_snapshot: Dictionary = Dictionary(Array(snapshot.get("air_asset_status", []))[0])
	var metrics: Dictionary = Dictionary(contract.call("build_serialization_metrics", snapshot))
	_assert(PackedStringArray(intent_snapshot.get("normalization_warnings", PackedStringArray())).has("unknown_verb:teleport:fallback_move"), "Multiplayer snapshot carries CommanderIntent normalization warning")
	_assert(PackedStringArray(air_snapshot.get("normalization_warnings", PackedStringArray())).has("unknown_state:offline-ish:fallback_intact"), "Multiplayer snapshot carries AirAssetStatus normalization warning")
	_assert(Array(metrics.get("large_payload_offenders", [])).is_empty(), "Diagnostics stay compact and do not trip large-payload scan")


func _test_patch_queue_is_small_and_actionable() -> void:
	var report_text: String = _read_text(REPORT_PATH)
	for token in [
		"cover_priority",
		"security_mode",
		"tactical_breakout_resolver.gd",
		"Forbidden-token",
		"Zwei-Instanzen-LAN",
		"Full-HD",
		"TASK_290",
	]:
		_assert(report_text.contains(token), "Patchqueue/manual queue contains %s" % token)
	_assert(report_text.contains("Keine P0-Blocker"), "Report states no P0 blockers")
	_assert(report_text.contains("Ready for polish"), "Report gives clear closeout decision")


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
