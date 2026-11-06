extends SceneTree
## Real ReadModel behavior, independent of mission startup or persisted saves.
## Breaks caught: unbounded cache lifetime, poisoned recursive results, aliased
## snapshots, missing revision barriers, and stale results after leaked passes.

const READ_MODEL: GDScript = preload("res://scripts/tactical/mission_hud_read_model.gd")

var _passed: int = 0
var _failed: int = 0


class ProjectionSource extends RefCounted:

	var model: Node
	var reads: Dictionary = {}
	var source: Dictionary = {"unit": {"hp": 7}, "members": [{"id": "original"}], "commands": [], "effects": []}

	func numbered(key: String) -> Dictionary:
		reads[key] = int(reads.get(key, 0)) + 1
		return {"key": key, "read": int(reads[key])}

	func snapshot() -> Dictionary:
		reads["source"] = int(reads.get("source", 0)) + 1
		return source

	func outer() -> Dictionary:
		reads["outer"] = int(reads.get("outer", 0)) + 1
		return {"kind": "outer", "nested": model.call("project", "nested", Callable(self, "numbered").bind("nested"))}

	func recursive() -> Dictionary:
		reads["recursive"] = int(reads.get("recursive", 0)) + 1
		return {"kind": "complete", "fallback": model.call("project", "recursive", Callable(self, "numbered").bind("fallback"))}

	func revision_during_build() -> Dictionary:
		var result: Dictionary = numbered("revision_during_build")
		model.call("mark_heavy_state_changed")
		return result


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var probe: Node = READ_MODEL.new()
	var api_ready: bool = true
	for method_name in ["begin_projection_pass", "end_projection_pass", "project"]:
		var present: bool = probe.has_method(method_name)
		_check(present, "ReadModel exposes %s for an explicit bounded projection pass" % method_name)
		api_ready = api_ready and present
	probe.free()
	if api_ready:
		_test_scope_reuse_and_fresh_boundaries()
		_test_nested_scope_lifetime()
		_test_nested_producers_and_recursive_fallback()
		_test_defensive_snapshot_copies()
		_test_revision_invalidation()
		_test_revision_during_producer()
		await _test_leaked_scope_expires_on_new_frame()
	print("HUD_ARCHITECTURE_20261106_READ_SCOPE: %d passed, %d failed" % [_passed, _failed])
	if _failed == 0:
		print("HUD_READ_SCOPE_VERIFY_PASS")
	quit(1 if _failed > 0 else 0)


func _test_scope_reuse_and_fresh_boundaries() -> void:
	var model: Node = READ_MODEL.new()
	var source = ProjectionSource.new()
	source.model = model
	var producer: Callable = Callable(source, "numbered").bind("density")
	model.call("begin_projection_pass")
	var first: Dictionary = model.call("project", "density", producer)
	var repeated: Dictionary = model.call("project", "density", producer)
	_check(first == {"key": "density", "read": 1} and repeated == first, "Repeated top-level read shares its one built result")
	_check(int(source.reads.get("density", 0)) == 1, "A hit does not call the producer")
	var diagnostics: Dictionary = model.call("get_diagnostics_snapshot")
	_check(int(diagnostics.get("projection_cached_entries", -1)) == 1 and int(diagnostics.get("projection_build_count", -1)) == 1 and int(diagnostics.get("projection_hit_count", -1)) == 1, "Diagnostics distinguish the single build and hit")
	model.call("end_projection_pass")
	_check(_cached_count(model) == 0 and _scope_depth(model) == 0, "Outer end drops all snapshot entries immediately")
	var direct_first: Dictionary = model.call("project", "density", producer)
	var direct_second: Dictionary = model.call("project", "density", producer)
	_check(int(direct_first.read) == 2 and int(direct_second.read) == 3 and _cached_count(model) == 0, "Out-of-scope reads always call the owner afresh")
	var frame_before: int = Engine.get_process_frames()
	model.call("begin_projection_pass")
	var new_pass: Dictionary = model.call("project", "density", producer)
	_check(Engine.get_process_frames() == frame_before and int(new_pass.read) == 4, "A new explicit pass in the same engineframe is fresh")
	model.call("end_projection_pass")
	model.call("end_projection_pass")
	_check(_scope_depth(model) == 0, "An unmatched end cannot retain or underflow a scope")
	model.free()


func _test_nested_scope_lifetime() -> void:
	var model: Node = READ_MODEL.new()
	var source = ProjectionSource.new()
	var producer: Callable = Callable(source, "numbered").bind("nested_pass")
	model.call("begin_projection_pass")
	model.call("project", "nested_pass", producer)
	model.call("begin_projection_pass")
	model.call("project", "nested_pass", producer)
	_check(_scope_depth(model) == 2 and int(source.reads.get("nested_pass", 0)) == 1, "Nested begin joins the current synchronous pass")
	model.call("end_projection_pass")
	model.call("project", "nested_pass", producer)
	_check(_scope_depth(model) == 1 and int(source.reads.get("nested_pass", 0)) == 1, "Inner end preserves only its still-open outer scope")
	model.call("end_projection_pass")
	_check(_scope_depth(model) == 0 and _cached_count(model) == 0, "The balanced nested pass leaves no persistent projection owner")
	model.free()


func _test_nested_producers_and_recursive_fallback() -> void:
	var model: Node = READ_MODEL.new()
	var source = ProjectionSource.new()
	source.model = model
	model.call("begin_projection_pass")
	var outer: Dictionary = model.call("project", "outer", Callable(source, "outer"))
	_check(int(outer.nested.read) == 1 and _cached_count(model) == 1, "Only the outer result is stored, not its nested producer")
	var standalone: Dictionary = model.call("project", "nested", Callable(source, "numbered").bind("nested"))
	_check(int(standalone.read) == 2, "A nested result is rebuilt when later requested at top level")
	var complete: Dictionary = model.call("project", "recursive", Callable(source, "recursive"))
	var complete_again: Dictionary = model.call("project", "recursive", Callable(source, "recursive"))
	_check(String(complete.kind) == "complete" and complete_again == complete and int(source.reads.get("recursive", 0)) == 1 and int(source.reads.get("fallback", 0)) == 1, "Reentry caches the complete outer result rather than its recursive fallback")
	model.call("end_projection_pass")
	model.call("begin_projection_pass")
	model.call("project", "nested", Callable(source, "numbered").bind("nested"))
	var with_primed_nested: Dictionary = model.call("project", "outer", Callable(source, "outer"))
	var retained_top: Dictionary = model.call("project", "nested", Callable(source, "numbered").bind("nested"))
	_check(int(with_primed_nested.nested.read) == 4 and int(retained_top.read) == 3, "Nested reads bypass existing top-level entries and cannot replace them")
	var diagnostics: Dictionary = model.call("get_diagnostics_snapshot")
	_check(int(diagnostics.get("projection_recursive_bypass_count", -1)) == 3, "Diagnostics account for all three nested producer bypasses")
	model.call("end_projection_pass")
	model.free()


func _test_defensive_snapshot_copies() -> void:
	var model: Node = READ_MODEL.new()
	var source = ProjectionSource.new()
	var original_owner: Dictionary = source.source.duplicate(true)
	model.call("begin_projection_pass")
	var first: Dictionary = model.call("project", "snapshot", Callable(source, "snapshot"))
	first.unit.hp = 0
	first.members[0].id = "consumer_changed"
	first.commands.append("invented_command")
	first.effects.append("invented_effect")
	_check(source.source == original_owner, "Mutating a first return cannot mutate owner health, identities, commands or effects")
	var second: Dictionary = model.call("project", "snapshot", Callable(source, "snapshot"))
	_check(second == original_owner, "First-return mutation cannot poison the stored nested Dictionary/Array snapshot")
	second.members.append({"id": "new_consumer_member"})
	var third: Dictionary = model.call("project", "snapshot", Callable(source, "snapshot"))
	_check(third == original_owner, "Each cache hit also returns a deep defensive copy")
	source.source.unit.hp = 4
	source.source.members[0].id = "owner_changed"
	var after_owner_change: Dictionary = model.call("project", "snapshot", Callable(source, "snapshot"))
	_check(after_owner_change == original_owner, "Later producer-source mutation cannot change the stored pass snapshot")
	model.call("mark_fireteam_heavy_state_changed", "BLUE")
	var diagnostics: Dictionary = model.call("get_diagnostics_snapshot")
	diagnostics.fireteam_heavy_revisions["blue"] = 900
	_check(int(model.call("get_fireteam_heavy_revision", "blue")) == 1, "Returned diagnostics cannot mutate owner revisions")
	_check(source.source.commands.is_empty() and source.source.effects.is_empty(), "Pure projection operations produce no owner commands or effects")
	model.call("end_projection_pass")
	model.free()


func _test_revision_invalidation() -> void:
	var model: Node = READ_MODEL.new()
	var source = ProjectionSource.new()
	var producer: Callable = Callable(source, "numbered").bind("revision")
	model.call("set_light_state", "feedback", "initial")
	model.call("begin_projection_pass")
	model.call("project", "revision", producer)
	_check(not bool(model.call("set_light_state", "feedback", "initial")), "An unchanged light value retains its existing revision")
	model.call("mark_fireteam_heavy_state_changed", " ")
	model.call("set_light_state", " ", "ignored")
	var unchanged: Dictionary = model.call("project", "revision", producer)
	_check(int(unchanged.read) == 1, "Unchanged light values and invalid IDs preserve the current pass entry")
	model.call("set_light_state", "feedback", "changed")
	var light_changed: Dictionary = model.call("project", "revision", producer)
	_check(int(light_changed.read) == 2, "A real light revision invalidates a pass immediately")
	model.call("mark_heavy_state_changed")
	var heavy_changed: Dictionary = model.call("project", "revision", producer)
	_check(int(heavy_changed.read) == 3, "A heavy revision invalidates a pass immediately")
	model.call("mark_fireteam_heavy_state_changed", "Blue")
	var fireteam_changed: Dictionary = model.call("project", "revision", producer)
	_check(int(fireteam_changed.read) == 4 and int(model.call("get_fireteam_heavy_revision", "blue")) == 1, "A fireteam heavy revision invalidates the shared projection without losing normalization")
	model.call("end_projection_pass")
	model.free()


func _test_revision_during_producer() -> void:
	var model: Node = READ_MODEL.new()
	var source = ProjectionSource.new()
	source.model = model
	model.call("begin_projection_pass")
	var first: Dictionary = model.call("project", "inflight", Callable(source, "revision_during_build"))
	_check(int(first.read) == 1 and _cached_count(model) == 0, "A producer invalidated while building cannot repopulate an expired generation")
	var second: Dictionary = model.call("project", "inflight", Callable(source, "revision_during_build"))
	_check(int(second.read) == 2, "The next read rebuilds after in-producer revision invalidation")
	model.call("end_projection_pass")
	model.free()


func _test_leaked_scope_expires_on_new_frame() -> void:
	var model: Node = READ_MODEL.new()
	var source = ProjectionSource.new()
	var producer: Callable = Callable(source, "numbered").bind("frame")
	model.call("begin_projection_pass")
	model.call("begin_projection_pass")
	model.call("project", "frame", producer)
	var frame_before: int = Engine.get_process_frames()
	while Engine.get_process_frames() == frame_before:
		await process_frame
	var next_frame: Dictionary = model.call("project", "frame", producer)
	var next_direct: Dictionary = model.call("project", "frame", producer)
	_check(int(next_frame.read) == 2 and int(next_direct.read) == 3, "A leaked pass cannot reuse old snapshots on the next engineframe")
	var diagnostics: Dictionary = model.call("get_diagnostics_snapshot")
	_check(int(diagnostics.get("projection_scope_depth", -1)) == 0 and int(diagnostics.get("projection_cached_entries", -1)) == 0 and int(diagnostics.get("projection_leaked_scope_count", -1)) == 1, "Frame expiration discards the complete nested leaked scope and records it once")
	model.call("begin_projection_pass")
	var restarted: Dictionary = model.call("project", "frame", producer)
	_check(int(restarted.read) == 4 and _scope_depth(model) == 1, "Only an explicit begin establishes a fresh pass after a leak")
	model.call("end_projection_pass")
	model.free()


func _cached_count(model: Node) -> int:
	var diagnostics: Dictionary = model.call("get_diagnostics_snapshot")
	return int(diagnostics.get("projection_cached_entries", -1))


func _scope_depth(model: Node) -> int:
	var diagnostics: Dictionary = model.call("get_diagnostics_snapshot")
	return int(diagnostics.get("projection_scope_depth", -1))


func _check(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		print("FAIL: %s" % message)
