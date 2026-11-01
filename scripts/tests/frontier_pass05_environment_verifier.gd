extends SceneTree
## Finite grounded decoration, source preservation and read-only display changes.
const PREVIEW = preload("res://scenes/tests/frontier_art_preview.tscn")
const HEX = preload("res://scripts/terrain/hex_grid.gd")
var passed := 0
var failed := 0
func _initialize() -> void:call_deferred("run")
func check(value: bool,label: String) -> void:
	if value:passed+=1
	else:
		failed+=1
		print("FAIL: ",label)
func run() -> void:
	var preview = PREVIEW.instantiate()
	root.add_child(preview)
	await process_frame
	preview.set_process(false)
	preview.get("_sim").set_physics_process(false)
	var data = preview.get("_data")
	var registry = preview.get("_registry")
	var work = preview.get("_worklife")
	check(work.use_groups.size()==3,"three authored use groups")
	check(work.source_facts.size()==3,"three original Kenney props identified")
	check(work.gravel_count>30 and work.gravel_count<=192,"contact gravel is nonempty and bounded")
	var batch: MultiMeshInstance3D = work.get_node("ContactGravelBatch")
	check(batch.multimesh.instance_count==work.gravel_count,"gravel uses one matching MultiMesh")
	var gravel_finite := true
	for i in range(batch.multimesh.instance_count):
		var transform := batch.multimesh.get_instance_transform(i)
		gravel_finite = gravel_finite and transform.is_finite() and work.call("_clear_ground",Vector2(transform.origin.x,transform.origin.z))
	check(gravel_finite,"decorative gravel transforms finite and outside authored circulation exclusions")
	for model in work.source_facts:
		var node: Node3D = work.get_node("Working_"+String(model["id"]).trim_prefix("working_"))
		var bounds: AABB = work.call("_bounds",node)
		check(absf(bounds.position.y-float(model["support_height"]))<0.0001,"prop sits on declared ground/table support")
		check(FileAccess.get_sha256(model["path"])==model["source_sha256"],"prop source GLB bytes unchanged")
	var solid_walkable := 0
	for tile in data.get_tiles():
		var p: Vector2 = HEX.axial_to_plane(Vector2(tile.grid_position))
		for rect in work.footprints:
			if rect.has_point(p) and registry.is_walkable(tile.grid_position):solid_walkable+=1
	check(solid_walkable==0,"all authored solid props reserve their ground cell centers")
	var crew_planes: Array[Vector2] = []
	for entry in preview.get("_crew"):
		var plane: Vector2 = HEX.axial_to_plane(Vector2(registry.world_to_grid(entry["actor"].position)))
		crew_planes.append(plane)
		check(registry.is_walkable(registry.world_to_grid(entry["actor"].position)),"citizen work placement is walkable")
	var distinct_depths := {}
	for p in crew_planes:distinct_depths[snappedf(p.y,0.1)]=true
	check(distinct_depths.size()>=3,"citizens no longer form one presentation row")
	var facts: Array = []
	for tile in data.get_tiles():facts.append(tile.to_dict())
	var paint: MeshInstance3D = work.get_node("DustBanksAndCompactedApproaches")
	paint.visible=false
	preview.call("_set_buildings_closed",false)
	paint.visible=true
	preview.call("_set_buildings_closed",true)
	var after: Array = []
	for tile in data.get_tiles():after.append(tile.to_dict())
	check(facts==after,"contact paint and building display toggles do not mutate map facts")
	var no_extra_lights: bool = preview.get("_stage").find_children("*","Light3D",true,false).is_empty()
	check(no_extra_lights,"art pass keeps global light and adds no local scene lights")
	preview.free()
	await process_frame
	print("FRONTIER_PASS05_ENVIRONMENT ",JSON.stringify({"passed":passed,"failed":failed,"synthetic_fixture":true}))
	quit(1 if failed else 0)
