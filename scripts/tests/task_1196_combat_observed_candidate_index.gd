extends SceneTree
const HARNESS_SCRIPT: GDScript = preload("res://scripts/tests/simulation_combat_ai_tick_budget_harness.gd")
var _passed := 0
var _failed := 0
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var harness = HARNESS_SCRIPT.new()
	var context: Dictionary = harness.call("_make_combat_context", root, "task1196", 16, 12, 4, true)
	await process_frame
	harness.call("_prime_state", context, true)
	var simulation_root: Node = context.get("simulation_root")
	var driver: Node = context.get("combat_driver")
	simulation_root.call("_physics_process", 0.1)
	var snapshot: Dictionary = Dictionary(driver.call("get_fire_candidate_index_debug_snapshot"))
	_assert(int(snapshot.get("tick", -1)) >= 0, "authoritative tick")
	_assert(bool(snapshot.get("derived_only", false)), "derived")
	_assert(bool(snapshot.get("read_only", false)), "read-only")
	_assert(not bool(snapshot.get("snapshot_serialized", true)), "not serialized")
	_assert(int(snapshot.get("candidate_pair_count", 0)) > 0, "real observations build pairs")
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)
func _assert(condition: bool, message: String) -> void:
	if condition: _passed += 1; print("PASS: %s" % message)
	else: _failed += 1; print("FAIL: %s" % message)
