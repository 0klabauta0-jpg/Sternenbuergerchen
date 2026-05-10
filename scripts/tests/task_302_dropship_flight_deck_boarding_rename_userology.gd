extends SceneTree

const META_USEROLOGY_CONTRACT_SCRIPT: GDScript = preload("res://scripts/meta/meta_userology_contract.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_302 Dropship Flight Deck Boarding Rename Userology ===")
	var craft: Dictionary = {"craft_id": "dropship_test", "display_name": "Sternlift", "pilot_unit_id": "pilot_one", "capacity": 6}
	var card: Dictionary = Dictionary(META_USEROLOGY_CONTRACT_SCRIPT.call("build_compact_flightdeck_card", craft, [{"unit_id": "unit_a", "display_name": "Anja"}]))
	_assert(String(card.get("display_name", "")) == "Sternlift", "Dropship display name is first-class")
	_assert(bool(card.get("rename_enabled", false)), "Dropship rename is enabled by contract")
	_assert(bool(card.get("compact_header", false)), "Flight deck header is compact")
	_assert(String(card.get("pilot_status", "")) == "assigned", "Pilot status is distinct and compact")
	_assert(Array(card.get("occupant_cards", [])).size() == 1, "Boarded occupant cards are exposed")
	_assert(bool(Dictionary(card.get("remove_action", {})).get("requires_confirmation", false)), "Remove action requires confirmation")
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
