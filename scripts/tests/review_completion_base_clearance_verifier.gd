extends "res://scripts/tests/hex_ground_lifecycle_verifier.gd"
const BASE = preload("res://scripts/core/base_personnel_runtime.gd")
const PERSON = preload("res://scripts/core/base_personnel_actor.gd")
const NAV = preload("res://scripts/meta/base_interior_navigation.gd")
const GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
class Adapter extends Node:
	var _pad_by_craft := {}
	var _service_pad_reservation := {}
class Flow extends Node:
	var _all_team_units: Array = []
	var _homebase_aircraft_definitions: Array = []
	var _aircraft_location_by_craft := {}
	func _find_pending_mission_craft_transfer(_craft: String) -> Dictionary: return {}
	func is_campaign_start() -> bool: return false

func _run() -> void:
	if not GUARD.require_isolated_user_data(): return
	_test_clearance_owner()
	await process_frame
	print("REVIEW_COMPLETION_BASE_CLEARANCE passed=%d failed=%d" % [passed,failed])
	quit(1 if failed else 0)

func _test_clearance_owner() -> void:
	var cells: Array = []
	for x in range(10):
		for y in range(3): cells.append(Vector2i(x,y))
	var rig := _admission_rig(cells)
	rig.sim.set_physics_process(false)
	for tile in rig.terrain.get_all_tiles(): tile.world_position = rig.terrain.grid_to_world(tile.grid_position)
	var flow := Flow.new(); rig.scene.add_child(flow)
	var adapter := Adapter.new(); rig.scene.add_child(adapter)
	for owner: Node in [rig.sim,rig.terrain,rig.units]: owner.reparent(adapter)
	rig.sim.unit_registry_path = rig.sim.get_path_to(rig.units)
	rig.sim.terrain_registry_path = rig.sim.get_path_to(rig.terrain)
	var base := BASE.new(); adapter.add_child(base)
	base._flow = flow
	base._sim = rig.sim
	base._terrain = rig.terrain
	base._registry = rig.units
	base._navigation_graph = NAV.new()
	base._navigation_graph.configure_graph(rig.terrain)
	rig.sim.configure_base_personnel(base)
	rig.sim.tick_processed.connect(base._on_tick)
	for id in ["walker","newcomer"]:
		var actor := PERSON.new()
		actor.unit_id = id
		base.add_child(actor)
		rig.units.register_unit(id,actor)
		rig.sim.register_known_unit(id,actor)
		base._states[id] = {"unit_id":id,"status":"outside","craft_id":"","bed_id":"","action":{},"last_result":{},"auto_rest_enabled":false}
	var initial: Array[Dictionary] = [{"unit_id":"walker","grid":Vector2i.ZERO}]
	var admitted: Dictionary = rig.sim.admit_base_ground_people(base,initial)
	_check(admitted.get("ok",false),"actual Base actor is admitted by its bound Root: "+str(admitted.get("reason","")))
	if not admitted.get("ok",false):
		rig.scene.free(); return
	base._navigation_graph.set_field_beds([{"visual_kind":"field_bunk","sleep_plane":[1.5,0.0]}])
	var mask: Dictionary = base.get_ground_ship_blocked_cells()
	_check(mask.get("ok",false) and mask.blocked_cells.has(Vector2i(6,0)),"actual existing clearance graph publishes physical bunk footprint")
	var ground_before: Dictionary = rig.sim.get_hex_ground_planning_snapshot()
	for index in range(4):
		_check(base.get_ground_ship_blocked_cells()==mask and rig.sim.get_hex_ground_planning_snapshot()==ground_before,"clearance reads preserve owner state and mask revision")
	var blocked: Dictionary = base.request_operation("base_move",{"unit_id":"walker","target_position":rig.terrain.grid_to_world(Vector2i(6,0))})
	_check(blocked.get("reason")=="target_blocked" and base._states.walker.action.is_empty(),"Hex Base move cannot enter an actual bunk footprint")
	var blocked_placement: Array[Dictionary] = [{"unit_id":"newcomer","grid":Vector2i(6,0)}]
	_check(rig.sim.admit_base_ground_people(base,blocked_placement).get("reason")=="base_clearance_blocked","atomic Base admission cannot place a person inside the same footprint")
	base._navigation_graph.set_field_beds([])
	var rectangles: Array[Rect2] = [Rect2(1.49,-0.01,0.02,0.02)]
	base._navigation_graph.set_craft_rectangles(rectangles)
	mask = base.get_ground_ship_blocked_cells()
	_check(mask.blocked_cells.has(Vector2i(6,0)),"parked craft footprint uses the same derived mask")
	_check(rig.sim.request_base_ground_move(base,"walker",rig.terrain.grid_to_world(Vector2i(6,0)),"base:1").get("reason")=="target_blocked","Root independently rejects a craft-blocked Hex destination")
	rectangles.clear()
	base._navigation_graph.set_craft_rectangles(rectangles)
	var moved: Dictionary = base.request_operation("base_move",{"unit_id":"walker","target_position":rig.terrain.grid_to_world(Vector2i(6,0))})
	_check(moved.get("ok",false),"removing owner clearance admits a real Base movement command")
	for step in range(150): rig.sim._physics_process(0.1)
	_check(rig.sim.get_hex_unit_state("walker").grid==Vector2i(6,0) and base._states.walker.status=="outside", "same actual Base actor reaches the cleared cell through Hex reservations")
	rig.scene.free()
