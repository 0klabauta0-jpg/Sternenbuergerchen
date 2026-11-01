extends SceneTree
## Native import, deck contact, pad fit and authoritative obstacle regression.
const PREVIEW = preload("res://scenes/tests/frontier_art_preview.tscn")
const HEX = preload("res://scripts/terrain/hex_grid.gd")
var passed := 0
var failed := 0
var diagnostics: Dictionary = {}

func _initialize() -> void:
	call_deferred("run")

func check(value: bool,label: String) -> void:
	if value:
		passed += 1
	else:
		failed += 1
		print("FAIL: ",label)

func run() -> void:
	var preview = PREVIEW.instantiate()
	root.add_child(preview)
	await process_frame
	preview.set_process(false)
	preview.get("_sim").set_physics_process(false)
	var stage: Node3D = preview.get("_stage")
	var registry = preview.get("_registry")
	var data = preview.get("_data")
	var ships := ["cutlass_01","buccaneer_01"]
	var pads: Array = preview.get("_pad_facts")
	check(pads.size()==2,"two separately authored outpost decks")
	for index in range(ships.size()):
		var ship: Node3D = stage.get_node(ships[index])
		var bounds: AABB = preview.call("_combined_bounds",ship)
		var pad: Dictionary = pads[index]
		var center := Vector2(pad["center"][0],pad["center"][1])
		var size := Vector2(pad["size"][0],pad["size"][1])
		var deck := Rect2(center-size*0.5,size)
		check(is_equal_approx(bounds.position.y,float(pad["deck_height"])),ships[index]+" landing feet contact the deck")
		var footprint := Rect2(Vector2(bounds.position.x,bounds.position.z),Vector2(bounds.size.x,bounds.size.z))
		check(deck.grow(-0.15).encloses(footprint),ships[index]+" entire rotated silhouette fits the pad")
		var tris := 0
		var finite := true
		for mesh in ship.find_children("*","MeshInstance3D",true,false):
			finite = finite and mesh.global_transform.is_finite()
			for surface in range(mesh.mesh.get_surface_count()):
				var arrays: Array = mesh.mesh.surface_get_arrays(surface)
				var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
				var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
				tris += (indices.size() if not indices.is_empty() else vertices.size())/3
				for vertex in vertices: finite = finite and vertex.is_finite()
		check(finite and tris>0 and tris<20000,ships[index]+" finite imported geometry within 20k triangle budget")
		diagnostics[ships[index]] = {"bounds":str(bounds),"triangles":tris}
	for id in ["01","02"]:
		var pad: Node3D = stage.get_node("OutpostLandingPad_"+id)
		var cap_count := 0
		var upward := true
		for mesh in pad.find_children("ChamferedDeck*","MeshInstance3D",true,false):
			var arrays: Array = mesh.mesh.surface_get_arrays(0)
			var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			for i in range(0,normals.size(),9):
				cap_count += 3
				for j in range(3): upward = upward and normals[i+j].y>0.95
		check(cap_count>0 and upward,"pad "+id+" deck has upward normals")
		var ramp: MeshInstance3D = pad.get_node("AccessRamp")
		var ramp_vertices: PackedVector3Array = ramp.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		check(not ramp_vertices.is_empty() and absf(ramp_vertices[0].x)<pad.footprint.size.x*0.5-0.04,"pad "+id+" ramp start overlaps the inset deck")
		var walkable_centers := 0
		for tile in data.get_tiles():
			if pad.footprint.has_point(HEX.axial_to_plane(Vector2(tile.grid_position))) and registry.is_walkable(tile.grid_position):
				walkable_centers += 1
		check(walkable_centers==0,"pad "+id+" raised deck contains no walkable ground cells")
	check(stage.has_node("utility_fuel_01") and not stage.has_node("service_unit_01"),"new supported utility replaces old tank assembly")
	check(stage.find_children("StaticYardLoaderVisualOnly","",true,false).is_empty(),"old toy loader removed")
	var shells: Array = preview.get("_closed_shells")
	check(shells.size()==2,"both buildings have complete optional exterior shells")
	preview.call("_set_buildings_closed",true)
	var visible_shells := 0
	for shell in shells:
		if shell.visible: visible_shells += 1
	check(visible_shells==2,"closed mode shows both exteriors")
	for shell in shells:
		var door: MeshInstance3D = shell.get_node("DoorFrame")
		var door_box: AABB = door.transform*door.get_aabb()
		var windows_clear := true
		for window in shell.find_children("*","MeshInstance3D",false,false):
			if window.name=="FrontWindowFrame" or (window.mesh is BoxMesh and window.position.y>0.3 and is_equal_approx(window.position.z,door.position.z) and window.mesh.size.x<door.mesh.size.x):
				var box: AABB = window.transform*window.get_aabb()
				windows_clear = windows_clear and (box.end.x<door_box.position.x or box.position.x>door_box.end.x)
		check(windows_clear,"exterior window frames remain outside the door opening")
	var facts: Array = []
	for tile in data.get_tiles(): facts.append(tile.to_dict())
	for id in ["cutlass_front","cutlass_rear","buccaneer_front","buccaneer_rear","utility","outpost"]:
		preview.call("_camera_view",id)
	preview.call("_set_buildings_closed",false)
	for shell in shells: check(not shell.visible,"cutaway mode hides exterior shell")
	preview.call("_set_buildings_closed",true)
	var after: Array = []
	for tile in data.get_tiles(): after.append(tile.to_dict())
	check(facts==after,"new display cameras do not mutate map facts")
	preview.free()
	await process_frame
	print("FRONTIER_PASS04 ",JSON.stringify({"passed":passed,"failed":failed,"diagnostics":diagnostics,"synthetic_fixture":true}))
	quit(1 if failed else 0)
