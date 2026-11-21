extends SceneTree

const Models = preload("res://models.gd")
const TOLERANCE := 0.001

var failures: PackedStringArray


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var variants := {}
	for file in [Models.SEGMENTED, Models.ATLAS, Models.GAME, Models.CUTLASS]:
		var loaded := Models.load_asset(file)
		if loaded.has("error"):
			failures.append(loaded.error)
			continue
		var stats: Dictionary = loaded.stats
		var label: String = file.get_file()
		variants[label] = stats
		if file == Models.CUTLASS:
			_expect(absf(stats.bounds_size[2] - 3.52) < TOLERANCE, label, "catalog scale gives 3.52 world units along Z")
		else:
			_verify_tanker(file, stats)
		(loaded.model as Node3D).free()

	var output := FileAccess.open("res://import_evidence.json", FileAccess.WRITE)
	if output == null:
		failures.append("Could not write import_evidence.json")
	else:
		output.store_line(JSON.stringify({
			"godot": Engine.get_version_info().string,
			"route": "GLTFDocument.append_from_file + generate_scene",
			"game_world_units_per_meter": Models.GAME_SCALE,
			"checks_failed": failures,
			"variants": variants,
		}, "  ", true, true))
		output.close()
	if not failures.is_empty():
		for failure in failures:
			printerr("FAIL: ", failure)
		quit(1)
		return
	print("PASS: tanker glTF")
	quit()


func _verify_tanker(file: String, stats: Dictionary) -> void:
	var expected_meshes := 82 if file == Models.SEGMENTED else 1
	var scale_factor := Models.GAME_SCALE if file == Models.GAME else 1.0
	var dimensions := Models.SIZE_METERS * scale_factor
	for axis in 3:
		_expect(absf(stats.bounds_size[axis] - dimensions[axis]) < TOLERANCE, file, "expected size on axis %s" % axis)
	for axis in [0, 2]:
		_expect(absf(stats.bounds_min[axis] + stats.bounds_max[axis]) < TOLERANCE, file, "centered on axis %s" % axis)
	_expect(absf(stats.bounds_min[1]) < TOLERANCE, file, "ground pivot Y = 0")
	_expect(stats.triangles == Models.CLEAN_TRIANGLES and stats.triangles <= 30000, file, "clean geometry triangle count within budget")
	_expect(stats.mesh_instances == expected_meshes, file, "expected mesh count")
	_expect(stats.mesh_surfaces == expected_meshes, file, "expected surface count")
	_expect(stats.materials == expected_meshes, file, "expected material count")
	_expect(stats.non_triangle_surfaces == 0, file, "all surfaces contain triangles")
	_expect(stats.missing_material_slots == 0, file, "material in every slot")
	_expect(stats.missing_surface_uv == 0, file, "complete UV0 on every surface")
	_expect(stats.missing_albedo_texture_slots == 0, file, "albedo texture in every slot")
	_expect(stats.source_images > 0 and stats.source_images == stats.embedded_image_buffer_views, file, "all GLB images embedded")
	_expect(stats.source_images == stats.decoded_images, file, "every embedded image decoded")


func _expect(condition: bool, file: String, expectation: String) -> void:
	if not condition:
		failures.append("%s: %s" % [file, expectation])
