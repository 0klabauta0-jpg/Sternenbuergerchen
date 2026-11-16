extends SceneTree
var failed:=0
func _init() -> void: call_deferred("_run")
func check(ok: bool,label: String) -> void:
	if not ok: failed+=1
	print("PASS: " if ok else "FAIL: ",label)
func _run() -> void:
	var map=load("res://scripts/terrain/terrain_map_data.gd").load_from_file("res://maps/trade_outpost.json")
	var presentation: Dictionary=map.get_place_presentation()
	check(float(presentation.get("initial_camera_size",0))==22,"place has deliberately closer initial tactical framing")
	var stage:=Node3D.new(); root.add_child(stage)
	var built: Dictionary=load("res://scripts/terrain/place_reference_dressing.gd").build(stage,presentation)
	# build() lists the structures first, then the props; fences, crates and walls do not all block by design.
	# Expectation derived from the saved map: one blocker per structure, plus one per prop whose scene exists (place_reference_dressing.gd).
	var building_count:=Array(presentation.get("structures",[])).size()
	var loadable_props:=0
	for prop: Dictionary in Array(presentation.get("props",[])):
		if ResourceLoader.exists(String(prop.get("path",""))): loadable_props+=1
	var building_blockers: Array=Array(built.blockers).slice(0,building_count)
	check(building_count>=1 and building_blockers.size()==building_count and Array(built.blockers).size()==building_count+loadable_props,"trade compound builds one blocker per saved structure plus one per loadable prop (%d + %d)"%[building_count,loadable_props])
	var missing:=0; var solids:=0
	for tile in map.get_tiles():
		var point: Vector2=load("res://scripts/terrain/hex_grid.gd").axial_to_plane(Vector2(tile.grid_position))
		for bounds: AABB in building_blockers:
			var footprint:=Rect2(Vector2(bounds.position.x,bounds.position.z),Vector2(bounds.size.x,bounds.size.z)).grow(.58)
			if footprint.has_point(point):
				solids+=1
				if tile.walkable or not tile.blocks_los or int(tile.object_height)<clampi(ceili(bounds.end.y/.42),1,3): missing+=1
	check(solids>25 and missing==0,"saved navigation and LOS cover actual closed exterior geometry")
	var registry: Node=load("res://scripts/terrain/terrain_registry.gd").new()
	registry.configure_iso_grid(map.get_grid_origin(),64,32,map.get_grid_topology())
	for tile in map.get_tiles(): registry.register_tile(tile)
	var navigation=load("res://scripts/meta/base_interior_navigation.gd").new(); navigation.configure_graph(registry)
	var path: Array=navigation.find_world_path(map.get_marker_position("spawn_alpha"),map.get_marker_position("trade_service"))
	check(not path.is_empty(),"real landing area remains connected to actual trade service")
	check(load("res://scripts/mission/field_landing_contract.gd").validate(registry,registry.world_to_grid(map.get_marker_position("spawn_alpha")),[]).get("ok",false),"compound leaves landing footprint free")
	registry.free(); stage.queue_free(); await process_frame
	print("PLACE_DRESSING failed=",failed); quit(1 if failed else 0)
