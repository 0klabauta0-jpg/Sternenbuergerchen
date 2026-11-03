extends SceneTree

const GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const SETUP = preload("res://scripts/tests/mission_test_setup.gd")
const FOW = preload("res://scripts/core/fog_of_war_system.gd")
const LOS = preload("res://scripts/core/los_system.gd")
const TILE = preload("res://scripts/terrain/terrain_tile_data.gd")
const UNIT = preload("res://scripts/npc/test_unit.gd")

# Only observe resource enumeration and the visual boundary; calculations remain real.
class CountingRegistry:
	extends "res://scripts/terrain/terrain_registry.gd"
	var enumerations: int = 0
	func get_sorted_tiles() -> Array:
		enumerations += 1
		return super.get_sorted_tiles()
	func get_all_tiles() -> Array:
		enumerations += 1
		return super.get_all_tiles()

class VisualSink extends Node:
	var last_state: Dictionary = {}
	func set_fog_of_war_state(state: Dictionary) -> void:
		last_state = state.duplicate(true)

var passed: int = 0
var failed: int = 0

func _init() -> void:
	if not GUARD.require_isolated_user_data(): return
	call_deferred("_run")

func _run() -> void:
	for side in [128, 256]:
		var control := _large_case(side, false)
		var moving := _large_case(side, true)
		_check(int(moving.first_commit) == int(control.first_commit), "%d enemy movement retains initial scan progress" % side)
	_test_dynamic_targets_and_invalidation()
	_test_pending_inputs_change_before_normal_process()
	print("REVIEW7_FOW_RESULT %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)

func _fixture(side: int) -> Dictionary:
	var holder := Node.new()
	root.add_child(holder)
	var registry := CountingRegistry.new()
	holder.add_child(registry)
	registry.configure_iso_grid(Vector2.ZERO, 64.0, 32.0)
	for x in range(side):
		for y in range(side):
			registry.register_tile(TILE.new({"tile_id": "tile_%d_%d" % [x, y], "type_id": "ground_flat", "grid_position": Vector2i(x,y), "world_position": registry.grid_to_world(Vector2i(x,y)), "walkable": true}))
	var center := Vector2i(side / 2, side / 2)
	var observer = _unit(holder, "observer", "team_alpha", registry.grid_to_world(center))
	var enemies: Array = []
	var units: Array = [observer]
	for i in range(4):
		var enemy = _unit(holder, "enemy_%d" % i, "team_bravo", observer.position + Vector2(80.0 + 16.0 * i, 0.0))
		enemies.append(enemy)
		units.append(enemy)
	var sink := VisualSink.new()
	holder.add_child(sink)
	var fog = FOW.new()
	var setup = SETUP.new()
	setup.set("_is_initialized", true)
	setup.set("_fog_of_war_system", fog)
	setup.set("_fog_of_war_los_system", LOS.new())
	setup.set("_fog_terrain_registry", registry)
	setup.set("_fog_unit_nodes", units)
	setup.set("_fog_observer_unit_nodes", [observer])
	setup.set("_terrain_3d_view", sink)
	setup.fog_of_war_mode = "unexplored_blackout"
	setup.fog_of_war_sight_range_world = 160.0
	holder.add_child(setup)
	setup.set_process(false)
	return {"holder":holder, "registry":registry, "observer":observer, "enemies":enemies, "sink":sink, "fog":fog, "setup":setup}

func _large_case(side: int, moving: bool) -> Dictionary:
	var f := _fixture(side)
	var setup = f.setup
	# Match the reviewed workload's default sight and 512 tiles per slice.
	setup.fog_of_war_sight_range_world = 640.0
	setup.call("_sync_fog_of_war_visual_state", true)
	var first_commit := -1
	var safely_pending := true
	for frame in range(240):
		if moving:
			for enemy in f.enemies:
				enemy.position += Vector2(80.0 / 60.0, 0.0)
		setup.call("_process", 1.0 / 60.0)
		var revision := int(f.fog.build_team_state_snapshot("team_alpha").get("visibility_revision", 0))
		if first_commit == -1 and revision > 0: first_commit = frame
		if first_commit == -1:
			safely_pending = safely_pending and bool(f.sink.last_state.get("visibility_pending", false))
	_check(safely_pending, "Incomplete initial scan remains conservatively pending")
	_check(first_commit >= 0, "%d scan publishes within 240 frames (moving=%s)" % [side, moving])
	_check(int(f.fog.build_team_state_snapshot("team_alpha").get("visibility_revision", 0)) == 1, "Target motion creates no terrain revisions")
	_check(not bool(f.sink.last_state.get("visibility_pending", false)), "Completed scan clears pending visual")
	# A stationary observer's tile result is independent of target positions.
	var oracle = FOW.new()
	oracle.set_mode_for_team("team_alpha", "unexplored_blackout")
	oracle.update_tile_visibility_for_team("team_alpha", [f.observer], f.registry, LOS.new(), 640.0)
	_check(_visible_tiles(f.fog) == _visible_tiles(oracle), "Terrain result equals independent full-scan oracle")
	print("REVIEW7_FOW_WORKLOAD ", JSON.stringify({"side":side,"moving":moving,"frames":240,"first_commit":first_commit,"enumerations":f.registry.enumerations}))
	f.holder.free()
	return {"first_commit":first_commit}

func _test_dynamic_targets_and_invalidation() -> void:
	var f := _fixture(32)
	var setup = f.setup
	setup.call("_sync_fog_of_war_visual_state", true)
	_drain(f)
	_check(f.fog.is_visible("team_alpha", "enemy_0"), "Nearby enemy initially visible")
	var before_revision := int(f.fog.build_team_state_snapshot("team_alpha").visibility_revision)
	var before_enumerations: int = f.registry.enumerations
	f.enemies[0].position = f.observer.position + Vector2(500.0, 0.0)
	for i in range(8): setup.call("_process", 1.0 / 60.0)
	_check(not f.fog.is_visible("team_alpha", "enemy_0"), "Target moving out of LOS/range is hidden at normal cadence")
	_check(not PackedStringArray(Dictionary(f.sink.last_state.get("current_visibility", {})).get("visible_target_ids", [])).has("enemy_0"), "Visual consumer receives target removal")
	f.enemies[0].position = f.observer.position + Vector2(20.0, 0.0)
	for i in range(8): setup.call("_process", 1.0 / 60.0)
	_check(f.fog.is_visible("team_alpha", "enemy_0"), "Target returning to range becomes visible")
	_check(int(f.fog.build_team_state_snapshot("team_alpha").visibility_revision) == before_revision, "Target-only refresh does not publish new terrain revision")
	_check(f.registry.enumerations == before_enumerations, "Target-only refresh never enumerates terrain")
	# An observer moving away and back while work is pending must not publish the away state.
	var origin: Vector2 = f.observer.position
	f.observer.position += Vector2(128.0, 0.0)
	setup.fog_of_war_work_budget_tiles = 16
	setup.call("_sync_fog_of_war_visual_state", false)
	_check(not String(setup.get("_fog_requested_runtime_signature")).is_empty(), "Observer movement creates pending work")
	f.observer.position = origin
	setup.call("_sync_fog_of_war_visual_state", false)
	_settle_latest(f)
	var oracle = FOW.new()
	oracle.set_mode_for_team("team_alpha", "unexplored_blackout")
	oracle.update_tile_visibility_for_team("team_alpha", [f.observer], f.registry, LOS.new(), 160.0)
	_check(_visible_tiles(f.fog) == _visible_tiles(oracle), "Returning observer does not publish obsolete pending position")
	var sig: String = setup.call("_build_fog_runtime_signature", "unexplored_blackout")
	setup.fog_of_war_sight_range_world = 80.0
	_check(String(setup.call("_build_fog_runtime_signature", "unexplored_blackout")) != sig, "Base sight range invalidates terrain work")
	setup.call("_sync_fog_of_war_visual_state", false)
	_drain(f)
	oracle.update_tile_visibility_for_team("team_alpha", [f.observer], f.registry, LOS.new(), 80.0)
	_check(_visible_tiles(f.fog) == _visible_tiles(oracle), "Changed sight matches full-scan oracle")
	sig = setup.call("_build_fog_runtime_signature", "unexplored_blackout")
	f.observer.get_vital_status().state = "down"
	_check(String(setup.call("_build_fog_runtime_signature", "unexplored_blackout")) != sig, "Downed observer changes terrain visibility input")
	setup.call("_sync_fog_of_war_visual_state", false)
	_drain(f)
	_check(_visible_tiles(f.fog).is_empty(), "Downed observer reveals no terrain")
	f.observer.get_vital_status().state = "fit"
	f.observer.visible = false
	setup.call("_sync_fog_of_war_visual_state", false)
	_drain(f)
	_check(_visible_tiles(f.fog).is_empty(), "Hidden observer reveals no terrain")
	f.observer.visible = true
	setup.call("_sync_fog_of_war_visual_state", false)
	_drain(f)
	_check(not _visible_tiles(f.fog).is_empty(), "Observer reactivation restores visibility")
	sig = setup.call("_build_fog_runtime_signature", "unexplored_blackout")
	var tile = f.registry.get_tile_at_grid(Vector2i(17, 16))
	tile.blocks_los = true
	tile.object_height = 3
	f.registry.register_tile(tile)
	_check(String(setup.call("_build_fog_runtime_signature", "unexplored_blackout")) != sig, "Terrain revision invalidates visibility input")
	setup.call("_sync_fog_of_war_visual_state", false)
	_drain(f)
	oracle.update_tile_visibility_for_team("team_alpha", [f.observer], f.registry, LOS.new(), 80.0)
	_check(_visible_tiles(f.fog) == _visible_tiles(oracle), "Terrain change matches LOS oracle")
	setup.set_fog_of_war_mode("off")
	_check(String(f.sink.last_state.get("mode", "")) == "off", "Mode off publishes immediately")
	setup.set_fog_of_war_mode("unexplored_blackout")
	_drain(f)
	_check(_visible_tiles(f.fog) == _visible_tiles(oracle), "Mode reenable restores correct terrain")
	f.holder.free()

func _test_pending_inputs_change_before_normal_process() -> void:
	for change in ["down", "position", "subtile_position", "sight", "terrain"]:
		var f := _fixture(32)
		var setup = f.setup
		setup.call("_sync_fog_of_war_visual_state", true)
		var requested_sample: String = setup.get("_fog_requested_runtime_signature")
		_check(int(f.fog.build_team_state_snapshot("team_alpha").visibility_revision) == 0, "%s fixture begins with half a full scan pending" % change)
		match change:
			"down": f.observer.get_vital_status().state = "down"
			"position": f.observer.position += Vector2(128.0, 0.0)
			"subtile_position": f.observer.position += Vector2(8.0, 0.0)
			"sight": setup.fog_of_war_sight_range_world = 80.0
			"terrain":
				var tile = f.registry.get_tile_at_grid(Vector2i(17, 16))
				tile.blocks_los = true
				tile.object_height = 3
				f.registry.register_tile(tile)
		# Normal frame, before the 100-ms refresh is due. Do not invoke _sync manually.
		setup.call("_process", 1.0 / 60.0)
		if change in ["position", "subtile_position"]:
			_check(String(setup.get("_fog_runtime_signature")) == requested_sample, "%s completed atomic sample retains its original request identity" % change)
			_check(String(setup.get("_fog_runtime_signature")) != String(setup.call("_build_fog_runtime_signature", "unexplored_blackout")), "%s sampled result never claims the newer observer position" % change)
		else:
			_check(int(f.fog.build_team_state_snapshot("team_alpha").visibility_revision) == 0, "%s hard input change cannot publish the obsolete pending scan" % change)
			_check(bool(f.sink.last_state.get("visibility_pending", false)), "%s visual stays conservative until replacement completes" % change)
		_settle_latest(f)
		var oracle = FOW.new()
		oracle.set_mode_for_team("team_alpha", "unexplored_blackout")
		oracle.update_tile_visibility_for_team("team_alpha", [f.observer], f.registry, LOS.new(), setup.fog_of_war_sight_range_world)
		_check(_visible_tiles(f.fog) == _visible_tiles(oracle), "%s replacement matches current-input oracle" % change)
		f.holder.free()

func _settle_latest(f: Dictionary) -> void:
	for i in range(2048):
		f.setup.call("_process", 1.0 / 60.0)
		if String(f.setup.get("_fog_requested_runtime_signature")).is_empty() and String(f.setup.get("_fog_runtime_signature")) == String(f.setup.call("_build_fog_runtime_signature", "unexplored_blackout")):
			return
	_check(false, "Latest observer sample finishes within bounded normal frames")

func _drain(f: Dictionary) -> void:
	for i in range(2048):
		if String(f.setup.get("_fog_requested_runtime_signature")).is_empty(): return
		f.setup.call("_advance_fog_of_war_visibility_work")
	_check(false, "Pending work finishes within bounded slices")

func _visible_tiles(fog) -> PackedStringArray:
	return PackedStringArray(Dictionary(fog.build_team_state_snapshot("team_alpha").get("terrain_knowledge", {})).get("visible_tile_ids", []))

func _unit(holder: Node, id: String, team: String, position: Vector2):
	var unit = UNIT.new()
	unit.unit_id = id
	unit.team_id = team
	holder.add_child(unit)
	unit.set_process(false)
	unit.position = position
	return unit

func _check(condition: bool, message: String) -> void:
	if condition: passed += 1
	else:
		failed += 1
		print("FAIL: ", message)
