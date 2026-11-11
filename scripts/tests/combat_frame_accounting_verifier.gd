extends SceneTree

var _checks := 0
var _failures := 0

func _init() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	_checks += 1
	if not ok: _failures += 1
	print("PASS: " if ok else "FAIL: ", message)

func _run() -> void:
	var helper_path := "res://scripts/core/frame_timing_accumulator.gd"
	if not FileAccess.file_exists(helper_path):
		_check(false, "Bounded per-frame timing accumulator exists")
		_finish()
		return
	var accumulator = load(helper_path).new()
	accumulator.record_sample(10, 11, {"commands": 4, "signal": 6}, 100)
	accumulator.record_sample(10, 17, {"commands": 8, "signal": 7}, 101)
	accumulator.record_sample(10, 5, {"signal": 2}, 102)
	var frame: Dictionary = accumulator.get_snapshot(10)
	_check(frame.sample_count == 3 and frame.sum_usec == 33 and frame.max_usec == 17,
		"Three catch-up samples retain exact count, sum and maximum")
	_check(frame.first_tick == 100 and frame.last_tick == 102 and frame.scopes_sum_usec == {"commands":12,"signal":15},
		"Tick span and every existing named scope survive aggregation")
	_check(frame.scopes_max_usec == {"commands":8,"signal":7}, "Scope maxima are independent of sums")
	frame.scopes_sum_usec.commands = 999
	_check(accumulator.get_snapshot(10).scopes_sum_usec.commands == 12, "Getter returns a defensive copy")
	var empty: Dictionary = accumulator.get_snapshot(11)
	_check(not empty.has_sample and empty.sample_count == 0 and empty.sum_usec == 0 and empty.scopes_sum_usec.is_empty(),
		"A frame without samples contains no stale physics work")
	for id in range(11, 23): accumulator.record_sample(id, 1, {}, id)
	_check(not accumulator.get_snapshot(10).has_sample and accumulator.get_snapshot(22).sample_count == 1,
		"Old frame receipts are bounded and explicitly unavailable")
	accumulator.clear()
	_check(not accumulator.get_snapshot(22).has_sample, "Disabling clears retained receipts")
	var sim = load("res://scripts/core/simulation_root.gd").new()
	root.add_child(sim)
	sim.set_physics_process(false)
	if not sim.has_method("get_runtime_frame_budget_debug_snapshot"):
		_check(false, "SimulationRoot exposes read-only per-frame debug accounting")
	else:
		sim.set_runtime_tick_budget_debug_enabled(true)
		var frame_id := Engine.get_process_frames()
		for index in range(3): sim.call("_physics_process", 1.0 / 60.0)
		var aggregate: Dictionary = sim.call("get_runtime_frame_budget_debug_snapshot", frame_id)
		_check(aggregate.process_frame == frame_id and aggregate.sample_count == 3 and aggregate.last_tick - aggregate.first_tick == 2,
			"Actual SimulationRoot records all three physics calls in the current process frame")
		_check(aggregate.scopes_sum_usec.has("tick_signal_emit_usec") and aggregate.sum_usec >= aggregate.max_usec,
			"Runtime aggregation contains synchronous signal work and consistent totals")
		while Engine.get_process_frames() == frame_id:
			await process_frame
		var zero: Dictionary = sim.call("get_runtime_frame_budget_debug_snapshot", Engine.get_process_frames())
		_check(zero.sample_count == 0 and zero.sum_usec == 0, "A later real process frame does not repeat the previous tick")
		sim.set_runtime_tick_budget_debug_enabled(false)
		_check(not bool(sim.call("get_runtime_frame_budget_debug_snapshot").get("enabled", true)),
			"Disabled instrumentation reports disabled and retains no samples")
	sim.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	print("COMBAT_FRAME_ACCOUNTING checks=", _checks, " failures=", _failures)
	quit(0 if _failures == 0 else 1)
