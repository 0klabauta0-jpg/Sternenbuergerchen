extends SceneTree
const NAV = preload("res://scripts/meta/base_interior_navigation.gd")
const REGISTRY = preload("res://scripts/terrain/terrain_registry.gd")
const CAPACITY = preload("res://scripts/meta/base_capacity_layout.gd")
var stage: Node3D
var failures: Array[String] = []
func _init() -> void: call_deferred("run")
func run() -> void:
	var map = NAV.load_map("res://maps/campaign_intro_base.json")
	var layout: Dictionary = NAV.layout("res://maps/campaign_intro_base.json")
	var terrain = REGISTRY.new(); root.add_child(terrain)
	var sizes: Dictionary = map.get_tile_size()
	terrain.configure_iso_grid(map.get_grid_origin(), sizes.half_width, sizes.half_height, map.get_grid_topology())
	for tile in map.get_tiles(): terrain.register_tile(tile)
	var nav = NAV.new(); nav.configure_graph(terrain)
	var expanded: Dictionary = {}
	for count in range(3,21):
		expanded = CAPACITY.expand(layout, terrain, nav, count, {"campaign_beds":count})
		if expanded.beds.size() != count: failures.append("sequential expansion failed at %d" % count); break
		nav.set_field_beds(expanded.beds)
	nav.set_field_beds(expanded.beds)
	stage = Node3D.new(); root.add_child(stage)
	for asset: Dictionary in layout.assets:
		if asset.id not in ["habitat_cutaway_01", "freihafen_hall_01", "utility_fuel_01"]: continue
		var model: Node3D = load(asset.path).instantiate(); stage.add_child(model)
		model.scale = Vector3.ONE * float(asset.scale); model.position = Vector3(asset.plane[0],0,asset.plane[1])
	await process_frame
	for model in stage.get_children():
		for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
			var body := StaticBody3D.new(); stage.add_child(body); body.global_transform = mesh.global_transform
			var shape := CollisionShape3D.new(); shape.shape = mesh.mesh.create_trimesh_shape(); body.add_child(shape)
	await physics_frame; await physics_frame
	var space := stage.get_world_3d().direct_space_state
	var box := BoxShape3D.new(); box.size = Vector3(0.65,0.22,1.8)
	var query := PhysicsShapeQueryParameters3D.new(); query.shape = box
	var fields: Array = []
	for bed: Dictionary in expanded.beds:
		if bed.get("visual_kind", "") != "field_bunk": continue
		var p := Vector3(float(bed.sleep_plane[0]), 0.3, float(bed.sleep_plane[1]))
		query.transform = Transform3D(Basis.IDENTITY,p)
		if not space.intersect_shape(query, 1).is_empty(): failures.append("bed intersects imported asset: " + String(bed.id))
		for other in fields:
			if absf(p.x-other.x) < 0.65 and absf(p.z-other.z) < 1.8: failures.append("beds overlap: " + String(bed.id))
		fields.append(p)
	for p: Vector3 in fields:
		var body := StaticBody3D.new(); stage.add_child(body); body.position = p
		var collider := CollisionShape3D.new(); collider.shape = box; body.add_child(collider)
	await physics_frame; await physics_frame
	var actor := CapsuleShape3D.new(); actor.radius = 0.18; actor.height = 0.65
	query.shape = actor
	var original_spawn := Vector2i(int(layout.avatar_spawn_grid[0]),int(layout.avatar_spawn_grid[1]))
	var spawn: Vector2i = terrain.world_to_grid(nav.nearest_available_world(terrain.grid_to_world(original_spawn)))
	var obstructed := 0
	var starts: Array[Vector2i] = [spawn]
	for item: Dictionary in expanded.beds:
		if item.get("visual_kind", "") == "field_bunk": starts.append(Vector2i(int(item.grid[0]),int(item.grid[1])))
	for bed: Dictionary in expanded.beds:
		if bed.get("visual_kind", "") != "field_bunk": continue
		var destination := Vector2i(int(bed.grid[0]),int(bed.grid[1]))
		for start in starts:
			if start == destination: continue
			var path: Array = nav.find_world_path(terrain.grid_to_world(start),terrain.grid_to_world(destination))
			if path.is_empty(): print("EMPTY_PATH ", bed.id, " from ",start); obstructed += 1; continue
			var previous := NAV.plane_at_grid(start)
			for point: Vector2 in path:
				var current := NAV.plane_at_grid(terrain.world_to_grid(point))
				query.transform = Transform3D(Basis.IDENTITY,previous + Vector3.UP * 0.545)
				query.motion = current - previous
				if not space.intersect_shape(query,1).is_empty() or space.cast_motion(query)[0] < 0.99999:
					print("BLOCKED_PATH ",bed.id," from ", start," at ", previous)
					obstructed += 1; break
				previous = current
	print("FIELD_BED_ROUTES_OBSTRUCTED ", obstructed)
	if obstructed > 0: failures.append("routes intersect bunk visuals: %d" % obstructed)
	print("ACTUAL_BEDS count=", expanded.beds.size(), " fields=", fields.size(), " failures=", failures)
	stage.queue_free(); terrain.queue_free(); await process_frame
	if failures.is_empty() and expanded.beds.size() == 20: print("CAMPAIGN_BED_ACTUAL_GEOMETRY_PASS"); quit(0)
	else: quit(1)
