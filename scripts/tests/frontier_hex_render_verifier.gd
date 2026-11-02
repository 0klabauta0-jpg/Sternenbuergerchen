extends SceneTree
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const VIEW = preload("res://scripts/terrain/terrain_map_3d_view.gd")
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
	var data = MAP.create_empty("hex_render",Vector2i(8,8),Vector2.ZERO,64.0,32.0,3,"hex_axial_v1")
	var view = VIEW.new()
	root.add_child(view)
	view.set_frontier_art_enabled(true)
	view.configure_from_map(data)
	var snapshot: Dictionary = view.get_render_snapshot()
	check(snapshot.get("grid_topology","")=="hex_axial_v1","renderer uses map topology")
	check(int(snapshot.get("tile_count",0))==64,"all Hex cells rendered")
	check(int(snapshot.get("ground_multimesh_tile_count",0))==64,"Hex cells use MultiMesh batching")
	check(int(snapshot.get("ground_multimesh_instance_count",0))<8,"resource count bounded by material/height family")
	var center_grid := Vector2i(3,3)
	var center: Vector3 = view.call("_grid_to_3d_position",Vector2(center_grid),0.0)
	for neighbor in HEX.neighbors(center_grid):
		var position: Vector3 = view.call("_grid_to_3d_position",Vector2(neighbor),0.0)
		check(is_equal_approx(center.distance_to(position),1.0),"equal visible neighbor distance")
		var origin_world: Vector2 = data.get_tile_at_grid(center_grid).world_position
		var target_world: Vector2 = data.get_tile_at_grid(neighbor).world_position
		var yaw: float = view.call("_get_unit_world_direction_yaw",origin_world,target_world,0.0)
		var recovered: Vector2 = view.call("_get_world_direction_from_proxy_yaw",origin_world,yaw)
		check(recovered.dot((target_world-origin_world).normalized())>0.99999,"Hex proxy yaw follows visible direction and roundtrips")
	var camera: Camera3D = view.get_node("ViewportContainer/SubViewport/WorldRoot/Camera3D")
	for grid in [Vector2i(2,2),Vector2i(4,2),Vector2i(2,4),Vector2i(4,4)]:
		var tile = data.get_tile_at_grid(grid)
		var world: Vector2 = tile.world_position
		check(view.world_to_grid_position(world)==grid,"Hex world roundtrip")
		var position: Vector3 = view.call("_grid_to_3d_position",Vector2(grid),0.0)
		var screen: Vector2 = camera.unproject_position(position)
		check(view.screen_to_grid_position(screen)==grid,"rendered Hex center picks its source cell")
		check(view.call("_get_tile_top_screen_quad",tile).size()==6,"picking polygon has six corners")
	view.set_selected_grid_positions([center_grid])
	var selection: MeshInstance3D = view.get_node("ViewportContainer/SubViewport/WorldRoot/SelectionRoot3D/Selection_3_3")
	check(selection.mesh is CylinderMesh and selection.mesh.radial_segments==6,"selection uses Hex geometry")
	view.set_hex_grid_visible(false)
	check(view.get_node("ViewportContainer/SubViewport/WorldRoot/MapRoot3D").get_node_or_null("TileGridLines3D")==null,"grid lines can be hidden without changing ground")
	check(data.get_tiles().size()==64,"display toggle preserves source map")
	var fow_root: Node3D = view.get_node("ViewportContainer/SubViewport/WorldRoot/FogOfWarRoot3D")
	view.call("_add_fow_overlay_multimesh","HexOverlayProbe",[Transform3D.IDENTITY],Color.BLACK,false,fow_root)
	var overlay: MultiMeshInstance3D = fow_root.get_node("HexOverlayProbe")
	check(overlay.multimesh.mesh is CylinderMesh and overlay.multimesh.mesh.radial_segments==6,"FoW uses six-sided cells")
	check(is_equal_approx(overlay.multimesh.mesh.top_radius,1.0/sqrt(3.0)),"FoW covers full Hex tips")
	view.queue_free()
	await process_frame
	print("FRONTIER_HEX_RENDER ",JSON.stringify({"passed":passed,"failed":failed}))
	quit(1 if failed else 0)
