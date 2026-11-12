extends SceneTree
const START = preload("res://scripts/meta/game_start_contract.gd")
const NAV = preload("res://scripts/meta/base_interior_navigation.gd")
var failed := 0
func check(value: bool, label: String) -> void:
	print(("PASS: " if value else "FAIL: ") + label)
	if not value: failed += 1
func _init() -> void: call_deferred("run")
func run() -> void:
	START.request_start(self, "campaign", "new")
	var flow: Node = load("res://scenes/meta/meta_layer_test.tscn").instantiate(); root.add_child(flow)
	await process_frame
	var adapter: Node = flow.get("_singleplayer_runtime")
	var base: Node = adapter.get_base_personnel_runtime()
	var result: Dictionary = adapter.request_operation("campaign_build_housing", {"request_id":"housing-geometry"})
	if not result.get("ok", false): check(false, "construct housing"); flow.queue_free(); await process_frame; quit(1); return
	var layout: Dictionary = base.get_snapshot().layout
	var stage := Node3D.new(); root.add_child(stage)
	for asset: Dictionary in layout.assets:
		if String(asset.id) not in ["habitat_cutaway_01", "freihafen_hall_01", "utility_fuel_01", "campaign_habitat_01"]: continue
		var model: Node3D = load(asset.path).instantiate(); stage.add_child(model)
		model.scale = Vector3.ONE * float(asset.scale); model.position = Vector3(asset.plane[0], 0, asset.plane[1])
	await process_frame
	for model in stage.get_children():
		for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
			var body := StaticBody3D.new(); stage.add_child(body); body.global_transform = mesh.global_transform
			var collider := CollisionShape3D.new(); collider.shape = mesh.mesh.create_trimesh_shape(); body.add_child(collider)
	await physics_frame; await physics_frame
	var space := stage.get_world_3d().direct_space_state
	var shape := CapsuleShape3D.new(); shape.radius = 0.18; shape.height = 0.65
	var query := PhysicsShapeQueryParameters3D.new(); query.shape = shape
	var terrain: Node = base.get_terrain_registry()
	var nav = base._navigation_graph
	var start: Vector2 = base.get_actor("campaign_leader").position
	for index in range(2,4):
		var bed: Dictionary = layout.beds[index]
		var grid := Vector2i(int(bed.grid[0]), int(bed.grid[1]))
		var path: Array = nav.find_world_path(start, terrain.grid_to_world(grid))
		var clear := not path.is_empty()
		var previous := NAV.plane_at_grid(terrain.world_to_grid(start))
		for point: Vector2 in path:
			var current := NAV.plane_at_grid(terrain.world_to_grid(point))
			query.transform = Transform3D(Basis.IDENTITY, previous + Vector3.UP * 0.545)
			query.motion = current - previous
			if not space.intersect_shape(query, 1).is_empty() or space.cast_motion(query)[0] < 0.99999:
				print("BLOCKED at ", previous, " to ", current); clear = false; break
			previous = current
		check(clear, "capsule path avoids actual building meshes to indoor bed %d" % index)
	stage.queue_free(); flow.queue_free(); await process_frame
	if failed == 0: print("CAMPAIGN_HOUSING_COLLISION_PASS")
	quit(0 if failed == 0 else 1)
