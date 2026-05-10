extends SceneTree

const META_USEROLOGY_CONTRACT_SCRIPT: GDScript = preload("res://scripts/meta/meta_userology_contract.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_307 FOB Arrivals Unassigned Operator Pool ===")
	var transit: Dictionary = Dictionary(META_USEROLOGY_CONTRACT_SCRIPT.call("build_transit_entry", "unit_a", "operator", "homebase", "fob", "ship", 100.0, 0, "arrived"))
	var pool: Dictionary = Dictionary(META_USEROLOGY_CONTRACT_SCRIPT.call("build_unassigned_pool", [{"unit_id": "unit_a", "display_name": "Anja"}], {}, {}, {}, []))
	_assert(String(transit.get("destination", "")) == "fob", "Arrived transit targets FOB")
	_assert(int(pool.get("card_count", 0)) == 1, "Arrived unassigned operator appears in pool")
	_assert(PackedStringArray(pool.get("drop_targets", PackedStringArray())).has("loadout"), "Unassigned pool supports loadout drop")
	_assert(PackedStringArray(pool.get("drop_targets", PackedStringArray())).has("fob_reserve"), "Unassigned pool supports FOB reserve drop")
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
