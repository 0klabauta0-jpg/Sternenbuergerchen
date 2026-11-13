extends SceneTree
const IDENTITY = preload("res://scripts/terrain/personnel_visual_identity.gd")
const PORTRAITS = preload("res://scripts/meta/portrait_identity_catalog.gd")
const VIEW = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const PREVIEW = preload("res://scripts/ui/components/personnel_body_preview.gd")
const CANVAS = preload("res://scripts/ui/star_map_canvas.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
const BATCH = preload("res://scripts/terrain/hex_ground_batch.gd")
const LAYOUT = preload("res://scripts/terrain/frontier_gm01_layout.gd")
const PROFILE = preload("res://scripts/terrain/frontier_art_profile.gd")
var passed := 0
var failed := 0
var bounds_records: Array = []

func _initialize() -> void: call_deferred("run")
func check(value: bool, label: String) -> void:
	if value: passed += 1
	else: failed += 1
	print(("PASS " if value else "FAIL ") + label)

func run() -> void:
	var actor: Node = load("res://scripts/npc/test_unit.gd").new()
	actor.unit_id = "crew_slot_shared"
	actor.team_id = "team_alpha"
	actor.armor_id = "suit"
	actor.portrait_path = PORTRAITS.resolve_path("char_portrait_004")
	root.add_child(actor)
	var identity := {"portrait_id": "char_portrait_004"}
	check(IDENTITY.resolve(identity) == "char_portrait_004", "authored portrait appearance")
	check(IDENTITY.resolve({}, actor) == "char_portrait_004", "tactical actor portrait appearance")
	check(IDENTITY.resolve({"portrait_id": "char_portrait_001"}) == "char_portrait_001", "different canonical portrait has its own appearance")
	check(IDENTITY.resolve({"portrait_id": "unknown"}).is_empty(), "unknown identity has no guessed appearance")
	check(IDENTITY.resolve({"portrait_path": "res://custom/unknown.png"}).is_empty(), "unknown path never uses UI fallback portrait")
	check(IDENTITY.material_for("unknown") == null, "unknown identity retains original material route")
	check(IDENTITY.resolve({}).is_empty(), "missing identity has no guessed appearance")
	check(IDENTITY.material_for("char_portrait_004") == IDENTITY.material_for("char_portrait_004"), "material shared without per-frame recreation")
	var catalog: Dictionary = PORTRAITS.load_catalog()
	check(catalog.entries.size() == 46, "all active portrait identities reviewed")
	var material_ids: Dictionary = {}
	for entry: Dictionary in catalog.entries:
		var id := String(entry.id)
		check(IDENTITY.resolve({"portrait_id": id}) == id, "canonical portrait maps to itself " + id)
		check(IDENTITY.resolve({"portrait_path": entry.path}) == id, "path resolves same appearance " + id)
		for alias in entry.legacy_paths:
			check(IDENTITY.resolve({"portrait_path": alias}) == id, "legacy path keeps canonical appearance " + id)
		var material: ShaderMaterial = IDENTITY.material_for(id)
		check(material != null and material == IDENTITY.material_for(id), "shared immutable material for " + id)
		material_ids[material.get_instance_id()] = true
	check(material_ids.size() == 46, "independent appearance material parameters cannot bleed into another person")
	check(IDENTITY.material_for("char_portrait_004").get_shader_parameter("skin_color") != IDENTITY.material_for("char_portrait_027").get_shader_parameter("skin_color"), "dark and light source portrait colors remain distinct")
	check(IDENTITY.material_for("char_portrait_004").get_shader_parameter("hair_color") != IDENTITY.material_for("char_portrait_006").get_shader_parameter("hair_color"), "dark and silver source hair remain distinct")
	var view := VIEW.new()
	var original_signature: String = view.call("_build_unit_visual_input_signature", actor)
	var visual: Node3D = view.call("_create_unit_proxy", actor)
	check(visual.get_meta("portrait_appearance") == "char_portrait_004", "actual tactical model uses portrait palette")
	check(visual.get_meta("uses_animated_character_model", false), "existing animated model retained")
	var source_meshes: Array = visual.find_children("*", "MeshInstance3D", true, false)
	check(not source_meshes.is_empty(), "native model meshes present")
	actor.portrait_path = PORTRAITS.resolve_path("char_portrait_001")
	check(view.call("_build_unit_visual_input_signature", actor) != original_signature, "portrait swap dirties rendering with same unit ID")
	var replacement: Node3D = view.call("_create_unit_proxy", actor)
	check(String(replacement.get_meta("portrait_appearance", "")) == "char_portrait_001", "crew slot replacement follows new person instead of retaining Anja appearance")
	visual.free()
	replacement.free()
	var preview := PREVIEW.new()
	root.add_child(preview)
	preview.update_actor(actor, {"armor": "suit"}, identity)
	var first_model: Node3D = preview.get("_model")
	check(first_model.get_meta("portrait_appearance") == "char_portrait_004", "base preview uses supplied canonical person projection")
	preview.update_actor(actor, {"armor": "suit"}, identity)
	check(preview.get("_model") == first_model, "unchanged identity/loadout retains preview mesh")
	preview.update_actor(actor, {"armor": "suit"}, {"portrait_id": "char_portrait_001"})
	check(String(preview.get("_model").get_meta("portrait_appearance", "")) == "char_portrait_001", "preview same actor follows changed person appearance")
	preview.update_actor(actor, {"armor": "suit"})
	actor.portrait_path = PORTRAITS.resolve_path("char_portrait_006")
	preview.update_actor(actor, {"armor": "suit"})
	check(String(preview.get("_model").get_meta("portrait_appearance", "")) == "char_portrait_006", "legacy two-argument preview tracks portrait changes on same actor")
	preview.update_actor(null, {})
	check(preview.get("_model") == null and not preview.get_meta("preview_uses_existing_model"), "missing actor clears stale preview")
	preview.free()
	var base_scene: PackedScene = load("res://Assets/curated/frontier_illustrated_20261101/citizens_pass02/operator.glb")
	var base_model := base_scene.instantiate() as Node3D
	check(IDENTITY.apply_to_model(base_model, identity), "existing base GLB accepts same identity palette")
	var updated_meshes := 0
	var original_meshes: Dictionary = {}
	for mesh: MeshInstance3D in base_model.find_children("*", "MeshInstance3D", true, false):
		original_meshes[mesh] = mesh.mesh
		if mesh.material_override == IDENTITY.material_for("char_portrait_004"): updated_meshes += 1
	check(updated_meshes > 0, "actual base body received material")
	check(not IDENTITY.apply_to_model(base_model, identity), "base palette projection is dirty-only")
	check(IDENTITY.apply_to_model(base_model, {"portrait_id": "char_portrait_001"}), "base palette changes to next canonical identity")
	for mesh in original_meshes:
		check(mesh.mesh == original_meshes[mesh], "base body/equipment geometry unchanged")
		check(mesh.material_override != IDENTITY.material_for("char_portrait_004"), "no old identity material after replacement")
	var node_count := base_model.find_children("*", "Node", true, false).size()
	var stable := true
	var stable_material: ShaderMaterial = IDENTITY.material_for("char_portrait_001")
	var read_start := Time.get_ticks_usec()
	for index in 1000:
		stable = not IDENTITY.apply_to_model(base_model, {"portrait_id": "char_portrait_001"}) and IDENTITY.material_for("char_portrait_001") == stable_material and stable
	print("APPEARANCE_READ_SAMPLE ", JSON.stringify({"reads":1000,"usec":Time.get_ticks_usec()-read_start,"fps_claim":false}))
	check(stable and base_model.find_children("*", "Node", true, false).size() == node_count, "repeated read-only appearance updates keep material and node tree stable")
	check(IDENTITY.apply_to_model(base_model, {"portrait_id": "custom_unknown"}), "unknown replacement restores original authored materials")
	for mesh: MeshInstance3D in base_model.find_children("*", "MeshInstance3D", true, false):
		if mesh.has_meta("identity_source_material"):
			check(mesh.material_override == mesh.get_meta("identity_source_material").material, "original material restored for custom portrait")
	base_model.free()
	actor.free()
	var parent := Node3D.new()
	root.add_child(parent)
	var ground := LAYOUT._ground(parent, PROFILE.new(), [Vector2i.ZERO, Vector2i.ONE])
	check(ground.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "GM01 flat receiver avoids self-shadow stripes")
	check(ground.get_meta("ground_cell_count") == 2, "authored flat ground coverage unchanged")
	var batch := BATCH.new()
	batch.queue_tile(Vector3.ZERO, Color.WHITE, 1.0, StandardMaterial3D.new())
	batch.queue_tile(Vector3(0, 1, 0), Color.WHITE, 1.0, StandardMaterial3D.new())
	batch.flush(parent, false)
	check(parent.get_child(1).cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "H0 column shadow disabled")
	check(parent.get_child(2).cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "raised visible cap cannot cause self-shadow acne")
	var raised_caster: MultiMeshInstance3D = parent.get_node("HexGroundSideShadow_0")
	check(raised_caster.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY and not raised_caster.multimesh.mesh.cap_top and not raised_caster.multimesh.mesh.cap_bottom, "raised real sides retain shadow without a cap caster")
	check(raised_caster.multimesh.mesh.height == parent.get_child(2).multimesh.mesh.height and raised_caster.multimesh.mesh.top_radius == parent.get_child(2).multimesh.mesh.top_radius, "side shadow hull preserves exact visible height and footprint")
	check(batch.mesh_for(1.09, 1.0 / sqrt(3.0), true) == raised_caster.multimesh.mesh, "side caster geometry is cached across chunks")
	parent.free()
	for raised_first: bool in [true, false]:
		var caps := Node3D.new()
		var cap_batch := BATCH.new()
		var cap_material := StandardMaterial3D.new()
		var heights: Array = [2.0, 0.0] if raised_first else [0.0, 2.0]
		for y: float in heights:
			cap_batch.queue_tile(Vector3(0.0, y, 0.0), Color.WHITE, 1.0, cap_material, true)
		var cap_counts: Dictionary = cap_batch.flush(caps, false)
		check(cap_counts.batch_count == 2 and cap_counts.tile_count == 2, "equal-thickness regional caps separate shadow ownership")
		for index in caps.get_child_count():
			var cap: MultiMeshInstance3D = caps.get_child(index)
			# Dummy/headless RenderingServer does not retain MultiMesh transform
			# readback. Match each emitted group to the known insertion sequence.
			check(cap.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "thin regional cap is a shadow receiver at every height and insertion order")
		caps.free()
	for deck_first: bool in [true, false]:
		var mixed := Node3D.new()
		var mixed_batch := BATCH.new()
		var shared_material := StandardMaterial3D.new()
		var deck_order: Array = [true, false] if deck_first else [false, true]
		for is_deck: bool in deck_order:
			mixed_batch.queue_tile(Vector3(0.0, 2.0 if is_deck else 0.05, 0.0), Color.WHITE, 1.0, shared_material, is_deck)
		var mixed_counts: Dictionary = mixed_batch.flush(mixed, false)
		check(mixed_counts.batch_count == 2 and mixed_counts.tile_count == 2, "equally thick cap and solid volume retain separate shadow ownership")
		check(mixed_counts.shadow_batch_count == 1, "only true raised volume produces a side shadow hull")
		for node: Node in mixed.get_children():
			var shadow_only: bool = String(node.name).begins_with("HexGroundSideShadow_")
			check(node.cast_shadow == (GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY if shadow_only else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF), "cap/side ownership is independent of mixed insertion order")
		mixed.free()
	var canvas: Control = CANVAS.new()
	root.add_child(canvas)
	canvas.size = Vector2(1280, 720)
	canvas.reset_camera()
	var shared_mesh: ArrayMesh = canvas.get("_grid_mesh")
	var low: float = canvas.get_camera_snapshot().grid_alpha
	for orbit: Dictionary in canvas.get_orbit_definitions().values():
		var cell := GRID.cell_from_record(orbit.markers[0])
		var center: Vector2 = canvas.map_to_screen(GRID.normalized(cell))
		var polygon: PackedVector2Array = canvas.call("_orbit_marker_polygon", cell)
		var bounds := Rect2(polygon[0], Vector2.ZERO)
		for point in polygon: bounds = bounds.expand(point)
		check(bounds.size.x >= 17.0 and bounds.size.y >= 12.0, "overview marker maintains readable screen extent")
		check(not canvas.orbit_marker_at(center).is_empty(), "rendered marker remains pickable")
	canvas.zoom_at(canvas.size * 0.5, 8.0)
	check(canvas.get_camera_snapshot().grid_alpha > low and low < 0.08, "dense overview grid fades with projected cell size")
	check(canvas.get("_grid_mesh") == shared_mesh, "zoom reuses existing static grid mesh")
	var location_data := {"satellite_crash": {"available": true}}
	canvas.set_location_snapshot(location_data)
	canvas.reset_camera()
	var button: Control = canvas.get("_location_buttons").satellite_crash
	check(button.size.x >= 20.0 and button.size.y >= 20.0, "surface destination has usable minimum target")
	check(location_data == {"satellite_crash": {"available": true}}, "location source stays unchanged")
	canvas.free()
	await _verify_asset_bounds(view)
	view.free()
	await process_frame
	var output := OS.get_environment("SB_REVIEW_COMPLETION_CAPTURE_DIR")
	if not output.is_empty():
		DirAccess.make_dir_recursive_absolute(output)
		var file := FileAccess.open(output.path_join("asset_bounds.json"), FileAccess.WRITE)
		file.store_string(JSON.stringify(bounds_records, "\t"))
		file.close()
	print("REVIEW_GRAPHICS_FIXES passed=%d failed=%d" % [passed, failed])
	quit(0 if failed == 0 else 1)

func _verify_asset_bounds(view: Node) -> void:
	var inventory: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://docs/qa/review_completion_20261113/graphics_inventory.json"))
	for item: Dictionary in inventory.resources:
		var path := "res://" + String(item.path)
		check(FileAccess.get_sha256(path) == String(item.sha256), "source SHA unchanged " + path.get_file())
		if path.get_extension() not in ["glb", "gltf", "fbx", "tscn"]: continue
		var packed: PackedScene = view.call("_get_asset_model_scene_by_path", path)
		check(packed != null, "active resource imports " + path.get_file())
		if packed == null: continue
		var model := packed.instantiate() as Node3D
		root.add_child(model)
		var boxes: Array[AABB] = []
		var mesh_count := 0
		var surface_count := 0
		for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
			if mesh.mesh == null: continue
			boxes.append(mesh.global_transform * mesh.get_aabb())
			mesh_count += 1
			surface_count += mesh.mesh.get_surface_count()
		var bounds := AABB()
		for box: AABB in boxes: bounds = box if not bounds.has_volume() else bounds.merge(box)
		check(not boxes.is_empty() and bounds.position.is_finite() and bounds.size.is_finite() and bounds.size.length() > 0.0, "finite imported bounds " + path.get_file())
		bounds_records.append({"path": item.path, "sha256": item.sha256, "bounds_position": [bounds.position.x, bounds.position.y, bounds.position.z], "bounds_size": [bounds.size.x, bounds.size.y, bounds.size.z], "mesh_count": mesh_count, "surface_count": surface_count, "material_route": item.route, "geometry_changed": false})
		model.free()
		await process_frame
