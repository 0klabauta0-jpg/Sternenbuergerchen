extends SceneTree
const FIX = preload("res://scripts/tests/native_visibility_fixtures.gd")
const HEX = preload("res://scripts/terrain/hex_grid.gd")
const LOS = preload("res://scripts/core/los_system.gd")
const CACHE = preload("res://scripts/mission/combat_visibility_cache.gd")
var passed := 0
var failures: Array = []
var native_calls := 0

class UnversionedReader extends Node:
	var source: Node
	func get_grid_topology(): return source.call("get_grid_topology")
	func get_tile_at_grid(grid: Vector2i): return source.call("get_tile_at_grid", grid)
	func blocks_los_at_grid(grid: Vector2i): return source.call("blocks_los_at_grid", grid)
	func get_object_height_at_grid(grid: Vector2i): return source.call("get_object_height_at_grid", grid)

func _init() -> void: call_deferred("_run")

func _run() -> void:
	_test_differential_rays()
	_test_wide_coordinates()
	_test_live_reader_and_half_heights()
	_test_square_wall_fallback()
	_test_cache_contract()
	if FIX.argument("--require-native", "false") == "true":
		_check(ClassDB.class_exists("NativeVisibilityKernel") and native_calls > 0, "Actual native work required; fallback cannot pass native acceptance")
	var result := {"schema": "native_visibility_parity.v1", "passed": passed, "failed": failures.size(), "failures": failures, "native_calls": native_calls,
		"engine": Engine.get_version_info(), "scope": "Differential line/blocker/reader/cache semantics; no rendering or FPS claim"}
	if not FIX.write_json(FIX.argument("--output", "user://native_visibility_verifier.json"), result): failures.append("Evidence write failed")
	print("NATIVE_VISIBILITY_VERIFIER passed=", passed, " failed=", failures.size(), " native_calls=", native_calls)
	quit(0 if failures.is_empty() else 1)

func _check(condition: bool, label: String) -> void:
	if condition: passed += 1
	else:
		failures.append(label)
		push_error(label)

func _test_differential_rays() -> void:
	var registry: Node = FIX.synthetic()
	var gd = FIX.los(false)
	var cpp = FIX.los(true)
	var rng := RandomNumberGenerator.new()
	rng.seed = 141126
	var pairs: Array = FIX.pairs(registry, 192)
	for index in range(96):
		pairs.append([Vector2i(rng.randi_range(-30, 30), rng.randi_range(-30, 30)), Vector2i(rng.randi_range(-30, 30), rng.randi_range(-30, 30))])
	for pair: Array in pairs:
		var a: Vector2i = pair[0]
		var b: Vector2i = pair[1]
		var native_line: Array[Vector2i] = []
		cpp.call("_build_grid_line_into", a, b, native_line, registry)
		_check(native_line == HEX.line(a, b), "Exact canonical Hex line %s -> %s" % [a, b])
		var reverse: Array[Vector2i] = []
		cpp.call("_build_grid_line_into", b, a, reverse, registry)
		reverse.reverse()
		_check(reverse == native_line, "Reciprocal rounding and negative-coordinate ties")
		for include_target: bool in [false, true]:
			for heights: Vector2 in [Vector2.INF, Vector2(0.5, 2.5), Vector2(2.5, 0.5), Vector2(16.0, 16.0)]:
				var expected: Vector2i = gd.find_first_blocker_grid(a, b, registry, Vector2(a), Vector2(b), include_target, heights)
				var actual: Vector2i = cpp.find_first_blocker_grid(a, b, registry, Vector2(a), Vector2(b), include_target, heights)
				_check(actual == expected, "First blocker, target inclusion and precise endpoint height match")
	_check(cpp.find_first_blocker_grid(Vector2i.ZERO, Vector2i.ZERO, registry) == LOS.NO_BLOCKER_GRID, "Same-cell ray never self-occludes")
	var far_a := Vector2i(1000001, -1000001)
	var far_b := far_a + Vector2i(4, 0)
	var far_line: Array[Vector2i] = []
	cpp.call("_build_grid_line_into", far_a, far_b, far_line, registry)
	_check(far_line == HEX.line(far_a, far_b), "Unsupported native coordinate range falls back to exact GDScript line")
	if ClassDB.class_exists("NativeVisibilityKernel"):
		_check(int(FIX.audit(cpp).get("fallback_calls", 0)) > 0, "Out-of-range native input exercises a real fallback")
	native_calls += int(FIX.audit(cpp).get("native_calls", 0))
	registry.free()

func _test_wide_coordinates() -> void:
	var registry: Node = FIX.synthetic()
	var reader = FIX.los(true)
	var shifts: Array[Vector2i] = [Vector2i(65536, -65536), Vector2i(-65536, 65536), Vector2i(999980, -999980), Vector2i(-999980, 999980)]
	var offsets: Array[Vector2i] = [Vector2i(7, -4), Vector2i(4, 4), Vector2i(8, -4), Vector2i(0, 9), Vector2i(-9, 3), Vector2i(12, -6)]
	for shift: Vector2i in shifts:
		for offset: Vector2i in offsets:
			for reverse: bool in [false, true]:
				var source: Vector2i = shift + offset if reverse else shift
				var target: Vector2i = shift if reverse else shift + offset
				var before: int = int(FIX.audit(reader).get("native_calls", 0))
				var cells: Array[Vector2i] = []
				reader.call("_build_grid_line_into", source, target, cells, registry)
				_check(cells == HEX.line(source, target), "Wide-coordinate canonical rounding matches at %s -> %s" % [source, target])
				if ClassDB.class_exists("NativeVisibilityKernel"):
					_check(int(FIX.audit(reader).get("native_calls", 0)) == before + 1, "Supported wide-coordinate test really uses native kernel")
	if ClassDB.class_exists("NativeVisibilityKernel"):
		var kernel = ClassDB.instantiate("NativeVisibilityKernel")
		_check(kernel.call("build_hex_line", Vector2i.ZERO, Vector2i(65537, 0)).is_empty(), "Native step limit rejects oversized allocation without running huge GDS fallback")
		_check(kernel.call("build_hex_line", Vector2i(1000001, 0), Vector2i(1000002, 0)).is_empty(), "Native coordinate limit rejects unsupported domain")
	native_calls += int(FIX.audit(reader).get("native_calls", 0))
	registry.free()

func _test_live_reader_and_half_heights() -> void:
	var registry: Node = FIX.synthetic()
	var cpp = FIX.los(true)
	var a := Vector2i.ZERO
	var b := Vector2i(4, 0)
	for grid: Vector2i in HEX.line(a, b):
		var tile = registry.call("get_tile_at_grid", grid)
		tile.height_level = 0
		tile.blocks_los = false
		tile.object_height = 0
	var revision: int = registry.call("get_revision")
	_check(cpp.find_first_blocker_grid(a, b, registry) == LOS.NO_BLOCKER_GRID, "Initial open ray")
	var obstacle = registry.call("get_tile_at_grid", Vector2i(2, 0))
	obstacle.blocks_los = true
	obstacle.object_height = 2
	_check(registry.call("get_revision") == revision, "Fixture direct property write intentionally does not advance registry revision")
	_check(cpp.find_first_blocker_grid(a, b, registry) == Vector2i(2, 0), "Native path observes direct mutable tile change without revision")
	_check(cpp.find_first_blocker_grid(a, b, registry, Vector2(a), Vector2(b), false, Vector2(2.5, 2.5)) == LOS.NO_BLOCKER_GRID, "Half-level 2.5 remains above height2 blocker")
	_check(cpp.find_first_blocker_grid(a, b, registry, Vector2(a), Vector2(b), false, Vector2(2.0, 2.0)) == Vector2i(2, 0), "Height2 equality remains blocking")
	registry.call("set_runtime_tile_overrides", [{"grid_position": Vector2i(2, 0), "blocks_los_override": false}])
	_check(cpp.find_first_blocker_grid(a, b, registry) == LOS.NO_BLOCKER_GRID, "Live runtime override takes effect")
	registry.call("clear_runtime_tile_overrides")
	var unversioned := UnversionedReader.new()
	unversioned.source = registry
	_check(cpp.find_first_blocker_grid(a, b, unversioned) == Vector2i(2, 0), "Custom unversioned reader preserves current semantics")
	obstacle.blocks_los = false
	_check(cpp.find_first_blocker_grid(a, b, unversioned) == LOS.NO_BLOCKER_GRID, "Unversioned reader observes next direct mutation")
	var target = registry.call("get_tile_at_grid", b)
	target.blocks_los = true
	target.object_height = 3
	_check(cpp.find_first_blocker_grid(a, b, registry) == LOS.NO_BLOCKER_GRID, "Combat target tile is excluded")
	_check(cpp.find_first_blocker_grid(a, b, registry, Vector2(a), Vector2(b), true) == b, "Preview explicitly includes target tile")
	_check(cpp.find_first_blocker_grid(b, a, registry, Vector2(b), Vector2(a), true) == LOS.NO_BLOCKER_GRID, "Source is always excluded")
	_check(cpp.find_first_blocker_grid(a, b, null) == LOS.NO_BLOCKER_GRID, "Null reader keeps fallback contract")
	var other: Node = FIX.synthetic()
	_check(cpp.find_first_blocker_grid(a, b, other) == FIX.los(false).find_first_blocker_grid(a, b, other), "Registry replacement cannot reuse old terrain")
	native_calls += int(FIX.audit(cpp).get("native_calls", 0))
	unversioned.free()
	other.free()
	registry.free()

func _test_square_wall_fallback() -> void:
	var registry: Node = FIX.synthetic("square8")
	for tile in registry.call("get_all_tiles"):
		tile.blocks_los = false
		tile.height_level = 0
	var wall = registry.call("get_tile_at_grid", Vector2i(2, 1))
	wall.type_id = "wall_straight_ne"
	wall.blocks_los = true
	wall.object_height = 2
	var gd = FIX.los(false)
	var cpp = FIX.los(true)
	for ray: Array in [[Vector2i(1, 1), Vector2i(3, 1)], [Vector2i(2, 0), Vector2i(2, 2)]]:
		_check(cpp.find_first_blocker_grid(ray[0], ray[1], registry) == gd.find_first_blocker_grid(ray[0], ray[1], registry), "Square directional wall segment keeps GDScript result")
	_check(cpp.find_first_blocker_grid(Vector2i(1, 1), Vector2i(3, 1), registry) == Vector2i(2, 1), "Square wall across edge blocks")
	_check(cpp.find_first_blocker_grid(Vector2i(2, 0), Vector2i(2, 2), registry) == LOS.NO_BLOCKER_GRID, "Square same-side wall permits sight")
	_check(int(FIX.audit(cpp).get("native_calls", 0)) == 0, "Square walls remain on GDScript path")
	registry.free()

func _test_cache_contract() -> void:
	var registry: Node = FIX.synthetic()
	var caches: Array = []
	for enabled: bool in [false, true]:
		var cache = CACHE.new()
		cache.set("_los_system", FIX.los(enabled))
		caches.append(cache)
	var pairs: Array = FIX.pairs(registry, 32)
	for tick in range(3):
		for cache in caches: cache.begin_tick(tick + 1)
		for repeat in range(4):
			for pair: Array in pairs:
				var observer := {"grid": pair[0], "facing_dir": repeat % 6, "stand_height_steps2": tick}
				var target := {"grid": pair[1], "stand_height_steps2": tick + 1}
				var profile := {"range_hex": -1 if repeat < 3 else 1, "arc_degrees": 360.0 if repeat < 2 else 120.0}
				_check(caches[0].query_hex_visibility(observer, target, registry, profile) == caches[1].query_hex_visibility(observer, target, registry, profile), "Cached terrain and fresh range/facing remain identical")
		_check(caches[0].get_audit_snapshot() == caches[1].get_audit_snapshot(), "Existing cache hits/misses/counters match")
		registry.call("set_runtime_tile_overrides", [{"grid_position": Vector2i(2 + tick, 0), "blocks_los_override": tick % 2 == 0, "object_height_override": 3}])
	native_calls += int(FIX.audit(caches[1].get("_los_system")).get("native_calls", 0))
	for cache: Node in caches: cache.free()
	registry.free()
