extends SceneTree

const HARNESS_SCRIPT: GDScript = preload("res://scripts/tests/simulation_combat_ai_tick_budget_harness.gd")
const TACTICAL_HARNESS_SCRIPT: GDScript = preload("res://scripts/tests/tactical_map_frame_budget_harness.gd")

var _passed := 0
var _failed := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var harness = HARNESS_SCRIPT.new()
	var tactical_harness = TACTICAL_HARNESS_SCRIPT.new()
	var harness_samples: Dictionary = {}
	tactical_harness.call("_record_command_attribution_samples", harness_samples, {
		"command_type_usec": {" Move_To_Position ": 17},
		"command_type_count": {" Move_To_Position ": 2},
		"command_requeue_count": {" Move_To_Position ": 1},
	})
	_assert(harness_samples.has("simulation_command.command_type_usec.move_to_position"), "harness exports exact timing namespace")
	_assert(harness_samples.has("simulation_command.command_type_count.move_to_position"), "harness exports exact count namespace")
	_assert(harness_samples.has("simulation_command.command_requeue_count.move_to_position"), "harness exports exact requeue namespace")
	_assert(Array(harness_samples.get("simulation_command.command_type_usec.move_to_position", [])).size() == 1 and is_equal_approx(float(Array(harness_samples["simulation_command.command_type_usec.move_to_position"])[0]), 17.0), "harness timing sample value is preserved")
	_assert(Array(harness_samples.get("simulation_command.command_type_count.move_to_position", [])).size() == 1 and is_equal_approx(float(Array(harness_samples["simulation_command.command_type_count.move_to_position"])[0]), 2.0), "harness count sample value is preserved")
	_assert(Array(harness_samples.get("simulation_command.command_requeue_count.move_to_position", [])).size() == 1 and is_equal_approx(float(Array(harness_samples["simulation_command.command_requeue_count.move_to_position"])[0]), 1.0), "harness requeue sample value is preserved")
	var large_samples: Dictionary = {}
	tactical_harness.call("_collect_large_combat_fixture_samples", large_samples, {"runs": [{"ticks": [{"simulation": {
		"total_tick_usec": 99,
		"command_type_usec": {"Move_To_Position": 23},
		"command_type_count": {"Move_To_Position": 4},
		"command_requeue_count": {"Move_To_Position": 2},
	}, "combat": {}}]}]})
	_assert(Array(large_samples.get("simulation_command.command_type_usec.move_to_position", [])).has(23.0), "large fixture exports timing namespace")
	_assert(Array(large_samples.get("simulation_command.command_type_count.move_to_position", [])).has(4.0), "large fixture exports count namespace")
	_assert(Array(large_samples.get("simulation_command.command_requeue_count.move_to_position", [])).has(2.0), "large fixture exports requeue namespace")
	var context: Dictionary = harness.call("_make_combat_context", root, "task1198", 2, 1, 1, false)
	await process_frame
	var simulation_root: Node = context.get("simulation_root")
	var friendly_units: Array = Array(context.get("friendly_units", []))
	_assert(simulation_root != null, "SimulationRoot fixture exists")
	_assert(friendly_units.size() >= 1, "fixture provides a command target")
	if simulation_root == null or friendly_units.is_empty():
		_print_results_and_quit()
		return

	var unit: Node = friendly_units[0]
	simulation_root.call("set_runtime_tick_budget_debug_enabled", true)
	var fire_rule_trace: Array[String] = []
	simulation_root.fire_rule_committed.connect(func(rule: Dictionary) -> void:
		fire_rule_trace.append(String(rule.get("fire_rule", "")))
	)
	simulation_root.call("enqueue_command", {
		"command_type": "set_fire_rule",
		"fireteam_id": "blue",
		"team_id": "team_alpha",
		"fire_rule": "hold",
		"priority": 20,
		"command_id": "task1198-fire-hold",
	})
	simulation_root.call("enqueue_command", {
		"command_type": "set_fire_rule",
		"fireteam_id": "blue",
		"team_id": "team_alpha",
		"fire_rule": "free",
		"priority": 10,
		"command_id": "task1198-fire-free",
	})
	var start_position: Vector2 = (unit as Node2D).global_position
	simulation_root.call("enqueue_command", {
		"command_type": "move_to_position",
		"unit_id": String(unit.call("get_unit_id")),
		"team_id": "team_alpha",
		"target_position": (unit as Node2D).global_position + Vector2(256.0, 0.0),
		"requeue_until_target": true,
		"command_id": "task1198-move",
	})
	simulation_root.call("_physics_process", 0.1)
	var snapshot: Dictionary = Dictionary(simulation_root.call("get_runtime_tick_budget_debug_snapshot"))
	var counts: Dictionary = Dictionary(snapshot.get("command_type_count", {}))
	var timings: Dictionary = Dictionary(snapshot.get("command_type_usec", {}))
	var requeues: Dictionary = Dictionary(snapshot.get("command_requeue_count", {}))
	var scopes: Dictionary = Dictionary(snapshot.get("scopes_usec", {}))
	_assert(counts.has("set_fire_rule") and counts.has("move_to_position"), "at least two command types are attributed")
	_assert(fire_rule_trace == ["hold", "free"], "command priority ordering is observable through authoritative signals")
	var fire_rule_state: Dictionary = Dictionary(simulation_root.call("get_authoritative_fire_rule_state", "blue"))
	_assert(String(fire_rule_state.get("fire_rule", "")) == "free" and int(fire_rule_state.get("revision", 0)) >= 2, "fire-rule command commits gameplay state")
	var moved_position: Vector2 = (unit as Node2D).global_position
	_assert(moved_position != start_position, "movement command changes authoritative unit position")
	_assert(int(snapshot.get("command_queue_after_tick", 0)) > 0, "movement requeue remains observable in the command queue")
	_assert(_sum_dictionary_values(counts) == int(snapshot.get("command_count", -1)), "type counts sum to command_count")
	_assert(int(timings.get("set_fire_rule", -1)) >= 0 and int(timings.get("move_to_position", -1)) >= 0, "type timings are non-negative")
	_assert(int(requeues.get("move_to_position", 0)) > 0, "movement requeue is attributed")
	_assert(requeues.has("set_fire_rule") and int(requeues.get("set_fire_rule", -1)) == 0, "non-requeued command type has explicit zero requeue count")
	_assert(int(scopes.get("command_ordering_usec", -1)) >= 0, "ordering scope is present and non-negative")
	_assert(int(scopes.get("command_apply_usec", -1)) >= 0, "apply scope is present and non-negative")
	_assert(String(Dictionary(snapshot.get("hotpath_audit", {})).get("command_queue_scope", "")) == "drain_order_apply", "command processing remains authoritative")

	simulation_root.call("set_runtime_tick_budget_debug_enabled", false)
	var disabled: Dictionary = Dictionary(simulation_root.call("get_runtime_tick_budget_debug_snapshot"))
	_assert(disabled.is_empty(), "disabling debug clears the snapshot")
	context.get("scene").queue_free()
	await process_frame
	_print_results_and_quit()

func _sum_dictionary_values(values: Dictionary) -> int:
	var total := 0
	for value in values.values():
		total += int(value)
	return total

func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		print("FAIL: %s" % message)

func _print_results_and_quit() -> void:
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)
