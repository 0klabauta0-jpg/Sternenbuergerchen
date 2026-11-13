extends "res://scripts/tests/astra_hex_combat_fixes_20261113.gd"
## Actual Driver/Root RNG ownership, independent from the process-global stream.

func _run() -> void:
	_test_driver_rng_ownership()
	_test_rng_checkpoint()
	_test_probability_boundaries()
	_test_stationary_facing_checkpoint()
	await process_frame
	print("REVIEW_COMPLETION_RNG passed=%d failed=%d" % [passed, failed])
	quit(1 if failed > 0 else 0)

func _test_stationary_facing_checkpoint() -> void:
	var f := _fixture(0)
	var direction: int = f.sim.get_hex_unit_state("own").facing_dir
	for index in range(3):
		var result: Dictionary = f.sim.queue_hex_facing_intent("own",direction,"stationary_%d"%index,"security_assignment")
		_check(result.get("unchanged",false) and f.sim.get_hex_checkpoint_guard().get("ok",false),"renewed stationary security direction does not create perpetual checkpoint work")
	var replay: Dictionary = f.sim.queue_hex_facing_intent("own",posmod(direction+1,6),"stationary_0","security_assignment")
	_check(replay.get("replayed",false) and f.sim.get_hex_checkpoint_guard().get("ok",false),"accepted unchanged facing IDs still reject a conflicting replay")
	var changed: Dictionary = f.sim.queue_hex_facing_intent("own",posmod(direction+1,6),"actual_turn","security_assignment")
	_check(changed.get("ok",false) and f.sim.get_hex_checkpoint_guard().get("reason")=="checkpoint_pending_work","real pending turn still blocks a partial checkpoint")
	f.scope.free()

func _seed_below(chance: float) -> int:
	var probe := RandomNumberGenerator.new()
	for candidate in range(10000):
		probe.seed = candidate
		if probe.randf() < chance: return candidate
	return -1

func _test_driver_rng_ownership() -> void:
	var f := _fixture(0)
	var chosen := _seed_below(DRIVER.DISCIPLINE_BREAK_BASE_CHANCE)
	_check(chosen >= 0, "deterministic seed exists for a real discipline break")
	var reference := RandomNumberGenerator.new()
	reference.seed = chosen
	reference.randf()
	f.sim.set_combat_rng_seed(chosen)
	seed(872)
	var expected_global := randf()
	seed(872)
	_check(f.driver._check_discipline_break(f.own), "discipline consumes the owning Root roll")
	_check(f.sim._combat_rng.state == reference.state, "discipline advances exactly one owner roll")
	_check(randf() == expected_global, "discipline leaves process-global RNG untouched")
	var after: int = f.sim._combat_rng.state
	_check(not f.driver._check_discipline_break(f.own) and f.sim._combat_rng.state == after, "cooldown does not consume another roll")
	f.enemy.team_id = "blue"
	f.driver.friendly_unit_paths.append(NodePath("../Enemy"))
	chosen = _seed_below(DRIVER.MISIDENTIFICATION_BASE_CHANCE * 0.5)
	f.sim.set_combat_rng_seed(chosen)
	reference.seed = chosen
	reference.randf()
	seed(912)
	expected_global = randf()
	seed(912)
	var misidentified: Dictionary = f.driver._check_misidentification(f.own, "own")
	_check(not misidentified.is_empty(), "real misidentification still selects an eligible friendly")
	_check(f.sim._combat_rng.state == reference.state and randf() == expected_global, "misidentification consumes exactly the owner stream")
	f.driver._runs_local_authority = false
	f.driver._discipline_break_cooldown.clear()
	f.driver._misidentification_cooldown.clear()
	after = f.sim._combat_rng.state
	_check(not f.driver._check_discipline_break(f.own) and f.driver._check_misidentification(f.own, "own").is_empty(), "replica Driver cannot make gameplay rolls")
	_check(f.sim._combat_rng.state == after, "replica leaves owner RNG unchanged")
	f.scope.free()

func _test_probability_boundaries() -> void:
	var model = preload("res://scripts/core/damage_model.gd").new()
	for roll in [0.0, 0.5, 1.0]:
		_check(not model.resolve_hit(0.0, roll), "0 percent never hits, including roll zero")
		_check(model.resolve_hit(1.0, roll), "100 percent always hits for a valid normalized roll")
	for roll in [-1.0, 1.01, NAN, INF]:
		_check(not model.resolve_hit(1.0, roll), "invalid roll cannot substitute a global random decision")
	for chance in [NAN, INF]: _check(not model.resolve_hit(chance, 0.0), "nonfinite chance is rejected")

func _test_rng_checkpoint() -> void:
	var f := _fixture(0)
	_check(f.sim.has_method("export_gameplay_rng_state"), "Root exposes portable RNG domains")
	if not f.sim.has_method("export_gameplay_rng_state"):
		f.scope.free()
		return
	f.sim.set_combat_rng_seed(792)
	f.sim._space_fire_rng = 991
	f.sim._air_ground_rng_state = 127
	var exported: Dictionary = f.sim.export_hex_checkpoint_state()
	_check(exported.get("ok", false), "actual Hex owner exports RNG checkpoint")
	if exported.get("ok", false):
		var saved: Dictionary = JSON.parse_string(JSON.stringify(exported.state))
		var expected: Array[float] = []
		for index in range(8): expected.append(f.sim.get_next_combat_roll())
		f.sim._space_fire_rng = 19
		f.sim._air_ground_rng_state = 23
		var restored: Dictionary = f.sim.restore_hex_checkpoint_state(saved)
		_check(restored.get("ok", false), "portable checkpoint restores all domains")
		var actual: Array[float] = []
		for index in range(8): actual.append(f.sim.get_next_combat_roll())
		_check(actual == expected and f.sim._space_fire_rng == 991 and f.sim._air_ground_rng_state == 127, "continuation preserves combat sequence and independent space/air seeds")
		var invalid: Dictionary = saved.duplicate(true)
		invalid.rng_streams.space_fire = -1
		var before: Dictionary = f.sim.export_gameplay_rng_state()
		_check(not f.sim.prepare_hex_checkpoint_restore(invalid).get("ok", true) and f.sim.export_gameplay_rng_state() == before, "invalid domain is rejected without consuming or replacing RNG")
		var legacy: Dictionary = saved.duplicate(true)
		legacy.erase("rng_streams")
		_check(f.sim.restore_hex_checkpoint_state(legacy).get("ok",false) and f.sim._space_fire_rng==1 and f.sim._air_ground_rng_state==1, "historical checkpoint restores combat state with documented space/air defaults")
		for field in ["_space_fire_rng", "_air_ground_rng_state"]:
			var prepared: Dictionary = f.sim.prepare_hex_checkpoint_restore(saved)
			_check(prepared.get("ok",false), "prepare existing checkpoint before independent stream change")
			if prepared.get("ok",false):
				f.sim.set(field, int(f.sim.get(field))+1)
				var ground_before: Dictionary = f.sim.get_hex_ground_planning_snapshot()
				var rng_before: Dictionary = f.sim.export_gameplay_rng_state()
				_check(not f.sim.commit_hex_checkpoint_restore(prepared.prepared).get("ok",true) and f.sim.get_hex_ground_planning_snapshot()==ground_before and f.sim.export_gameplay_rng_state()==rng_before, "changed space/air stream rejects stale prepare without partial publication")
	f.scope.free()
