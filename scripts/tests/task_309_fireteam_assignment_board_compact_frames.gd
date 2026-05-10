extends SceneTree

const META_USEROLOGY_CONTRACT_SCRIPT: GDScript = preload("res://scripts/meta/meta_userology_contract.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_309 Fireteam Assignment Board Compact Frames ===")
	var board: Dictionary = Dictionary(META_USEROLOGY_CONTRACT_SCRIPT.call("build_fireteam_board", [{"id": "ft1", "label": "Fireteam 1", "lead_unit_id": "unit_a"}], [{"unit_id": "unit_a", "display_name": "Anja"}, {"unit_id": "unit_b", "display_name": "Milo"}], {"unit_a": "ft1"}))
	var frame: Dictionary = Dictionary(Array(board.get("frames", []))[0])
	_assert(String(frame.get("label", "")) == "Fireteam 1", "Fireteam frame has editable label")
	_assert(bool(frame.get("rename_enabled", false)), "Fireteam rename enabled")
	_assert(Array(frame.get("member_cards", [])).size() == 1, "Assigned member appears in compact frame")
	_assert(Array(Dictionary(board.get("unassigned", {})).get("cards", [])).size() == 1, "Unassigned column is adjacent in board snapshot")
	_assert(String(frame.get("remove_target", "")) == "fob_unassigned", "Remove moves member to unassigned")
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
