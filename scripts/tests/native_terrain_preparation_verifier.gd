extends SceneTree
## Differential checks at the native edge-preparation boundary, including fallback.
const NAV = preload("res://scripts/terrain/native_navigation.gd")
const BASE = preload("res://scripts/tests/native_terrain_preparation_reference.gd")
const BENCH = preload("res://scripts/tests/native_terrain_preparation_benchmark.gd")
const FIX = preload("res://scripts/tests/native_navigation_main_fixtures.gd")
const IO = preload("res://scripts/tests/native_navigation_prototype_fixtures.gd")
var passed := 0
var failed := 0
var failures: Array = []
var compared_edges := 0

class RejectBuilder:
	extends RefCounted
	func build_edges(_fields: Dictionary) -> Dictionary: return {}

class MissingBuilderApi:
	extends RefCounted

class DerivedGeometryReader:
	extends "res://scripts/terrain/terrain_registry.gd"
	var changed_tile
	func get_tile_at_grid(grid: Vector2i):
		if grid == Vector2i.RIGHT and changed_tile != null: return changed_tile
		return super.get_tile_at_grid(grid)

func _init() -> void: call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	if condition: passed += 1
	else:
		failed += 1
		failures.append(label)
		push_error(label)

func _run() -> void:
	_check(ClassDB.class_exists("NativeTerrainBuilder"), "Native terrain builder is actually registered")
	if failed == 0:
		var gm: Dictionary = FIX.real_map()
		_compare("actual GM01 importer", gm.terrain)
		gm.terrain.free()
		var ramps: Dictionary = FIX.synthetic()
		_compare("explicit Main ramps", ramps.terrain)
		ramps.terrain.free()
		_test_edge_rules()
		_test_specific_rules()
		_test_fallbacks()
		_test_rejections()
	var result := {"schema": "native_terrain_preparation_verifier.v1", "passed": passed, "failed": failed,
		"failures": failures, "compared_edges": compared_edges, "engine": Engine.get_version_info(),
		"reference_body_sha256": BASE.BASE_BODY_SHA256}
	if not IO.write_json(IO.argument("--output", "user://native_terrain_preparation_verifier.json"), result): failed += 1
	print("NATIVE_TERRAIN_PREPARATION_VERIFIER ", passed, "/", failed, " edges=", compared_edges)
	quit(0 if failed == 0 else 1)

func _compare(label: String, terrain, mode: String = "native") -> void:
	var original = BASE.new()
	var candidate = NAV.new()
	original._kernel = BENCH.CaptureKernel.new(original._kernel)
	candidate._kernel = BENCH.CaptureKernel.new(candidate._kernel)
	if mode == "disabled": candidate.native_terrain_builder_enabled = false
	elif mode == "missing": candidate._terrain_builder = null
	elif mode == "rejected": candidate._terrain_builder = RejectBuilder.new()
	elif mode == "missing_api": candidate._terrain_builder = MissingBuilderApi.new()
	var revision: int = terrain.get_revision()
	var original_ok: bool = original.prepare(terrain)
	var candidate_ok: bool = candidate.prepare(terrain)
	_check(original_ok and candidate_ok, label + " accepted by existing kernel")
	var a: Dictionary = original._kernel.snapshot
	var b: Dictionary = candidate._kernel.snapshot
	_check(a == b and var_to_bytes(a) == var_to_bytes(b), label + " exact packed fields/ordered edges/float bytes")
	_check(terrain.get_revision() == revision, label + " preserves authoritative terrain revision")
	_check(candidate.get_debug_snapshot().get("terrain_builder", "") == ("native" if mode == "native" else "gdscript"), label + " expected edge backend")
	compared_edges += b.get("neighbors", PackedInt32Array()).size()

func _test_edge_rules() -> void:
	for direction_index in range(6):
		for from_ramp in range(-1, 6):
			for to_ramp in range(-1, 6):
				var registry = FIX.REG.new()
				registry.configure_iso_grid(Vector2.ZERO, 64, 32, "hex_axial_v1")
				var source := Vector2i(-3, -4)
				var target: Vector2i = source + FIX.HEX.DIRECTIONS[direction_index]
				var from_height: int = (from_ramp + 1) % 2
				var to_height: int = (to_ramp + 1) % 2
				registry.register_tile(FIX.TILE.new({"tile_id": "a", "grid_position": source, "height_level": from_height,
					"explicit_hex_ramps": true, "ramp_direction": from_ramp, "surface_type": "road"}))
				registry.register_tile(FIX.TILE.new({"tile_id": "b", "grid_position": target, "height_level": to_height,
					"explicit_hex_ramps": true, "ramp_direction": to_ramp, "surface_type": "sand"}))
				_compare("ramp dirs %d/%d/%d" % [direction_index, from_ramp, to_ramp], registry)
				registry.free()
	for topology in ["hex_axial_v1", "square8"]:
		for scenario in range(12):
			var registry = IO.synthetic(topology, 7, 6, Vector2i(-5, -3))
			for tile in registry.get_all_tiles():
				var ordinal: int = absi(tile.grid_position.x * 7 + tile.grid_position.y * 11 + scenario)
				tile.height_level = ordinal % 4
				tile.regional_grade = scenario % 3 == 0
				tile.object_type_id = "glut_bridge_deck" if ordinal % 9 == 0 else ""
				tile.explicit_hex_ramps = scenario >= 6 and ordinal % 4 != 0
				tile.ramp_direction = ordinal % 7 - 1
				tile.walkable = ordinal % 5 != 0
			registry.notify_tile_data_changed()
			_compare("%s mixed flags %d" % [topology, scenario], registry)
			var grid: Vector2i = registry.get_all_tiles()[0].grid_position
			registry.set_runtime_tile_overrides([{"grid_position": grid, "walkable_override": true, "cover_value_override": 77,
				"blocks_los_override": false, "object_height_override": 1}])
			_compare("%s override %d" % [topology, scenario], registry)
			registry.free()

func _test_fallbacks() -> void:
	var fixture: Dictionary = FIX.synthetic(8, 6)
	for mode in ["disabled", "missing", "rejected", "missing_api"]: _compare(mode + " builder", fixture.terrain, mode)
	var tile = fixture.terrain.get_all_tiles()[0]
	tile.height_level = 1000000
	fixture.terrain.notify_tile_data_changed()
	_compare("outside canonical height domain", fixture.terrain, "unsupported")
	tile.height_level = 0
	tile.ramp_direction = 4294967296
	fixture.terrain.notify_tile_data_changed()
	_compare("wide invalid ramp index cannot wrap into packed valid index", fixture.terrain, "unsupported")
	fixture.terrain.free()
	var derived := DerivedGeometryReader.new()
	derived.configure_iso_grid(Vector2.ZERO, 64, 32, "square8")
	derived.register_tile(FIX.TILE.new({"tile_id": "a", "grid_position": Vector2i.ZERO}))
	derived.register_tile(FIX.TILE.new({"tile_id": "b", "grid_position": Vector2i.RIGHT}))
	derived.changed_tile = FIX.TILE.new({"tile_id": "b_effective", "grid_position": Vector2i.RIGHT, "height_level": 3, "edge_type": "cliff"})
	_check(derived.get_all_tiles()[1].height_level == 0 and not FIX.PATH.new().can_traverse_step(Vector2i.ZERO, Vector2i.RIGHT, derived), "Derived reader fixture exposes effective geometry distinct from enumeration")
	_compare("derived effective geometry reader keeps original calls", derived, "unsupported")
	derived.free()

func _test_specific_rules() -> void:
	var registry = IO.synthetic("square8", 2, 2, Vector2i.ZERO, false)
	var source := Vector2i.ZERO
	var target := Vector2i.ONE
	var side = registry.get_tile_at_grid(Vector2i.RIGHT)
	var pathfinder = FIX.PATH.new()
	_check(pathfinder.can_traverse_step(source, target, registry), "Square diagonal fixture begins traversable")
	_compare("square open diagonal", registry)
	side.walkable = false
	registry.notify_tile_data_changed()
	_check(not pathfinder.can_traverse_step(source, target, registry), "Square diagonal blocked by one side")
	_compare("square corner blocked", registry)
	side.walkable = true
	side.height_level = 3
	side.edge_type = "cliff"
	registry.notify_tile_data_changed()
	_check(not pathfinder.can_traverse_step(source, target, registry), "Square diagonal blocked by side height transition")
	_compare("square corner cliff", registry)
	side.edge_type = "slope"
	registry.notify_tile_data_changed()
	_check(pathfinder.can_traverse_step(source, target, registry), "Legacy slope preserves transition greater than one level")
	_compare("square corner legacy high slope", registry)
	registry.get_tile_at_grid(source).walkable = false
	registry.get_tile_at_grid(target).walkable = false
	registry.notify_tile_data_changed()
	registry.set_runtime_tile_overrides([{"grid_position": source, "walkable_override": true}, {"grid_position": target, "walkable_override": true}])
	_check(pathfinder.can_traverse_step(source, target, registry), "Effective overrides supersede both raw source and target walkability")
	_compare("square source target override", registry)
	registry.free()
	registry = IO.synthetic("hex_axial_v1", 2, 1, Vector2i.ZERO, false)
	var a = registry.get_tile_at_grid(source)
	var b = registry.get_tile_at_grid(Vector2i.RIGHT)
	a.explicit_hex_ramps = true
	a.ramp_direction = 0
	a.height_level = 16
	b.explicit_hex_ramps = true
	b.height_level = 16
	registry.notify_tile_data_changed()
	_check(not pathfinder.can_traverse_step(source, Vector2i.RIGHT, registry), "Ramp at MAX_HEIGHT is not a legal ramp endpoint")
	_compare("max-height explicit ramp", registry)
	a.ramp_direction = 6
	registry.notify_tile_data_changed()
	_compare("invalid ramp direction uses original GDScript", registry, "unsupported")
	a.explicit_hex_ramps = false
	b.explicit_hex_ramps = false
	a.ramp_direction = -1
	a.height_level = 0
	b.height_level = 1
	a.regional_grade = true
	b.regional_grade = true
	registry.notify_tile_data_changed()
	_check(pathfinder.can_traverse_step(source, Vector2i.RIGHT, registry), "Regional one-level grade traverses")
	_compare("regional one-level grade", registry)
	b.object_type_id = "glut_bridge_deck"
	registry.notify_tile_data_changed()
	_check(not pathfinder.can_traverse_step(source, Vector2i.RIGHT, registry), "Bridge deck excludes regional grade step")
	_compare("regional bridge exclusion", registry)
	b.object_type_id = ""
	b.height_level = 2
	b.edge_type = "slope"
	registry.notify_tile_data_changed()
	_check(not pathfinder.can_traverse_step(source, Vector2i.RIGHT, registry), "Regional two-level grade remains blocked even with slope tag")
	_compare("regional two-level exclusion", registry)
	registry.free()

func _test_rejections() -> void:
	var builder: Object = ClassDB.instantiate("NativeTerrainBuilder")
	_check(builder.call("build_edges", {}).is_empty(), "Missing packed fields rejected")
	var good := {"coords": PackedInt32Array([0, 0, 1, 0]), "height": PackedInt32Array([0, 0]),
		"walkable": PackedByteArray([1, 1]), "traits": PackedByteArray([0, 0]), "ramp_direction": PackedInt32Array([-1, -1]),
		"stand_height": PackedFloat64Array([0.0, 0.0]), "surface_cost": PackedFloat64Array([1.0, 0.7]), "hex": true}
	var valid: Dictionary = builder.call("build_edges", good)
	_check(valid.get("offsets") == PackedInt32Array([0, 1, 2]) and valid.get("neighbors") == PackedInt32Array([1, 0]) and valid.get("costs") == PackedFloat64Array([0.7, 1.0]), "Small direct API baseline")
	for key in ["coords", "height", "walkable", "traits", "ramp_direction", "stand_height", "surface_cost", "hex"]:
		var invalid: Dictionary = good.duplicate(true)
		invalid[key] = "wrong type"
		_check(builder.call("build_edges", invalid).is_empty(), "Invalid packed type " + key)
	var invalid: Dictionary = good.duplicate(true)
	invalid.coords = PackedInt32Array([0, 0, 0, 0])
	_check(builder.call("build_edges", invalid).is_empty(), "Duplicate coordinate rejected")
	invalid = good.duplicate(true)
	invalid.surface_cost = PackedFloat64Array([NAN, 0.7])
	_check(builder.call("build_edges", invalid).is_empty(), "Nonfinite cost rejected")
	_check(builder.call("build_edges", good) == valid, "Rejected call retains no stale builder state")
