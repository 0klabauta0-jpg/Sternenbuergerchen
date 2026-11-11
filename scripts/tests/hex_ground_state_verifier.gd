extends SceneTree

const REGISTRY = preload("res://scripts/terrain/terrain_registry.gd")
const TILE = preload("res://scripts/terrain/terrain_tile_data.gd")
const RUNTIME_PATH := "res://scripts/core/hex_ground_runtime.gd"
var passed := 0
var failed := 0

func _init() -> void:
	call_deferred("_run")

func _check(value: bool, label: String) -> void:
	if value:
		passed += 1
		print("PASS: ", label)
	else:
		failed += 1
		print("FAIL: ", label)

func _batch(entries: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	result.assign(entries)
	return result

func _run() -> void:
	_check(ResourceLoader.exists(RUNTIME_PATH), "HexGroundRuntime is implemented")
	if failed > 0:
		_finish()
		return
	var script = load(RUNTIME_PATH)
	var state = script.new()
	var terrain: Node = REGISTRY.new()
	terrain.configure_iso_grid(Vector2.ZERO, 64.0, 32.0, "hex_axial_v1")
	for x in range(4):
		terrain.register_tile(TILE.new({"tile_id":"field_%d" % x,"grid_position":Vector2i(x,0),
			"walkable":x != 3,"explicit_hex_ramps":true,"height_level":2 if x == 2 else 0,
			"ramp_direction":0 if x == 2 else -1}))
	_check(not state.admit_units(_batch([{"unit_id":"a","grid":Vector2i.ZERO}])).ok, "unconfigured admission rejected")
	state.configure(terrain, "fixture", 7)
	_check(state.admit_units(_batch([{"unit_id":"a","grid":Vector2i.ZERO,"facing_dir":0},
		{"unit_id":"b","grid":Vector2i(1,0),"facing_dir":3}])).ok, "two exclusive cells admitted")
	var before: Dictionary = state.build_planning_snapshot()
	_check(not state.admit_units(_batch([{"unit_id":"c","grid":Vector2i(2,0)},
		{"unit_id":"d","grid":Vector2i.ZERO}])).ok, "occupied group member rejects entire batch")
	_check(state.build_planning_snapshot() == before and state.read_unit("c").is_empty(), "failed group leaves no partial admission")
	_check(not state.admit_units(_batch([{"unit_id":"c","grid":Vector2i(2,0)},
		{"unit_id":"c","grid":Vector2i(3,0)}])).ok, "duplicate batch ID rejected")
	_check(not state.admit_units(_batch([{"unit_id":"c","grid":Vector2i(2,0)},
		{"unit_id":"d","grid":Vector2i(2,0)}])).ok, "duplicate batch cell rejected")
	_check(not state.admit_units(_batch([{"unit_id":"c","grid":Vector2i(3,0)}])).ok, "unwalkable cell rejected")
	for invalid in [{"unit_id":"c","grid":Vector2.ZERO}, {"unit_id":"c","grid":Vector2i(2,0),"facing_dir":6},
		{"unit_id":"c","grid":Vector2i(2,0),"facing_dir":true}, {"unit_id":"","grid":Vector2i(2,0)}]:
		_check(not state.admit_units(_batch([invalid])).ok, "invalid placement rejected")
	_check(state.build_planning_snapshot() == before, "all rejected inputs preserve original state")
	_check(state.admit_units(_batch([{"unit_id":"ramp","grid":Vector2i(2,0),"posture_key":"ready"}])).ok, "ramp cell admitted")
	var ramp: Dictionary = state.read_unit("ramp")
	_check(ramp.stand_height_steps2 == 5 and ramp.posture_key == "ready", "real ramp height H+0.5 preserved")
	ramp.grid = Vector2i(99,99)
	ramp.movement_state.moving = true
	_check(state.read_unit("ramp").grid == Vector2i(2,0) and not state.read_unit("ramp").movement_state.moving, "read payload cannot mutate runtime")
	var before_height: Dictionary = state.read_unit("ramp")
	var before_cells: Dictionary = state.build_planning_snapshot().occupant_by_grid
	terrain.get_tile_at_grid(Vector2i(2,0)).height_level=3
	terrain.notify_tile_data_changed([Vector2i(2,0)])
	var after_height: Dictionary = state.read_unit("ramp")
	_check(after_height.stand_height_steps2==7 and after_height.terrain_revision>before_height.terrain_revision and after_height.state_revision==before_height.state_revision,"terrain height and revision stay fresh without mutating unit state")
	_check(state.build_planning_snapshot().occupant_by_grid==before_cells,"terrain update preserves logical occupancy")
	var snapshot: Dictionary = state.build_planning_snapshot()
	snapshot.occupant_by_grid.clear()
	snapshot.units_by_id.clear()
	_check(state.read_unit("a").grid == Vector2i.ZERO and state.build_planning_snapshot().occupant_by_grid.size() == 3, "planning snapshot cannot mutate indices")
	state.release_unit("a", "removed")
	var released: Dictionary = state.build_planning_snapshot()
	state.release_unit("a", "removed")
	_check(state.read_unit("a").is_empty() and state.build_planning_snapshot() == released, "release is idempotent")
	_check(state.admit_units(_batch([{"unit_id":"replacement","grid":Vector2i.ZERO}])).ok, "released cell reusable")
	state.clear()
	_check(state.read_unit("b").is_empty() and not state.admit_units(_batch([{"unit_id":"x","grid":Vector2i.ZERO}])).ok, "clear removes context and claims")
	state.configure(terrain,"second_map",0)
	var empty: Dictionary = state.build_planning_snapshot()
	_check(state.admit_units(_batch([])).ok and state.build_planning_snapshot()==empty,"empty admission is a no-op")
	_check(not state.admit_units(_batch([{"unit_id":"x","grid":Vector2i.ZERO,"posture_key":null}])).ok,"invalid posture rejected")
	var square: Node = REGISTRY.new()
	square.configure_iso_grid(Vector2.ZERO,64.0,32.0,"square8")
	state.configure(square,"legacy",0)
	_check(not state.admit_units(_batch([{"unit_id":"x","grid":Vector2i.ZERO}])).ok,"legacy square registry cannot enable hex state")
	square.free()
	terrain.free()
	_finish()

func _finish() -> void:
	print("RESULTS: %d passed, %d failed" % [passed, failed])
	if failed == 0:
		print("HEX_GROUND_STATE_PASS")
	quit(0 if failed == 0 else 1)
