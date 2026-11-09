extends SceneTree

const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const REGISTRY = preload("res://scripts/terrain/terrain_registry.gd")
const PATHFINDER = preload("res://scripts/terrain/terrain_pathfinder.gd")
const HEX = preload("res://scripts/terrain/hex_grid.gd")
const BASE = preload("res://scenes/meta/explorable_homebase.tscn")
var passed: int = 0
var failed: int = 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://maps/homebase_frontier_exploration.json"))
	var layout: Dictionary = raw.get("homebase_exploration", {})
	var interiors: Array = layout.get("interiors", [])
	var pads: Array = layout.get("landing_pads", [])
	_expect(interiors.size() == 2, "Two authored interiors have independent navigation records")
	_expect(pads.size() == 2, "Two real landing footprints are authored")
	if interiors.size() != 2 or pads.size() != 2:
		_finish()
		return
	var map = MAP.load_from_file("res://maps/homebase_frontier_exploration.json")
	_expect(map.get_grid_topology() == "hex_axial_v1", "Base uses the shared axial topology")
	_expect(map.get_tiles().size() > 480, "Base offers more authored space than the old yard")
	var registry = REGISTRY.new()
	root.add_child(registry)
	var tile_size: Dictionary = map.get_tile_size()
	registry.configure_iso_grid(map.get_grid_origin(), tile_size.half_width, tile_size.half_height, map.get_grid_topology())
	for tile in map.get_tiles():
		registry.register_tile(tile)
	var start: Vector2i = _grid(layout.avatar_spawn_grid)
	var reachable: Dictionary = _reachable(start, registry)
	var pathfinder = PATHFINDER.new()
	for room in interiors:
		var inside: Vector2i = _grid(room.interior_grid)
		var door: Vector2i = _grid(room.door_grid)
		_expect(reachable.has(inside) and reachable.has(door), "%s interior and door connect to Commander start" % room.id)
		var path: Array = pathfinder.find_path(start, inside, registry)
		_expect(not path.is_empty() and path.has(door), "%s runtime route enters through authored doorway" % room.id)
		for wall in room.wall_grids:
			_expect(not registry.is_walkable(_grid(wall)), "%s exterior wall blocks movement at %s" % [room.id, wall])
		for floor_grid in room.floor_grids:
			_expect(registry.is_walkable(_grid(floor_grid)), "%s stored floor is walkable at %s" % [room.id, floor_grid])
	var ids: Array = []
	for pad in pads:
		ids.append(String(pad.id))
		_expect(reachable.has(_grid(pad.grid)), "%s pad approach is reachable" % pad.id)
	_expect(ids.has("homebase_pad_01") and ids.has("homebase_pad_02"), "Pad identities remain stable for the real craft projection")
	for terminal in layout.terminals:
		_expect(reachable.has(_grid(terminal.grid)), "%s terminal is on reachable authored ground" % terminal.id)
	_expect(Array(layout.get("expansion_areas", [])).size() >= 1, "Future construction retains an authored free footprint")
	var base: Control = BASE.instantiate()
	root.add_child(base)
	await process_frame
	base.call("set_active", true)
	await process_frame
	var snapshot: Dictionary = base.call("get_exploration_snapshot")
	_expect(Array(snapshot.get("landing_pads", [])).size() == 2, "Runtime exposes both pad identities without owning transport")
	_expect(Array(snapshot.get("interiors", [])).size() == 2, "Runtime exposes the authored interior/navigation records")
	_expect(int(snapshot.get("cutaway_wall_visual_count", -1)) == 0, "Runtime does not replace furnished source buildings with bare walls")
	_expect(Dictionary(snapshot.get("structure_visuals", {})).size() == 2, "Runtime restores both furnished source building models")
	_expect(not bool(snapshot.get("owns_transport", true)), "Pad display introduces no second craft owner")
	var first_room: Dictionary = interiors[0]
	var destination: Vector2 = registry.grid_to_world(_grid(first_room.interior_grid))
	_expect(bool(base.call("request_walk_to", destination)), "Real runtime accepts a walk into the first room")
	var deadline: int = Time.get_ticks_msec() + 12000
	while Time.get_ticks_msec() < deadline:
		await physics_frame
		var current: Dictionary = base.call("get_exploration_snapshot")
		if Vector2(current.avatar_position).distance_to(destination) < 1.0:
			break
	snapshot = base.call("get_exploration_snapshot")
	_expect(Vector2(snapshot.avatar_position).distance_to(destination) < 1.0, "SimulationRoot actually moves Commander through the door onto interior floor")
	_expect(not bool(base.call("request_walk_to", registry.grid_to_world(_grid(first_room.wall_grids[0])))), "Actual wall rejects a runtime movement request")
	base.call("set_active", false)
	var inactive: Dictionary = base.call("get_exploration_snapshot")
	await physics_frame
	_expect(base.call("get_exploration_snapshot").avatar_position == inactive.avatar_position and not paused, "Deactivation stops only base movement without global pause")
	base.queue_free()
	registry.queue_free()
	await process_frame
	_finish()

func _reachable(start: Vector2i, registry: Node) -> Dictionary:
	var reached: Dictionary = {start: true}
	var pending: Array[Vector2i] = [start]
	var index: int = 0
	while index < pending.size():
		var current: Vector2i = pending[index]
		index += 1
		for neighbor in HEX.neighbors(current):
			if not reached.has(neighbor) and registry.is_walkable(neighbor):
				reached[neighbor] = true
				pending.append(neighbor)
	return reached

func _grid(value: Array) -> Vector2i:
	return Vector2i(int(value[0]), int(value[1]))

func _expect(ok: bool, message: String) -> void:
	if ok:
		passed += 1
		print("PASS: " + message)
	else:
		failed += 1
		push_error("FAIL: " + message)

func _finish() -> void:
	print("BASE_INTERIOR_PAD: %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)
