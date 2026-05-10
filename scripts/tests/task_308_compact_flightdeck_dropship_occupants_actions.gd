extends SceneTree

const META_USEROLOGY_CONTRACT_SCRIPT: GDScript = preload("res://scripts/meta/meta_userology_contract.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_308 Compact Flightdeck Dropship Occupants Actions ===")
	var card: Dictionary = Dictionary(META_USEROLOGY_CONTRACT_SCRIPT.call("build_compact_flightdeck_card", {"craft_id": "ship", "display_name": "Sternlift", "capacity": 3}, [{"unit_id": "unit_a"}, {"unit_id": "unit_b"}]))
	_assert(bool(card.get("compact_header", false)), "Flight deck card uses compact header")
	_assert(String(card.get("pilot_status", "")) == "missing", "Missing pilot is a compact status")
	_assert(Array(card.get("occupant_cards", [])).size() == 2, "Occupants render as mini cards")
	_assert(int(card.get("empty_slot_count", -1)) == 1, "Empty slots remain visible")
	_assert(String(Dictionary(card.get("remove_action", {})).get("label", "")) == "X", "Remove action is compact X")
	_assert(bool(Dictionary(card.get("remove_action", {})).get("requires_confirmation", false)), "Remove X requires confirmation")
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
