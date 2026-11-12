extends "res://scripts/tests/hex_ground_lifecycle_verifier.gd"

const FOOTPRINT_PATH="res://scripts/mission/hex_ground_ship_footprint.gd"
const BODY_PROFILE=preload("res://scripts/mission/polisa_ground_body_profile.gd")
const SHIP_VISUALS=preload("res://scripts/terrain/frontier_ship_visuals.gd")

func _finish()->void:
	_check(ResourceLoader.exists(FOOTPRINT_PATH),"bounded footprint rasterizer reuses the bound ship body contract")
	if failed==0:_test_body_cells()
	print("RESULTS: %d passed, %d failed"%[passed,failed])
	if failed==0:print("HEX_GROUND_SHIP_FOOTPRINT_PASS")
	quit(0 if failed==0 else 1)

func _body_profile(craft:Dictionary,bounds:AABB,yaw:float=0.0)->Dictionary:
	var identity:Dictionary=SHIP_VISUALS.get_ui_identity(craft)
	return BODY_PROFILE.from_projection(craft,{"ok":true,"model_id":craft.model_id,"asset_id":identity.get("asset_id",""),"bounds":bounds,"model_scale":1.0,"cell_size":1.0,"yaw_degrees":yaw})

func _test_body_cells()->void:
	var rig:Dictionary=_admission_rig([Vector2i.ZERO,Vector2i(1,0),Vector2i(2,0),Vector2i(0,1),Vector2i(1,1),Vector2i(2,1)])
	var helper=load(FOOTPRINT_PATH).new()
	var craft:Dictionary={"craft_id":"foreign","model_id":"cutlass"}
	var bound:Dictionary=_body_profile(craft,AABB(Vector3(-0.1,-0.1,-0.1),Vector3(0.2,0.2,0.2)))
	_check(bound.ok,"fixture uses canonical craft/model/asset bound profile")
	if not bound.ok:
		rig.scene.free()
		return
	var before:Dictionary=rig.sim.get_hex_ground_planning_snapshot()
	var cells:Dictionary=helper.cells_for_body(rig.terrain,craft,Vector2.ZERO,bound.profile)
	_check(cells.ok and cells.blocked_cells==[Vector2i.ZERO] and rig.sim.get_hex_ground_planning_snapshot()==before,"small bound body blocks its cell without mutating ground")
	var edge:Dictionary=_body_profile(craft,AABB(Vector3(-0.02,-0.1,-0.02),Vector3(0.04,0.2,0.04)))
	var edge_cells:Dictionary=helper.cells_for_body(rig.terrain,craft,Vector2(32,16),edge.profile)
	_check(edge_cells.ok and edge_cells.blocked_cells.has(Vector2i.ZERO) and edge_cells.blocked_cells.has(Vector2i(1,0)),"body crossing a shared edge blocks both hex surfaces despite missing both centers")
	var touch:Dictionary=_body_profile(craft,AABB(Vector3(0.0,-0.1,-0.02),Vector3(0.04,0.2,0.04)))
	var touch_cells:Dictionary=helper.cells_for_body(rig.terrain,craft,Vector2(32,16),touch.profile)
	_check(touch_cells.ok and touch_cells.blocked_cells.has(Vector2i.ZERO),"boundary contact is conservatively occupied")
	var rejected:Dictionary=helper.cells_for_body(rig.terrain,craft,Vector2.ZERO,bound.profile,1)
	_check(not rejected.ok and rejected.reason=="footprint_budget" and rejected.blocked_cells.is_empty() and rejected.examined==0,"raster budget rejects before returning any clipped free area")
	var wrong:Dictionary=craft.duplicate()
	wrong.craft_id="other"
	_check(not helper.cells_for_body(rig.terrain,wrong,Vector2.ZERO,bound.profile).ok and not helper.cells_for_body(rig.terrain,craft,Vector2.ZERO,{}).ok,"foreign or unbound geometry fails closed")
	var shifted:Dictionary=helper.cells_for_body(rig.terrain,craft,rig.terrain.grid_to_world(Vector2i(1,0)),bound.profile)
	var ids:=PackedStringArray(["a","b"])
	for id in ids:_add_admission_actor(rig,id)
	var prepared:Dictionary=rig.sim.prepare_hex_ground_deployment(ids,Vector2i.ZERO,shifted.blocked_cells)
	var clear:=bool(prepared.ok)
	if prepared.ok:
		for placement in prepared.placements:clear=clear and placement.grid!=Vector2i(1,0)
	_check(clear,"actual Root group admission excludes the foreign body and finds a legal route around it")
	if prepared.ok:rig.sim.cancel_hex_ground_deployment(prepared.admission_id,"fixture_done")
	var blocked:Dictionary=rig.sim.prepare_hex_ground_deployment(ids,Vector2i(1,0),shifted.blocked_cells)
	_check(not blocked.ok and rig.sim.get_hex_ground_planning_snapshot().admission_slots_by_grid.is_empty(),"blocked body anchor leaves full group aboard without partial slots")
	rig.terrain.configure_iso_grid(Vector2(731.5,-223.75),96,24,"hex_axial_v1")
	var metric:Dictionary=helper.cells_for_body(rig.terrain,craft,rig.terrain.grid_to_world(Vector2i.ZERO),bound.profile)
	_check(metric.ok and metric.blocked_cells.has(Vector2i.ZERO),"raster uses actual registry origin and projection metric")
	rig.scene.free()
