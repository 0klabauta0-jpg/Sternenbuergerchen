extends SceneTree

const META_USEROLOGY_CONTRACT_SCRIPT: GDScript = preload("res://scripts/meta/meta_userology_contract.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_305 Fireteam Staging Copy Cohesion Status ===")
	var units: Array = [
		{"unit_id": "unit_a", "display_name": "Anja", "role_name": "Lead", "rank_badges": [{"badge_id": "leader"}]},
		{"unit_id": "unit_b", "display_name": "Milo", "role_name": "Medic", "rank_badges": []},
	]
	var board: Dictionary = Dictionary(META_USEROLOGY_CONTRACT_SCRIPT.call("build_fireteam_board", [{"id": "ft1", "label": "Blue", "lead_unit_id": "unit_a"}], units, {"unit_a": "ft1"}))
	var frame: Dictionary = Dictionary(Array(board.get("frames", []))[0])
	_assert(Array(frame.get("member_cards", [])).size() == 1, "Operator can be staged into fireteam frame")
	_assert(not bool(frame.get("missing_leader_warning", true)), "Leader assignment clears missing leader warning")
	_assert(PackedStringArray(board.get("dragdrop_semantics", PackedStringArray())).has("unassigned_to_fireteam"), "Board supports unassigned-to-fireteam drag")
	_assert(String(frame.get("remove_target", "")) == "fob_unassigned", "Remove returns to unassigned instead of deleting")
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
