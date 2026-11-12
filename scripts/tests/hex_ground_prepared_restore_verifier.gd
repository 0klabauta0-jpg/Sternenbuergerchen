extends SceneTree
const GROUND=preload("res://scripts/core/hex_ground_runtime.gd")
const REGISTRY=preload("res://scripts/terrain/terrain_registry.gd")
const TILE=preload("res://scripts/terrain/terrain_tile_data.gd")
var passed:=0
var failed:=0
func check(value:bool,label:String)->void:
	if value:passed+=1
	else:failed+=1
	print("PASS " if value else "FAIL ",label)
func _initialize()->void:
	var terrain=REGISTRY.new()
	terrain.configure_iso_grid(Vector2.ZERO,64,32,"hex_axial_v1")
	for q in range(4):
		for r in range(3):terrain.register_tile(TILE.new({"tile_id":"%d_%d"%[q,r],"grid_position":Vector2i(q,r)}))
	var live=GROUND.new();live.configure(terrain,"prepared",0)
	var placements:Array[Dictionary]=[{"unit_id":"a","grid":Vector2i(1,1),"facing_dir":2}]
	assert(live.admit_units(placements).ok)
	var saved:Dictionary=live.export_state()
	var target_state:Dictionary=saved.duplicate(true);target_state.units[0].facing_dir=4
	var before:Dictionary=live.build_planning_snapshot()
	var prepared:Dictionary=live.prepare_restore_state(target_state)
	check(prepared.ok and live.build_planning_snapshot()==before,"Prepare validates detached target without live writes")
	if not prepared.ok:terrain.free();finish();return
	var handle:RefCounted=prepared.prepared
	var target:RefCounted=live.get_prepared_restore_ground(handle)
	check(target!=live and target.read_unit("a").facing_dir==4 and live.read_unit("a").facing_dir==2,"Target Ground is detached and exposes actual restored values")
	target_state.units[0].facing_dir=0
	check(live.validate_prepared_restore(handle).ok and target.read_unit("a").facing_dir==4,"Mutating caller save dictionary cannot alter preparation")
	var result:Dictionary=live.publish_prepared_restore(handle)
	check(result.ok and live.read_unit("a").facing_dir==4 and live.get_instance_id()!=target.get_instance_id(),"Public publish updates original owner after validation")
	assert(target.commit_facing("a",1))
	check(live.read_unit("a").facing_dir==4,"Retained target Ground cannot mutate published live values")
	before=live.build_planning_snapshot()
	check(not live.publish_prepared_restore(handle).ok and live.build_planning_snapshot()==before,"Consumed handle cannot publish twice")
	prepared=live.prepare_restore_state(saved);assert(prepared.ok)
	var foreign=GROUND.new();foreign.configure(terrain,"prepared",0)
	check(not foreign.publish_prepared_restore(prepared.prepared).ok and not live.validate_prepared_restore(RefCounted.new()).ok,"Foreign owners and forged handles fail closed")
	assert(live.commit_facing("a",3))
	before=live.build_planning_snapshot()
	check(not live.publish_prepared_restore(prepared.prepared).ok and live.build_planning_snapshot()==before,"Live revision race rejects without partial write")
	prepared=live.prepare_restore_state(saved);assert(prepared.ok)
	live.advance_tick(1)
	check(not live.validate_prepared_restore(prepared.prepared).ok,"Live tick race invalidates preparation")
	prepared=live.prepare_restore_state(saved);assert(prepared.ok)
	target=live.get_prepared_restore_ground(prepared.prepared);assert(target.commit_facing("a",5))
	check(not live.publish_prepared_restore(prepared.prepared).ok,"Mutation of borrowed target Ground invalidates preparation")
	prepared=live.prepare_restore_state(saved);assert(prepared.ok)
	live.configure(terrain,"prepared",1)
	check(not live.validate_prepared_restore(prepared.prepared).ok,"Same-object same-map reconfigure invalidates old handles")
	prepared=live.prepare_restore_state(saved);assert(prepared.ok)
	terrain.notify_tile_data_changed()
	check(not live.publish_prepared_restore(prepared.prepared).ok and live.get_unit_ids().is_empty(),"Terrain revision race rejects before publication")
	live.configure(terrain,"prepared",1)
	var invalid:Dictionary=saved.duplicate(true);invalid.terrain_revision=terrain.get_revision();invalid.units.append(invalid.units[0].duplicate(true))
	before=live.build_planning_snapshot()
	check(not live.prepare_restore_state(invalid).ok and live.build_planning_snapshot()==before,"Existing save validator rejects duplicate cell/identity atomically")
	var fresh:Dictionary=saved.duplicate(true);fresh.terrain_revision=terrain.get_revision()
	prepared=live.prepare_restore_state(fresh);assert(prepared.ok)
	var validation:Dictionary=live.validate_prepared_restore(prepared.prepared);assert(validation.ok)
	check(live._publish_prepared_restore(prepared.prepared,validation).ok and live.read_unit("a").facing_dir==2,"Validated private tail publishes prepared values for later Root grouping")
	terrain.free();finish()
func finish()->void:
	print("HEX_GROUND_PREPARED_RESTORE passed=",passed," failed=",failed)
	quit(0 if failed==0 else 1)
