extends RefCounted
## Current Main map loading and real HexGround command fixtures, without visuals.
const SIM = preload("res://scripts/core/simulation_root.gd")
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const REG = preload("res://scripts/terrain/terrain_registry.gd")
const UNITS = preload("res://scripts/registries/unit_registry.gd")
const TILE = preload("res://scripts/terrain/terrain_tile_data.gd")
const HEX = preload("res://scripts/terrain/hex_grid.gd")
const PATH = preload("res://scripts/terrain/terrain_pathfinder.gd")

class Actor:
	extends Node2D
	var unit_id: String = "probe"
	var current_command: RefCounted
	var target_position: Vector2
	func get_unit_id() -> String: return unit_id
	func get_team_id() -> String: return "blue"
	func get_vital_state() -> String: return "fit"
	func get_current_unit_command(): return current_command
	func assign_unit_command(value) -> void: current_command = value
	func set_target_position(value: Vector2) -> void: target_position = value
	func get_target_position() -> Vector2: return target_position
	func get_move_speed_factor() -> float: return 1.0
	func get_combat_speed_multiplier() -> float: return 1.0

static func synthetic(width: int = 24, height: int = 12) -> Dictionary:
	var map = MAP.create_empty("native_main_ramps", Vector2i(width, height), Vector2.ZERO, 64, 32, 3, "hex_axial_v1")
	map.set_tactical_grid_rules("hex_tactical_v1")
	for tile in map.get_tiles():
		var grid: Vector2i = tile.grid_position
		tile.explicit_hex_ramps = true
		tile.height_level = 1 if grid.x >= width / 2 + 1 else 0
		tile.ramp_direction = 0 if grid.x == width / 2 else -1
		tile.cover_value = (grid.x * 13 + grid.y * 7) % 101
		tile.surface_type = "road" if (grid.x + grid.y) % 5 == 0 else "ground"
		tile.walkable = not (grid.x == width / 3 and grid.y not in [2, height - 3])
		tile.blocks_los = not tile.walkable
		tile.object_height = 2 if tile.blocks_los else 0
	return from_map(map)

static func real_map() -> Dictionary:
	# Use the real importer: Main stores ramp activation in root metadata.
	# Decoding individual JSON tiles alone would silently omit these rules.
	var map = MAP.load_from_file("res://maps/Ground_Mission01_32x32.json")
	return from_map(map)

static func from_map(map) -> Dictionary:
	var terrain = REG.new()
	var size: Dictionary = map.get_tile_size()
	terrain.configure_iso_grid(map.get_grid_origin(), size.half_width, size.half_height, map.get_grid_topology())
	for tile in map.get_tiles(): terrain.register_tile(tile)
	terrain.prepare_spatial_queries()
	return {"map": map, "terrain": terrain}

static func connected_pairs(terrain, count: int = 8) -> Array:
	var pathfinder = PATH.new()
	var remaining: Dictionary = {}
	for tile in terrain.get_all_tiles():
		if terrain.is_walkable(tile.grid_position): remaining[tile.grid_position] = true
	var largest: Array = []
	while not remaining.is_empty():
		var seed: Vector2i = remaining.keys()[0]
		var component: Array = [seed]
		remaining.erase(seed)
		var index: int = 0
		while index < component.size():
			var from: Vector2i = component[index]
			index += 1
			for direction: Vector2i in HEX.DIRECTIONS:
				var target: Vector2i = from + direction
				if remaining.has(target) and pathfinder.can_traverse_step(from, target, terrain):
					remaining.erase(target)
					component.append(target)
		if component.size() > largest.size(): largest = component
	largest.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.x < b.x or (a.x == b.x and a.y < b.y))
	var pairs: Array = []
	if largest.size() < 2: return pairs
	for sample in range(count):
		var source: int = (sample * 47 + 13) % largest.size()
		var target: int = (source + int(largest.size() / 2) + sample * 31 + 17) % largest.size()
		if source == target: target = (target + 1) % largest.size()
		pairs.append([largest[source], largest[target]])
	return pairs

static func create_rig(parent: Node, map, terrain, native_enabled: bool) -> Dictionary:
	var scene := Node.new()
	parent.add_child(scene)
	var units = UNITS.new()
	scene.add_child(units)
	var sim = SIM.new()
	sim.native_navigation_enabled = native_enabled
	scene.add_child(sim)
	sim.set_physics_process(false)
	sim.set_process(false)
	sim.unit_registry_path = sim.get_path_to(units)
	sim.terrain_registry_path = sim.get_path_to(terrain)
	# Keep the Main defaults for traffic/spacing. HexGround owns their behavior.
	var configured: Dictionary = sim.configure_hex_ground_runtime(map, terrain)
	var actor := Actor.new()
	scene.add_child(actor)
	units.register_unit(actor.unit_id, actor)
	sim.register_known_unit(actor.unit_id, actor)
	return {"scene": scene, "sim": sim, "units": units, "actor": actor, "configured": configured}

static func command(terrain, pair: Array, sample: int) -> Dictionary:
	return {"type": "move_to_position", "unit_id": "probe", "team_id": "blue",
		"command_token": "native_main_%d" % sample, "target_position": terrain.grid_to_world(pair[1]),
		"move_speed_factor": 1.0, "requeue_until_target": true,
		"navigation_cover_aware": true, "navigation_cover_weight": 0.2 + float(sample % 3) * 0.15,
		"navigation_exposure_weight": 0.72,
		"navigation_corridor_enabled": true, "navigation_corridor_start_position": terrain.grid_to_world(pair[0]),
		"navigation_corridor_end_position": terrain.grid_to_world(pair[1]), "navigation_corridor_half_width_world": 96.0,
		"navigation_corridor_weight": 0.62, "navigation_lane_enabled": true, "navigation_lane_weight": 0.88,
		"navigation_lane_offset_world": float(sample % 3 - 1) * 48.0,
		"navigation_blocker_clearance_weight": 0.392, "navigation_blocker_clearance_radius": 1}

static func run_move(rig: Dictionary, map, terrain, pair: Array, sample: int, limit: int = 4096) -> Dictionary:
	var sim = rig.sim
	var actor = rig.actor
	var configured: Dictionary = sim.configure_hex_ground_runtime(map, terrain)
	if not configured.get("ok", false) or not configured.get("enabled", false):
		return _failed_move("hex_configuration_failed", configured)
	actor.global_position = terrain.grid_to_world(pair[0])
	var placements: Array[Dictionary] = [{"unit_id": "probe", "grid": pair[0]}]
	var admission: Dictionary = sim.admit_hex_ground_units(placements)
	if not admission.get("ok", false):
		return _failed_move("hex_admission_failed", configured, admission)
	var cmd: Dictionary = command(terrain, pair, sample)
	sim.enqueue_command(cmd)
	var trace: Array = []
	var path: Array = []
	var tick_times: Array = []
	var navigation_tick_times: Array = []
	var expansions: int = 0
	var native_slices: int = 0
	var gdscript_slices: int = 0
	var bounded: bool = true
	for tick in range(limit):
		var started: int = Time.get_ticks_usec()
		sim._physics_process(0.25)
		var elapsed: int = Time.get_ticks_usec() - started
		tick_times.append(elapsed)
		# Readouts and differential comparisons are outside the timing window.
		var audit: Dictionary = sim.get_hex_movement_audit_snapshot()
		var state: Dictionary = sim.get_hex_unit_state("probe")
		var readout: Dictionary = sim.get_hex_movement_readout("probe")
		if state.is_empty() or readout.is_empty():
			return _failed_move("accepted_move_has_no_runtime_state", configured, admission)
		if int(audit.get("navigation_slices", 0)) > 0: navigation_tick_times.append(elapsed)
		expansions += int(audit.get("navigation_expansions", 0))
		native_slices += int(audit.get("native_navigation_slices", 0))
		gdscript_slices += int(audit.get("gdscript_navigation_slices", 0))
		bounded = bounded and int(audit.get("navigation_slices", 0)) <= 4 and int(audit.get("navigation_expansions", 0)) <= 96
		bounded = bounded and int(audit.get("reservation_requests", 0)) <= 16 and int(audit.get("accepted_steps", 0)) <= 48
		var orders: Dictionary = sim.get("_hex_movement_runtime").get("_orders")
		if path.is_empty() and orders.has("probe") and not orders.probe.path.is_empty(): path = orders.probe.path.duplicate()
		trace.append([state.get("grid"), state.get("movement_state", {}).get("moving", false), actor.global_position,
			readout.get("status"), readout.get("reason"), readout.get("navigation_jobs"), readout.get("navigation_pending"),
			audit.get("navigation_expansions", 0), audit.get("navigation_slices", 0),
			audit.get("reservation_requests", 0), audit.get("accepted_steps", 0)])
		if sim.has_hex_destination_arrived("probe", cmd.command_token): break
	return {"configured": configured, "admission": admission, "arrived": sim.has_hex_destination_arrived("probe", cmd.command_token),
		"trace": trace, "path": path, "position": actor.global_position, "ticks": tick_times.size(),
		"tick_times_usec": tick_times, "navigation_tick_times_usec": navigation_tick_times,
		"expanded_count": expansions, "native_slices": native_slices, "gdscript_slices": gdscript_slices,
		"budget_bounded": bounded, "backend": sim.get_navigation_backend_debug_snapshot(),
		"readout": sim.get_hex_movement_readout("probe"), "options": sim._build_navigation_cost_options(cmd, terrain)}

static func _failed_move(reason: String, configured: Dictionary = {}, admission: Dictionary = {}) -> Dictionary:
	# Keep the result shape stable so a failed prerequisite produces explicit
	# assertions instead of cascading missing-key errors or empty fixture passes.
	return {"failure_reason": reason, "configured": configured, "admission": admission,
		"arrived": false, "trace": [], "path": [], "position": Vector2.ZERO, "ticks": 0,
		"tick_times_usec": [], "navigation_tick_times_usec": [], "expanded_count": 0,
		"native_slices": 0, "gdscript_slices": 0, "budget_bounded": false,
		"backend": {}, "readout": {}, "options": {}}
