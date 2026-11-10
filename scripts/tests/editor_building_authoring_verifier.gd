extends SceneTree
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const SERVICE_PATH := "res://scripts/editor/building_layout_authoring.gd"
var passed := 0
var failed := 0
func _init() -> void: call_deferred("_run")
func check(value: bool, label: String) -> void:
	if value: passed += 1
	else: failed += 1
	print("PASS: " if value else "FAIL: ",label)
func _run() -> void:
	check(FileAccess.file_exists(SERVICE_PATH), "building authoring service exists")
	if not FileAccess.file_exists(SERVICE_PATH): quit(1); return
	var service = load(SERVICE_PATH)
	for topology in ["square8","hex_axial_v1"]:
		var map = MAP.create_empty("building_test",Vector2i(32,24),Vector2.ZERO,64,32,3,topology)
		var start: String = JSON.stringify(map.get_tiles()[0].to_dict())
		var plan: Dictionary = service.plan(map,"place",{"asset_id":"frontier_hall_exterior","grid":Vector2i(10,10),"scale":1.0})
		check(plan.get("ok",false),topology+" full building placement plans")
		if not plan.get("ok",false): print(plan); continue
		check(map.get_place_presentation().is_empty(),topology+" planning never mutates source")
		check(Array(plan.changes).size()>1,topology+" footprint covers multiple real cells")
		service.apply(map,plan)
		var id: String = plan.building_id
		check(service.id_at_grid(map,Vector2i(10,10))==id,topology+" building can be picked by footprint")
		check(not map.get_tile_at_grid(Vector2i(10,10)).walkable,topology+" placement blocks navigation")
		var move: Dictionary = service.plan(map,"move",{"building_id":id,"grid":Vector2i(18,12)})
		check(move.get("ok",false),topology+" move plans")
		service.apply(map,move)
		check(map.get_tile_at_grid(Vector2i(10,10)).walkable,topology+" old footprint released")
		var rotated: Dictionary = service.plan(map,"rotate",{"building_id":id,"delta_degrees":90.0})
		check(rotated.get("ok",false),topology+" rotate plans")
		service.apply(map,rotated)
		var before: String=JSON.stringify(map.get_place_presentation())
		var blocked: Dictionary = service.plan(map,"place",{"asset_id":"frontier_habitat_exterior","grid":Vector2i(18,12)})
		check(not blocked.get("ok",true),topology+" intersecting hulls rejected")
		check(JSON.stringify(map.get_place_presentation())==before,topology+" rejection leaves metadata unchanged")
		check(not service.plan(map,"move",{"building_id":id,"grid":Vector2i(0,0)}).get("ok",true),topology+" map-edge overflow rejected")
		var scratch := "user://editor_building_%d/%s.json" % [OS.get_process_id(),topology]
		check(map.save_to_file(scratch)==OK,topology+" saves authoring data")
		var loaded=MAP.load_from_file(scratch)
		check(service.id_at_grid(loaded,Vector2i(18,12))==id,topology+" picking survives JSON number types")
		var remove: Dictionary=service.plan(loaded,"remove",{"building_id":id})
		check(remove.get("ok",false),topology+" loaded building can be removed")
		service.apply(loaded,remove)
		check(loaded.get_tile_at_grid(Vector2i(18,12)).walkable,topology+" reload/remove restores substrate")
		check(JSON.stringify(loaded.get_tiles()[0].to_dict())==start,topology+" unrelated terrain untouched")
		map.set_marker("protected_point","objective_point",map.get_tile_at_grid(Vector2i(26,18)).world_position)
		check(not service.plan(map,"place",{"asset_id":"frontier_habitat_exterior","grid":Vector2i(26,18)}).get("ok",true),topology+" marker remains reachable")
		map.set_patrol_path("watch",[map.get_tile_at_grid(Vector2i(5,15)).world_position])
		check(not service.plan(map,"place",{"asset_id":"frontier_habitat_exterior","grid":Vector2i(5,15)}).get("ok",true),topology+" patrol remains reachable")
		map.get_tile_at_grid(Vector2i(5,5)).surface_type="water"
		check(not service.plan(map,"place",{"asset_id":"frontier_habitat_exterior","grid":Vector2i(5,5)}).get("ok",true),topology+" water rejected")
		map.get_tile_at_grid(Vector2i(23,5)).height_level=1
		check(not service.plan(map,"place",{"asset_id":"frontier_habitat_exterior","grid":Vector2i(23,5)}).get("ok",true),topology+" uneven ground rejected")
	var shared=MAP.create_empty("shared",Vector2i(24,24),Vector2.ZERO,64,32)
	var hall: Dictionary=service.plan(shared,"place",{"asset_id":"frontier_hall_exterior","grid":Vector2i(10,10),"scale":.85})
	service.apply(shared,hall)
	var habitat: Dictionary=service.plan(shared,"place",{"asset_id":"frontier_habitat_exterior","grid":Vector2i(7,10),"scale":.85})
	check(habitat.get("ok",false),"separate hulls may share a coarse reservation cell")
	service.apply(shared,habitat)
	service.apply(shared,service.plan(shared,"remove",{"building_id":habitat.building_id}))
	check(not shared.get_tile_at_grid(Vector2i(8,10)).walkable,"shared cell stays blocked for remaining owner")
	service.apply(shared,service.plan(shared,"remove",{"building_id":hall.building_id}))
	check(shared.get_tile_at_grid(Vector2i(8,10)).walkable,"last owner releases shared cell")
	for name in ["station_outpost_64x64","station_outpost_192x192"]:
		var station=MAP.load_from_file("res://maps/%s.json"%name)
		var prop: Dictionary=station.get_place_presentation().props[0]
		var request: Dictionary=service.plan(station,"remove",{"building_id":prop.building_id})
		check(request.get("ok",false),name+" persisted building is editable")
		if not request.get("ok",false): print(request)
		else:
			service.apply(station,request)
			var remaining: Array=station.get_place_presentation().props
			check(remaining.size()==(1 if name.ends_with("64x64") else 17),name+" removal preserves other buildings")
	var protected=MAP.load_from_file("res://maps/campaign_intro_base.json")
	check(not service.plan(protected,"place",{"asset_id":"frontier_habitat_exterior","grid":Vector2i(50,50)}).get("ok",true),"separate base fine navigation protected")
	print("EDITOR_BUILDING_AUTHORING passed=%d failed=%d" % [passed,failed])
	quit(1 if failed else 0)
