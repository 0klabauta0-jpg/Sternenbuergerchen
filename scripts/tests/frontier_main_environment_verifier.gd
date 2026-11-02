extends SceneTree
## Versioned adoption gate: seven original assets plus two explicit Ref03 ships.
## Historical P06 all-nine-unchanged assertion remains in its original verifier.
const PREVIEW = preload("res://scenes/tests/frontier_art_preview.tscn")
const HEX = preload("res://scripts/terrain/hex_grid.gd")
const GROUND_SHADER = preload("res://shaders/terrain/frontier_ground.gdshader")
var passed := 0
var failed := 0
func _initialize() -> void:call_deferred("run")
func check(value: bool,label: String) -> void:
	if value:passed+=1
	else:
		failed+=1
		print("FAIL: ",label)
func facts(data) -> Array:
	var result: Array = []
	for tile in data.get_tiles():result.append(tile.to_dict())
	return result
func run() -> void:
	var preview = PREVIEW.instantiate()
	root.add_child(preview)
	await process_frame
	preview.set_process(false)
	preview.get("_sim").set_physics_process(false)
	var stage: Node3D = preview.get("_stage")
	var view = preview.get("_view")
	var data = preview.get("_data")
	var registry = preview.get("_registry")
	var old: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://output/grafik_20261101/pass06_environment_before_capture.json"))
	var old_models: Dictionary = {}
	for row in old.get("models",[]):old_models[row["id"]]=row["source_sha256"]
	var unchanged: bool = old_models.size()==9 and preview.get("_model_facts").size()==9
	var adopted_ship_hashes := {"cutlass_01":"21484195affa66a1bc503f34b20ae561312057e46e077250e8a772b6881e6daf","buccaneer_01":"922bd0fa668a90121dd5101541f4b5792d791f801a6dd1e7caa9d98a59b3a6c3"}
	for row in preview.get("_model_facts"):
		var expected: String = adopted_ship_hashes.get(row["id"],old_models.get(row["id"],""))
		unchanged = unchanged and expected==FileAccess.get_sha256(row["path"])
	check(unchanged,"seven environment/citizen GLBs unchanged and exactly the two user-directed Ref03 ships adopted")
	check(data.get_grid_topology()=="hex_axial_v1" and data.get_tiles().size()==396,"existing 396 Hex facts remain the navigation domain")
	var flat := true
	for tile in data.get_tiles():flat = flat and tile.height_level==0
	check(flat,"visual foot relief does not invent gameplay height levels")
	var ground: MeshInstance3D = stage.get_node("DistantGroundVisualOnly")
	check(ground.mesh is PlaneMesh and is_equal_approx(ground.position.y,0.0015),"flat authoritative display owner remains a separate unmodified plane")
	check(ground.material_override is ShaderMaterial and ground.material_override.shader==GROUND_SHADER,"continuous soil uses the revised shared painterly material")
	var dressing: Node3D = stage.get_node("FrontierWorkingGround")
	var apron: MeshInstance3D = dressing.get_node("LoadingApron")
	check(apron.material_override is ShaderMaterial and apron.material_override.get_shader_parameter("paved_surface")==true,"loading apron actually uses scuffed paving route")
	var marks := 0
	var worn_marks := true
	for mesh in dressing.find_children("*","MeshInstance3D",true,false):
		var part: String = mesh.get_meta("art_part","")
		if part in ["PathEdgeGuide","ServiceLaneGuide","ApronBayStripe"]:
			marks+=1
			worn_marks = worn_marks and mesh.material_override is ShaderMaterial and mesh.material_override.get_shader_parameter("marking_surface")==true
	check(marks>40 and worn_marks,"all actual authored path and apron markings use selective paint loss")
	var paint: MeshInstance3D = preview.get("_worklife").get_node("DustBanksAndCompactedApproaches")
	check(paint.position.y<apron.position.y+0.006,"dust contact layer stays below opaque loading apron")
	var before: Array = facts(data)
	preview.call("_set_buildings_closed",false)
	paint.hide()
	preview.call("_set_buildings_closed",true)
	paint.show()
	view.set_hex_grid_visible(true)
	view.set_hex_grid_visible(false)
	check(before==facts(data),"weathering visibility, C and Hex display cannot change terrain facts")
	var grounded := true
	for entry in preview.get("_crew"):
		var p: Vector3 = view.call("_world_to_surface_3d_position",entry["actor"].position,0.003)
		grounded = grounded and registry.is_walkable(registry.world_to_grid(entry["actor"].position)) and is_equal_approx(p.y,0.003)
	check(grounded,"all four citizens retain walkable flat support at their authored positions")
	check(stage.find_children("*","Light3D",true,false).is_empty(),"material revision adds no local lights")
	preview.free()
	await process_frame
	print("FRONTIER_MAIN_ENVIRONMENT ",JSON.stringify({"passed":passed,"failed":failed,"synthetic_fixture":true,"markings":marks}))
	quit(1 if failed else 0)
