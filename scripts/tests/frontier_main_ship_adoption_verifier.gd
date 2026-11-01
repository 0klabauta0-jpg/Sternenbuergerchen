extends SceneTree
## Ref03 adoption: full P04 pad/shell/fact gate plus explicit <25k source identity.
## Historical P04/R02 <20k source and evidence remain unchanged.
const PREVIEW: PackedScene = preload("res://scenes/tests/frontier_art_preview.tscn")
const VIEW: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const MAP: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const HEX: GDScript = preload("res://scripts/terrain/hex_grid.gd")
const SHIPS: GDScript = preload("res://scripts/terrain/frontier_ship_visuals.gd")
const CATALOG_PATH: String = "res://data/frontier_ship_visual_catalog.json"
const OUTPUT_PATH: String = "res://output/grafik_20261101/main_adoption/ships/adoption_check.json"
const EXPECTED: Dictionary = {
	"cutlass_01":{"sha256":"21484195affa66a1bc503f34b20ae561312057e46e077250e8a772b6881e6daf","triangles":22496,"length":16.0},
	"buccaneer_01":{"sha256":"922bd0fa668a90121dd5101541f4b5792d791f801a6dd1e7caa9d98a59b3a6c3","triangles":19672,"length":11.0}}
var passed: int = 0
var failed: int = 0
var checks: Array[Dictionary] = []
var diagnostics: Dictionary = {}

func _initialize() -> void:
	call_deferred("run")

func check(value: bool,label: String) -> void:
	checks.append({"pass":value,"label":label})
	if value:
		passed += 1
	else:
		failed += 1
		print("FAIL: ",label)

func run() -> void:
	check(FileAccess.file_exists(CATALOG_PATH),"one shared versioned visual catalog exists")
	check(SHIPS.get_for_role("dropship").get("asset_id","")=="cutlass_01","normal dropship role resolves Cutlass")
	check(SHIPS.get_for_role("fighter_reference").get("asset_id","")=="buccaneer_01","Buccaneer catalog reference creates no fighter gameplay")
	var preview: Node = PREVIEW.instantiate()
	root.add_child(preview)
	await process_frame
	preview.set_process(false)
	var simulation: Node = preview.get("_sim") as Node
	simulation.set_physics_process(false)
	var stage: Node3D = preview.get("_stage") as Node3D
	var registry: Node = preview.get("_registry") as Node
	var data: RefCounted = preview.get("_data") as RefCounted
	var pads: Array = Array(preview.get("_pad_facts"))
	var model_facts: Array = Array(preview.get("_model_facts"))
	check(pads.size()==2,"two separately authored outpost decks")
	var index: int = 0
	for ship_id: String in EXPECTED:
		var entry: Dictionary = SHIPS.get_ship(ship_id)
		var path: String = String(entry.get("model_path",""))
		check(SHIPS.get_ship("  "+ship_id.to_upper()+".glb  ")==entry,ship_id+" normalized catalog identity")
		check(FileAccess.get_sha256(path)==String(EXPECTED[ship_id]["sha256"]),ship_id+" exact immutable Ref03 bytes")
		check(float(entry.get("scale",0))==0.22 and String(entry.get("forward_axis",""))=="+Z" and float(entry.get("root_rotation_y_degrees",-1))==0.0,ship_id+" .22 +Z yaw0 convention")
		var matched: bool = false
		for fact_value: Variant in model_facts:
			var fact: Dictionary = Dictionary(fact_value)
			matched = matched or (String(fact.get("path",""))==path and String(fact.get("source_sha256",""))==FileAccess.get_sha256(path))
		check(matched,ship_id+" preview source matches catalog hash")
		var packed: PackedScene = load(path) as PackedScene
		check(packed!=null,ship_id+" fresh Godot imported resource exists")
		if packed!=null:
			var source: Node3D = packed.instantiate() as Node3D
			root.add_child(source)
			var source_bounds: AABB = preview.call("_combined_bounds",source)
			var bmin: Array = Array(entry["bounds_min"])
			var bsize: Array = Array(entry["bounds_size"])
			check(source_bounds.position.distance_to(Vector3(float(bmin[0]),float(bmin[1]),float(bmin[2])))<0.002 and source_bounds.size.distance_to(Vector3(float(bsize[0]),float(bsize[1]),float(bsize[2])))<0.002,ship_id+" imported bounds match independently audited source")
			check(absf(source_bounds.position.y)<0.002 and absf(source_bounds.size.z-float(EXPECTED[ship_id]["length"]))<0.002,ship_id+" ground pivot and stylized normalized length")
			check(source.get_child_count()==1 and source.find_children("*","AnimationPlayer",true,false).is_empty() and source.find_children("*","CollisionObject3D",true,false).is_empty(),ship_id+" static consolidated visual only")
			source.free()
		var ship: Node3D = stage.get_node(ship_id) as Node3D
		var bounds: AABB = preview.call("_combined_bounds",ship)
		var pad: Dictionary = Dictionary(pads[index])
		var center: Vector2 = Vector2(float(pad["center"][0]),float(pad["center"][1]))
		var size: Vector2 = Vector2(float(pad["size"][0]),float(pad["size"][1]))
		var deck: Rect2 = Rect2(center-size*0.5,size)
		check(is_equal_approx(bounds.position.y,float(pad["deck_height"])),ship_id+" landing feet contact deck")
		check(deck.grow(-0.15).encloses(Rect2(Vector2(bounds.position.x,bounds.position.z),Vector2(bounds.size.x,bounds.size.z))),ship_id+" complete rotated silhouette fits pad")
		var stats: Dictionary = mesh_stats(ship)
		check(bool(stats["finite"]) and int(stats["triangles"])==int(EXPECTED[ship_id]["triangles"]) and int(stats["triangles"])<25000,ship_id+" finite exact geometry within versioned 25k budget")
		check(int(stats["materials"])==8 and not bool(stats["missing_material"]) and not bool(stats["material_override"]),ship_id+" eight original imported materials without override")
		diagnostics[ship_id] = {"path":path,"sha256":FileAccess.get_sha256(path),"bounds":str(bounds),"stats":stats}
		index += 1
	for pad_id: String in ["01","02"]:
		var pad_node: Node3D = stage.get_node("OutpostLandingPad_"+pad_id) as Node3D
		var cap_count: int = 0
		var upward: bool = true
		for found: Node in pad_node.find_children("ChamferedDeck*","MeshInstance3D",true,false):
			var mesh: MeshInstance3D = found as MeshInstance3D
			var normals: PackedVector3Array = mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_NORMAL]
			for i: int in range(0,normals.size(),9):
				cap_count += 3
				for j: int in range(3):
					upward = upward and normals[i+j].y>0.95
		check(cap_count>0 and upward,"pad "+pad_id+" deck upward normals")
		var ramp: MeshInstance3D = pad_node.get_node("AccessRamp") as MeshInstance3D
		var ramp_vertices: PackedVector3Array = ramp.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		var footprint: Rect2 = pad_node.get("footprint")
		check(not ramp_vertices.is_empty() and absf(ramp_vertices[0].x)<footprint.size.x*0.5-0.04,"pad "+pad_id+" ramp overlaps inset deck")
		var walkable_centers: int = 0
		for tile: RefCounted in data.call("get_tiles"):
			var grid: Vector2i = tile.get("grid_position")
			if footprint.has_point(HEX.axial_to_plane(Vector2(grid))) and bool(registry.call("is_walkable",grid)):
				walkable_centers += 1
		check(walkable_centers==0,"pad "+pad_id+" no walkable ground under raised deck")
	check(stage.has_node("utility_fuel_01") and not stage.has_node("service_unit_01"),"supported utility replaces old tank assembly")
	check(stage.find_children("StaticYardLoaderVisualOnly","",true,false).is_empty(),"old toy loader removed")
	var shells: Array = Array(preview.get("_closed_shells"))
	check(shells.size()==2,"both buildings retain optional exterior shells")
	preview.call("_set_buildings_closed",true)
	var visible_shells: int = 0
	for shell: Node3D in shells:
		if shell.visible:
			visible_shells += 1
		var door: MeshInstance3D = shell.get_node("DoorFrame") as MeshInstance3D
		var door_box: AABB = door.transform*door.get_aabb()
		var windows_clear: bool = true
		for found: Node in shell.find_children("*","MeshInstance3D",false,false):
			var window: MeshInstance3D = found as MeshInstance3D
			if window.name=="FrontWindowFrame" or (window.mesh is BoxMesh and window.position.y>0.3 and is_equal_approx(window.position.z,door.position.z) and window.mesh.size.x<door.mesh.size.x):
				var box: AABB = window.transform*window.get_aabb()
				windows_clear = windows_clear and (box.end.x<door_box.position.x or box.position.x>door_box.end.x)
		check(windows_clear,"exterior window frames outside door opening")
	check(visible_shells==2,"closed mode shows both exteriors")
	var facts: Array = tile_facts(data)
	for camera_id: String in ["cutlass_front","cutlass_rear","buccaneer_front","buccaneer_rear","utility","outpost"]:
		preview.call("_camera_view",camera_id)
	preview.call("_set_buildings_closed",false)
	for shell: Node3D in shells:
		check(not shell.visible,"cutaway mode hides exterior shell")
	preview.call("_set_buildings_closed",true)
	check(facts==tile_facts(data),"display cameras and shell modes preserve map facts")
	preview.free()
	await process_frame
	await check_normal_dropship()
	var report: Dictionary = {"passed":passed,"failed":failed,"checks":checks,"diagnostics":diagnostics,"version":"astra_ref03_main_adoption_v1","synthetic_preview_checks":true,"new_gameplay_capability":false,"catalog_sha256":FileAccess.get_sha256(CATALOG_PATH),"verifier_sha256":FileAccess.get_sha256(get_script().resource_path)}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_PATH.get_base_dir()))
	var file: FileAccess = FileAccess.open(OUTPUT_PATH,FileAccess.WRITE)
	if file!=null:
		file.store_string(JSON.stringify(report,"  "))
		file.close()
	else:
		failed += 1
		push_error("Cannot write adoption evidence")
	print("FRONTIER_MAIN_SHIP_ADOPTION ",JSON.stringify(report))
	quit(1 if failed else 0)

func tile_facts(data: RefCounted) -> Array:
	var result: Array = []
	for tile: RefCounted in data.call("get_tiles"):
		result.append(tile.call("to_dict"))
	return result

func mesh_stats(ship: Node3D) -> Dictionary:
	var tris: int = 0
	var finite: bool = true
	var mats: Dictionary = {}
	var missing: bool = false
	var overrides: bool = false
	for found: Node in ship.find_children("*","MeshInstance3D",true,false):
		var mesh: MeshInstance3D = found as MeshInstance3D
		finite = finite and mesh.transform.is_finite()
		overrides = overrides or mesh.material_override!=null
		for surface: int in range(mesh.mesh.get_surface_count()):
			var arrays: Array = mesh.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			tris += int((indices.size() if not indices.is_empty() else vertices.size())/3)
			for vertex: Vector3 in vertices:
				finite = finite and vertex.is_finite()
			var material: Material = mesh.get_active_material(surface)
			missing = missing or material==null
			if material!=null:
				mats[material.get_instance_id()] = true
	return {"triangles":tris,"finite":finite,"materials":mats.size(),"missing_material":missing,"material_override":overrides}

func check_normal_dropship() -> void:
	var view: Node = VIEW.new()
	root.add_child(view)
	var data: RefCounted = MAP.call("create_empty","ship_yaw",Vector2i(8,8),Vector2.ZERO) as RefCounted
	view.call("configure_from_map",data)
	var before: Array = tile_facts(data)
	var origin_tile: RefCounted = data.call("get_tile_at_grid",Vector2i(3,3)) as RefCounted
	var from_world: Vector2 = origin_tile.get("world_position")
	var axes: Array[Vector2i] = [Vector2i(4,3),Vector2i(2,3),Vector2i(3,4),Vector2i(3,2),Vector2i(4,4),Vector2i(2,4),Vector2i(4,2),Vector2i(2,2)]
	for target_grid: Vector2i in axes:
		var target_tile: RefCounted = data.call("get_tile_at_grid",target_grid) as RefCounted
		var target_world: Vector2 = target_tile.get("world_position")
		view.call("set_mission_drop_visual_state",{"dropship_visible":true,"dropship_position":from_world,"dropship_target_position":target_world,"flight_altitude_clearance":1.36,"team_id":"team_alpha"})
		await process_frame
		var drop_root: Node3D = view.get("_drop_root") as Node3D
		var models: Array[Node] = drop_root.find_children("DropshipModel_*","Node3D",false,false)
		check(models.size()==1,"normal dropship has one model "+str(target_grid))
		if models.size()!=1:
			continue
		var model: Node3D = models[0] as Node3D
		check(String(model.get_meta("ship_asset_id",""))=="cutlass_01" and String(model.get_meta("ship_source_sha256",""))==String(EXPECTED["cutlass_01"]["sha256"]),"normal dropship uses exact adopted identity "+str(target_grid))
		var physical_from: Vector3 = view.call("_world_to_3d_position",from_world,0.0)
		var physical_to: Vector3 = view.call("_world_to_3d_position",target_world,0.0)
		check(model.basis.z.normalized().dot((physical_to-physical_from).normalized())>0.9999,"+Z nose follows actual flight direction "+str(target_grid))
		var snapshot: Dictionary = view.call("get_render_snapshot")
		check(model.scale.is_equal_approx(Vector3.ONE*0.22) and is_equal_approx(float(snapshot.get("dropship_air_clearance",0)),1.36) and is_equal_approx(model.position.y,float(snapshot.get("dropship_surface_y",0))+1.36),"adopted scale and unchanged air clearance "+str(target_grid))
		check(String(model.get_meta("flight_altitude_layer",""))=="mission_air" and bool(model.get_meta("terrain_height_independent",false)),"existing mission_air metadata retained "+str(target_grid))
	check(before==tile_facts(data),"dropship appearance/yaw preserves authoritative tile facts")
	var cache: Dictionary = view.get("_model_scene_cache")
	cache[String(SHIPS.get_for_role("dropship")["model_path"])] = null
	check(Dictionary(view.call("_get_frontier_dropship_visual_entry")).is_empty(),"unavailable adopted scene allows existing mapping fallback")
	var fallback: Node3D = view.call("_add_dropship_proxy",from_world,{"dropship_visible":true},"fallback_test") as Node3D
	check(fallback!=null and String(fallback.get_meta("ship_asset_id",""))=="legacy_speeder_b","legacy craft mapping remains renderable fallback")
	view.queue_free()
	await process_frame
