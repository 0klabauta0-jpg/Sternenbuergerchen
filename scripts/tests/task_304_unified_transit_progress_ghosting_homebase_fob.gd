extends SceneTree

const META_USEROLOGY_CONTRACT_SCRIPT: GDScript = preload("res://scripts/meta/meta_userology_contract.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_304 Unified Transit Progress Ghosting Homebase FOB ===")
	var entry: Dictionary = Dictionary(META_USEROLOGY_CONTRACT_SCRIPT.call("build_transit_entry", "unit_a", "operator", "homebase", "fob", "dropship_one", 42.0, 18, "in_transit"))
	var snapshot: Dictionary = Dictionary(META_USEROLOGY_CONTRACT_SCRIPT.call("build_transit_snapshot", [entry]))
	var completed: Dictionary = Dictionary(META_USEROLOGY_CONTRACT_SCRIPT.call("complete_transit", [entry], "unit_a"))
	_assert(bool(entry.get("ghost_on_source", false)) and bool(entry.get("ghost_on_destination", false)), "Transit ghosts source and destination")
	_assert(float(entry.get("progress", 0.0)) == 42.0, "Transit progress is a shared value")
	_assert(bool(snapshot.get("single_progress_truth", false)), "Transit snapshot declares one progress truth")
	_assert(bool(completed.get("stale_ghost_removed", false)), "Transit completion removes stale ghost")
	_assert(String(Dictionary(completed.get("completed", {})).get("status", "")) == "arrived", "Completed transit becomes arrived")
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
