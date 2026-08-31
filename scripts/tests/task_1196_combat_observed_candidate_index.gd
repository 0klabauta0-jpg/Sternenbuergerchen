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
	driver.call("set_combat_tick_budget_debug_enabled", false)
	var unprofiled_context: Dictionary = Dictionary(driver.call("_build_fire_decision_context"))
	_assert(not unprofiled_context.has("record_target_evaluation"), "unprofiled context has no resolver counter callback")
	var legacy: Dictionary = await _run_oracle(false, false)
	var indexed: Dictionary = await _run_oracle(true, false)
	var prevalidated: Dictionary = await _run_oracle(true, true)
	print("resolver legacy=%d indexed=%d" % [int(legacy.get("pairs", 0)), int(indexed.get("pairs", 0))])
	_assert(int(legacy.get("pairs", 0)) > 0, "legacy resolver evaluates target pairs")
	_assert(legacy.get("contacts", []) == indexed.get("contacts", []), "indexed contacts equal legacy")
	_assert(legacy.get("detection", {}) == indexed.get("detection", {}), "indexed detection equals legacy")
	_assert(legacy.get("fire_events", []) == indexed.get("fire_events", []), "indexed fire events equal legacy")
	_assert(legacy.get("unit_states", []) == indexed.get("unit_states", []), "indexed unit states equal legacy")
	_assert(legacy.get("mission_result", {}) == indexed.get("mission_result", {}), "indexed mission result equal legacy")
	_assert(int(indexed.get("pairs", 0)) <= int(legacy.get("pairs", 0)), "indexed selection never evaluates more pairs")
	_assert(indexed.get("contacts", []) == prevalidated.get("contacts", []), "prevalidated contacts equal indexed")
	_assert(indexed.get("detection", {}) == prevalidated.get("detection", {}), "prevalidated detection equals indexed")
	_assert(indexed.get("fire_events", []) == prevalidated.get("fire_events", []), "prevalidated fire events equal indexed")
	_assert(indexed.get("unit_states", []) == prevalidated.get("unit_states", []), "prevalidated unit states equal indexed")
	_assert(indexed.get("mission_result", {}) == prevalidated.get("mission_result", {}), "prevalidated mission result equal indexed")
	_assert(int(prevalidated.get("pairs", 0)) <= int(indexed.get("pairs", 0)), "prevalidation never evaluates more target pairs")
	_assert(int(prevalidated.get("reuse_count", 0)) > 0, "prevalidation reuses observed terrain LOS")
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _run_oracle(use_index: bool, use_prevalidation: bool) -> Dictionary:
	seed(1196)
	var harness = HARNESS_SCRIPT.new()
	var context: Dictionary = harness.call("_make_combat_context", root, "task1196_oracle", 16, 12, 4, true)
	await process_frame
	harness.call("_prime_state", context, true)
	var driver: Node = context.get("combat_driver")
	driver.call("set_use_observed_fire_candidate_index", use_index)
	driver.call("set_use_observed_los_prevalidation", use_prevalidation)
	var simulation_root: Node = context.get("simulation_root")
	for _tick in range(600):
		simulation_root.call("_physics_process", 0.1)
	var unit_states: Array = []
	for unit in Array(context.get("friendly_units", [])) + Array(context.get("enemy_units", [])):
		unit_states.append({"id": String(unit.call("get_unit_id")), "health": int(unit.call("get_health")) if unit.has_method("get_health") else 0, "vital": String(unit.call("get_vital_state"))})
	unit_states.sort_custom(func(a, b): return String(a["id"]) < String(b["id"]))
	var result := {"contacts": driver.call("get_contact_snapshot"), "detection": driver.call("get_detection_progress"), "fire_events": driver.call("get_fire_event_snapshot"), "unit_states": unit_states, "mission_result": driver.call("get_mission_result"), "pairs": int(driver.call("get_resolver_target_evaluation_count")), "reuse_count": int(driver.call("get_observed_los_prevalidation_reuse_count"))}
	context.get("scene").queue_free()
	return result
func _assert(condition: bool, message: String) -> void:
	if condition: _passed += 1; print("PASS: %s" % message)
	else: _failed += 1; print("FAIL: %s" % message)
