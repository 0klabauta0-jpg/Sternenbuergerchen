extends "res://scripts/tests/review7_fow_verifier.gd"

# Reuse the guarded real MissionTestSetup/FogOfWarSystem fixture. Only the
# workload differs: an observer keeps walking while bounded jobs finish.
func _run() -> void:
	for side in [32, 128, 256]:
		var stationary: Dictionary = _continuous_case(side, false)
		var walking: Dictionary = _continuous_case(side, true)
		_check(int(walking.first_commit) == int(stationary.first_commit), "%d continuous observer motion preserves initial scan completion frame" % side)
	print("REVIEW7_FOW_MOTION_RESULT %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)


func _continuous_case(side: int, walking: bool) -> Dictionary:
	var f: Dictionary = _fixture(side)
	var setup = f.setup
	var origin: Vector2 = f.observer.position
	var label: String = "%d %s" % [side, "walking" if walking else "stationary"]
	setup.call("_sync_fog_of_war_visual_state", true)
	var initial_sample_signature: String = String(setup.get("_fog_requested_runtime_signature"))
	var first_commit: int = -1
	var first_commit_sample_matches: bool = false
	var first_commit_enumerations: int = -1
	var conservative_while_pending: bool = _pending_is_atomic(f)
	var dynamic_samples_correct: bool = true
	var final_revision_while_walking: int = 0
	var frames: int = ceili(float(side * side) / 512.0) + 90
	for frame in range(frames):
		if walking:
			f.observer.position += Vector2(80.0 / 60.0, 0.0)
		# Two genuine target visibility changes occur before the 128/256 full
		# scan can complete. They must use the regular 100-ms dynamic cadence.
		if frame < 2 or (frame >= 11 and frame < 31):
			f.enemies[0].position = f.observer.position + Vector2(20.0, 0.0)
		else:
			f.enemies[0].position = f.observer.position + Vector2(1000.0, 0.0)
		setup.call("_process", 1.0 / 60.0)
		if frame in [8, 20, 40]:
			var should_be_visible: bool = frame == 20
			dynamic_samples_correct = dynamic_samples_correct and f.fog.is_visible("team_alpha", "enemy_0") == should_be_visible
		var revision: int = int(f.fog.build_team_state_snapshot("team_alpha").get("visibility_revision", 0))
		if first_commit == -1 and revision > 0:
			first_commit = frame
			# A finished request may be sampled in the past; it must keep that
			# precise identity instead of claiming it used the latest position.
			first_commit_sample_matches = String(setup.get("_fog_runtime_signature")) == initial_sample_signature
			first_commit_sample_matches = first_commit_sample_matches and _visible_tiles(f.fog) == _oracle_at(f, origin)
			first_commit_enumerations = int(f.registry.enumerations)
		conservative_while_pending = conservative_while_pending and _pending_is_atomic(f)
		final_revision_while_walking = revision
	_check(first_commit >= 0, label + " initial scan completes while the workload is still running")
	_check(first_commit_sample_matches, label + " first atomic result retains its frozen request sample and matches the full oracle")
	_check(conservative_while_pending, label + " pending terrain retains only the last complete published sample")
	_check(dynamic_samples_correct, label + " targets enter and leave visibility at the normal cadence even during pending terrain work")
	if walking:
		_check(final_revision_while_walking > 1, label + " coalesced motion produces follow-up revisions without stopping")
	else:
		_check(final_revision_while_walking == 1, label + " stationary observer creates only its initial terrain revision")
	var settled: bool = false
	for _frame in range(120):
		setup.call("_process", 1.0 / 60.0)
		var current_signature: String = setup.call("_build_fog_runtime_signature", "unexplored_blackout")
		if String(setup.get("_fog_requested_runtime_signature")).is_empty() and String(setup.get("_fog_runtime_signature")) == current_signature:
			settled = true
			break
	_check(settled, label + " stopping coalesces the latest position within bounded normal frames")
	_check(first_commit_enumerations >= 0 and int(f.registry.enumerations) == first_commit_enumerations, label + " follow-up motion and target refreshes never enumerate the full map again")
	_check(_visible_tiles(f.fog) == _oracle_at(f, f.observer.position), label + " final committed terrain exactly matches the latest-position full oracle")
	print("REVIEW7_FOW_MOTION_WORKLOAD ", JSON.stringify({"side": side, "walking": walking, "frames": frames, "first_commit": first_commit, "revisions_before_stop": final_revision_while_walking, "enumerations": f.registry.enumerations}))
	f.holder.free()
	return {"first_commit": first_commit}


func _pending_is_atomic(f: Dictionary) -> bool:
	if String(f.setup.get("_fog_requested_runtime_signature")).is_empty():
		return true
	var committed: Dictionary = f.fog.build_team_state_snapshot("team_alpha")
	return bool(f.sink.last_state.get("visibility_pending", false)) and Dictionary(f.sink.last_state.get("terrain_knowledge", {})) == Dictionary(committed.get("terrain_knowledge", {})) and int(f.sink.last_state.get("visibility_revision", -1)) == int(committed.get("visibility_revision", 0))


func _oracle_at(f: Dictionary, position: Vector2) -> PackedStringArray:
	var observer = _unit(f.holder, "oracle_observer", "team_alpha", position)
	var oracle = FOW.new()
	oracle.set_mode_for_team("team_alpha", "unexplored_blackout")
	oracle.update_tile_visibility_for_team("team_alpha", [observer], f.registry, LOS.new(), 160.0)
	var visible: PackedStringArray = _visible_tiles(oracle)
	observer.free()
	return visible
