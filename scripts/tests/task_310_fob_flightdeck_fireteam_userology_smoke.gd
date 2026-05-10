extends SceneTree

const META_USEROLOGY_CONTRACT_SCRIPT: GDScript = preload("res://scripts/meta/meta_userology_contract.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_310 FOB Flightdeck Fireteam Userology Smoke ===")
	var units: Array = [{"unit_id": "unit_a", "display_name": "Anja"}, {"unit_id": "unit_b", "display_name": "Milo"}]
	var transit_done: Dictionary = Dictionary(META_USEROLOGY_CONTRACT_SCRIPT.call("complete_transit", [META_USEROLOGY_CONTRACT_SCRIPT.call("build_transit_entry", "unit_a", "operator", "homebase", "fob", "ship", 98.0, 1)], "unit_a"))
	var board: Dictionary = Dictionary(META_USEROLOGY_CONTRACT_SCRIPT.call("build_fireteam_board", [{"id": "ft1", "label": "Blue", "lead_unit_id": "unit_a"}], units, {"unit_a": "ft1"}))
	var flightdeck: Dictionary = Dictionary(META_USEROLOGY_CONTRACT_SCRIPT.call("build_compact_flightdeck_card", {"craft_id": "ship", "display_name": "Sternlift", "pilot_unit_id": "unit_b"}, [{"unit_id": "unit_a", "display_name": "Anja"}]))
	_assert(bool(transit_done.get("stale_ghost_removed", false)), "Smoke completes Homebase->FOB transit")
	_assert(Array(Dictionary(Array(board.get("frames", []))[0]).get("member_cards", [])).size() == 1, "Smoke assigns operator to fireteam frame")
	_assert(Array(flightdeck.get("occupant_cards", [])).size() == 1, "Smoke boards operator into dropship")
	_assert(String(flightdeck.get("pilot_status", "")) == "assigned", "Smoke shows pilot separately")
	_assert(bool(Dictionary(flightdeck.get("remove_action", {})).get("requires_confirmation", false)), "Smoke covers remove-X confirmation")
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
