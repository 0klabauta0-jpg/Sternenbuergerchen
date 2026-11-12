extends SceneTree
const Registry = preload("res://scripts/core/space_ship_registry.gd")
const Flight = preload("res://scripts/core/space_flight_state.gd")
var checks := 0
var failures := 0
func _initialize() -> void:
	var registry = Registry.new()
	_check(registry.has_method("export_checkpoint_index"), "portable checkpoint API exists")
	if failures == 0: _exercise(registry)
	print("SPACE_REGISTRY_CHECKPOINT checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
func _check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)
func _flight(id: String, area: String):
	var flight = Flight.new()
	_check(flight.configure(id, {"position_plane":Vector2.ZERO, "space_area_id":area, "coordinate_frame":"strategic" if area.is_empty() else "local"}).ok, "configure real Flight " + id)
	return flight
func _exercise(registry) -> void:
	var a = _flight("a", "orbit")
	var b = _flight("b", "")
	var departed = _flight("departed", "old")
	registry.register_actor("b", b)
	registry.update_actor_cells("b", _points([Vector2i(1, 1)]))
	registry.register_actor("a", a)
	registry.update_actor_cells("a", _points([Vector2i(2, 1), Vector2i(1, 1)]))
	registry.register_actor("departed", departed)
	registry.update_actor_cells("departed", _points([Vector2i.ZERO]))
	registry.unregister_actor("departed")
	var state: Dictionary = registry.export_checkpoint_index()
	_check(state.schema == "space_registry_checkpoint.v1" and state.actors[0].craft_id == "a", "schema and deterministic actor ordering")
	var decoded: Dictionary = JSON.parse_string(JSON.stringify(state))
	var flights := {"a":a, "b":b, "extra":_flight("extra", "")}
	var before_a: Dictionary = a.get_snapshot()
	var result: Dictionary = Registry.prepare_checkpoint_candidate(decoded, flights)
	_check(result.ok, "JSON roundtrip accepted")
	if result.ok:
		var copy = result.candidate
		_check(copy != registry and copy.get_actor("a") == a and copy.get_actor("extra") == null, "detached registry binds actual owners and only listed actors")
		_check(copy.export_checkpoint_index() == state, "exact index and departed revisions preserved")
		_check(copy.get_area_revision("old") == 2, "departed area revision survives")
		_check(copy.query_cells(_points([Vector2i(1, 1)]), "orbit") == ["a"], "lookup index rebuilt")
	for kind in ["duplicate", "collision", "stale", "area", "fraction", "huge", "revision", "unknown", "extra_field", "missing", "duplicate_cell", "unsafe_revision", "nonfinite", "bounds", "boolean", "alias_owner", "actor_limit", "area_limit", "wrong_array"]:
		var bad := decoded.duplicate(true)
		match kind:
			"duplicate": bad.actors.append(bad.actors[0].duplicate(true))
			"collision":
				bad.actors.append({"craft_id":"c", "area_id":"orbit", "flight_revision":0, "cells":[[1, 1]]})
				flights["c"] = _flight("c", "orbit")
			"stale": bad.actors[0].flight_revision += 1
			"area": bad.actors[0].area_id = "wrong"
			"fraction": bad.actors[0].cells[0][0] = 1.5
			"huge": bad.actors[0].cells.resize(4097)
			"revision": bad.area_revisions.orbit = 0
			"unknown": bad.schema = "future"
			"extra_field": bad.actors[0].extra = true
			"missing": bad.area_revisions.erase("orbit")
			"duplicate_cell": bad.actors[0].cells.append(bad.actors[0].cells[0])
			"unsafe_revision": bad.area_revisions.orbit = 9007199254740992
			"nonfinite": bad.actors[0].cells[0][0] = INF
			"bounds": bad.actors[0].cells[0][0] = 2147483648
			"boolean": bad.actors[0].cells[0][0] = true
			"alias_owner":
				var aliased := flights.duplicate()
				aliased["b"] = a
				_check(not Registry.prepare_checkpoint_candidate(bad, aliased).ok, "reject double-owned Flight")
				continue
			"actor_limit": bad.actors.resize(4097)
			"area_limit":
				for i in range(4097): bad.area_revisions[str(i)] = 0
			"wrong_array": bad.actors[0].cells = {"x":1, "y":1}
		_check(not Registry.prepare_checkpoint_candidate(bad, flights).ok, "reject " + kind)
	_check(a.get_snapshot() == before_a and registry.export_checkpoint_index() == state, "prepare failures and success leave live owners unchanged")
	var unindexed = Registry.new()
	unindexed.register_actor("a", a)
	_check(not unindexed.export_checkpoint_index().get("ok", true), "export rejects unindexed actor")
	var overlapping = Registry.new()
	overlapping.register_actor("a", a)
	overlapping.update_actor_cells("a", _points([Vector2i.ZERO]))
	overlapping.register_actor("c", flights.c)
	overlapping.update_actor_cells("c", _points([Vector2i.ZERO]))
	_check(not overlapping.export_checkpoint_index().get("ok", true), "export rejects colliding index")
	registry._cells["orbit"].erase(Vector2i(1, 1))
	_check(not registry.export_checkpoint_index().get("ok", true), "export rejects inconsistent lookup index")

func _points(values: Array) -> Array[Vector2i]:
	var typed: Array[Vector2i] = []
	typed.assign(values)
	return typed
