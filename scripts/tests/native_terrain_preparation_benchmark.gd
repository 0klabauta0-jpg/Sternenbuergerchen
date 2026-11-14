extends SceneTree
## Whole adapter preparation, with a frozen Main reference and exact packed parity.
const NAV = preload("res://scripts/terrain/native_navigation.gd")
const BASE = preload("res://scripts/tests/native_terrain_preparation_reference.gd")
const FIX = preload("res://scripts/tests/native_navigation_main_fixtures.gd")
const IO = preload("res://scripts/tests/native_navigation_prototype_fixtures.gd")
var failures: Array = []
var rows: Array = []

class CaptureKernel:
	extends RefCounted
	var inner: Object
	var snapshot: Dictionary = {}
	var load_count := 0
	func _init(kernel: Object) -> void: inner = kernel
	func load_terrain(value: Dictionary) -> bool:
		snapshot = value
		load_count += 1
		return inner.call("load_terrain", value)
	func begin_query(value: Dictionary) -> bool: return inner.call("begin_query", value)
	func get_query_debug() -> Dictionary: return inner.call("get_query_debug")
	func load_snapshot(value: Dictionary) -> bool: return inner.call("load_snapshot", value)

func _init() -> void: call_deferred("_run")

func _run() -> void:
	if not ClassDB.class_exists("NativeNavigationKernel"):
		push_error("Terrain benchmark requires native navigation DLL")
		quit(1)
		return
	var sample_count: int = clampi(int(IO.argument("--samples", "6")), 1, 20)
	var expect_builder: bool = ClassDB.class_exists("NativeTerrainBuilder")
	for name in ["ramps", "gm01"]:
		var fixture: Dictionary = FIX.real_map() if name == "gm01" else FIX.synthetic()
		var registry = fixture.terrain
		var changed: Vector2i = _walkable_cell(registry)
		for sample in range(sample_count):
			registry.clear_runtime_tile_overrides()
			var adapters: Dictionary = {"reference": BASE.new(), "candidate": NAV.new()}
			for adapter in adapters.values(): adapter._kernel = CaptureKernel.new(adapter._kernel)
			for phase in ["cold", "reused", "revision_closed", "revision_reopened"]:
				if phase == "revision_closed":
					registry.set_runtime_tile_overrides([{"grid_position": changed, "walkable_override": false, "blocks_los_override": true, "object_height_override": 3}])
				elif phase == "revision_reopened": registry.clear_runtime_tile_overrides()
				var outcomes: Dictionary = {}
				for backend in (["reference", "candidate"] if sample % 2 == 0 else ["candidate", "reference"]):
					var adapter = adapters[backend]
					var revision: int = registry.get_revision()
					var start: int = Time.get_ticks_usec()
					var accepted: bool = adapter.prepare(registry)
					var elapsed: int = Time.get_ticks_usec() - start
					var captured: Dictionary = adapter._kernel.snapshot
					outcomes[backend] = {"accepted": accepted, "total_usec": elapsed, "snapshot": captured,
						"sha256": var_to_bytes(captured).hex_encode().sha256_text(), "debug": adapter.get_debug_snapshot(),
						"revision_unchanged": registry.get_revision() == revision, "load_count": adapter._kernel.load_count,
						"phases": adapter.phases.duplicate() if backend == "reference" else {}}
				var original: Dictionary = outcomes.reference
				var current: Dictionary = outcomes.candidate
				var expected_builds: int = 1 if phase in ["cold", "reused"] else (2 if phase == "revision_closed" else 3)
				var same: bool = original.snapshot == current.snapshot and original.sha256 == current.sha256
				var valid: bool = same and original.accepted and current.accepted and original.revision_unchanged and current.revision_unchanged and original.load_count == expected_builds and current.load_count == expected_builds
				var actual_builder: String = String(current.debug.get("terrain_builder", "gdscript"))
				var builder_proven: bool = not expect_builder or actual_builder == ("reused" if phase == "reused" else "native")
				valid = valid and builder_proven
				if not valid: failures.append("%s/%d/%s parity or lifecycle failed" % [name, sample, phase])
				rows.append({"fixture": name, "sample": sample, "phase": phase, "exact_packed_parity": same,
					"reference_usec": original.total_usec, "candidate_usec": current.total_usec,
					"reference_phases": original.phases if phase != "reused" else {}, "candidate_debug": current.debug,
					"snapshot_sha256": current.sha256, "tile_count": registry.get_tile_count(),
					"edge_count": current.snapshot.get("neighbors", PackedInt32Array()).size(), "builder_proven": builder_proven, "valid": valid})
			print("TERRAIN_PREPARATION_PAIR ", name, " ", sample, " exact=", failures.is_empty())
		registry.free()
	var result := {"schema": "native_terrain_preparation.v1", "passed": failures.is_empty(), "failures": failures,
		"reference_body_sha256": BASE.BASE_BODY_SHA256, "rows": rows,
		"context": {"engine": Engine.get_version_info(), "cpu": OS.get_processor_name(), "os": OS.get_name(),
			"renderer": "headless", "gpu_timing": "unavailable", "samples_per_fixture_phase": sample_count,
			"metric": "Whole NativeNavigation.prepare call with identical capture proxy; current Main reference only adds three phase timers. Snapshot equality/hash outside timing. Cold means adapter-cold within running process. Registry/map import excluded equally. Revision changes include full preparation, reused calls must avoid load_terrain.",
			"scope": "GM01 real map importer plus explicit-ramp fixture, no rendering/FPS claim"}}
	if not IO.write_json(IO.argument("--output", "user://native_terrain_preparation.json"), result): failures.append("Evidence write failed")
	print("NATIVE_TERRAIN_PREPARATION rows=", rows.size(), " failures=", failures.size())
	quit(0 if failures.is_empty() else 1)

func _walkable_cell(registry) -> Vector2i:
	for tile in registry.get_all_tiles():
		if registry.is_walkable(tile.grid_position): return tile.grid_position
	return Vector2i.ZERO
