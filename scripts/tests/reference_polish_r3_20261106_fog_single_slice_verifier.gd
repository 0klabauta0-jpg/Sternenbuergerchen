extends SceneTree
## Controlled scheduling fixture with real Fog/LOS/Registry components.
## Synthetic observer positions and process deltas are not physical play proof.
const REGISTRY: GDScript = preload("res://scripts/terrain/terrain_registry.gd")
const TILE: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")
const LOS: GDScript = preload("res://scripts/core/los_system.gd")
const FOG: GDScript = preload("res://scripts/core/fog_of_war_system.gd")
const TEAM := "team_alpha"

class CountingFog extends "res://scripts/core/fog_of_war_system.gd":
	var slice_calls := 0
	var budgets: Array = []
	var receipts: Array = []
	func process_pending_tile_visibility_work(team_id: String, work_budget_tiles: int = DEFAULT_WORK_BUDGET_TILES) -> Dictionary:
		slice_calls += 1
		budgets.append(work_budget_tiles)
		var result := super.process_pending_tile_visibility_work(team_id, work_budget_tiles)
		receipts.append(result.duplicate(true))
		return result
	func reset_counts() -> void:
		slice_calls = 0
		budgets.clear()
		receipts.clear()

class Observer extends Node2D:
	var unit_id := "synthetic_observer"
	var team := "team_alpha"
	func get_unit_id() -> String:
		return unit_id
	func get_team_id() -> String:
		return team
	func get_vital_state() -> String:
		return "fit"
	func get_sight_range_factor() -> float:
		return 1.0

class ViewReceipt extends Node:
	var snapshots: Array = []
	func set_fog_of_war_state(snapshot: Dictionary) -> void:
		snapshots.append(snapshot.duplicate(true))

class SetupProbe extends "res://scripts/tests/mission_test_setup.gd":
	func _ready() -> void:
		set_process(false)
	func bind_fixture(fog, registry: Node, view: Node, observer: Node2D, target: Node2D, los) -> void:
		_fog_of_war_system = fog
		_fog_terrain_registry = registry
		_terrain_3d_view = view
		_fog_of_war_los_system = los
		_fog_observer_unit_nodes = [observer]
		_fog_unit_nodes = [observer, target]
		fog_of_war_mode = "unexplored_blackout"
		fog_viewer_team_id = "team_alpha"
		fog_of_war_sight_range_world = 96.0
		fog_of_war_work_budget_tiles = 512

var _passed := 0
var _failed := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var fixture := Node.new()
	root.add_child(fixture)
	var registry: Node = REGISTRY.new()
	fixture.add_child(registry)
	registry.call("configure_iso_grid", Vector2.ZERO, 16.0, 8.0)
	for x in range(16):
		for y in range(16):
			var grid := Vector2i(x, y)
			registry.call("register_tile", TILE.call("from_dict", {"tile_id": "tile_%d_%d" % [x, y], "type_id": "ground_flat", "grid_position": grid, "world_position": registry.call("grid_to_world", grid), "walkable": true, "blocks_los": false, "height_level": 0, "object_height": 0, "cover_value": 0, "surface_type": "ground", "edge_type": "none"}))
	var observer := Observer.new()
	fixture.add_child(observer)
	observer.position = registry.call("grid_to_world", Vector2i(6, 6))
	var target := Observer.new()
	target.unit_id = "synthetic_enemy"
	target.team = "team_bravo"
	fixture.add_child(target)
	target.position = registry.call("grid_to_world", Vector2i(15, 15))
	var fog := CountingFog.new()
	var los = LOS.new()
	var view := ViewReceipt.new()
	fixture.add_child(view)
	var setup := SetupProbe.new()
	fixture.add_child(setup)
	setup.bind_fixture(fog, registry, view, observer, target, los)
	var oracle = FOG.new()
	oracle.call("set_mode_for_team", TEAM, "unexplored_blackout")
	oracle.call("update_tile_visibility_for_team", TEAM, [observer], registry, los, 96.0)
	fog.reset_counts()
	setup.call("_sync_fog_of_war_visual_state", true)
	_check(fog.slice_calls == 1, "Explicit Force preserves its immediate real service slice")
	_check(String(setup.get("_fog_requested_runtime_signature")).is_empty(), "Small authored terrain seed completes normally")
	_check(_terrain_state(fog) == _terrain_state(oracle), "Initial publication matches the full-scan oracle")
	_check(not fog.is_visible(TEAM, target.unit_id), "Dynamic enemy begins outside current LOS")
	observer.position = registry.call("grid_to_world", Vector2i(7, 6))
	oracle.call("update_tile_visibility_for_team", TEAM, [observer], registry, los, 96.0)
	var at_seven := _terrain_state(oracle)
	setup.call("_sync_fog_of_war_visual_state", false)
	_check(not String(setup.get("_fog_requested_runtime_signature")).is_empty(), "Movement queues a real incremental request")
	_check(not bool(Dictionary(fog.receipts.back()).get("completed", true)), "Candidate collection remains an incomplete atomic sample")
	observer.position = registry.call("grid_to_world", Vector2i(8, 6))
	oracle.call("update_tile_visibility_for_team", TEAM, [observer], registry, los, 96.0)
	var at_eight := _terrain_state(oracle)
	target.position = observer.position + Vector2(16.0, 0.0)
	fog.reset_counts()
	setup.call("_process", 0.1)
	_check(fog.slice_calls <= 1, "One process pass cannot complete old terrain and execute a second new terrain slice")
	_check(_terrain_state(fog) == at_seven, "The frozen seven-position sample commits atomically before the next request")
	_check(not String(setup.get("_fog_requested_runtime_signature")).is_empty(), "Newest moving observer state is queued instead of discarded")
	_check(fog.is_visible(TEAM, target.unit_id), "Current dynamic-target LOS remains independent of pending terrain")
	var continuation_frames := 0
	while not String(setup.get("_fog_requested_runtime_signature")).is_empty() and continuation_frames < 12:
		fog.reset_counts()
		setup.call("_process", 1.0 / 60.0)
		_check(fog.slice_calls <= 1, "Each following process pass preserves the one-slice bound")
		for budget in fog.budgets:
			_check(int(budget) == 512, "Single-slice scheduling preserves the original 512-tile work budget")
		continuation_frames += 1
	_check(String(setup.get("_fog_requested_runtime_signature")).is_empty(), "Queued moving-state terrain completes without starvation")
	_check(_terrain_state(fog) == at_eight, "Final visible/explored sets equal the complete full-scan sequence")
	_check(100.0 + float(continuation_frames) * (1000.0 / 60.0) <= 350.0, "Synthetic continuation stays within the existing estimated 350ms staleness bound")
	# A genuine registry revision invalidates an unfinished positional sample.
	observer.position = registry.call("grid_to_world", Vector2i(9, 6))
	setup.call("_sync_fog_of_war_visual_state", false)
	registry.call("set_runtime_tile_overrides", [{"grid_position": Vector2i(10, 6), "walkable_override": false, "blocks_los_override": true, "object_height_override": 3, "cover_value_override": 0}])
	fog.reset_counts()
	setup.call("_process", 0.1)
	_check(fog.slice_calls <= 1, "Static invalidation also processes at most one real slice in a process pass")
	for _index in range(12):
		if String(setup.get("_fog_requested_runtime_signature")).is_empty():
			break
		fog.reset_counts()
		setup.call("_process", 1.0 / 60.0)
		_check(fog.slice_calls <= 1, "Rebuilt static-state work retains the same slice bound")
	oracle.call("update_tile_visibility_for_team", TEAM, [observer], registry, los, 96.0)
	_check(String(setup.get("_fog_requested_runtime_signature")).is_empty() and _terrain_state(fog) == _terrain_state(oracle), "Changed terrain rejects stale work and converges to the real LOS oracle")
	fog.reset_counts()
	setup.call("_sync_fog_of_war_visual_state", true)
	_check(fog.slice_calls == 1, "Explicit Force remains immediate after normal scheduling and invalidation")
	_check(not view.snapshots.is_empty(), "Existing renderer consumer continues receiving actual service snapshots")
	print("R3_FOG_SLICE_FACTS " + JSON.stringify({"continuation_frames": continuation_frames, "work_budget_tiles": setup.fog_of_war_work_budget_tiles, "dynamic_enemy_visible": fog.is_visible(TEAM, target.unit_id), "synthetic_process_delta": true, "physical_play_proof": false}))
	fixture.queue_free()
	await process_frame
	await process_frame
	print("R3_FOG_SINGLE_SLICE: %d passed, %d failed" % [_passed, _failed])
	if _failed == 0:
		print("R3_FOG_SINGLE_SLICE_PASS")
	quit(1 if _failed > 0 else 0)


func _terrain_state(fog) -> Dictionary:
	var snapshot: Dictionary = fog.call("build_team_state_snapshot", TEAM)
	var visible := Array(snapshot.get("visible_tile_ids", []))
	var explored := Array(snapshot.get("explored_tile_ids", []))
	visible.sort()
	explored.sort()
	return {"visible": visible, "explored": explored}


func _check(ok: bool, message: String) -> void:
	if ok:
		_passed += 1
		print("PASS: ", message)
	else:
		_failed += 1
		print("FAIL: ", message)
