extends SceneTree
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const DRESSING = preload("res://scripts/terrain/place_reference_dressing.gd")
const SHELL = preload("res://scripts/terrain/frontier_closed_buildings.gd")
const WEAR = preload("res://shaders/terrain/frontier_building_wear.gdshader")
var passed := 0
var failed := 0

func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else: failed += 1
	print("PASS " if ok else "FAIL ", label)

func mesh_parts(node: Node) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	if node is MeshInstance3D and node.mesh != null: result.append(node)
	for child: Node in node.get_children(): result.append_array(mesh_parts(child))
	return result

func audit(parts: Array[MeshInstance3D], label: String) -> Dictionary:
	var materials: Dictionary = {}
	var count := 0
	var valid_bounds := true
	var no_instance_properties := true
	for part: MeshInstance3D in parts:
		for property: Dictionary in part.get_property_list():
			if String(property.name).begins_with("instance_shader_parameters/"): no_instance_properties = false
		var material := part.material_override as ShaderMaterial
		if material == null or material.shader != WEAR: continue
		count += 1
		materials[material.get_instance_id()] = true
		var bounds := part.get_aabb()
		var minimum: Variant = material.get_shader_parameter("wear_part_min")
		var maximum: Variant = material.get_shader_parameter("wear_part_max")
		valid_bounds = valid_bounds and minimum is Vector3 and maximum is Vector3
		if minimum is Vector3 and maximum is Vector3:
			valid_bounds = valid_bounds and minimum.is_equal_approx(bounds.position) and maximum.is_equal_approx(bounds.end)
	check(count > 0 and valid_bounds, label + " preserves exact local bounds on all wear parts")
	check(no_instance_properties, label + " allocates no per-instance shader slots")
	return {"parts": count, "materials": materials}

func run() -> void:
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/frontier_building_visual_catalog.json"))
	var source_audit: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://docs/qa/review_completion_20261113/frontier_wear_material_migration.json"))
	for record: Dictionary in source_audit.scenes:
		check(FileAccess.get_sha256("res://"+String(record.path)) == String(record.after_sha256), "migrated scene matches byte-preservation audit " + String(record.path))
		check(not FileAccess.get_file_as_string("res://"+String(record.path)).contains("instance_shader_parameters/wear_part_"), "serialized scene needs no legacy instance values")
	for kind: String in ["habitat", "hall"]:
		var spec: Dictionary = catalog["frontier_"+kind+"_exterior"]
		var scene: PackedScene = load(String(spec.model_path))
		var first: Node3D = scene.instantiate()
		var second: Node3D = scene.instantiate()
		var holder := Node3D.new(); root.add_child(holder); holder.add_child(first); holder.add_child(second)
		var a: Array[MeshInstance3D] = mesh_parts(first)
		var b: Array[MeshInstance3D] = mesh_parts(second)
		var result := audit(a, "packed " + kind)
		check(result.parts == (44 if kind == "habitat" else 43), "every original wear part is present " + kind)
		var shared := a.size() == b.size()
		for index in mini(a.size(), b.size()): shared = shared and a[index].mesh == b[index].mesh and a[index].material_override == b[index].material_override and a[index].transform == b[index].transform
		check(shared, "repeated " + kind + " shares meshes and material variants with identical transforms")
		var bounds: AABB = DRESSING.mesh_bounds(first, holder)
		var lo := Vector3(float(spec.min[0]), float(spec.min[1]), float(spec.min[2]))
		var hi := Vector3(float(spec.max[0]), float(spec.max[1]), float(spec.max[2]))
		check(bounds.position.is_equal_approx(lo) and bounds.end.is_equal_approx(hi), "published original model bounds remain unchanged " + kind)
		check(FileAccess.get_sha256(String(spec.source_model)) == String(spec.source_sha256), "original binary source unchanged " + kind)
		var shell := SHELL.new(); holder.add_child(shell)
		var original: AABB = first.get_child(0).get_meta("original_world_bounds")
		shell.build(original, kind == "hall")
		var built := audit(mesh_parts(shell), "live builder " + kind)
		check(built.parts == result.parts, "live builder and saved scene retain every wear part " + kind)
		var old_count: int = shell.get("_materials").size()
		var part: MeshInstance3D = mesh_parts(shell)[0]
		var unchanged := part.material_override as ShaderMaterial
		var color: Color = unchanged.get_shader_parameter("base_color")
		for index in range(1000): shell.call("_route_material", part, String(part.get_meta("surface_role_label")), color.to_html(false))
		check(shell.get("_materials").size() == old_count and part.material_override == unchanged, "1000 unchanged bounds reuse live material " + kind)
		holder.free()
	var map = MAP.load_from_file("res://maps/station_outpost_192x192.json")
	var presentation: Dictionary = map.get_place_presentation()
	var unchanged_map: PackedByteArray = var_to_bytes(map.get_tiles().map(func(tile): return tile.to_dict()))
	var owner := Node3D.new(); root.add_child(owner)
	var dressing: Dictionary = DRESSING.build(owner, presentation)
	var live := audit(mesh_parts(dressing.root), "actual 18 Station192 buildings")
	check(presentation.props.size() == 18 and dressing.blockers.size() == 18, "real production presentation instantiates all 18 authored buildings")
	check(live.parts == 783, "783 live wear parts exceed old 256-instance capacity without dropping any part")
	check(live.materials.size() == 86, "18 buildings reuse only 86 immutable material variants")
	check(var_to_bytes(map.get_tiles().map(func(tile): return tile.to_dict())) == unchanged_map, "rendering preserves every actual terrain fact")
	await process_frame
	owner.free()
	print("REVIEW_BUILDING_MATERIAL passed=%d failed=%d" % [passed, failed])
	quit(0 if failed == 0 else 1)
