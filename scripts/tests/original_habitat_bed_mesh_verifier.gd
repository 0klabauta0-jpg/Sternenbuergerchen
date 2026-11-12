extends SceneTree
const BED = preload("res://scripts/meta/original_habitat_bed_mesh.gd")
const GEO = preload("res://scripts/meta/modular_base_geometry.gd")
func _init() -> void:
	var mesh: ArrayMesh = BED.mesh()
	if mesh == null: printerr("FAIL: bed mesh unavailable"); quit(1); return
	var bounds: AABB = mesh.get_aabb()
	if mesh.get_surface_count() != 3 or bounds.size.x < 0.5 or bounds.size.x > 0.7 or bounds.size.z < 0.9 or bounds.size.z > 1.2:
		printerr("FAIL: source bed bounds or materials changed: ", bounds); quit(1); return
	for angle in range(4):
		var room := {"id":"r", "x":0, "y":0, "rotation":angle}
		var bed: Dictionary = GEO.bed_geometry(room, {"id":"b", "slot":0})
		var p := Vector2(bed.sleep_plane[0], bed.sleep_plane[1])
		var access := Vector2(bed.rest_plane[0], bed.rest_plane[1])
		if not GEO.bed_blocks(bed,p) or GEO.bed_blocks(bed,access):
			printerr("FAIL: bed body/access invalid at rotation ", angle); quit(1); return
	print("ORIGINAL_HABITAT_BED_MESH_PASS surfaces=", mesh.get_surface_count(), " bounds=", bounds)
	quit(0)
