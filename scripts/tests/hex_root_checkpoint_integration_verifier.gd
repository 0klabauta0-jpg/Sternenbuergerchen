extends "res://scripts/tests/hex_ground_lifecycle_verifier.gd"

func _run() -> void:
	var rig: Dictionary = _admission_rig([Vector2i.ZERO, Vector2i(1,0), Vector2i(2,0), Vector2i(3,0)])
	var sim: Node = rig.sim
	var actor: Node2D = _add_admission_actor(rig, "a")
	var admitted: Dictionary = sim.admit_hex_ground_actor_group(PackedStringArray(["a"]), Vector2i.ZERO)
	_check(admitted.get("ok", false), "actual root admits actor")
	sim.enqueue_command(_command("a", rig.terrain.grid_to_world(Vector2i(3,0))))
	_check(not sim.get_hex_checkpoint_guard().get("ok", true), "pending commands block export")
	sim._physics_process(0.1)
	var captured: Dictionary = sim.export_hex_checkpoint_state()
	_check(captured.get("ok", false), "actual root exports composite checkpoint: " + str(captured.get("reason", "")))
	if captured.get("ok", false):
		var state: Dictionary = captured.state
		_check(not Array(state.get("ground", {}).get("active_segments", [])).is_empty(), "checkpoint contains actual active movement")
		var canonical: Dictionary = JSON.parse_string(JSON.stringify(state))
		var bad := canonical.duplicate(true); bad.map_id = "wrong_map"
		var before: Dictionary = sim.get_hex_ground_planning_snapshot()
		var refused: Dictionary = sim.prepare_hex_checkpoint_restore(bad)
		_check(not refused.get("ok", true) and sim.get_hex_ground_planning_snapshot() == before, "wrong map is rejected without mutation")
		var ground = sim._hex_ground_runtime; var movement = sim._hex_movement_runtime
		var prepared: Dictionary = sim.prepare_hex_checkpoint_restore(canonical)
		_check(prepared.get("ok", false), "root prepares portable composite: " + str(prepared.get("reason", "")))
		if prepared.get("ok", false):
			var valid: Dictionary = sim.validate_prepared_hex_checkpoint_restore(prepared.prepared)
			_check(valid.get("ok", false), "root validates prepared owner bundle")
			var committed: Dictionary = sim.commit_hex_checkpoint_restore(prepared.prepared, false) if valid.get("ok", false) else {"ok":false}
			var finished: Dictionary = sim.finalize_hex_checkpoint_restore(prepared.prepared) if committed.get("ok", false) else {"ok":false}
			_check(committed.get("ok", false) and finished.get("ok", false) and sim._hex_ground_runtime == ground and sim._hex_movement_runtime == movement, "composite restore retains root owners")
			_check(not sim.get_hex_unit_state("a").is_empty() and is_instance_valid(actor), "actor remains registered after restore")
			var again: Dictionary = sim.export_hex_checkpoint_state()
			_check(again.get("ok", false) and JSON.stringify(again.get("state", {}), "", true) == JSON.stringify(state, "", true), "restored movement and ground state match checkpoint")
	rig.scene.free()
	print("HEX_ROOT_CHECKPOINT_INTEGRATION passed=", passed, " failed=", failed)
	if failed == 0: print("HEX_ROOT_CHECKPOINT_INTEGRATION_PASS")
	quit(0 if failed == 0 else 1)
