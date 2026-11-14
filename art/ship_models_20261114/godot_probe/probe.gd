extends SceneTree
## Isolated, offline importer. This script never loads the game or its cache.
## Capture mode is native Godot rendering; structural verdicts are independent.
const SHIP_IDS := ["prospector", "vulture", "gladius", "hornet", "caterpillar"]
var _checks: Array[Dictionary] = []
var _failures := 0
var _reports: Array[Dictionary] = []
var _run_dir: String
var _render := false
var _stage: Node3D
var _camera: Camera3D
var _floor: MeshInstance3D
var _label: Label
var _capture_paths: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	_checks.append({"pass": ok, "label": label})
	if not ok:
		_failures += 1
		print("FAIL: ", label)

func _vector(v: Vector3) -> Array:
	return [v.x, v.y, v.z]

func _bounds_json(b: AABB) -> Dictionary:
	return {"min": _vector(b.position), "max": _vector(b.end), "size": _vector(b.size)}

func _run() -> void:
	var selected: Array = SHIP_IDS.duplicate()
	var tag := "headless"
	for arg: String in OS.get_cmdline_user_args():
		if arg == "--render":
			_render = true
			tag = "native"
		elif arg.begins_with("--ships="):
			selected = Array(arg.trim_prefix("--ships=").split(",", false))
	var stamp := Time.get_datetime_string_from_system(true).replace(":", "").replace("-", "")
	_run_dir = ProjectSettings.globalize_path("res://runs/" + tag + "_" + stamp + "_" + str(OS.get_process_id()))
	DirAccess.make_dir_recursive_absolute(_run_dir)
	_check(not selected.is_empty(), "nonempty selected model list")
	if _render:
		_check(DisplayServer.get_name() != "headless", "capture uses actual native renderer")
		_setup_studio()
	for ship: String in selected:
		await _inspect_ship(ship)
	if _render and not _capture_paths.is_empty():
		_make_contact_sheet()
	var report := {"schema": "ship_models.godot_probe.v1", "engine": Engine.get_version_info(),
		"probe_sha256": FileAccess.get_sha256("res://probe.gd"), "rendered": _render,
		"renderer": RenderingServer.get_current_rendering_method(), "checks": _checks,
		"check_count": _checks.size(), "failures": _failures, "ships": _reports,
		"captures": _capture_paths, "scope": "Fresh direct GLTFDocument imports in an isolated Godot project. Asset geometry and animation preview only; no gameplay integration, playthrough, collision, performance or artistic approval."}
	var file := FileAccess.open(_run_dir.path_join("report.json"), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(report, "  "))
		file.close()
	else:
		_failures += 1
		print("FAIL: cannot write report")
	if _stage:
		_stage.free()
	await process_frame
	print("SHIP_PROBE_REPORT ", _run_dir.path_join("report.json"))
	print("SHIP_PROBE_CHECKS ", _checks.size(), " FAILURES ", _failures)
	if _failures == 0:
		print("PASS: ship_asset_import")
	quit(1 if _failures else 0)

func _inspect_ship(ship: String) -> void:
	var path := ProjectSettings.globalize_path("res://../" + ship + "/" + ship + ".glb").simplify_path()
	_check(FileAccess.file_exists(path), ship + " GLB exists")
	if not FileAccess.file_exists(path):
		return
	var input_hash := FileAccess.get_sha256(path)
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var result := doc.append_from_file(path, state)
	_check(result == OK, ship + " direct GLTFDocument import succeeds")
	if result != OK:
		return
	var model := doc.generate_scene(state) as Node3D
	_check(model != null, ship + " generate_scene returns Node3D")
	if model == null:
		return
	root.add_child(model)
	await process_frame
	var stats := _geometry_stats(model)
	var bounds: AABB = stats["aabb"]
	stats.erase("aabb")
	_check(int(stats["meshes"]) > 0 and int(stats["triangles"]) > 0, ship + " nonempty imported mesh")
	_check(bool(stats["finite"]), ship + " finite vertices, normals and transforms")
	_check(int(stats["missing_materials"]) == 0, ship + " every surface has a material")
	_check(int(stats["normal_count"]) == int(stats["vertex_count"]) and int(stats["bad_normals"]) == 0, ship + " complete unit normals")
	_check(int(stats["bad_indices"]) == 0, ship + " triangle indices remain in range")
	var source_json: Dictionary = state.json
	var gltf_triangles := 0
	for gltf_mesh: Dictionary in source_json.get("meshes", []):
		for primitive: Dictionary in gltf_mesh.get("primitives", []):
			var accessor: int = int(primitive.get("indices", primitive.get("attributes", {}).get("POSITION", -1)))
			if accessor >= 0:
				gltf_triangles += int(source_json["accessors"][accessor]["count"]) / 3
	_check(int(stats["triangles"]) == gltf_triangles, ship + " imported triangle count matches GLB accessors")
	_check(int(stats["material_count"]) == source_json.get("materials", []).size(), ship + " imported material count matches GLB declarations")
	_check(bounds.size.x > 0.01 and bounds.size.y > 0.01 and bounds.size.z > 0.01, ship + " positive three-dimensional bounds")
	_check(absf(bounds.position.y) < 0.02, ship + " underside on ground pivot")
	var pivot_bounds := bounds
	var pivot_reference := "complete static model"
	if ship == "caterpillar":
		var hulls := model.find_children("Hull", "MeshInstance3D", true, false)
		if hulls.size() == 1:
			var hull := hulls[0] as MeshInstance3D
			pivot_bounds = hull.global_transform * hull.get_aabb()
			pivot_reference = "static Hull; separately authored outboard service lift expands aggregate starboard bounds"
	_check(absf(pivot_bounds.get_center().x) < 0.05 and absf(pivot_bounds.get_center().z) < 0.05, ship + " centered horizontal anchor: " + pivot_reference)
	var recorded := {"ship": ship, "file": path, "sha256": input_hash, "bytes": FileAccess.get_file_as_bytes(path).size(), "geometry": stats, "bounds": _bounds_json(bounds)}
	recorded["pivot_reference"] = {"basis": pivot_reference, "bounds": _bounds_json(pivot_bounds), "aggregate_center": _vector(bounds.get_center())}
	recorded["authoring_metrics"] = _metrics_audit(ship, path.get_base_dir().path_join("metrics.json"), stats, bounds)
	var animations := _animation_audit(model, ship)
	recorded["animations"] = animations
	if _render:
		_reset_animations(model)
		var frame_bounds := _combined_bounds(model)
		var extra: AABB = animations.get("pose_union", frame_bounds)
		frame_bounds = frame_bounds.merge(extra)
		_fit_studio(frame_bounds)
		await _capture(model, ship, "closed", frame_bounds, Vector3(1.1, 0.72, 1.3))
		await _capture(model, ship, "rear", frame_bounds, Vector3(-1.1, 0.6, -1.3))
		if ship == "caterpillar":
			for player: AnimationPlayer in model.find_children("*", "AnimationPlayer", true, false):
				for animation: String in player.get_animation_list():
					if animation == "RESET":
						continue
					_reset_animations(model)
					player.play(animation)
					player.seek(player.get_animation(animation).length * 2.0 / 3.0, true)
					player.pause()
					await _capture(model, ship, "open_lift_down_" + animation.validate_filename(), frame_bounds, Vector3(1.1, 0.72, 1.3))
	animations.erase("pose_union")
	_check(input_hash == FileAccess.get_sha256(path), ship + " GLB bytes unchanged during audit/capture")
	_reports.append(recorded)
	model.free()
	await process_frame

func _metrics_audit(ship: String, path: String, stats: Dictionary, bounds: AABB) -> Dictionary:
	_check(FileAccess.file_exists(path), ship + " current authoring metrics exist")
	if not FileAccess.file_exists(path):
		return {}
	var file_hash := FileAccess.get_sha256(path)
	var source: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	_check(source is Dictionary, ship + " authoring metrics parse")
	if not source is Dictionary:
		return {}
	var metrics: Dictionary = source
	var processed: Dictionary = metrics.get("processed", {})
	var expected_count := int(metrics.get("output_triangles", processed.get("triangles", -1)))
	_check(expected_count > 0 and int(stats["triangles"]) == expected_count, ship + " actual imported triangles match current authoring metrics")
	if not processed.is_empty():
		var raw_min: Array = processed["bounds_min"]
		var raw_max: Array = processed["bounds_max"]
		var expected_min := Vector3(float(raw_min[0]), float(raw_min[2]), -float(raw_max[1]))
		var expected_max := Vector3(float(raw_max[0]), float(raw_max[2]), -float(raw_min[1]))
		_check(bounds.position.distance_to(expected_min) < 0.002 and bounds.end.distance_to(expected_max) < 0.002, ship + " actual imported bounds match current Blender metrics with axis conversion")
		var roundtrip: Dictionary = metrics.get("roundtrip", {})
		if roundtrip.has("materials"):
			_check(int(stats["material_count"]) == int(roundtrip["materials"]), ship + " material count matches current Blender GLB roundtrip")
	_check(file_hash == FileAccess.get_sha256(path), ship + " authoring metrics unchanged while read")
	return {"file": path, "sha256": file_hash, "expected_triangles": expected_count}

func _geometry_stats(model: Node3D) -> Dictionary:
	var meshes := model.find_children("*", "MeshInstance3D", true, false)
	if model is MeshInstance3D:
		meshes.push_front(model)
	var tris := 0
	var vertices_count := 0
	var normals_count := 0
	var bad_normals := 0
	var bad_indices := 0
	var missing_materials := 0
	var finite := true
	var materials: Dictionary = {}
	var parts: Array[Dictionary] = []
	for found: Node in meshes:
		var mesh := found as MeshInstance3D
		finite = finite and mesh.global_transform.is_finite()
		var part_tris := 0
		if not mesh.mesh:
			continue
		for surface: int in range(mesh.mesh.get_surface_count()):
			var arrays := mesh.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			vertices_count += vertices.size()
			normals_count += normals.size()
			part_tris += int((indices.size() if not indices.is_empty() else vertices.size()) / 3)
			for v: Vector3 in vertices:
				finite = finite and v.is_finite()
			for n: Vector3 in normals:
				finite = finite and n.is_finite()
				if absf(n.length() - 1.0) > 0.01:
					bad_normals += 1
			for idx: int in indices:
				if idx < 0 or idx >= vertices.size():
					bad_indices += 1
			var material := mesh.get_active_material(surface)
			if material == null:
				missing_materials += 1
			else:
				materials[material.get_instance_id()] = material.resource_name
		tris += part_tris
		parts.append({"path": str(model.get_path_to(mesh)), "triangles": part_tris, "surfaces": mesh.mesh.get_surface_count(), "bounds": _bounds_json(mesh.global_transform * mesh.get_aabb())})
	return {"meshes": meshes.size(), "triangles": tris, "vertex_count": vertices_count, "normal_count": normals_count,
		"bad_normals": bad_normals, "bad_indices": bad_indices, "finite": finite, "materials": materials.values(),
		"material_count": materials.size(), "missing_materials": missing_materials, "parts": parts, "aabb": _combined_bounds(model)}

func _combined_bounds(model: Node3D) -> AABB:
	var first := true
	var bounds := AABB()
	var meshes := model.find_children("*", "MeshInstance3D", true, false)
	if model is MeshInstance3D:
		meshes.push_front(model)
	for found: Node in meshes:
		var mesh := found as MeshInstance3D
		if not mesh.mesh:
			continue
		var b: AABB = mesh.global_transform * mesh.get_aabb()
		bounds = b if first else bounds.merge(b)
		first = false
	return bounds

func _transforms(model: Node3D) -> Dictionary:
	var values := {}
	for node: Node in model.find_children("*", "Node3D", true, false):
		values[str(model.get_path_to(node))] = (node as Node3D).global_transform
	return values

func _reset_animations(model: Node3D) -> void:
	for player: AnimationPlayer in model.find_children("*", "AnimationPlayer", true, false):
		if player.has_animation("RESET"):
			player.play("RESET")
			player.seek(0.0, true)
		else:
			for clip: String in player.get_animation_list():
				player.play(clip)
				player.seek(0.0, true)
		player.pause()

func _animation_audit(model: Node3D, ship: String) -> Dictionary:
	var clips: Array[Dictionary] = []
	var union := _combined_bounds(model)
	if ship == "caterpillar":
		_check(model.find_children("Hull", "MeshInstance3D", true, false).size() == 1, "caterpillar has one separate static Hull mesh")
	for player: AnimationPlayer in model.find_children("*", "AnimationPlayer", true, false):
		for clip: String in player.get_animation_list():
			if clip == "RESET":
				continue
			_reset_animations(model)
			var before := _transforms(model)
			var duration := player.get_animation(clip).length
			_check(duration > 0.0, ship + " " + clip + " positive animation duration")
			var samples: Array[Dictionary] = []
			var any_moved := {}
			for fraction: float in [1.0 / 3.0, 2.0 / 3.0, 1.0]:
				player.play(clip)
				player.seek(duration * fraction, true)
				player.pause()
				var after := _transforms(model)
				var changed: Array[String] = []
				var stable: Array[String] = []
				var deltas := {}
				for node_path: String in before:
					var from: Transform3D = before[node_path]
					var to: Transform3D = after[node_path]
					if not from.is_equal_approx(to):
						changed.append(node_path)
						any_moved[node_path] = true
						deltas[node_path] = {"translation": _vector(to.origin - from.origin), "rotation_radians": _vector((to.basis * from.basis.inverse()).get_euler())}
					else:
						stable.append(node_path)
					if ship == "caterpillar" and node_path.get_file() == "Hull":
						_check(from.is_equal_approx(to), "caterpillar static Hull stable at clip fraction " + str(fraction))
				var b := _combined_bounds(model)
				union = union.merge(b)
				samples.append({"fraction": fraction, "time": duration * fraction, "moved": changed, "stable": stable, "deltas": deltas, "bounds": _bounds_json(b)})
			_check(not any_moved.is_empty(), ship + " " + clip + " moves imported nodes")
			if ship == "caterpillar":
				var moving_doors := 0
				var moving_lifts := 0
				for node_path: String in any_moved:
					if node_path.get_file().begins_with("CargoDoor_"):
						moving_doors += 1
					if node_path.get_file() == "ServiceLiftDeck":
						moving_lifts += 1
				_check(moving_doors == 8, "caterpillar eight separate imported cargo doors move")
				_check(moving_lifts == 1, "caterpillar separate imported service lift moves")
				_check(samples.back()["moved"].is_empty(), "caterpillar clip returns to closed rest pose")
			clips.append({"name": clip, "length": duration, "tracks": player.get_animation(clip).get_track_count(), "moved": any_moved.keys(), "samples": samples})
	if ship == "caterpillar":
		_check(not clips.is_empty(), "caterpillar has exported mechanical animation")
	_reset_animations(model)
	return {"clips": clips, "pose_union": union}

func _setup_studio() -> void:
	_stage = Node3D.new()
	_stage.name = "IsolatedAssetStudio"
	root.add_child(_stage)
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.055, 0.072, 0.09)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.76, 0.84, 1.0)
	environment.ambient_light_energy = 0.15
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_environment.environment = environment
	_stage.add_child(world_environment)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-45, -35, 0)
	key.light_energy = 0.25
	key.shadow_enabled = true
	_stage.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20, 135, 0)
	fill.light_energy = 0.08
	fill.light_color = Color(0.66, 0.79, 1.0)
	_stage.add_child(fill)
	_floor = MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(1000, 1000)
	_floor.mesh = plane
	_floor.position.y = -0.02
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.11, 0.14, 0.17)
	material.roughness = 0.9
	_floor.material_override = material
	_stage.add_child(_floor)
	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.near = 0.01
	_camera.far = 1000.0
	_stage.add_child(_camera)
	_camera.current = true
	var canvas := CanvasLayer.new()
	_stage.add_child(canvas)
	_label = Label.new()
	_label.position = Vector2(24, 20)
	_label.add_theme_font_size_override("font_size", 22)
	canvas.add_child(_label)
	Engine.max_fps = 30
	root.size = Vector2i(960, 720)

func _fit_studio(bounds: AABB) -> void:
	_floor.position.y = minf(-0.02, bounds.position.y - 0.02)

func _capture(_model: Node3D, ship: String, pose: String, bounds: AABB, direction: Vector3) -> void:
	var extent := maxf(bounds.size.x, maxf(bounds.size.y, bounds.size.z))
	_camera.position = bounds.get_center() + direction.normalized() * extent * 2.5
	_camera.look_at(bounds.get_center(), Vector3.UP)
	_camera.size = extent * 1.12
	_label.text = ship.capitalize() + " / " + pose + "\nGodot 4.6.2 · GLB candidate · isolated studio"
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var path := _run_dir.path_join(ship + "_" + pose + ".png")
	var screenshot := root.get_texture().get_image()
	_check(not screenshot.is_empty() and screenshot.get_width() == 960, ship + " " + pose + " nonempty native capture")
	var error := screenshot.save_png(path)
	_check(error == OK, ship + " " + pose + " saved native capture")
	_capture_paths.append(path)

func _make_contact_sheet() -> void:
	var columns := 2
	var width := 480
	var height := 360
	var rows := ceili(float(_capture_paths.size()) / columns)
	var contact := Image.create(width * columns, height * rows, false, Image.FORMAT_RGB8)
	contact.fill(Color(0.055, 0.072, 0.09))
	for i: int in range(_capture_paths.size()):
		var capture := Image.load_from_file(_capture_paths[i])
		capture.convert(Image.FORMAT_RGB8)
		capture.resize(width, height, Image.INTERPOLATE_LANCZOS)
		contact.blit_rect(capture, Rect2i(0, 0, width, height), Vector2i((i % columns) * width, (i / columns) * height))
	contact.save_png(_run_dir.path_join("native_contact_sheet.png"))
