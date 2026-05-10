extends SceneTree

const META_USEROLOGY_CONTRACT_SCRIPT: GDScript = preload("res://scripts/meta/meta_userology_contract.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_303 FOB Transfer Dragdrop Card Readability ===")
	var pool: Dictionary = Dictionary(META_USEROLOGY_CONTRACT_SCRIPT.call("build_unassigned_pool", [
		{"unit_id": "unit_a", "display_name": "Anja", "rank_badges": [{"badge_id": "pilot"}]},
		{"unit_id": "unit_b", "display_name": "Milo", "rank_badges": []},
	], {"unit_b": "ft1"}))
	var drag_contract: Dictionary = Dictionary(META_USEROLOGY_CONTRACT_SCRIPT.call("build_drag_badge_contract"))
	_assert(int(pool.get("card_count", 0)) == 1, "Assigned operators are not duplicated in transfer pool")
	_assert(PackedStringArray(pool.get("drop_targets", PackedStringArray())).has("fireteam"), "Transfer pool accepts fireteam drops")
	_assert(String(Dictionary(drag_contract).get("tooltip_policy", "")).contains("no_active_drag"), "Tooltips avoid active drag blocking")
	_assert(bool(pool.get("prevents_duplicate_active_cards", false)), "Transfer pool declares duplicate prevention")
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
