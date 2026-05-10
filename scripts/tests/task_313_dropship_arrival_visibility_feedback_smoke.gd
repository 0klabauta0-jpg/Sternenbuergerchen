extends SceneTree

const LZ_CONTRACT_SCRIPT: GDScript = preload("res://scripts/mission/dropship_lz_accuracy_contract.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_313 Dropship Arrival Visibility Feedback Smoke ===")
	var no_lz: Dictionary = Dictionary(LZ_CONTRACT_SCRIPT.call("build_arrival_feedback_state", {"has_lz": false, "has_pilot": true, "has_boarded_team": true}))
	var no_pilot: Dictionary = Dictionary(LZ_CONTRACT_SCRIPT.call("build_arrival_feedback_state", {"has_lz": true, "has_pilot": false, "has_boarded_team": true}))
	var success: Dictionary = Dictionary(LZ_CONTRACT_SCRIPT.call("build_arrival_feedback_state", {"has_lz": true, "has_pilot": true, "has_boarded_team": true, "phase": "in_transit", "resolved_lz_position": Vector2(1, 2)}))
	_assert(String(no_lz.get("visible_reason", "")) == "no_lz", "Missing LZ gives visible reason")
	_assert(String(no_pilot.get("visible_reason", "")) == "no_pilot", "Missing pilot gives visible reason")
	_assert(String(success.get("phase", "")) == "in_transit", "Successful flow exposes transit phase")
	_assert(bool(success.get("shows_resolved_lz", false)), "Successful flow shows resolved LZ when available")
	_assert(bool(success.get("no_silent_failure", false)), "Feedback contract forbids silent failure")
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
