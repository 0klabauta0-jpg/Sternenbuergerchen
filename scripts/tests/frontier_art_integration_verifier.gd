extends SceneTree
const PREVIEW = preload("res://scenes/tests/frontier_art_preview.tscn")
const HEX = preload("res://scripts/terrain/hex_grid.gd")
var passed := 0
var failed := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	if value:
		passed += 1
	else:
		failed += 1
		print("FAIL: ",label)

func run() -> void:
	var preview = PREVIEW.instantiate()
	root.add_child(preview)
	await process_frame
	var crew: Array = preview.get("_crew")
	var view = preview.get("_view")
	var data = preview.get("_data")
	var registry = preview.get("_registry")
	var simulation = preview.get("_sim")
	simulation.set_physics_process(false)
	check(crew.size()==4,"four Kenney-based citizens in the native fixture")
	check(preview.get("_model_facts").size()==9,"three structures, two ships and four citizens loaded")
	check(data.get_grid_topology()=="hex_axial_v1","new base uses Hex map facts")
	for entry in crew:
		var visual: Node3D = entry["visual"]
		var meshes: Array = visual.find_children("*","MeshInstance3D",true,false)
		check(meshes.size()==2,"original character and modular gear meshes imported")
		var original_count := 0
		for mesh in meshes:
			if mesh.mesh.get_surface_count()==1:
				original_count += 1
		check(original_count==1,"original body atlas remains a single-material mesh")
		check(not String(entry["idle"]).is_empty() and not String(entry["walk"]).is_empty(),"original idle and walk imported")
		check(registry.is_walkable(registry.world_to_grid(entry["actor"].position)),"citizen starts on walkable Hex")
	preview.call("_camera_view","crew")
	var before_size: float = view.get_camera_size()
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel.pressed = true
	preview.call("_unhandled_input",wheel)
	check(view.get_camera_size()<before_size,"crew zoom-in moves closer instead of jumping to mission zoom floor")
	var camera: Camera3D = view.get_node("ViewportContainer/SubViewport/WorldRoot/Camera3D")
	var before_transform: Transform3D = camera.transform
	var key := InputEventKey.new()
	key.keycode = KEY_G
	key.pressed = true
	preview.call("_unhandled_input",key)
	check(camera.transform.is_equal_approx(before_transform),"Hex grid toggle preserves preview close framing")
	check(is_equal_approx(view.get_camera_size(),before_size*0.9),"Hex grid toggle preserves preview zoom")
	var facts_before: Array = _map_facts(data)
	preview.call("_walk_demo")
	var actor: Node2D = crew[0]["actor"]
	var start: Vector2 = actor.position
	for index in range(360):
		simulation.call("_physics_process",1.0/60.0)
	check(actor.position.distance_to(start)>10.0,"SimulationRoot executes the preview walking command")
	check(registry.is_walkable(registry.world_to_grid(actor.position)),"walking ends on a walkable Hex")
	check(_map_facts(data)==facts_before,"walking and display controls do not mutate map facts")
	var stage: Node3D = preview.get("_stage")
	var overlapping_mesa_centers := 0
	var mesa_meshes: Array = []
	for mesh in stage.find_children("*","MeshInstance3D",true,false):
		if String(mesh.get_parent().name).begins_with("MesaCluster_"):
			mesa_meshes.append(mesh)
	for tile in data.get_tiles():
		if not tile.walkable:
			continue
		var plane: Vector2 = HEX.axial_to_plane(Vector2(tile.grid_position))
		for mesh in mesa_meshes:
			var box: AABB = mesh.global_transform * mesh.get_aabb()
			# Conservative AABB test catches a decorative mass entering a walkable cell.
			if box.grow(0.01).has_point(Vector3(plane.x,0.0,plane.y)):
				overlapping_mesa_centers += 1
	check(overlapping_mesa_centers==0,"decorative mesas stay outside walkable centers")
	preview.queue_free()
	await process_frame
	print("FRONTIER_ART_INTEGRATION ",JSON.stringify({"passed":passed,"failed":failed}))
	quit(1 if failed else 0)

func _map_facts(data) -> Array:
	var result: Array = []
	for tile in data.get_tiles():
		result.append(tile.to_dict())
	return result
