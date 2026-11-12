extends SceneTree
const GROUND=preload("res://scripts/core/hex_ground_runtime.gd")
const REGISTRY=preload("res://scripts/terrain/terrain_registry.gd")
const TILE=preload("res://scripts/terrain/terrain_tile_data.gd")
const PLANNER=preload("res://scripts/tactical/bottleneck_reservation_resolver.gd")
var passed:=0
var failed:=0
func check(ok:bool,label:String)->void:
	if ok:passed+=1
	else:failed+=1
	print("PASS " if ok else "FAIL ",label)
func json_copy(value:Dictionary)->Dictionary:return JSON.parse_string(JSON.stringify(value))
func segment(id:String,a:Vector2i,b:Vector2i,start:int,duration:int)->Dictionary:
	return {"unit_id":id,"command_id":"move-"+id,"from_grid":a,"to_grid":b,"start_tick":start,"duration_ticks":duration,"handoff_tick":start+ceili(duration/2.0)}
func _initialize()->void:
	var ground=GROUND.new()
	check(ground.has_method("export_state") and ground.has_method("restore_state"),"Ground exposes canonical save APIs")
	if failed:finish();return
	var terrain=REGISTRY.new();terrain.configure_iso_grid(Vector2.ZERO,64,32,"hex_axial_v1")
	for q in range(6):
		for r in range(4):terrain.register_tile(TILE.new({"tile_id":"%d_%d"%[q,r],"grid_position":Vector2i(q,r),"walkable":true}))
	ground.configure(terrain,"save-fixture",0)
	var placements:Array[Dictionary]=[{"unit_id":"a","grid":Vector2i(1,1),"facing_dir":4},{"unit_id":"b","grid":Vector2i(4,2),"facing_dir":2}]
	assert(ground.admit_units(placements).ok)
	var snapshot:Dictionary=ground.build_planning_snapshot()
	var plan:Dictionary=PLANNER.build_hex_plan([{"unit_id":"a","command_id":"move-a","priority":0,"path_grid_points":[Vector2i(1,1),Vector2i(2,1),Vector2i(3,1)],"duration_ticks_by_step":[6,6]}],snapshot,terrain)
	assert(plan.ok and plan.accepted_steps.size()==2 and ground.commit_plan(plan,snapshot.revision).ok)
	ground.advance_tick(2)
	var saved:Dictionary=ground.export_state()
	var restored=GROUND.new();restored.configure(terrain,"save-fixture",2)
	var result:Dictionary=restored.restore_state(json_copy(saved))
	check(result.get("ok",false) and restored.read_unit("a").grid==Vector2i(1,1) and restored.read_unit("a").facing_dir==4 and restored.get_motion_projection("a",0.0)==ground.get_motion_projection("a",0.0),"JSON roundtrip preserves facing and prehandoff segment progress")
	ground.advance_tick(4);restored.advance_tick(4)
	check(restored.read_unit("a").grid==Vector2i(2,1) and restored.get_motion_projection("a",0.0)==ground.get_motion_projection("a",0.0),"Rebuilt commitments perform identical handoff")
	var post:Dictionary=ground.export_state()
	check(restored.restore_state(json_copy(post)).get("ok",false) and restored.get_motion_projection("a",0.0)==ground.get_motion_projection("a",0.0),"Posthandoff active segment restores")
	var before:Dictionary=restored.build_planning_snapshot()
	var bad:=json_copy(post);bad.units[1].grid=bad.units[0].grid
	check(not restored.restore_state(bad).get("ok",false) and restored.build_planning_snapshot()==before,"Duplicate occupancy rejects atomically")
	bad=json_copy(post);bad.schema="hex_ground_v99"
	check(not restored.restore_state(bad).get("ok",false) and restored.build_planning_snapshot()==before,"Unknown schema rejects without mutation")
	bad=json_copy(post);bad.map_id="other"
	check(not restored.restore_state(bad).get("ok",false) and restored.build_planning_snapshot()==before,"Foreign map rejects without mutation")
	bad=json_copy(post);bad.active_segments[0].duration_ticks=0
	check(not restored.restore_state(bad).get("ok",false) and restored.build_planning_snapshot()==before,"Invalid segment times reject without mutation")
	bad=json_copy(post);bad.units[1].grid=[3,1]
	check(restored.restore_state(bad).get("reason")=="ground_save_no_passing_space" and restored.build_planning_snapshot()==before,"Future segment cannot claim stationary occupant after restore")
	var detached:Dictionary=restored.export_state();detached.units[0].grid=[99,99]
	check(restored.read_unit("a").grid==Vector2i(2,1),"Export contains detached primitive values")
	var input:=json_copy(post);assert(restored.restore_state(input).ok);input.units[0].facing_dir=0
	check(restored.read_unit("a").facing_dir==4,"Restored owner does not alias input dictionaries")
	assert(ground.stop_units(PackedStringArray(["a"]),"fixture-stop").ok)
	var centered:Dictionary=ground.export_state()
	check(restored.restore_state(json_copy(centered)).get("ok",false) and restored.read_unit("a").movement_state.phase=="centering" and restored.get_motion_projection("a",0.0)==ground.get_motion_projection("a",0.0),"Centering phase survives JSON roundtrip")
	ground.advance_tick(6);restored.advance_tick(6)
	check(restored.get_motion_projection("a",0.0)==ground.get_motion_projection("a",0.0) and not restored.has_motion_commitments("a"),"Restored centering finishes at same deadline")
	var reserved:Array[Dictionary]=[{"unit_id":"pending","grid":Vector2i(0,2)}]
	assert(ground.reserve_admission_group("ticket",reserved,ground.build_planning_snapshot().revision).ok)
	check(ground.export_state().get("reason")=="ground_save_pending_admission","Pending admission is explicitly unsupported")
	assert(ground.cancel_admission_group("ticket","fixture").ok)
	var corridor=REGISTRY.new();corridor.configure_iso_grid(Vector2.ZERO,64,32,"hex_axial_v1")
	for q in range(6):corridor.register_tile(TILE.new({"tile_id":"line%d"%q,"grid_position":Vector2i(q,0),"walkable":true}))
	var passage=GROUND.new();passage.configure(corridor,"passage-fixture",0)
	var admitted:Array[Dictionary]=[{"unit_id":"c","grid":Vector2i(1,0)}];assert(passage.admit_units(admitted).ok)
	var passage_plan:Dictionary=PLANNER.build_hex_plan([{"unit_id":"c","command_id":"passage","priority":0,"path_grid_points":[Vector2i(1,0),Vector2i(2,0)],"duration_ticks_by_step":[6]}],passage.build_planning_snapshot(),corridor)
	assert(passage_plan.ok and not passage_plan.corridor_grants.is_empty() and passage.commit_plan(passage_plan,passage_plan.expected_revision).ok)
	check(passage.export_state().get("reason")=="ground_save_corridor_commitments_unsupported","Active passage promise never silently disappears")
	var empty_passage=GROUND.new();empty_passage.configure(corridor,"passage-fixture",2)
	bad=json_copy(saved);bad.map_id="passage-fixture";bad.terrain_revision=corridor.get_revision()
	bad.units[0].grid=[1,0];bad.units[1].grid=[4,0]
	for value in bad.active_segments:value.from_grid[1]=0;value.to_grid[1]=0
	check(empty_passage.restore_state(bad).get("reason")=="ground_save_corridor_grant_missing" and empty_passage.get_unit_ids().is_empty(),"Restore rejects corridor segments without lossless passage schema")
	var dynamic=GROUND.new();dynamic.configure(terrain,"save-fixture",2);assert(dynamic.restore_state(json_copy(saved)).ok)
	var stale_receiver=GROUND.new();stale_receiver.configure(terrain,"save-fixture",2);assert(stale_receiver.restore_state(json_copy(saved)).ok)
	for tile in terrain.get_all_tiles():tile.height_level=1
	terrain.notify_tile_data_changed()
	# Warm only the derived bounded topology cache; Ground has not advanced yet.
	terrain.get_hex_corridor_topology([Vector2i(1,1),Vector2i(2,1),Vector2i(3,1)],64)
	var stale_projection:Dictionary=dynamic.get_motion_projection("a",0.0)
	check(is_zero_approx(stale_projection.stand_height_logical) and dynamic.export_state().get("reason")=="ground_save_terrain_revalidation_pending" and dynamic.get_motion_projection("a",0.0)==stale_projection,"Terrain change before Ground tick blocks export instead of changing saved height")
	bad=json_copy(saved);bad.terrain_revision=terrain.get_revision()
	var stale_before:Dictionary=stale_receiver.build_planning_snapshot()
	check(stale_receiver.restore_state(bad).get("reason")=="ground_save_terrain_revalidation_pending" and stale_receiver.build_planning_snapshot()==stale_before and stale_receiver.get_motion_projection("a",0.0)==stale_projection,"Terrain-unrevalidated live receiver rejects restore before candidate mutation")
	dynamic.advance_tick(3)
	var valid_dynamic:Dictionary=dynamic.export_state()
	var dynamic_copy=GROUND.new();dynamic_copy.configure(terrain,"save-fixture",3)
	check(valid_dynamic.get("schema")=="hex_ground_v1" and dynamic_copy.restore_state(json_copy(valid_dynamic)).get("ok",false) and is_equal_approx(dynamic.get_motion_projection("a",0.0).stand_height_logical,1.0) and dynamic_copy.get_motion_projection("a",0.0)==dynamic.get_motion_projection("a",0.0),"Existing Ground revalidation restores legal raised plateau roundtrip")
	corridor.free();terrain.free();finish()
func finish()->void:
	print("HEX_GROUND_SAVE_STATE passed=",passed," failed=",failed)
	quit(0 if failed==0 else 1)
