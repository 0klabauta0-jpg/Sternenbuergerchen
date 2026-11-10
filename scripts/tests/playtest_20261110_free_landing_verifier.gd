extends SceneTree
var failed := 0
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var registry: Node = load("res://scripts/terrain/terrain_registry.gd").new()
	root.add_child(registry)
	var map = load("res://scripts/terrain/terrain_map_data.gd").create_empty("field_lz", Vector2i(14,14), Vector2(1536,64),64,32,4)
	registry.configure_iso_grid(map.get_grid_origin(),64,32,map.get_grid_topology())
	for tile in map.get_tiles(): registry.register_tile(tile)
	var path := "res://scripts/mission/field_landing_contract.gd"
	_check(FileAccess.file_exists(path), "Free field landing has shared footprint validation")
	if FileAccess.file_exists(path):
		var contract = load(path)
		_check(bool(contract.validate(registry, Vector2i(6,6), []).ok), "Open interior landing accepted")
		_check(not bool(contract.validate(registry, Vector2i(0,0), []).ok), "Footprint across map edge rejected")
		var blocker = registry.get_tile_at_grid(Vector2i(7,6))
		blocker.walkable = false
		_check(not bool(contract.validate(registry, Vector2i(6,6), []).ok), "Neighbouring obstacle blocks footprint")
		blocker.walkable = true
		var position: Vector2 = registry.grid_to_world(Vector2i(6,6))
		_check(not bool(contract.validate(registry, Vector2i(6,6), [position]).ok), "Occupied landing area rejected")
		var result: Dictionary = contract.resolve(registry, position, "seed", 0.5, 0.5, [])
		_check(bool(result.ok) and result.requested_lz_position == position, "Safe skill resolution preserves requested target")
		_check(bool(contract.validate(registry, registry.world_to_grid(result.resolved_lz_position), []).ok), "Actual skill landing remains safe")
	var flight = load("res://scripts/terrain/mission_flight_visual.gd")
	_check(flight.has_method("normal_arrival_speed"), "Normal approach brakes before touchdown")
	if flight.has_method("normal_arrival_speed"):
		_check(float(flight.normal_arrival_speed(150.0)) < float(flight.normal_arrival_speed(1500.0)), "Near approach is slower than straight flight")
		_check(float(flight.arrival_clearance(0.0, 0.0)) > float(flight.arrival_clearance(0.0, 1.0)), "Hover transitions down to touchdown")
	var use_state: Dictionary = load("res://scripts/mission/mission_interaction_runtime_use_state.gd").build_snapshot({"bindings":[{"interaction_id":"ship_return", "marker_id":"ship_return"}]}, map, {"marker_positions":{"ship_return":Vector2(900,400)}})
	_check(use_state.interactions[0].marker_position == Vector2(900,400), "Return interaction follows authoritative craft anchor")
	registry.queue_free()
	await process_frame
	print("FREE_LANDING failed=", failed)
	quit(1 if failed else 0)
func _check(value: bool, label: String) -> void:
	if not value: failed += 1
	print("PASS: " if value else "FAIL: ", label)
